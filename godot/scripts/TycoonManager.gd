extends Node
## TycoonManager — aktive Rustwater-Wirtschaft & Ripple-Balancer (Master-GDD §2.2, §5.4).
##
## Als Autoload NACH "GameState" registrieren (Name "TycoonManager"). Node-basiert, weil
## der Tick eine aktive Simulationsuhr braucht.
##
## STRIKT AKTIVE SPIELZEIT: Der Tick akkumuliert `_process(delta)` und feuert exakt einmal
## pro real vergangener Sekunde WÄHREND das Spiel läuft. Kein Zeitstempel, kein Offline-
## Ertrag — schließt der Spieler das Spiel, ruht die Wirtschaft (GDD §2.2). Als Autoload
## im Default-Prozessmodus (PAUSABLE) ruht der Tick auch, wenn der Baum pausiert wird.

signal second_ticked(income: int)
signal building_upgraded(building_id: String, new_level: int)
signal boost_activated(building_id: String, until_sim_time: float)

## Einkommens-Gebäude (Master-GDD §2.2). `laboratory` = Raffinerie/Labor (Smog-Gate §1.7.2),
## selbst ohne Einkommen, aber über dieselbe Kostenkurve ausbaubar.
const BUILDINGS: Dictionary = {
	"saloon":     { "name": "Gatling-Saloon", "base_cost": 100, "income_per": 1, "max": 5 },
	"forge":      { "name": "Eiserne Schmiede", "base_cost": 220, "income_per": 2, "max": 5 },
	"distillery": { "name": "Mondschein-Destille", "base_cost": 400, "income_per": 4, "max": 5 },
	"laboratory": { "name": "Alchemie-Labor", "base_cost": 500, "income_per": 0, "max": 5 },
}

# ── Ripple-Matrix (aktive Booster-Synergie, §5.4) ─────────────────────────────
const RIPPLE_FORGE_INCOME_BONUS: float = 0.15   # Saloon-Boost -> +15% Schmiede-Einkommen
const RIPPLE_COST_DISCOUNT: float = 0.10        # Forge-Boost  -> -10% auf Ausbau/Waffen-Tuning
const RIPPLE_SELL_BONUS: float = 0.20           # Destille-Boost -> +20% Verkaufswert beim Händler

# ── Laufzeit (nur aktive In-Game-Zeit) ────────────────────────────────────────
var sim_seconds: float = 0.0                    # akkumulierte aktive Spielzeit
var _tick_accum: float = 0.0                    # Rest bis zur nächsten vollen Sekunde
## Booster-Ablaufzeitpunkte in `sim_seconds`. 0 = inaktiv.
var _boost_until: Dictionary = { "saloon": 0.0, "forge": 0.0, "distillery": 0.0 }


func _process(delta: float) -> void:
	sim_seconds += delta
	_tick_accum += delta
	# Ganze Sekunden abarbeiten (robust gegen Frame-Drops: mehrere Ticks bei großem delta).
	while _tick_accum >= 1.0:
		_tick_accum -= 1.0
		_tick_second()


func _tick_second() -> void:
	var income: int = income_per_sec()
	if income > 0:
		GameState.add_gold(income)   # add_gold arbeitet ganzzahlig (kein Float-Drift)
	second_ticked.emit(income)


# ── Einkommen (ganzzahlig) ────────────────────────────────────────────────────

## Einkommen/Sek = Σ (level × income_per). Saloon-Boost hebt die Schmiede-Komponente
## um +15%; das Endergebnis wird auf ganze Gold-Einheiten gerundet (kein Float-Drift).
func income_per_sec() -> int:
	var total: float = 0.0
	total += float(GameState.building_level("saloon") * int(BUILDINGS["saloon"]["income_per"]))
	var forge_income: float = float(GameState.building_level("forge") * int(BUILDINGS["forge"]["income_per"]))
	if is_boost_active("saloon"):
		forge_income *= (1.0 + RIPPLE_FORGE_INCOME_BONUS)   # „mehr Kundschaft -> mehr Aufträge"
	total += forge_income
	total += float(GameState.building_level("distillery") * int(BUILDINGS["distillery"]["income_per"]))
	return roundi(total)


# ── Kostenkurve & Ausbau (ganzzahlig) ─────────────────────────────────────────

## Ausbaukosten = base_cost × (aktuelle_Stufe + 1), danach Forge-Boost-Rabatt (falls aktiv).
## Die Kurve ist linear-progressiv: Stufe n→n+1 kostet das (n+1)-fache der Basis, sodass
## späte Stufen spürbar teurer werden.
func upgrade_cost(building_id: String) -> int:
	assert(BUILDINGS.has(building_id), "TycoonManager: unbekanntes Gebäude '%s'" % building_id)
	var level: int = GameState.building_level(building_id)
	var raw: int = int(BUILDINGS[building_id]["base_cost"]) * (level + 1)
	return roundi(raw * cost_multiplier())

## Multiplikator auf ALLE Ausbau-/Waffen-Tuning-Kosten (Forge-Boost -> 0.90).
func cost_multiplier() -> float:
	return (1.0 - RIPPLE_COST_DISCOUNT) if is_boost_active("forge") else 1.0

## Multiplikator auf den Verkaufswert beim Händler (Destille-Boost -> 1.20).
func sell_multiplier() -> float:
	return (1.0 + RIPPLE_SELL_BONUS) if is_boost_active("distillery") else 1.0

## Endgültiger Verkaufswert eines Items/Stapels inkl. Destille-Ripple (ganzzahlig).
func sell_value(base_value: int) -> int:
	return maxi(0, roundi(base_value * sell_multiplier()))

func is_maxed(building_id: String) -> bool:
	return GameState.building_level(building_id) >= int(BUILDINGS[building_id]["max"])

## Versucht den Ausbau: prüft Max-Stufe & Gold, bucht atomar ganzzahlig ab.
func try_upgrade(building_id: String) -> bool:
	assert(BUILDINGS.has(building_id), "TycoonManager: unbekanntes Gebäude '%s'" % building_id)
	if is_maxed(building_id):
		return false
	var cost: int = upgrade_cost(building_id)
	if GameState.gold < cost:
		return false
	GameState.add_gold(-cost)
	var new_level: int = GameState.building_level(building_id) + 1
	GameState.set_building_level(building_id, new_level)
	building_upgraded.emit(building_id, new_level)
	return true


# ── Booster (Ripple) ──────────────────────────────────────────────────────────

## Aktiviert einen Booster für `duration_sec` aktive Spielsekunden (z. B. via
## Tycoon-Booster-Mini-Quest, §5.4). Läuft rein über die Simulationsuhr, kein Realzeit-Timer.
func activate_boost(building_id: String, duration_sec: float) -> void:
	assert(_boost_until.has(building_id), "TycoonManager: kein Booster für '%s'" % building_id)
	_boost_until[building_id] = sim_seconds + maxf(0.0, duration_sec)
	boost_activated.emit(building_id, float(_boost_until[building_id]))

func is_boost_active(building_id: String) -> bool:
	return sim_seconds < float(_boost_until.get(building_id, 0.0))

## Restdauer eines Boosters in Sekunden (0 = inaktiv).
func boost_remaining(building_id: String) -> float:
	return maxf(0.0, float(_boost_until.get(building_id, 0.0)) - sim_seconds)
