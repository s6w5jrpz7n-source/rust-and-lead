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
signal tracked_changed(quest_id: String)

## Wo jeder Auftraggeber steht. Zum Abgeben muss man wieder zu ihm — und dafür muss der
## Wegweiser wissen, wo „zu ihm" ist. Bewusst eine eigene Tabelle und nicht in `QUESTS`
## wiederholt: Ein Auftraggeber steht an EINEM Ort, egal wie viele Aufträge er vergibt.
const GIVER_POI: Dictionary = {
	"mabel": "rustwater", "silas": "rustwater", "doc": "rustwater",
	"gideon": "fort_freedom", "quentin": "sektor01", "slick": "rogues_landing",
}

## Verbindliche Quest-Daten — Master-GDD §4.2 (Fraktions-Matrix) & §4.3 (Hub-NPCs).
##   kind == "kill":    nutzt den questBase-Mechanismus (Kills seit Annahme).
##   kind == "collect": prüft GameState.inventory und verbraucht die Items bei Abgabe.
##   guild (optional):  bindet die Quest an eine Fraktion (Gilden-Gate).
##   chapter:           Mindest-Kapitel, ab dem die Quest angeboten wird.
##   advance_to:        Kapitel, auf das nach Abschluss gehoben wird (0 = kein Sprung).
##   reward_item:       "" | "dampfkern" | "zahnrad" | "potion".
##   target:            WOHIN man dafür muss. Der Wegweiser auf der Karte und die Fußspur in
##                      der Welt lesen genau dieses Feld.
##
## Bis hierher hatte eine Quest ein Ziel („12 Gegner erlegen") und keinen ORT. Man konnte sie
## annehmen und stand danach in der Stadt, ohne den geringsten Hinweis, wohin. Bei einer Welt
## von 5 km Kantenlänge ist das kein Spielraum, sondern ein Sackgassen-Erlebnis: Man läuft in
## eine beliebige Richtung, bis irgendetwas passiert. Jede Quest zeigt deshalb jetzt auf einen
## Ort, an dem sich ihr Ziel auch wirklich erledigen lässt — Ratten in den Schrott-Minen,
## Wegelagerer im Rattengestrüpp.
const QUESTS: Dictionary = {
	# ── Hub-Einführungs-Kopfgelder (ab Kapitel 1 verfügbar) ──
	"q_bounty": { "title": "Kopfgeld: Wegelagerer", "giver": "mabel", "kind": "kill",
		"count": 8, "reward_gold": 120, "reward_item": "zahnrad", "target": "rattengestruepp", "chapter": 1, "advance_to": 0 },
	# `grubenstahl` und NICHT `schrott` -- der Unterschied ist der ganze Auftrag.
	#
	# Er verlangte gewoehnlichen Schrott, und den hat man ohnehin: Er faellt bei jedem Kill,
	# liegt ueberall herum, und die zwoelf Stueck hatte man beisammen, bevor man Silas
	# ueberhaupt zugehoert hatte. Ein Auftrag, den man versehentlich erfuellt, ist keiner.
	#
	# Grubenstahl gibt es NUR in den Truhen des Stollens (siehe GameState.NUR_IM_STOLLEN).
	# Damit schickt der Auftrag einen an einen Ort, statt eine Strichliste zu fuehren -- und der
	# Stollen bekommt den Grund, hineinzugehen, den er vorher nicht hatte.
	"q_scrap":  { "title": "Baumaterial: Grubenstahl", "giver": "silas", "kind": "collect",
		# ZWANZIG und nicht zwoelf: Ebene 1 des Stollens liefert hoechstens fuenfzehn. Bei
		# zwoelf waere der Auftrag oben erledigt, und die zweite Ebene haette wieder keinen
		# Grund. Der Test rechnet das nach — er hat die Zahl auch gefunden.
		"item": "grubenstahl", "count": 20, "reward_gold": 160, "reward_item": "potion",
		"target": "stollen", "chapter": 1, "advance_to": 0 },
	"q_rats":   { "title": "Plage: Schrott-Ratten", "giver": "doc", "kind": "kill",
		"count": 5, "reward_gold": 70, "reward_item": "potion", "target": "schrott_minen", "chapter": 1, "advance_to": 0 },

	# ── Kapitel 1 geht weiter: je zwei Anschlussaufträge pro Auftraggeber ──
	#
	# Wozu: Nach den drei Einführungs-Kopfgeldern war Rustwater STUMM. Die nächsten Aufträge
	# hängen an Kapitel 5 und am Gilden-Reveal, also standen alle drei NPCs da und hatten nichts
	# zu sagen — man konnte die Wegweisung gar nicht mehr ausprobieren.
	#
	# `_quest_for_giver` nimmt immer den ERSTEN nicht erledigten Auftrag eines Gebers. Aus der
	# Reihenfolge in dieser Tabelle wird damit von selbst eine Kette: Mabel gibt erst das
	# Kopfgeld, dann die Zahnräder, dann die lange Fuhre.
	#
	# Die Ziele sind bewusst über ALLE vier Orte von Sektor 1 gestreut, damit die Fußspur in
	# jede Richtung einmal geprüft wird — inklusive **Zugdepot**, wo die gerade Linie durch den
	# Strahlensumpf führt und der Umweg greifen muss. Das ist der Fall, der ohne Wegweisung
	# tödlich endet, und deshalb der einzige, der wirklich getestet gehört.
	"q_m2": { "title": "Zahnräder für die Zapfanlage", "giver": "mabel", "kind": "collect", "item": "zahnrad",
		"count": 4, "reward_gold": 110, "reward_item": "potion", "target": "schrott_minen", "chapter": 1, "advance_to": 0 },
	"q_m3": { "title": "Die lange Fuhre", "giver": "mabel", "kind": "kill",
		"count": 10, "reward_gold": 200, "reward_item": "zahnrad", "target": "zugdepot", "chapter": 1, "advance_to": 0,
		"repeatable": true },
	"q_s2": { "title": "Kesselflicken", "giver": "silas", "kind": "kill",
		"count": 6, "reward_gold": 100, "reward_item": "zahnrad", "target": "rattengestruepp", "chapter": 1, "advance_to": 0 },
	"q_s3": { "title": "Ein Kern für die Esse", "giver": "silas", "kind": "collect", "item": "dampfkern",
		"count": 1, "reward_gold": 180, "reward_item": "", "target": "zugdepot", "chapter": 1, "advance_to": 0,
		"repeatable": true },
	"q_d2": { "title": "Feldversuch: Rostproben", "giver": "doc", "kind": "collect", "item": "schrott",
		"count": 8, "reward_gold": 80, "reward_item": "potion", "target": "rattengestruepp", "chapter": 1, "advance_to": 0 },
	"q_d3": { "title": "Kadaverzählung", "giver": "doc", "kind": "kill",
		"count": 12, "reward_gold": 160, "reward_item": "potion", "target": "schrott_minen", "chapter": 1, "advance_to": 0,
		"repeatable": true },

	# ── Rebellengilde (Gideon, Fort Freedom) ──
	"q_rebels5":  { "title": "Sand im Getriebe", "guild": "rebels", "giver": "gideon", "kind": "kill",
		"count": 12, "reward_gold": 250, "reward_item": "dampfkern", "target": "zugdepot", "chapter": 5, "advance_to": 8 },
	"q_rebels8":  { "title": "Der Kinetoskop-Betrug", "guild": "rebels", "giver": "gideon", "kind": "kill",
		"count": 18, "reward_gold": 500, "reward_item": "dampfkern", "target": "rogues_landing", "chapter": 8, "advance_to": 12 },
	"q_rebels12": { "title": "Sturm auf die Iron Rail", "guild": "rebels", "giver": "gideon", "kind": "kill",
		"count": 30, "reward_gold": 1200, "reward_item": "dampfkern", "target": "sektor01", "chapter": 12, "advance_to": 0 },

	# ── Eiserne Gilde (Quentin, Sektor 01) ──
	"q_corp5":  { "title": "Streikbrecher", "guild": "corp", "giver": "quentin", "kind": "kill",
		"count": 12, "reward_gold": 250, "reward_item": "dampfkern", "target": "zugdepot", "chapter": 5, "advance_to": 8 },
	"q_corp8":  { "title": "Archiv-Säuberung", "guild": "corp", "giver": "quentin", "kind": "kill",
		"count": 18, "reward_gold": 500, "reward_item": "dampfkern", "target": "rattengestruepp", "chapter": 8, "advance_to": 12 },
	"q_corp12": { "title": "Der eiserne Frieden", "guild": "corp", "giver": "quentin", "kind": "kill",
		"count": 30, "reward_gold": 1200, "reward_item": "dampfkern", "target": "fort_freedom", "chapter": 12, "advance_to": 0 },

	# ── Schmugglergilde (Slick, Rogue's Landing) ──
	"q_smug5":  { "title": "Das Sumpf-Gold", "guild": "smugglers", "giver": "slick", "kind": "collect", "item": "dampfkern",
		"count": 3, "reward_gold": 300, "reward_item": "", "target": "schrott_minen", "chapter": 5, "advance_to": 8 },
	"q_smug8":  { "title": "Heiße Ware, heiße Wahrheit", "guild": "smugglers", "giver": "slick", "kind": "collect", "item": "dampfkern",
		"count": 6, "reward_gold": 700, "reward_item": "", "target": "alchemie_raffinerie", "chapter": 8, "advance_to": 12 },
	"q_smug12": { "title": "Der letzte Deal", "guild": "smugglers", "giver": "slick", "kind": "collect", "item": "dampfkern",
		"count": 10, "reward_gold": 1600, "reward_item": "", "target": "schmelzoefen_vulcan", "chapter": 12, "advance_to": 0 },
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


## Wurde dieser wiederholbare Auftrag heute schon abgegeben?
##
## ## Warum es diese Bremse gibt
##
## Wiederholbare Auftraege waren als Gegenmittel gegen ein stummes Rustwater gedacht: Nach den
## letzten Kopfgeldern hatte kein NPC mehr etwas zu sagen. Sie schossen aber uebers Ziel hinaus
## — „ich kann bei Mabel den Auftrag unendlich oft abschliessen". Zehn Gegner am Zugdepot,
## zweihundert Gold, wieder annehmen: Das ist kein Auftrag mehr, sondern ein Geldhahn, und er
## entwertet nebenbei jedes Fundstueck, jeden Preis und jede Kaufentscheidung im Spiel.
##
## Die Bremse ist der TAG und nicht ein Zaehler. Ein „dreimal und dann nie wieder" waere
## dasselbe Problem eine Woche spaeter: Rustwater faellt zurueck ins Schweigen. Einmal am Tag
## bleibt beides erhalten — der Ort hat dauerhaft etwas zu bieten, und niemand steht eine
## Stunde vor demselben Auftraggeber.
##
## Es kostet den Spieler nichts an Zeit: Die Uhr laeuft ohnehin (`DayCycle`), und ein Tag ist
## in wenigen Minuten Spielzeit herum.
func heute_schon_abgegeben(quest_id: String) -> bool:
	if not bool(get_definition(quest_id).get("repeatable", false)):
		return false
	return int(GameState.quest_tag.get(quest_id, -1)) == GameState.tag

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


# ── Wegweisung: welcher Auftrag wird verfolgt, und wohin zeigt er ─────────────
## Der Teil, der aus einer Zahl im Menü einen Ort in der Welt macht.
##
## Diablo löst das mit genau zwei Mitteln, und wir kopieren beide: eine Marke auf der Karte
## („dort ist es") und eine Fußspur am Boden („dort entlang"). Die Marke beantwortet die Frage
## beim Blick auf die Karte, die Spur beantwortet sie beim Laufen — und man muss die Karte
## nicht mehr aufmachen. Beide lesen `quest_target()`.

## Ziel des verfolgten Auftrags — WOHIN gerade zu gehen ist ("" = nirgendwohin).
##
## Der Ort wechselt mit dem Fortschritt, und das ist der ganze Witz: Solange das Ziel offen ist,
## zeigt er auf den Ort der Arbeit; sobald es erfüllt ist, auf den Auftraggeber. Ein Wegweiser,
## der nach dem letzten Kill weiter in die Wildnis zeigt, wäre schlimmer als keiner.
func quest_target(quest_id: String) -> String:
	if not has_quest(quest_id) or get_quest_state(quest_id) != STATE_ACTIVE:
		return ""
	var def: Dictionary = get_definition(quest_id)
	if is_quest_complete(quest_id):
		return String(GIVER_POI.get(String(def.get("giver", "")), ""))
	return String(def.get("target", ""))


## Alle laufenden Aufträge, in der Reihenfolge der Tabelle.
func active_quests() -> Array:
	var out: Array = []
	for qid in QUESTS.keys():
		if get_quest_state(String(qid)) == STATE_ACTIVE:
			out.append(String(qid))
	return out


## Der verfolgte Auftrag ("" = keiner).
##
## Wird hier VALIDIERT statt beim Setzen: Der Wert steht im Spielstand, und ein Spielstand kann
## eine Quest enthalten, die inzwischen abgegeben wurde (oder aus einer älteren Fassung stammt).
## Ein Wegweiser, der auf einen erledigten Auftrag zeigt, ist ein Fehler, den niemand meldet —
## man wundert sich nur, warum die Spur ins Nichts führt.
func tracked_quest() -> String:
	var qid: String = String(GameState.tracked_quest)
	if qid != "" and has_quest(qid) and get_quest_state(qid) == STATE_ACTIVE:
		return qid
	# Nichts (mehr) verfolgt: den ersten laufenden Auftrag nehmen. Wer gerade eine Quest
	# abgegeben hat und noch eine zweite laufen hat, soll nicht ohne Wegweiser dastehen.
	var laufend: Array = active_quests()
	return String(laufend[0]) if not laufend.is_empty() else ""


## Auftrag verfolgen. `false`, wenn er nicht läuft.
func track_quest(quest_id: String) -> bool:
	if not has_quest(quest_id) or get_quest_state(quest_id) != STATE_ACTIVE:
		return false
	GameState.tracked_quest = quest_id
	tracked_changed.emit(quest_id)
	return true


## Den nächsten laufenden Auftrag verfolgen (Knopf im HUD). Gibt die neue Id zurück.
func track_next() -> String:
	var laufend: Array = active_quests()
	if laufend.is_empty():
		GameState.tracked_quest = ""
		tracked_changed.emit("")
		return ""
	var i: int = laufend.find(tracked_quest())
	var naechste: String = String(laufend[(i + 1) % laufend.size()])
	track_quest(naechste)
	return naechste


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

	# (4) Tagesgrenze bei wiederholbaren Auftraegen. Sie steht beim ANNEHMEN und nicht erst beim
	#     Abgeben: Wer ihn annehmen darf und am Ende hoert „heute nicht mehr", hat umsonst
	#     gekaempft. Ein gesperrter Auftrag darf gar nicht erst anfangen.
	if heute_schon_abgegeben(quest_id):
		questline_blocked.emit(quest_id, "heute_schon")
		return false

	# Übergang. Bei Kill-Quests den aktuellen Kill-Stand als Basis einfrieren.
	GameState.quests[quest_id] = STATE_ACTIVE
	if String(def["kind"]) == "kill":
		GameState.quest_base[quest_id] = GameState.kills

	# Der frisch angenommene Auftrag wird SOFORT verfolgt. Wer gerade „ja" gesagt hat, will
	# als Naechstes wissen, wohin — und nicht erst ein Menue suchen, in dem er das einstellt.
	GameState.tracked_quest = quest_id

	GameState.quest_state_changed.emit(quest_id, STATE_ACTIVE)
	tracked_changed.emit(quest_id)
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
	#
	# Wiederholbare Aufträge gehen zurück auf "available" statt auf "done": Der Auftraggeber
	# bietet sie beim nächsten Gespräch erneut an. Ohne sie ist Rustwater nach dem letzten
	# Auftrag wieder stumm, und dann lässt sich weder die Wegweisung noch sonst etwas prüfen.
	#
	# Der Kill-Basiswert wird in beiden Fällen gelöscht. Bei einem wiederholbaren Auftrag ist
	# das die halbe Miete: `accept_quest` friert ihn beim nächsten Annehmen neu ein, der
	# Fortschritt fängt also wieder bei 0 an statt sofort auf voll zu stehen.
	var wiederholbar: bool = bool(def.get("repeatable", false))
	var neuer_zustand: String = STATE_AVAILABLE if wiederholbar else STATE_DONE
	# Und der Tag wird vermerkt: Wieder verfuegbar heisst „ab morgen", nicht „sofort noch mal".
	# Ohne diese Zeile ist der Auftrag ein Geldhahn (siehe `heute_schon_abgegeben`).
	if wiederholbar:
		GameState.quest_tag[quest_id] = GameState.tag
	GameState.quests[quest_id] = neuer_zustand
	GameState.quest_base.erase(quest_id)
	GameState.quest_state_changed.emit(quest_id, neuer_zustand)

	# (6) Kapitel-Fortschritt der Ketten-Quests.
	var advance_to: int = int(def.get("advance_to", 0))
	if advance_to > GameState.current_chapter:
		_set_chapter(advance_to)

	# Verfolgt wurde dieser Auftrag? Dann auf den naechsten laufenden umhaengen statt den
	# Wegweiser ins Leere zeigen zu lassen. `tracked_quest()` faellt von selbst zurueck, die
	# Zuweisung macht es nur explizit und speicherbar.
	if String(GameState.tracked_quest) == quest_id:
		GameState.tracked_quest = tracked_quest()
		tracked_changed.emit(String(GameState.tracked_quest))

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
