class_name AmmoData
## Munition & Energiekristalle (Master-GDD §7.1.1) — begrenzter Vorrat statt Dauerfeuer.
##
## Zwei Pools, damit der Waffenwechsel eine Entscheidung ist und nicht nur eine Farbe: Der
## Blei-Karabiner frisst Munition, die drei Energiewaffen teilen sich die knapperen Kristalle.
## Wer die starke Waffe leerschießt, muss auf den Karabiner zurück.
##
## Zahlen 1:1 aus GDD §7.1.1 und dem durchgespielten Prototyp. Bei 5 Schuss/s reicht ein voller
## Munitionsvorrat für rund 36 Sekunden Dauerfeuer — im Gefecht netto-positiv durch Drops.

const POOLS: Dictionary = {
	"muni":     { "name": "Munition", "icon": "◆", "cap": 180, "start": 90, "drop": [3, 6], "color": Color(0.98, 0.75, 0.14) },
	"kristall": { "name": "Energiekristalle", "icon": "◇", "cap": 120, "start": 45, "drop": [3, 5], "color": Color(0.22, 0.74, 0.97) },
}
const ORDER: Array = ["muni", "kristall"]


## Welcher Pool speist diese Waffe?
##
## Entschieden wird an der SCHADENSART, nicht am Namen: Was Blei verschießt (KINETIC), zieht
## Munition, alles andere Kristalle. Vorher stand hier `weapon_id == "karabiner"` — das ging
## gut, solange der Karabiner die einzige kinetische Waffe war, und wurde in dem Moment falsch,
## in dem die Gatling dazukam: Eine Kurbelkanone mit Messingläufen bekam Energiekristalle.
static func pool_for(weapon_id: String) -> String:
	if not kennt(weapon_id):
		return ORDER[0]
	return "muni" if String(CombatData.WEAPONS[weapon_id]["type"]) == CombatData.KINETIC else "kristall"


## Kennt die Waffentabelle diese Kennung?
##
## `""` heisst **leere Haende**, und das ist seit dem Prolog ein regulaerer Spielzustand: Der
## Held erwacht ohne alles auf der Kippe und findet den Karabiner erst in der Truhe. Vorher
## trug er von der ersten Sekunde an alle fuenf Waffen — deshalb konnte hier nie eine unbekannte
## Kennung ankommen, und deshalb griff jede Funktion direkt in die Tabelle.
##
## Genau das hat den Prolog beim ersten echten Spielen zerlegt: `_update_hud` fragte im ERSTEN
## Bild nach der Munition der Waffe, die es noch nicht gab, und riss `_process` mit — samt
## Bewegungskreuz und jeder Eingabe. Ein Spiel, das mit leeren Haenden anfaengt, muss diese
## Frage beantworten koennen, ohne stehenzubleiben.
##
## Beantwortet wird sie mit „nichts": kein Magazin, kein Nachladen, kein Schuss. Der Vorrat
## selbst bleibt ansprechbar (man kann Munition einsammeln, bevor man eine Waffe hat) — deshalb
## faellt `pool_for` auf den ersten Pool zurueck, statt einen leeren Namen zu liefern, an dem
## `POOLS[...]` als naechstes zerbraeche.
static func kennt(weapon_id: String) -> bool:
	return weapon_id != "" and CombatData.WEAPONS.has(weapon_id)


## Vorratsgrenze eines Pools — inklusive des Perks „Munitionsgurt" (+25 je Rang).
## Der Perk stand seit jeher in der Tabelle und wirkte nirgends; im Prototyp hebt er genau das.
static func cap(pool: String) -> int:
	return int(POOLS[pool]["cap"]) + ProgressionManager.perk_val("gurt")


# ── Magazin & Nachladen ───────────────────────────────────────────────────────
## Geschossen wird aus dem MAGAZIN, nachgefuellt wird aus dem Vorrat. Ohne diese zweite Stufe
## waere „Munition" nur ein langsam sinkender Zaehler; erst das Magazin erzeugt den Rhythmus
## aus Feuern und Deckungsuche, und erst dadurch ist die Gatling eine Entscheidung: 60 Schuss
## am Stueck, danach 4,5 Sekunden wehrlos.

static func mag_size(weapon_id: String) -> int:
	if not kennt(weapon_id):
		return 0
	return int(CombatData.WEAPONS[weapon_id].get("mag", 1))


static func in_mag(weapon_id: String) -> int:
	return int(GameState.mag.get(weapon_id, mag_size(weapon_id)))


static func set_mag(weapon_id: String, count: int) -> void:
	GameState.mag[weapon_id] = clampi(count, 0, mag_size(weapon_id))


static func mag_full(weapon_id: String) -> bool:
	return in_mag(weapon_id) >= mag_size(weapon_id)


## Kann ueberhaupt nachgeladen werden? Ein leerer Vorrat macht das Nachladen sinnlos — und ein
## Nachladeversuch, der nichts bewirkt, ist schlimmer als gar keiner.
static func can_reload(weapon_id: String) -> bool:
	return not mag_full(weapon_id) and amount(pool_for(weapon_id)) > 0


## Magazin auffuellen: nimmt aus dem Vorrat, so viel fehlt und da ist. Liefert die geladene
## Menge, damit der Aufrufer ein Teil-Nachladen ehrlich melden kann.
## HEISST BEWUSST NICHT `reload`: Das gibt es bereits auf `GDScript` selbst (Skript neu laden),
## und ein statischer Aufruf `AmmoData.refill_mag(...)` landet dort statt hier — mit einer
## Typfehlermeldung ueber ein `bool`, die nichts mit Munition zu tun hat.
static func refill_mag(weapon_id: String) -> int:
	var fehlt: int = mag_size(weapon_id) - in_mag(weapon_id)
	var pool: String = pool_for(weapon_id)
	var nimm: int = mini(fehlt, amount(pool))
	if nimm <= 0:
		return 0
	GameState.ammo[pool] = amount(pool) - nimm
	set_mag(weapon_id, in_mag(weapon_id) + nimm)
	return nimm


## Alle Magazine voll — fuer ein neues Spiel.
static func fresh_mags() -> Dictionary:
	var out: Dictionary = {}
	for id in CombatData.WEAPONS:
		out[String(id)] = mag_size(String(id))
	return out


static func amount(pool: String) -> int:
	return int(GameState.ammo.get(pool, 0))


## Waffe schussbereit? Leeres Magazin zaehlt als leer, auch wenn der Vorrat voll ist.
static func is_empty(weapon_id: String) -> bool:
	return in_mag(weapon_id) <= 0


## Gar nichts mehr da — weder im Magazin noch im Vorrat. Nur dann hilft auch Nachladen nicht.
static func is_dry(weapon_id: String) -> bool:
	return in_mag(weapon_id) <= 0 and amount(pool_for(weapon_id)) <= 0


## Legt Nachschub an, gedeckelt auf die Kapazität. Liefert, wie viel WIRKLICH ankam — der Rest
## wäre sonst still verschwunden, und der Aufrufer könnte keine ehrliche Meldung anzeigen.
static func add(pool: String, count: int) -> int:
	if not POOLS.has(pool) or count <= 0:
		return 0
	var before: int = amount(pool)
	var after: int = mini(before + count, cap(pool))
	GameState.ammo[pool] = after
	return after - before


## Einen Schuss abbuchen — aus dem MAGAZIN, nicht aus dem Vorrat.
## `false` = Magazin leer, es muss nachgeladen werden.
static func consume(weapon_id: String) -> bool:
	if not kennt(weapon_id):
		return false
	var have: int = in_mag(weapon_id)
	if have <= 0:
		return false
	set_mag(weapon_id, have - 1)
	return true


## Zufällige Drop-Menge für einen Kill (Bandbreite je Pool aus dem GDD).
static func roll_drop(pool: String, rng: RandomNumberGenerator = null) -> int:
	var span: Array = POOLS[pool]["drop"]
	if rng == null:
		return randi_range(int(span[0]), int(span[1]))
	return rng.randi_range(int(span[0]), int(span[1]))


## Startvorrat für ein neues Spiel.
static func fresh() -> Dictionary:
	var out: Dictionary = {}
	for id in ORDER:
		out[id] = int(POOLS[id]["start"])
	return out
