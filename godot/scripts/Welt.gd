extends RefCounted
## Der Weltzustand des Abenteuers — lesen, ändern, Wirkungen anwenden.
##
## ## Warum eine eigene Klasse und nicht alles in `GameState`
##
## `GameState` ist Speicher: sechs Felder, die der `SaveManager` schreibt und liest, und nichts
## weiter. Hier steht, was sie bedeuten. Diese Trennung ist nicht Geschmack — sie ist der Grund
## dafür, dass die Testsuite ein ganzes Rätsel durchspielen kann, ohne eine Szene zu laden:
## `Welt.wirken()` ist eine Funktion mit Rückgabewert, und die prüft man headless.
##
## ## Eine Regel, die hier eingebaut ist
##
## **Jede Wirkung ist genau einmal wirksam, wenn sie `einmal` setzt.** Der Spieler darf einen
## Hotspot beliebig oft anklicken — ein Adventure, in dem Doppelklick Geld verdoppelt, ist
## kaputt, und zwar auf eine Art, die beim Testen nie auffällt, weil niemand freiwillig
## zwanzigmal auf denselben Kaktus klickt.

const MissionDaten = preload("res://scripts/MissionDaten.gd")
const OrtDaten = preload("res://scripts/OrtDaten.gd")


# ── Flaggen ───────────────────────────────────────────────────────────────────

static func flagge(kennung: String) -> bool:
	return bool(GameState.flaggen.get(kennung, false))


static func flagge_setzen(kennung: String) -> void:
	if kennung != "":
		GameState.flaggen[kennung] = true


# ── Beutel ────────────────────────────────────────────────────────────────────

static func im_beutel(kennung: String) -> bool:
	return kennung in GameState.beutel


## Einen Gegenstand aufnehmen. Doppelt aufnehmen gibt es nicht — ein zweiter Schraubstock wäre
## kein Vorteil, sondern eine Zeile mehr im Inventar und eine Frage mehr beim Kombinieren.
static func nehmen(kennung: String) -> bool:
	if kennung == "" or im_beutel(kennung):
		return false
	GameState.beutel.append(kennung)
	return true


static func abgeben(kennung: String) -> bool:
	var i: int = GameState.beutel.find(kennung)
	if i < 0:
		return false
	GameState.beutel.remove_at(i)
	return true


# ── Zähler ────────────────────────────────────────────────────────────────────

static func zaehler(kennung: String) -> int:
	return int(GameState.zaehler.get(kennung, 0))


static func zaehlen(kennung: String, um: int = 1) -> int:
	if kennung == "":
		return 0
	GameState.zaehler[kennung] = zaehler(kennung) + um
	return int(GameState.zaehler[kennung])


# ── Orte ──────────────────────────────────────────────────────────────────────

static func war_schon(ort_kennung: String) -> bool:
	return ort_kennung in GameState.besucht


## Einen Ort betreten. Gibt zurück, ob es das erste Mal war — der Aufrufer zeigt dann den
## Ortsnamen groß an, sonst nur kurz.
static func betreten(ort_kennung: String) -> bool:
	GameState.ort = ort_kennung
	if war_schon(ort_kennung):
		return false
	GameState.besucht.append(ort_kennung)
	return true


# ── Notizen ───────────────────────────────────────────────────────────────────

static func hat_notiz(kennung: String) -> bool:
	return kennung in GameState.notizen


static func notieren(kennung: String) -> bool:
	if kennung == "" or hat_notiz(kennung):
		return false
	if MissionDaten.notiz(kennung).is_empty():
		return false   # eine Notiz, die es nicht gibt, wird nicht angelegt
	GameState.notizen.append(kennung)
	return true


# ── Sichtbarkeit von Hotspots ─────────────────────────────────────────────────

## Ist dieser Hotspot gerade da?
##
## `sicht` verlangt eine Flagge, `weg` verbietet eine. Zusätzlich verschwindet jeder Hotspot
## mit `nehmen`, dessen Gegenstand schon im Beutel liegt — sonst stünde die Akte weiter auf dem
## Tisch, nachdem man sie eingesteckt hat, und das ist der häufigste sichtbare Fehler in
## selbstgebauten Adventures.
static func sichtbar(punkt: Dictionary) -> bool:
	if punkt.has("sicht") and not flagge(str(punkt["sicht"])):
		return false
	if punkt.has("weg") and flagge(str(punkt["weg"])):
		return false
	if punkt.has("nehmen") and im_beutel(str(punkt["nehmen"])):
		return false
	return true


## Als `Callable` für `OrtDaten.punkt_bei()`.
static func sicht_pruefer() -> Callable:
	return func(_k: String, p: Dictionary) -> bool: return sichtbar(p)


# ── Wirkungen ─────────────────────────────────────────────────────────────────

## Eine Wirkung anwenden — der Kern des Rätsel-Systems.
##
## Nimmt entweder eine Wirkungs-Kennung aus `MissionDaten.WIRKUNGEN` oder ein fertiges
## Wirkungs-Dictionary (so benutzen es die Antworten in `GespraechDaten`). Gibt den Text
## zurück, den die Oberfläche anzeigt — leerer String heißt: nichts zu sagen.
static func wirken(was: Variant) -> String:
	var w: Dictionary = {}
	if was is String:
		w = MissionDaten.wirkung(str(was))
	elif was is Dictionary:
		w = was as Dictionary
	if w.is_empty():
		return ""

	# 0. Eine Wirkung, die eine Flagge voraussetzt, tut vorher nichts.
	#
	# Das ist die Sperre gegen unlösbare Spielstände. Wer Dolores die gesprungene Walze gibt,
	# bevor Silas die Stifte gesetzt hat, wäre sie los — und damit die Mission, denn eine
	# zweite Walze gibt es nicht. Solche Zustände merkt man beim Testen nie, weil man die
	# richtige Reihenfolge kennt. Der Spieler kennt sie nicht; das ist ja das Rätsel.
	if w.has("nur_wenn") and not flagge(str(w["nur_wenn"])):
		return str(w.get("text_noch_nicht", "Noch nicht."))

	# 1. Fehlt ein benötigter Gegenstand, passiert GAR NICHTS — auch keine Flagge. Sonst
	#    könnte man einen Schritt abschließen, ohne ihn getan zu haben.
	var noetig: Array = MissionDaten.braucht_liste(w)
	if not noetig.is_empty():
		var habe: bool = false
		for g in noetig:
			if im_beutel(str(g)):
				habe = true
				break
		if not habe:
			return str(w.get("text_fehlt", "Dafür fehlt mir etwas."))

	# 2. Schon gewirkt? Dann nur noch der Nachsatz.
	if w.has("einmal") and flagge(str(w["einmal"])):
		return str(w.get("text_wieder", w.get("text", "")))

	# 3. Jetzt erst ändern.
	if w.has("gegenstand"):
		nehmen(str(w["gegenstand"]))
	if w.has("flagge"):
		flagge_setzen(str(w["flagge"]))
	# Mehrere auf einmal. Gebraucht am Ende eines Kapitels, wo eine Antwort gleichzeitig
	# einen Weg oeffnet und das Kapitel abhakt.
	for f in w.get("flaggen", []) as Array:
		flagge_setzen(str(f))
	if w.has("einmal"):
		flagge_setzen(str(w["einmal"]))
	if w.has("notiz"):
		notieren(str(w["notiz"]))
	if w.has("zaehler"):
		zaehlen(str(w["zaehler"]), int(w.get("um", 1)))
	if w.has("gold"):
		GameState.gold = maxi(0, GameState.gold + int(w["gold"]))
	if w.has("erfahrung"):
		GameState.add_xp(int(w["erfahrung"]))
	if w.has("quest"):
		mission_annehmen(str(w["quest"]))
	if bool(w.get("enthuellen", false)) and not GameState.is_revealed:
		# Der Reveal. Er steht als Wirkung und nicht im Gespraechscode, weil er an GENAU
		# einer Stelle ausgeloest werden darf und man das dann auch nachlesen kann.
		GameState.is_revealed = true
		GameState.reveal_finished.emit()
	if w.has("verbraucht"):
		abgeben(str(w["verbraucht"]))

	return str(w.get("text", ""))


## Zwei Gegenstände verbinden. Gibt den Text zurück, oder "" wenn nichts daraus wird.
##
## Beide gehen dabei in den neuen über. Das ist die einzige Stelle, an der ein Gegenstand den
## Beutel verlässt, und deshalb muss jede Verbindung anderswo einen zweiten Weg lassen oder
## ihr Ergebnis muss alles können, was die Teile konnten — siehe `MissionDaten.braucht_liste`.
static func verbinden(a: String, b: String) -> String:
	var v: Dictionary = MissionDaten.verbindung(a, b)
	if v.is_empty() or not im_beutel(a) or not im_beutel(b):
		return ""
	abgeben(a)
	abgeben(b)
	nehmen(str(v.get("wird", "")))
	GameState.add_xp(60)
	return str(v.get("text", ""))


# ── Missionen ─────────────────────────────────────────────────────────────────

## Eine Mission annehmen. Doppelt annehmen ist kein Fehler, sondern ein Nichts — der Spieler
## darf eine Antwort zweimal wählen, ohne dass der Fortschritt zurückgesetzt wird.
static func mission_annehmen(kennung: String) -> bool:
	if kennung == "" or MissionDaten.mission(kennung).is_empty():
		return false
	if GameState.quests.get(kennung, "") in ["active", "done"]:
		return false
	GameState.quests[kennung] = "active"
	GameState.quest_state_changed.emit(kennung, "active")
	return true


static func mission_laeuft(kennung: String) -> bool:
	return str(GameState.quests.get(kennung, "")) == "active"


static func mission_fertig(kennung: String) -> bool:
	return str(GameState.quests.get(kennung, "")) == "done"


## Wie weit eine Mission ist: [erledigte Schritte, Schritte insgesamt].
static func fortschritt(kennung: String) -> Array:
	# Lambdas und nicht `Callable(Welt, "flagge")`: Dieses Skript hat keinen `class_name`, also
	# gibt es innerhalb der Datei keinen Namen, unter dem man sich selbst adressieren koennte.
	# Ein `Callable(self, ...)` gibt es bei statischen Funktionen auch nicht.
	return MissionDaten.fortschritt(kennung,
		func(k: String) -> bool: return flagge(k),
		func(k: String) -> bool: return im_beutel(k),
		func(k: String) -> int: return zaehler(k),
		func(k: String) -> bool: return war_schon(k))


## Alle laufenden Missionen prüfen und fertige auszahlen.
##
## Gibt die Kennungen der Missionen zurück, die in diesem Durchgang fertig geworden sind — die
## Oberfläche sagt sie an. Wird nach jeder Wirkung aufgerufen; das ist billiger als es aussieht
## (eine Handvoll Missionen, ein paar Dictionary-Zugriffe) und spart die Pflicht, an jedem
## einzelnen Rätsel an die Abgabe zu denken. Genau die wird nämlich vergessen.
static func missionen_pruefen() -> Array:
	var fertig: Array = []
	for kennung in GameState.quests.keys():
		if not mission_laeuft(str(kennung)):
			continue
		var f: Array = fortschritt(str(kennung))
		if int(f[1]) > 0 and int(f[0]) >= int(f[1]):
			GameState.quests[kennung] = "done"
			GameState.quest_state_changed.emit(str(kennung), "done")
			var lohn: Dictionary = MissionDaten.mission(str(kennung)).get("lohn", {}) as Dictionary
			if lohn.has("gold"):
				GameState.add_gold(int(lohn["gold"]))
			if lohn.has("erfahrung"):
				GameState.add_xp(int(lohn["erfahrung"]))
			fertig.append(str(kennung))
	return fertig


## Die laufenden Missionen, in der Reihenfolge der Tabelle — damit das Tagebuch nicht bei jedem
## Öffnen anders sortiert ist (ein Dictionary hat keine verlässliche Reihenfolge über
## Spielstände hinweg).
static func laufende_missionen() -> Array:
	var raus: Array = []
	for k in MissionDaten.alle_missionen():
		if mission_laeuft(str(k)):
			raus.append(str(k))
	return raus


static func fertige_missionen() -> Array:
	var raus: Array = []
	for k in MissionDaten.alle_missionen():
		if mission_fertig(str(k)):
			raus.append(str(k))
	return raus


# ── Neu anfangen ──────────────────────────────────────────────────────────────

## Den Abenteuer-Zustand auf den Anfang stellen.
##
## Rührt den Rest von `GameState` nicht an. Das ist wichtig für „Neues Spiel" aus einem
## laufenden Spiel heraus: Wer hier auch Gold und Stufe zurücksetzt, löscht einen Spielstand,
## den der Spieler nicht löschen wollte.
static func neu() -> void:
	GameState.ort = "kippe"
	GameState.flaggen = {}
	GameState.beutel = []
	GameState.zaehler = {}
	GameState.besucht = []
	GameState.notizen = []
