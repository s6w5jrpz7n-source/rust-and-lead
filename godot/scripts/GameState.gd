extends Node
## GameState — globaler Laufzeit-Zustand ("Single Source of Truth") für "Rust & Lead".
##
## Als Autoload registrieren: Project Settings ▸ Autoload ▸ Name = "GameState".
## Enthält ausschließlich Daten + zustandsverändernde Kernmethoden — keine UI, kein
## Gameplay, keine Szenen-Referenzen. Der QuestManager und das Kampfsystem greifen
## ausschließlich über dieses Singleton auf den Zustand zu.
##
## Feldnamen spiegeln das Master-GDD §2.3 (State-Schema). Persistenz (Speichern/Laden)
## serialisiert genau diese Felder; die Quest-Zustände bleiben bewusst Strings
## ("available"/"active"/"done"), damit Save-Daten menschenlesbar und versionsstabil sind.

# ── Signale (für UI/Audio-Reaktionen; das Backend selbst hängt nicht davon ab) ──
signal chapter_changed(new_chapter: int)
signal guild_chosen(guild_id: String)
signal reveal_started()
signal reveal_finished()
signal level_up(new_level: int)
signal xp_gained(amount: int, current_xp: int, level: int)
signal gold_changed(new_gold: int)
signal inventory_changed(item_id: String, new_count: int)
signal quest_state_changed(quest_id: String, new_state: String)

# ── Story-Progression ─────────────────────────────────────────────────────────
var current_chapter: int = 1
var is_revealed: bool = false
## null = noch keine Gilde gewählt. Danach exakt einer aus {"rebels","corp","smugglers"}.
## Bewusst als nullable Variant gehalten, um dem GDD-Kontrakt (`chosen_guild == null`)
## zu entsprechen; alle Vergleiche laufen gegen `null` bzw. den konkreten String.
var chosen_guild: Variant = null

# ── Level & Erfahrung (Master-GDD §7.5) ───────────────────────────────────────
const LEVEL_MAX: int = 30
const LEVEL_HP_BONUS: int = 8
const PLAYER_BASE_HP: int = 100
var level: int = 1
var xp: int = 0

# ── Wirtschaft & Beutel ───────────────────────────────────────────────────────
var gold: int = 0
var potions: int = 3
var inventory: Dictionary = { "schrott": 0, "zahnrad": 0, "dampfkern": 0 }

# ── Kampf-Zähler: monotone Gesamt-Kills; Basis für das Kill-Quest-Tracking ─────
var kills: int = 0

# ── Quest-Zustände ────────────────────────────────────────────────────────────
var quests: Dictionary = {}       ## quest_id (String) -> "available" | "active" | "done"
var quest_base: Dictionary = {}   ## quest_id (String) -> Kill-Stand zum Annahme-Zeitpunkt (int)

# ── Ablauf-Flags (nur backend-relevante; UI-Only-Flags leben in der UI-Schicht) ─
var flags_ui: Dictionary = { "reveal_playing": false }


# ── Erfahrungs-Kurve & abgeleitete Werte ──────────────────────────────────────
func xp_to_next(lvl: int) -> int:
	# Kurve laut GDD: Level 1->2 = 70 XP, danach +30 pro Stufe.
	return 40 + lvl * 30

func max_hp() -> int:
	# Basis + Level-Bonus. Ausrüstungs-/Werkstatt-Boni addiert das Kampfsystem separat.
	return PLAYER_BASE_HP + (level - 1) * LEVEL_HP_BONUS


# ── Kampf-Zähler ──────────────────────────────────────────────────────────────
func add_kill(amount: int = 1) -> void:
	# Wird vom Kampfsystem bei jedem bestätigten Gegner-Tod aufgerufen.
	# Monoton steigend: Kill-Quests messen ihre Differenz gegen einen eingefrorenen
	# Basiswert (quest_base) — so zählen nur Kills NACH Annahme (siehe QuestManager).
	kills += maxi(0, amount)


# ── Gold & XP ─────────────────────────────────────────────────────────────────
func add_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)
	gold_changed.emit(gold)

func add_xp(amount: int) -> void:
	# Ignoriert nicht-positive Beträge und respektiert das Level-Cap; verhindert so
	# Endlosschleifen und negative XP-Zustände (Korruptionsschutz).
	if amount <= 0 or level >= LEVEL_MAX:
		return
	xp += amount
	var leveled: bool = false
	# Mehrfach-Aufstieg in einem Schritt sauber abarbeiten.
	while level < LEVEL_MAX and xp >= xp_to_next(level):
		xp -= xp_to_next(level)
		level += 1
		leveled = true
	if leveled:
		level_up.emit(level)
	xp_gained.emit(amount, xp, level)


# ── Inventar ──────────────────────────────────────────────────────────────────
func item_count(id: String) -> int:
	return int(inventory.get(id, 0))

func add_item(id: String, amount: int = 1) -> void:
	inventory[id] = item_count(id) + maxi(0, amount)
	inventory_changed.emit(id, item_count(id))

## Zieht Items ab; gibt false zurück, wenn nicht genug vorhanden ist (kein Unterlauf).
func remove_item(id: String, amount: int) -> bool:
	if amount <= 0:
		return true
	if item_count(id) < amount:
		return false
	inventory[id] = item_count(id) - amount
	inventory_changed.emit(id, item_count(id))
	return true

func add_potion(amount: int = 1) -> void:
	potions += maxi(0, amount)
