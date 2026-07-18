extends Node
## QuestManager — reines Logik-Backend für Quests, Fraktionen & Kapitel-Progression.
##
## Als Autoload NACH "GameState" registrieren: Project Settings ▸ Autoload ▸
## Name = "QuestManager". Das Interface läuft ausschließlich über GameState; es gibt
## bewusst KEINE UI-, Szenen- oder Node-Referenzen — reine Zustandsmaschine.
##
## Zustandsmaschine je Quest:  available ──accept──▶ active ──complete──▶ done
## Sämtliche Übergänge sind streng bewacht (siehe Kommentare), sodass doppelte Eingaben
## (Doppeltipp/Doppelklick) und Zustandskorruption ausgeschlossen sind.

# ── Quest-Zustände als String-Konstanten (save-kompatibel, GDD §2.3) ──────────
const STATE_AVAILABLE: String = "available"
const STATE_ACTIVE: String = "active"
const STATE_DONE: String = "done"

const VALID_GUILDS: PackedStringArray = ["rebels", "corp", "smugglers"]
const GUILD_CHOICE_CHAPTER: int = 5

# ── Signale ───────────────────────────────────────────────────────────────────
signal quest_accepted(quest_id: String)
signal quest_completed(quest_id: String, reward_gold: int, reward_xp: int)
signal quest_progress(quest_id: String, current: int, target: int)
signal questline_blocked(quest_id: String, reason: String)

## Verbindliche Quest-Daten — Master-GDD §4.2 (Fraktions-Matrix) & §4.3 (Hub-NPCs).
##   kind == "kill":    nutzt den questBase-Mechanismus (Kills seit Annahme).
##   kind == "collect": prüft GameState.inventory und verbraucht die Items bei Abgabe.
##   guild (optional):  bindet die Quest an eine Fraktion (Gilden-Gate).
##   chapter:           Mindest-Kapitel, ab dem die Quest angeboten wird.
##   advance_to:        Kapitel, auf das nach Abschluss gehoben wird (0 = kein Sprung).
##   reward_item:       "" | "dampfkern" | "zahnrad" | "potion".
const QUESTS: Dictionary = {
	# ── Hub-Einführungs-Kopfgelder (ab Kapitel 1 verfügbar) ──
	"q_bounty": { "title": "Kopfgeld: Wegelagerer", "giver": "mabel", "kind": "kill",
		"count": 8, "reward_gold": 120, "reward_item": "zahnrad", "chapter": 1, "advance_to": 0 },
	"q_scrap":  { "title": "Baumaterial: Schrott", "giver": "silas", "kind": "collect", "item": "schrott",
		"count": 12, "reward_gold": 90, "reward_item": "", "chapter": 1, "advance_to": 0 },
	"q_rats":   { "title": "Plage: Schrott-Ratten", "giver": "doc", "kind": "kill",
		"count": 5, "reward_gold": 70, "reward_item": "potion", "chapter": 1, "advance_to": 0 },

	# ── Rebellengilde (Gideon, Fort Freedom) ──
	"q_rebels5":  { "title": "Sand im Getriebe", "guild": "rebels", "giver": "gideon", "kind": "kill",
		"count": 12, "reward_gold": 250, "reward_item": "dampfkern", "chapter": 5, "advance_to": 8 },
	"q_rebels8":  { "title": "Der Kinetoskop-Betrug", "guild": "rebels", "giver": "gideon", "kind": "kill",
		"count": 18, "reward_gold": 500, "reward_item": "dampfkern", "chapter": 8, "advance_to": 12 },
	"q_rebels12": { "title": "Sturm auf die Iron Rail", "guild": "rebels", "giver": "gideon", "kind": "kill",
		"count": 30, "reward_gold": 1200, "reward_item": "dampfkern", "chapter": 12, "advance_to": 0 },

	# ── Eiserne Gilde (Quentin, Sektor 01) ──
	"q_corp5":  { "title": "Streikbrecher", "guild": "corp", "giver": "quentin", "kind": "kill",
		"count": 12, "reward_gold": 250, "reward_item": "dampfkern", "chapter": 5, "advance_to": 8 },
	"q_corp8":  { "title": "Archiv-Säuberung", "guild": "corp", "giver": "quentin", "kind": "kill",
		"count": 18, "reward_gold": 500, "reward_item": "dampfkern", "chapter": 8, "advance_to": 12 },
	"q_corp12": { "title": "Der eiserne Frieden", "guild": "corp", "giver": "quentin", "kind": "kill",
		"count": 30, "reward_gold": 1200, "reward_item": "dampfkern", "chapter": 12, "advance_to": 0 },

	# ── Schmugglergilde (Slick, Rogue's Landing) ──
	"q_smug5":  { "title": "Das Sumpf-Gold", "guild": "smugglers", "giver": "slick", "kind": "collect", "item": "dampfkern",
		"count": 3, "reward_gold": 300, "reward_item": "", "chapter": 5, "advance_to": 8 },
	"q_smug8":  { "title": "Heiße Ware, heiße Wahrheit", "guild": "smugglers", "giver": "slick", "kind": "collect", "item": "dampfkern",
		"count": 6, "reward_gold": 700, "reward_item": "", "chapter": 8, "advance_to": 12 },
	"q_smug12": { "title": "Der letzte Deal", "guild": "smugglers", "giver": "slick", "kind": "collect", "item": "dampfkern",
		"count": 10, "reward_gold": 1600, "reward_item": "", "chapter": 12, "advance_to": 0 },
}


# ── Abfragen ──────────────────────────────────────────────────────────────────

func has_quest(quest_id: String) -> bool:
	return QUESTS.has(quest_id)

func get_definition(quest_id: String) -> Dictionary:
	assert(QUESTS.has(quest_id), "QuestManager: unbekannte Quest-ID '%s'" % quest_id)
	return QUESTS[quest_id]

func get_quest_state(quest_id: String) -> String:
	# Unbekannte/neue Quests gelten implizit als "available".
	return String(GameState.quests.get(quest_id, STATE_AVAILABLE))

func is_faction_quest(quest_id: String) -> bool:
	return get_definition(quest_id).has("guild")

## Ist die Fraktion aktuell zugänglich? Vor dem Reveal niemand; danach nur die gewählte.
func can_access_guild(guild_id: String) -> bool:
	if not GameState.is_revealed:
		return false
	return GameState.chosen_guild == guild_id


# ── Fortschritt ───────────────────────────────────────────────────────────────

## Liefert {"current": int, "target": int, "complete": bool} für aktive/laufende Quests.
func check_quest_progress(quest_id: String) -> Dictionary:
	var def: Dictionary = get_definition(quest_id)
	var target: int = int(def["count"])
	var current: int = 0
	if String(def["kind"]) == "kill":
		# questBase-Mechanismus: nur Kills SEIT Annahme zählen. Ist keine Basis gesetzt
		# (Quest nie angenommen), gilt der aktuelle Stand als Basis -> Fortschritt 0.
		var base: int = int(GameState.quest_base.get(quest_id, GameState.kills))
		current = clampi(GameState.kills - base, 0, target)
	else: # "collect"
		current = clampi(GameState.item_count(String(def["item"])), 0, target)
	var complete: bool = current >= target
	quest_progress.emit(quest_id, current, target)
	return { "current": current, "target": target, "complete": complete }

func is_quest_complete(quest_id: String) -> bool:
	# Bewusst über den Rohwert (nicht den geklammerten) geprüft, damit Überschuss zählt.
	var def: Dictionary = get_definition(quest_id)
	var target: int = int(def["count"])
	if String(def["kind"]) == "kill":
		var base: int = int(GameState.quest_base.get(quest_id, GameState.kills))
		return (GameState.kills - base) >= target
	return GameState.item_count(String(def["item"])) >= target


# ── Zustandsübergänge ─────────────────────────────────────────────────────────

## Nimmt eine Quest an: available -> active. Gibt false zurück, wenn ein Gate greift.
func accept_quest(quest_id: String) -> bool:
	var def: Dictionary = get_definition(quest_id)

	# (1) Doppel-Annahme / falscher Ausgangszustand blockieren. Nur AUS "available"
	#     heraus annehmbar -> verhindert erneutes Einfrieren von quest_base (Korruption).
	if get_quest_state(quest_id) != STATE_AVAILABLE:
		questline_blocked.emit(quest_id, "not_available")
		return false

	# (2) Fraktions-Gate: Gilden-Quests nur nach dem Reveal und nur für die gewählte
	#     Gilde. Fremde Fraktionen sind nach der Wahl vollständig gesperrt.
	if def.has("guild") and not can_access_guild(String(def["guild"])):
		questline_blocked.emit(quest_id, "guild_locked")
		return false

	# (3) Kapitel-Gate: Quest erst ab ihrem Kapitel. Ketten-Quests (…8, …12) werden so
	#     erst zugänglich, nachdem die Vorgänger via advance_to das Kapitel angehoben haben.
	if int(def.get("chapter", 0)) > GameState.current_chapter:
		questline_blocked.emit(quest_id, "chapter_locked")
		return false

	# Übergang. Bei Kill-Quests den aktuellen Kill-Stand als Basis einfrieren.
	GameState.quests[quest_id] = STATE_ACTIVE
	if String(def["kind"]) == "kill":
		GameState.quest_base[quest_id] = GameState.kills

	GameState.quest_state_changed.emit(quest_id, STATE_ACTIVE)
	quest_accepted.emit(quest_id)
	return true


## Schließt eine Quest ab: active -> done, inkl. Belohnungen & Kapitel-Fortschritt.
## Gibt false zurück, wenn die Quest nicht aktiv oder die Bedingung nicht erfüllt ist.
func complete_quest(quest_id: String) -> bool:
	var def: Dictionary = get_definition(quest_id)

	# (1) Nur AKTIVE Quests sind abgebbar. Verhindert doppeltes Kassieren der Belohnung
	#     (zweiter Aufruf sieht bereits "done" -> Abbruch).
	if get_quest_state(quest_id) != STATE_ACTIVE:
		questline_blocked.emit(quest_id, "not_active")
		return false

	# (2) Ziel-Bedingung serverseitig verifizieren — kein Vertrauen auf die UI.
	if not is_quest_complete(quest_id):
		questline_blocked.emit(quest_id, "incomplete")
		return false

	# (3) Collect-Quests: Items ATOMAR abziehen, BEVOR der Zustand wechselt. Schlägt der
	#     Abzug fehl (Race Condition), bricht die Abgabe folgenlos ab.
	if String(def["kind"]) == "collect":
		if not GameState.remove_item(String(def["item"]), int(def["count"])):
			questline_blocked.emit(quest_id, "items_missing")
			return false

	# (4) Belohnungen. XP laut GDD: max(25, round(reward_gold * 0.5)).
	var reward_gold: int = int(def["reward_gold"])
	var reward_xp: int = maxi(25, roundi(reward_gold * 0.5))
	GameState.add_gold(reward_gold)
	GameState.add_xp(reward_xp)
	_grant_item_reward(String(def.get("reward_item", "")))

	# (5) Zustand fixieren.
	GameState.quests[quest_id] = STATE_DONE
	GameState.quest_base.erase(quest_id) # Basis wird nicht mehr gebraucht.
	GameState.quest_state_changed.emit(quest_id, STATE_DONE)

	# (6) Kapitel-Fortschritt der Ketten-Quests.
	var advance_to: int = int(def.get("advance_to", 0))
	if advance_to > GameState.current_chapter:
		_set_chapter(advance_to)

	quest_completed.emit(quest_id, reward_gold, reward_xp)
	return true


func _grant_item_reward(item_id: String) -> void:
	match item_id:
		"":
			pass
		"potion":
			GameState.add_potion(1)
		_:
			GameState.add_item(item_id, 1)


# ── Fraktions-Wahl (das Kapitel-5-Gate) ───────────────────────────────────────

## Wählt endgültig eine Gilde. Nur EINMAL möglich (Kapitel 5, noch keine Gilde gewählt).
## Danach sind die beiden anderen Fraktionen komplett gesperrt (siehe can_access_guild).
func choose_guild(guild_id: String) -> bool:
	assert(VALID_GUILDS.has(guild_id), "QuestManager: ungültige Gilde '%s'" % guild_id)

	# Gate: nur in Kapitel 5 und nur solange keine Gilde feststeht (Einmal-Entscheidung).
	if GameState.current_chapter != GUILD_CHOICE_CHAPTER:
		questline_blocked.emit(guild_id, "wrong_chapter")
		return false
	if GameState.chosen_guild != null:
		questline_blocked.emit(guild_id, "guild_already_chosen")
		return false
	# Der Reveal muss geschehen sein (Gilden existieren erst danach spielerisch).
	if not GameState.is_revealed:
		questline_blocked.emit(guild_id, "not_revealed")
		return false

	GameState.chosen_guild = guild_id
	GameState.guild_chosen.emit(guild_id)
	return true


# ── Kapitel-Progression ───────────────────────────────────────────────────────

## Erhöht das aktuelle Kapitel um 1 (gedeckelt bei 12).
func advance_chapter() -> int:
	_set_chapter(GameState.current_chapter + 1)
	return GameState.current_chapter

func _set_chapter(new_chapter: int) -> void:
	var clamped: int = clampi(new_chapter, 1, 12)
	if clamped == GameState.current_chapter:
		return
	GameState.current_chapter = clamped
	GameState.chapter_changed.emit(clamped)


# ── Der Kapitel-4-Reveal (Zugüberfall) ────────────────────────────────────────

## Simuliert den Tod des Zugüberfall-Bosses: startet die Reveal-Sequenz.
## Idempotent — ein zweiter Aufruf während/nach dem Reveal tut nichts (kein Doppel-Reveal).
## Ablauf: flags_ui.reveal_playing = true, is_revealed = true. Das eigentliche Kapitel
## springt erst auf 5, wenn die Cutscene meldet, dass sie fertig ist -> finish_reveal().
func trigger_chapter_4_reveal() -> void:
	if GameState.is_revealed or bool(GameState.flags_ui.get("reveal_playing", false)):
		return
	GameState.flags_ui["reveal_playing"] = true
	GameState.is_revealed = true
	GameState.reveal_started.emit()

## Wird von der Reveal-Cutscene beim Ende aufgerufen: beendet die Sequenz und hebt auf
## Kapitel 5. Ohne laufenden Reveal folgenlos (schützt vor verirrten Aufrufen).
func finish_reveal() -> void:
	if not bool(GameState.flags_ui.get("reveal_playing", false)):
		return
	GameState.flags_ui["reveal_playing"] = false
	_set_chapter(5)
	GameState.reveal_finished.emit()
