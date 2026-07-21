class_name MemoryManager extends RefCounted
## MemoryManager — roter Faden: Erinnerungs-Walzen & Familien-Bogen (Master-GDD §7.5.12a/b, §8.3).
##
## Reine Logik/Daten (`class_name`, statisch). Alle Zustandsänderungen laufen über `GameState`
## (memories_found / memorials_seen / family_buried / codex) — kein dupliziter Zustand.
## Portiert aus dem validierten Web-Prototyp (`MEMORIES`, `recoverMemory`, `playMemorial`).
##
## Determinismus: `try_recover_memory` nimmt optional einen `roll` (0..1) statt `randf()`,
## damit der Drop-Pfad testbar ist.

# ── Erinnerungskette: geordnet (früh → dunkel); jeder Fund enthüllt das nächste Fragment. ──
const MEMORIES: Array = [
	{ "title": "Der Nagel", "text": "Du schlugst einen Nagel in den Türrahmen — eine Kerbe für Saras Größe. „Halt still\", sagte Liv, „sie wächst schneller, als du hämmerst.\" Das Holz war warm von der Sonne." },
	{ "title": "Kaffee, zu früh", "text": "Vier Uhr, noch dunkel. Liv drückte dir den Blechbecher in die Hand, ohne die Augen aufzumachen. „Der Kaffee wird kalt, Jeremiah.\" Er wurde nie kalt. Du trankst ihn im Gehen." },
	{ "title": "Toms Ohr an der Schiene", "text": "Tom legte ein Ohr auf den kalten Stahl, um den Zug zu hören, bevor man ihn sah. „Noch nicht, Pa?\" — „Noch nicht.\" Ihr wartetet zusammen, bis die Schiene sang." },
	{ "title": "Livs Lachen", "text": "Sie lachte immer eine Terz zu hoch. Beim Wäscheaufhängen, den Mund voll Klammern. Keinem hat's was ausgemacht. Dir am wenigsten." },
	{ "title": "Das erleuchtete Fenster", "text": "Zwölf Stunden Schotter und Sonne, der Rücken ein einziger Krampf. Aber am Ende der Schicht lag Rustwater vor dir, und ein Fenster war erleuchtet. Deins." },
	{ "title": "Der Streik", "text": "Sie kürzten den Lohn zum dritten Mal. „Wir legen die Werkzeuge nieder\", sagtest du zu den Männern. Liv nähte die Transparente. Providence Cut sollte gehört werden." },
	{ "title": "Das Versprechen", "text": "Sara fragte, ob du zum Fest zurück bist. „Bevor die Lampen an sind\", sagtest du. Du hast das Versprechen nicht gebrochen, weil du es vergessen hast. Es hat dich gebrochen." },
	{ "title": "Der Stollen", "text": "Der Balken gab nach, ohne Warnung. Ein Krachen, dann Gewicht, dann nichts mehr unterhalb der Brust. Du hörtest die Männer graben. Du hörtest Liv rennen. Du hörtest den Zug." },
	{ "title": "Vanes Zug", "text": "Ein Waggon hielt, wo keiner halten sollte. Eine Rampe fiel. Ein Mann mit einem Gesicht wie ruhiges Öl kniete sich zu dir in den Staub. „Ich kann den Tod aufhalten\", sagte er. „Fragt sich nur, ob du mir dafür dienst.\"" },
	{ "title": "Livs Bitte", "text": "Sie bettelte an seinem Zug um Hilfe, die Hände am kalten Messing. Vane lächelte und half — auf seine Art. Das Letzte, was du als Mensch sahst, war ihr Gesicht im Türspalt." },
	{ "title": "Die Naht", "text": "Kälte, dann kein Körper mehr. Man hört das Ticken, bevor man das Denken hört. Eine Stimme ohne Mund: „Systemstart. Einheit 13. Willkommen im Dienst.\"" },
	{ "title": "Der erste Schritt", "text": "Der Boden fühlte sich nicht an. Deine Hand — nicht deine Hand — schloss sich zur Faust, und der Stahl gehorchte, bevor du es wolltest. Irgendwo unter dem Öl schrie etwas, das du warst." },
	{ "title": "Befehl", "text": "Auf der Lochkarte stand nur: STRECKE RÄUMEN. Kein Ort. Keine Namen. Der Konzern gibt Werkzeugen keine Namen weiter. Du rolltest nordwärts, gehorsam wie ein Uhrwerk." },
	{ "title": "Providence Cut", "text": "Die Rampe fiel. Streikposten an der Trasse. Transparente, die du kanntest, ohne zu wissen, warum. Und eine Frau trat vor — so, wie man einem Mann in den Weg tritt, den man kennt." },
	{ "title": "Ihr Mund formte ein Wort", "text": "Kein Ton blieb auf der Walze. Aber jeder, der es je sah, liest dasselbe von ihren Lippen: „Jeremiah?\" Du hast nicht angehalten. Du konntest nicht. Du warst nicht mehr du." },
	{ "title": "Der Kaskadenfehler", "text": "Danach: ein Ticken, das zu laut wurde. Ein Rechenkern, der sich selbst zerriss, um nicht zu wissen, was er getan hatte. Du gingst in die Wüste, um zu verlöschen. Der Kessel ließ dich nicht. Also vergaßest du. Bis jetzt." },
]

# ── Drop-Wahrscheinlichkeit aus mechanischen Gegnern (Prototyp: 3 % normal, 50 % Boss). ──
const DROP_CHANCE_NORMAL: float = 0.03
const DROP_CHANCE_BOSS: float = 0.50

# ── Familiensuche: Erinnerungspunkte in Providence Cut. ──
const MEMORIAL_IDS: Array = ["doorframe", "photo", "graves"]

const FLASHBACKS: Dictionary = {
	"doorframe": [
		"Der Türrahmen steht noch — verkohlt, aber aufrecht. Auf Hüfthöhe: Kerben im Holz, mit dem Messer gezogen.",
		"„SARA — 4\" … „SARA — 5\" … und darüber, frisch verkohlt, eine Kerbe, die du nie gemessen hast.",
		"Deine Stahlfinger fahren die letzte Kerbe nach. Damals war das Holz warm von der Sonne. Jetzt ist es kalt — kalt wie du.",
		"Hier warst du ein Vater. Der Nagel in deiner Hand hat kein Werkzeug gebaut. Er hat ein Kind gemessen.",
	],
	"photo": [
		"Auf dem verrußten Sims liegt ein Kinetoskop-Streifen, halb geschmolzen. Du hältst ihn gegen das Wüstenlicht.",
		"Vier Bilder, immer dieselben: eine Frau, die eine Terz zu hoch lacht. Ein Junge, das Ohr an einer Spielzeugschiene. Ein Mädchen auf Schultern.",
		"Die Schultern gehören einem Mann aus Fleisch — breit, sonnenverbrannt, lebendig. Du kennst die Haltung. Du kennst das Gesicht nicht mehr.",
		"Liv. Tom. Sara. Und Jeremiah Hale, der einmal du war. Du steckst den Streifen dorthin, wo dein Herz nicht mehr schlägt.",
	],
}

## Gräber sind gestuft: unvollständig verweist zurück auf die Walzensuche; bei 16/16 → Begräbnis.
const GRAVES_LINES: Dictionary = {
	"incomplete": [
		"Drei Hügel, namenlos. Die Nachbarn haben begraben, was der Konzern zurückließ — sie wussten nicht, wen.",
		"Du kniest dich hin, aber deine Hände sind leer. Was hier liegt, ist noch nicht ganz. Du bist es auch nicht.",
		"Erst musst du dich finden — Splitter für Splitter, aus dem Blech deines Feindes.",
		"Komm wieder, wenn du ganz bist. Dann kannst du sie heimbringen.",
	],
	"ready": [
		"Drei Hügel, namenlos — die Nachbarn haben begraben, was der Konzern zurückließ. Du weißt jetzt, wer hier liegt.",
		"Sechzehn Walzen tickst du in deiner Handfläche. Splitter eines Mannes, den sie eingeschmolzen und über die halbe Wüste verstreut haben.",
		"Du legst sie in den Sand. Eine für Liv. Eine für Tom. Eine für Sara. Und den Rest für den Mann, der es nicht verhindern konnte.",
		"„Ich bin vor den Lampen zurück\", sagst du. Vierzig Jahre zu spät. Aber du bist da.",
	],
	"buried": [
		"Drei Steine, frisch gerichtet. Auf jedem eine Messingwalze, halb im Sand: für Liv, für Tom, für Sara.",
		"Der Kessel in deiner Brust tickt ruhig. Zum ersten Mal, seit man dich aufgeweckt hat, ist nichts mehr zu bergen.",
		"Du bleibst eine Weile. Dann drehst du dich zur Wüste. Irgendwo läuft noch ein Direktor frei herum.",
	],
}


# ── Erinnerungskette ──────────────────────────────────────────────────────────

static func chain_length() -> int:
	return MEMORIES.size()

static func is_complete() -> bool:
	return GameState.memories_found >= MEMORIES.size()

## Das nächste ungesehene Fragment (ohne es zu bergen), oder {} wenn die Kette voll ist.
static func next_memory() -> Dictionary:
	if is_complete():
		return {}
	return MEMORIES[GameState.memories_found]

## Birgt das nächste Fragment: rückt die Kette vor und schaltet beim ersten Fund den
## Codex-Eintrag zur Drop-Logik frei. Gibt das geborgene Fragment zurück ({} wenn voll).
static func recover_memory() -> Dictionary:
	if is_complete():
		return {}
	var m: Dictionary = MEMORIES[GameState.memories_found]
	GameState.memories_found += 1
	if GameState.memories_found == 1:
		GameState.unlock_codex("steuerwalzen")
	return m

static func recovery_chance(is_boss: bool) -> float:
	return DROP_CHANCE_BOSS if is_boss else DROP_CHANCE_NORMAL

## Kill-Handler-Einstieg für mechanische Gegner: würfelt den Drop und birgt bei Treffer.
## `roll` (0..1) macht den Pfad testbar; sonst `randf()`. Gibt das Fragment zurück oder {}.
static func try_recover_memory(is_boss: bool, roll: float = -1.0) -> Dictionary:
	if is_complete():
		return {}
	var r: float = roll if roll >= 0.0 else randf()
	if r >= recovery_chance(is_boss):
		return {}
	return recover_memory()


# ── Familiensuche (Providence Cut) ────────────────────────────────────────────

## Providence Cut öffnet erst nach dem Erwachen (reveal-gegatet).
static func is_providence_open() -> bool:
	return GameState.is_revealed

static func graves_state() -> String:
	if GameState.family_buried:
		return "buried"
	return "ready" if is_complete() else "incomplete"

## Spielt einen Erinnerungspunkt: markiert ihn als gesehen, schaltet ggf. Codex frei und
## liefert die Flashback-Zeilen. Für die Gräber zusätzlich `graves_state`; das Begräbnis
## selbst ist die separate Aktion `bury_family()` (View entscheidet im Zustand "ready").
static func play_memorial(id: String) -> Dictionary:
	assert(MEMORIAL_IDS.has(id), "MemoryManager: unbekannter Erinnerungspunkt '%s'" % id)
	var first: bool = not GameState.memorials_seen.has(id)
	if first:
		GameState.memorials_seen.append(id)
	if id == "graves":
		var gs: String = graves_state()
		return { "id": id, "first_seen": first, "graves_state": gs, "lines": GRAVES_LINES[gs] }
	if first:
		GameState.unlock_codex("familie")
	return { "id": id, "first_seen": first, "graves_state": "", "lines": FLASHBACKS[id] }

## Bettet die Familie bei — nur bei voller Kette und noch nicht begraben. Setzt family_buried,
## schaltet die Familien-/Heimkehr-Codex-Einträge frei. Gibt Erfolg zurück.
static func bury_family() -> bool:
	if not is_complete() or GameState.family_buried:
		return false
	GameState.family_buried = true
	GameState.unlock_codex("familie")
	GameState.unlock_codex("heimkehr")
	return true


# ── Erfolge (abgeleitet, kein eigener Zustand) ────────────────────────────────

static func is_rememberer() -> bool:   # „Jeremiah Hale": alle 16 Walzen geborgen
	return is_complete()

static func is_homecoming() -> bool:   # „Heimkehr": Familie beigesetzt
	return GameState.family_buried
