class_name ShopScreen extends Control
## Laden-Bildschirm — die Gold-Senke des Spiels, in zwei Betriebsarten.
##
## `WERKSTATT` (bei Silas Kupferauge): Kampfkraft ausbauen — Schaden, Feuerrate, Panzerung,
## Tempo, Regeneration, Loot-Magnet. Daten aus `WorkshopData`, wirksam über `PlayerStats`.
##
## `WIRTSCHAFT` (bei Mamma Mabel): die vier Rustwater-Betriebe ausbauen. Daten und Kauf über
## `TycoonManager`, der pro aktiver Spielsekunde Einkommen ausschüttet.
##
## Beides ist dieselbe Liste aus Zeilen — Bezeichnung, Stufe, Preis, Knopf — deshalb ein
## Skript und nicht zwei. Der Unterschied steckt allein in `_rows()` und `_buy()`.
##
## Warum es das ueberhaupt braucht: Bis hierher hatte Gold KEINE Senke. `add_gold` wurde beim
## Kill und an der Truhe gerufen, ausgegeben wurde es nirgends — die Kernschleife
## „töten → Gold → stärker werden" brach nach dem zweiten Schritt ab, obwohl Kostenkurven,
## Höchststufen und Einkommensrechnung im Hintergrund längst liefen.

## `WAFFEN` (bei Wanda Kessler): fertige Waffen gegen Gold. Anders als die beiden anderen
## Betriebsarten verkauft sie GEGENSTAENDE und keine Stufen — die Spalte "Stufe" traegt deshalb
## dort die Stufenanforderung des Teils.
enum Mode { WERKSTATT, WIRTSCHAFT, WAFFEN }

const PANEL_W: float = 470.0
const ROW_H: float = 52.0

## „Mach zu." — vom ✕ oben rechts.
##
## Es gab schon zwei Wege hinaus: `[Esc]` und ein Tipp neben die Liste. Beide sind auf einem
## Telefon unbrauchbar, der erste offensichtlich und der zweite auf den zweiten Blick: Die Liste
## ist 470 Punkte breit, die Abdunklung liegt darueber, und „daneben" ist auf einem schmalen
## Bildschirm ein Streifen von wenigen Millimetern am Rand. Wer ihn nicht trifft, sitzt fest.
signal zu_machen

var mode: int = Mode.WERKSTATT

var _list: VBoxContainer
var _title: Label
var _purse: Label
var _hint: Label


func _ready() -> void:
	# `..._and_offsets_...`: Die kurze Variante setzt nur die Anker und laesst die Raender bei 0.
	# Unter einem `CanvasLayer` bleibt der Bildschirm dadurch 0x0 gross — die Abdunklung ist dann
	# unsichtbar und alles mittig Verankerte zentriert auf den Nullpunkt statt auf das Bild.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.03, 0.04, 0.88)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	box.position = Vector2(-PANEL_W * 0.5, 54.0)
	box.custom_minimum_size = Vector2(PANEL_W, 0.0)
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 22)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	_purse = Label.new()
	_purse.add_theme_font_size_override("font_size", 16)
	_purse.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_purse)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 5)
	box.add_child(_list)
	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.text = "✕ oben rechts, Tippen neben die Liste oder [Esc] schließt"
	box.add_child(_hint)
	# Der ✕ sitzt am BILDSCHIRMRAND, nicht an der Liste: Er soll immer an derselben Stelle sein,
	# auch wenn die Liste je nach Laden drei oder acht Zeilen hat. Ein Schliessknopf, der wandert,
	# muss gesucht werden.
	var zu := Button.new()
	zu.text = "✕"
	zu.focus_mode = Control.FOCUS_NONE
	zu.add_theme_font_size_override("font_size", 24)
	zu.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	zu.offset_left = -74.0
	zu.offset_right = -18.0
	zu.offset_top = 14.0
	zu.offset_bottom = 62.0
	zu.pressed.connect(func() -> void: zu_machen.emit())
	add_child(zu)


func open(which: int) -> void:
	mode = which
	visible = true
	refresh()


func close() -> void:
	visible = false


## Liegt der Punkt auf der Liste selbst (statt daneben)?
##
## Braucht `OverworldView`, um zu unterscheiden: Ein Tipp DANEBEN schliesst den Laden, ein Tipp
## DARAUF muss unangetastet an die Knoepfe durchgereicht werden. Ohne die Unterscheidung wuerde
## entweder kein Kauf ankommen oder der Laden liesse sich nicht mehr schliessen.
func hits_panel(at: Vector2) -> bool:
	var top: float = 40.0
	var height: float = 150.0 + ROW_H * float(maxi(_list.get_child_count(), 1))
	return Rect2(Vector2(size.x * 0.5 - PANEL_W * 0.5 - 12.0, top),
		Vector2(PANEL_W + 24.0, height)).has_point(at)


## Zeilen der aktuellen Betriebsart:
## `[id, Bezeichnung, Beschreibung, Stufe, Höchststufe, Preis, kaufbar, Sperrgrund]`
func _rows() -> Array:
	var out: Array = []
	if mode == Mode.WERKSTATT:
		for id in WorkshopData.ORDER:
			var u: Dictionary = WorkshopData.UPGRADES[id]
			var lvl: int = WorkshopData.level(String(id))
			var maxed: bool = WorkshopData.is_maxed(String(id))
			var locked: bool = WorkshopData.is_locked(String(id))
			var price: int = WorkshopData.cost(String(id))
			var reason: String = ""
			if locked:
				reason = "⊘ erst nach dem Erwachen"
			elif maxed:
				reason = "ausgebaut"
			elif GameState.gold < price:
				reason = "zu teuer"
			out.append([String(id), "%s %s" % [String(u["icon"]), WorkshopData.label(String(id))],
				String(u["desc"]), lvl, WorkshopData.max_level(String(id)), price,
				not locked and not maxed and GameState.gold >= price, reason])
	elif mode == Mode.WAFFEN:
		var regal: Array = HaendlerData.bestand()
		for i in regal.size():
			var g: Dictionary = regal[i]
			var p: int = HaendlerData.preis(g)
			var noetig: int = EquipManager.stufe_fuer(g)
			var weg: bool = HaendlerData.verkauft(i)
			var farbe: String = String(ProgressionManager.RARITY[String(g["rarity"])]["name"])
			var desc: String = "%s · +%d %s" % [farbe, int(g["stat"]["val"]),
				String(g["stat"]["key"])]
			# Sie verkauft auch, was man noch nicht tragen darf — ein Regal, in dem nur steht,
			# was man ohnehin anlegen kann, gibt einem nichts zum Hinarbeiten. Die Zeile sagt
			# es dazu; gekauft werden darf es trotzdem, es wartet dann im Beutel.
			if not EquipManager.darf_tragen(g):
				desc += "   ⊘ tragbar ab Stufe %d" % noetig
			var grund: String = ""
			if weg:
				grund = "verkauft"
			elif GameState.gold < p:
				grund = "zu teuer"
			elif not BagManager.has_room_for(g):
				grund = "Beutel voll"
			out.append([str(i), "⚔ " + String(g["name"]), desc, noetig, 0, p,
				not weg and GameState.gold >= p and BagManager.has_room_for(g), grund])
	else:
		for id in TycoonManager.BUILDINGS.keys():
			var b: Dictionary = TycoonManager.BUILDINGS[id]
			var lvl: int = GameState.building_level(String(id))
			var maxed: bool = TycoonManager.is_maxed(String(id))
			var price: int = TycoonManager.upgrade_cost(String(id))
			var per: int = int(b["income_per"])
			var desc: String = ("+%d ¤/s je Stufe" % per) if per > 0 else "kein Einkommen, aber Rabatte"
			var reason: String = ""
			if maxed:
				reason = "ausgebaut"
			elif GameState.gold < price:
				reason = "zu teuer"
			out.append([String(id), "⌂ " + String(b["name"]), desc, lvl, int(b["max"]), price,
				not maxed and GameState.gold >= price, reason])
	return out


func _buy(id: String) -> bool:
	if mode == Mode.WERKSTATT:
		return WorkshopData.buy(id)
	if mode == Mode.WAFFEN:
		return HaendlerData.kaufen(int(id))
	return TycoonManager.try_upgrade(id)


## Baut die Liste neu auf. Nach jedem Kauf noetig, weil sich Gold, Stufe UND Preis der naechsten
## Stufe gleichzeitig aendern — und mit ihnen, was man sich sonst noch leisten kann.
func refresh() -> void:
	if _list == null:
		return
	# Erst aus dem Baum nehmen, dann freigeben: `queue_free` wirkt erst am Frame-Ende, die alten
	# Zeilen stuenden sonst noch unter den neuen (derselbe Fehler wie in der Aktionsleiste).
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	if mode == Mode.WERKSTATT:
		_title.text = "⚒ Werkstatt — Silas Kupferauge"
		_purse.text = "¤ %d Gold" % GameState.gold
	elif mode == Mode.WAFFEN:
		_title.text = "⚔ Waffenlager — Wanda Kessler"
		# Der Hinweis auf den Wechsel gehoert hierher und nicht in eine Zeile darunter: Wer
		# nichts findet, was ihm passt, soll wissen, dass Wiederkommen etwas bringt.
		_purse.text = "¤ %d Gold      Neue Ware jeden Morgen" % GameState.gold
	else:
		_title.text = "¤ Geschäfte — Mamma Mabel"
		_purse.text = "¤ %d Gold      Einkommen: %d ¤/s" % [GameState.gold, TycoonManager.income_per_sec()]
	for r in _rows():
		_list.add_child(_make_row(r))


func _make_row(r: Array) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(PANEL_W, ROW_H)
	row.add_theme_constant_override("separation", 10)
	var text := Label.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_font_size_override("font_size", 15)
	# Bei gesperrten Koerper-Eingriffen steht als Bezeichnung nur „—" in der Tabelle: Vor dem
	# Reveal soll der Held gar nicht wissen, dass es diese Teile gibt.
	var name: String = String(r[1])
	if String(r[7]).begins_with("⊘"):
		name = "⊘ ???"
	text.text = "%s\n   %s · Stufe %d/%d" % [name, String(r[2]), int(r[3]), int(r[4])]
	row.add_child(text)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(150.0, 40.0)   # Daumengroesse
	btn.add_theme_font_size_override("font_size", 15)
	if String(r[7]) != "":
		btn.text = String(r[7]) if String(r[7]) != "zu teuer" else "¤ %d" % int(r[5])
		btn.disabled = true
	else:
		btn.text = "Ausbauen  ¤ %d" % int(r[5])
		btn.pressed.connect(_on_buy.bind(String(r[0])))
	row.add_child(btn)
	return row


func _on_buy(id: String) -> void:
	if _buy(id):
		refresh()
