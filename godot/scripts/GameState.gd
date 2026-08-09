extends Node

const DayCycle = preload("res://scripts/DayCycle.gd")
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
## Perk-Baum (Fallout-Achse, Master-GDD §7.5.1): Punkte + Ränge je Perk-id.
var perk_points: int = 0
var perks: Dictionary = {}   ## perk_id (String) -> Rang (int)
## Werkstatt-Upgrades (Stufen) — fließen in die effektiven Werte (PlayerStats).
var upgrades: Dictionary = { "damage": 0, "firerate": 0, "reload": 0, "hp": 0, "speed": 0,
	"regen": 0, "magnet": 0 }
## New Game+-Zyklus (Beute-/Skalierungs-Ertrag).
var ng_plus: int = 0

# ── Wirtschaft & Beutel ───────────────────────────────────────────────────────
var gold: int = 0
var potions: int = 3
var inventory: Dictionary = { "schrott": 0, "zahnrad": 0, "dampfkern": 0, "grubenstahl": 0 }

## Wie die Materialien heißen, wenn sie jemand liest.
##
## `grubenstahl` ist das jüngste und das einzige, das man **nirgendwo sonst** bekommt. Der
## Grund steht in der Sache selbst: Schrott von der Oberfläche liegt seit dem Krieg in Sonne
## und Sandstürmen und ist durchgerostet. Was im Stollen liegt, lag im Trockenen und im
## Dunkeln — es ist noch Stahl.
##
## Das ist nicht nur Beiwerk. Silas' Auftrag verlangte anfangs schlicht `schrott`, und damit
## hätte man ihn mit dem erledigen können, was ohnehin überall herumliegt — der Stollen wäre
## ein Umweg gewesen, den man auslassen kann. Ein Auftrag, der einen an einen Ort schicken
## soll, muss nach etwas verlangen, das es **nur dort** gibt.
const MATERIAL_NAMEN: Dictionary = {
	"schrott": "Schrott",
	"zahnrad": "Zahnrad",
	"dampfkern": "Dampfkern",
	"grubenstahl": "Grubenstahl",
}

## Nur im Stollen zu finden — die Prüfung hält das fest, damit es nicht versehentlich in eine
## Beutetabelle der Oberwelt rutscht.
const NUR_IM_STOLLEN: Array[String] = ["grubenstahl"]
## Angelegte Ausrüstung: equip_slot (String) -> Gear-Dictionary (leer/fehlend = nichts).
## Slots: helmet/armor/weapon/gadget/boots + plate1..plate8 (Platten/Tech). Siehe EquipManager.
var equip: Dictionary = {}
## Beutel: Array von Gear-Dictionaries. Aufgesammelte Ausrüstung landet hier, statt sich
## selbst anzulegen — sonst wäre Beute etwas, das einem PASSIERT, statt etwas, das man
## entscheidet. Kapazität und Platzbedarf rechnet `BagManager` über das Grid-Inventar.
var bag: Array = []
## Munitionsvorräte (GDD §7.1.1): pool -> Menge. Siehe `AmmoData`.
var ammo: Dictionary = { "muni": 90, "kristall": 45 }
## Geladene Schüsse je Waffe. Zwei Stufen statt einer: aus dem MAGAZIN wird geschossen, aus
## `ammo` wird nachgeladen. Erst das erzeugt den Rhythmus aus Feuern und Deckung.
var mag: Dictionary = {}

## Township-Gebäude: id -> Ausbaustufe (int). Flache Form (im GDD-Schema §2.3 verschachtelt
## als {level:int} beschrieben; hier vereinfacht, `building_level()` kapselt den Zugriff).
## `laboratory` (Alchemie-Labor) ist das Raffinerie-Gebäude für das Smog-Gate (§1.7.2).
var economy: Dictionary = { "saloon": 0, "forge": 0, "distillery": 0, "laboratory": 0 }

# ── Kampf-Zähler: monotone Gesamt-Kills; Basis für das Kill-Quest-Tracking ─────
var kills: int = 0

# ── Quest-Zustände ────────────────────────────────────────────────────────────
var quests: Dictionary = {}       ## quest_id (String) -> "available" | "active" | "done"
var quest_base: Dictionary = {}   ## quest_id (String) -> Kill-Stand zum Annahme-Zeitpunkt (int)
## Der VERFOLGTE Auftrag ("" = keiner). Er bestimmt, wohin die Marke auf der Karte und die
## Fussspur am Boden zeigen. Gehoert in den Spielstand: Wer das Spiel mitten auf dem Weg
## verlaesst, soll beim naechsten Start nicht wieder ohne Richtung dastehen.
var tracked_quest: String = ""

# ── Waffen: was der Held GEFUNDEN hat ────────────────────────────────────────
## Bisher trug er alle fuenf Waffen von der ersten Sekunde an — mit dem Umschalter durch das
## ganze Arsenal, ohne je eine gefunden zu haben. Damit ist die Beute wertlos und die
## Schadensarten-Mechanik (§6.1) hat keinen Aufbau: Wer alles hat, lernt nichts dazu.
##
## Jetzt beginnt er mit **leeren Haenden** in der Schrottgrube. Der Blei-Karabiner liegt in der
## Truhe dort — der erste Fund des Spiels, und der Grund, ueberhaupt hinzusehen.
var weapons: Array = []

## Hat er diese Waffe?
func has_weapon(id: String) -> bool:
	return weapons.has(id)

## Aufsammeln. `true`, wenn sie neu war.
func add_weapon(id: String) -> bool:
	if id == "" or weapons.has(id):
		return false
	weapons.append(id)
	return true

## Die zurzeit gefuehrte Waffe ("" = keine).
var weapon_id: String = ""

## Prolog abgeschlossen? Steuert, wo eine Runde ANFAENGT: erst die Grube, danach Rustwater.
var prolog_done: bool = false
## Laeuft die Runde als TUTORIAL? Dann bekommt der Prolog Hinweistafeln.
##
## Das Tutorial ist derselbe Prolog und kein zweiter Inhalt: Ein eigener Tutorial-Abschnitt
## hiesse zwei Anfaenge zu pflegen, und einer davon wird schlechter. Der Unterschied sind
## eingeblendete Saetze, nicht eine andere Welt.
var tutorial: bool = false
## Ist die Szene mit dem ersten Gegner schon gelaufen?
##
## Sie darf genau einmal stattfinden — sie erklaert das Pluendern, und was erklaert ist, muss
## nicht noch einmal erklaert werden.
var erst_gegner_done: bool = false

## Hat er Rustwater schon einmal von weitem gesehen? Steuert den einmaligen Kameraflug.
var saw_rustwater: bool = false
## Lief die Aufwach-Szene schon? Eigenes Merkmal neben `prolog_done`, weil beides verschiedene
## Fragen beantwortet: `prolog_done` heisst „der Anfang ist durch", `saw_wake` heisst „das
## Aufstehen wurde gezeigt". Wer mitten im Prolog speichert und wiederkommt, soll da weiter-
## machen, wo er war — und nicht jedes Mal neu aufstehen.
var saw_wake: bool = false
## Stand er schon oben auf dem Ausguck? Die Rundsicht laeuft einmal.
var saw_vista: bool = false

## Wen man schon einmal angesprochen hat — `giver` → true.
##
## Steuert die `erst`-Zeilen in `DialogData`: Eine Begruessung, die man jedes Mal hoert, ist
## keine Begruessung. Eigenes Feld und nicht aus dem Questzustand abgeleitet, weil man auch mit
## Leuten reden kann, die nichts zu vergeben haben — und die begruessen einen trotzdem nur
## einmal.
var met: Dictionary = {}

## Tageszeit in Stunden (0–24). Laeuft in Echtzeit weiter und steht im Spielstand — wer abends
## aufhoert, faengt abends wieder an.
var hour: float = DayCycle.START_HOUR

## Wie viele Tage vergangen sind. Zaehlt hoch, wenn `hour` ueber Mitternacht laeuft.
##
## Gebraucht fuer Wandas Regal: Ihr Bestand ist eine Funktion dieser Zahl (siehe
## `HaendlerData`), nicht eine Liste im Spielstand. Damit liegt an einem Tag immer dasselbe
## aus — beim Oeffnen, beim Schliessen, nach dem Laden — und am naechsten Morgen etwas anderes,
## ohne dass irgendwo Gegenstaende gespeichert werden muessten, die niemandem gehoeren.
var tag: int = 0
## Welche Regalplaetze an welchem Tag schon gekauft wurden. Verkauft ist verkauft.
var gekauft_heute: Dictionary = {}

## Wie viele Schlüssel man bei sich trägt.
##
## Sie kommen ausschließlich von **Anführern** und öffnen ausschließlich **Beutekammern**. Das
## ist der ganze Zweck: Die beste Truhe im Spiel steht sichtbar da und lässt sich trotzdem nicht
## einfach einsammeln — man muss dafür dreimal einen Kampf suchen, den man umgehen könnte.
##
## Sie stehen hier und nicht im Beutel: Ein Schlüssel ist kein Gegenstand, den man ablegt,
## verkauft oder verschrottet, und im Rucksack wäre er beides — ein Platz, den er wegnimmt, und
## ein Versehen, das man nicht rückgängig machen kann.
var schluessel: int = 0

# ── Der Stollen ───────────────────────────────────────────────────────────────
#
# Ein Dungeon ist eine EIGENE Szene, und der Weg zurück muss ihn überleben. Diese drei Werte
# sind alles, was die Oberwelt darüber wissen muss:
#
# `stollen_ebene` 0 = draußen, sonst die Ebene, in der man steckt. Sie steht hier und nicht in
# der Szene, weil die Szene beim Wechsel verschwindet.
var stollen_ebene: int = 0
## Aus welchem Startwert der Grundriss gerechnet wird. Er bleibt gleich, solange man drin ist —
## sonst stünde man nach der Treppe in einem anderen Stollen als dem, den man betreten hat.
var stollen_startwert: int = 0
## Wohin die Figur zurückgesetzt wird, wenn sie wieder herauskommt. Ohne das landet man beim
## Verlassen an der Startposition der Oberwelt — also unter Umständen quer über der Karte.
var stollen_rueckkehr: Vector3 = Vector3.ZERO

# ── Roter Faden: Erinnerungs-Walzen & Familien-Bogen (Master-GDD §7.5.12a/b, §8.3) ──
var memories_found: int = 0        ## 0..MemoryManager.chain_length(); geordnete Erinnerungskette
var memorials_seen: Array = []     ## ids besuchter Erinnerungspunkte in Providence Cut
var family_buried: bool = false    ## alle Walzen an den drei Gräbern beigesetzt (16/16)
var codex: Array = []              ## freigeschaltete Codex-Einträge (ids)

## Kamera-Zoomstufe (Index in OverworldView.CAM_ZOOM_STEPS). Gehoert in den Spielstand, weil
## die Wahl zwischen "nah in der Stadt" und "weit in der Wueste" eine Entscheidung ist — man
## soll sie nicht jede Sitzung neu treffen muessen.
var cam_zoom: int = 1

## Erkundete Karte (Fog of War, siehe `FogOfWar`): Zellenschlüssel (int) -> 1.
## Nur BESUCHTE Zellen stehen drin — ein Raster über die ganze Karte wären 15 625 Einträge in
## jedem Spielstand, auch bei jemandem, der noch nichts gesehen hat.
var fog: Dictionary = {}

# ── Ablauf-Flags (nur backend-relevante; UI-Only-Flags leben in der UI-Schicht) ─
var flags_ui: Dictionary = { "reveal_playing": false }


## Alles auf Anfang — fuer „Neues Spiel" im Titelbildschirm.
##
## Die Spielstanddatei zu loeschen reicht nicht: Dieser Knoten ist ein Autoload und ueberlebt
## jeden Szenenwechsel. Wer im Titel „Neues Spiel" waehlt, nachdem er schon einmal gespielt hat,
## braechte sonst Gold, Stufe und Ausruestung mit — und, schlimmer, die erledigten Marken des
## Prologs: Der Film waere gelaufen, und danach haette die Figur wortlos in der Grube gestanden,
## weil `saw_wake` noch stand.
##
## Aufgezaehlt wird hier ABSICHTLICH von Hand und nicht ueber eine Schleife: Wer ein neues Feld
## einfuehrt, das eine Runde ueberdauert, soll gezwungen sein, sich zu entscheiden, ob es beim
## Neuanfang stehenbleibt. Eine Schleife wuerde diese Entscheidung stillschweigend treffen.
func neu_beginnen() -> void:
	current_chapter = 1
	is_revealed = false
	chosen_guild = null
	level = 1
	xp = 0
	perk_points = 0
	perks = {}
	upgrades = { "damage": 0, "firerate": 0, "reload": 0, "hp": 0, "speed": 0,
		"regen": 0, "magnet": 0 }
	ng_plus = 0
	gold = 0
	potions = 3
	inventory = { "schrott": 0, "zahnrad": 0, "dampfkern": 0, "grubenstahl": 0 }
	equip = {}
	bag = []
	ammo = { "muni": 90, "kristall": 45 }
	mag = {}
	economy = { "saloon": 0, "forge": 0, "distillery": 0, "laboratory": 0 }
	kills = 0
	tag = 0
	gekauft_heute = {}
	quests = {}
	quest_base = {}
	tracked_quest = ""
	weapons = []
	weapon_id = ""
	met = {}
	memories_found = 0
	memorials_seen = []
	family_buried = false
	codex = []
	fog = {}
	flags_ui = { "reveal_playing": false }
	# Der Prolog. Alles hier muss zurueck, sonst faengt das „neue" Spiel mittendrin an.
	prolog_done = false
	saw_wake = false
	saw_rustwater = false
	saw_vista = false
	erst_gegner_done = false
	hour = 18.6
	stollen_ebene = 0
	stollen_startwert = 0
	stollen_rueckkehr = Vector3.ZERO
	schluessel = 0


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

## Gold ausgeben. Liefert `false` und ändert NICHTS, wenn es nicht reicht.
##
## Bewusst kein `add_gold(-kosten)`: Das klemmt still bei 0 ab, ein Kauf ginge also auch mit zu
## wenig Gold durch und der Spieler stünde hinterher einfach bei null. Ein Kauf muss ganz
## stattfinden oder gar nicht — und der Aufrufer muss das am Rückgabewert erkennen können.
func spend_gold(amount: int) -> bool:
	if amount <= 0 or gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

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


## Wie viel ein Trank heilt — als ANTEIL, nicht als feste Zahl.
##
## Eine feste Zahl ist auf Stufe 1 ein halbes Leben und auf Stufe 20 ein Tropfen. Ein Anteil
## bleibt ueber die ganze Kampagne dasselbe Versprechen: „ungefaehr ein Drittel zurueck".
const TRANK_ANTEIL: float = 0.35


## Einen Trank trinken. `false`, wenn keiner da ist oder es nichts zu heilen gibt.
##
## Die zweite Bedingung ist keine Schikane, sondern Schutz: Auf dem Handy sitzt der Knopf dort,
## wo der Daumen ohnehin liegt, und ein Trank, der bei vollem Leben verschwindet, ist ein
## Fehlgriff, den niemand rueckgaengig machen kann.
func trank_trinken(hp: float) -> float:
	if potions <= 0 or hp >= float(max_hp()) - 0.5:
		return -1.0
	potions -= 1
	return minf(float(max_hp()), hp + float(max_hp()) * TRANK_ANTEIL)


# ── Township-Gebäude ──────────────────────────────────────────────────────────
func building_level(id: String) -> int:
	return int(economy.get(id, 0))

func set_building_level(id: String, level: int) -> void:
	economy[id] = maxi(0, level)


# ── Codex ─────────────────────────────────────────────────────────────────────
func codex_has(id: String) -> bool:
	return codex.has(id)

## Schaltet einen Codex-Eintrag frei; gibt false zurück, wenn schon bekannt (idempotent).
func unlock_codex(id: String) -> bool:
	if codex.has(id):
		return false
	codex.append(id)
	return true
