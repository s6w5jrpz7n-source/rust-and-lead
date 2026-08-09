class_name CharacterScreen extends Control
## Charakter-Bildschirm — Ausrüstung, Beutel und Fähigkeiten (GDD §7.4/§7.5.1).
##
## Zwei Reiter, weil beides dieselbe Frage beantwortet („was habe ich aus dem Gespielten
## gemacht?") und beides vorher **unsichtbar** war:
##
## * **Ausrüstung:** Truhen legten bisher automatisch an, was besser war. Man sah nie, was man
##   trug, konnte nie tauschen und nie vergleichen — Beute war etwas, das einem passierte.
## * **Fähigkeiten:** `perk_points` stiegen bei jedem Aufstieg und ließen sich nirgends
##   ausgeben. Der ganze Perk-Baum aus `ProgressionManager` war tote Rechenleistung.
##
## Der Bildschirm rechnet nichts selbst. Ausrüstung läuft über `EquipManager`/`BagManager`,
## Fähigkeiten über `ProgressionManager` — hier steht nur, wie es aussieht und was ein Tipp
## auslöst.

enum Tab { AUSRUESTUNG, FAEHIGKEITEN }

const PaperDoll = preload("res://scripts/PaperDoll.gd")

## Zweispaltig, seit der Beutel ein Raster ist: links die getragene Ausrüstung als Puppe, rechts
## das Raster. Bei 1280×720 Bezugsauflösung passen 1080 px Tafelbreite bequem.
const PANEL_W: float = 1080.0
const LEFT_W: float = 430.0     # Spalte „Getragen" + Werteblatt
const GRID_W: float = 250.0
const PAD: float = 14.0     # 5 Spalten x 44 px + Fugen

## „Mach zu." — vom ✕ oben rechts in der Tafel.
##
## Hinaus kam man bisher mit `[C]`, `[Esc]` oder einem Tipp NEBEN die Tafel. Auf einem Telefon
## gibt es die ersten beiden nicht, und der dritte ist ein Rand von wenigen Millimetern: Die
## Tafel ist 1080 von 1280 Punkten breit. Wer im Rucksack sitzt und diesen Streifen nicht
## trifft, kommt nicht mehr heraus — dieselbe Sorte Sackgasse wie der Ausgang des Stollens.
signal zu_machen

var tab: int = Tab.AUSRUESTUNG

var _head: Label
var _tabs: HBoxContainer
var _list: VBoxContainer
var _scroll: ScrollContainer
var _cols: Control                # Sammelknoten der rechten Spalte (Raster + Aktionen)
var _panel: Panel
var _grid: InventoryGrid
var _grid_head: Label
var _detail: Label
var _act_equip: Button
var _act_scrap: Button
var _stats: Label
var _doll: PaperDoll
## Gewählte Fassung an der Puppe ("" = keine). Die Auswahl liegt HIER und nicht nur in der
## Puppe, weil sie einen `refresh()` überleben muss: Nach dem Anlegen wird die linke Spalte neu
## befüllt, und der Spieler soll danach immer noch sehen, worüber er gerade entscheidet.
var _sel_slot: String = ""


## Feste Tafel statt verschachtelter Container.
##
## Der erste Anlauf setzte zwei Spalten in eine HBox in eine VBox mit Anker und Versatz. Das
## Ergebnis war unbrauchbar: keine Abdunklung, die linke Spalte 60 px breit statt 430, die
## Kopfzeile mitten im HUD. Container verhandeln ihre Größen untereinander, und wer dabei
## `position` und `custom_minimum_size` von außen hineinreicht, kämpft gegen die Verhandlung
## statt sie zu nutzen.
##
## Jetzt: eine `Panel` mit festen Rändern, mittig verankert, darin alles an festen Positionen.
## Bei fester Bezugsauflösung (1280×720, siehe `project.godot`) ist das nicht nur einfacher,
## sondern auch genauer — die Tafel sitzt auf jedem Gerät gleich.
const PANEL_H: float = 646.0

func _ready() -> void:
	# `set_anchors_AND_OFFSETS_preset`, nicht `set_anchors_preset`.
	#
	# Die kurze Variante setzt nur die ANKER und lässt die Ränder stehen. Bei einem Control
	# direkt unter einem `CanvasLayer` sind die beim Erzeugen alle 0 — und 0 Ränder auf einem
	# Anker von (0,0,1,1) ergeben rechnerisch Vollbild, praktisch aber blieb dieser Bildschirm
	# 0×0 groß. Die Folge war grotesk und schwer zuzuordnen: Die Abdunklung war unsichtbar (0×0),
	# und die mittig verankerte Tafel zentrierte auf den Nullpunkt, ragte also zu drei Vierteln
	# aus dem Bild. Die lange Variante setzt beides und ist hier die einzige richtige.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.03, 0.04, 0.90)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	# Die Tafel: mittig, feste Größe. RÄNDER statt `position`, weil Ränder immer relativ zum
	# Anker sind — `position` zählt nach `add_child` absolut (dieselbe Falle wie beim
	# Schuss-Knopf, die dort einen Knopf auf (−146, −146) gesetzt hat).
	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -PANEL_W * 0.5
	_panel.offset_right = PANEL_W * 0.5
	_panel.offset_top = -PANEL_H * 0.5
	_panel.offset_bottom = PANEL_H * 0.5
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	_head = Label.new()
	_head.add_theme_font_size_override("font_size", 17)
	_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_head.position = Vector2(0.0, 10.0)
	_head.custom_minimum_size = Vector2(PANEL_W, 0.0)
	_panel.add_child(_head)
	_tabs = HBoxContainer.new()
	_tabs.position = Vector2(PAD, 38.0)
	_tabs.add_theme_constant_override("separation", 8)
	_panel.add_child(_tabs)
	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(PAD, 88.0)
	_scroll.size = Vector2(LEFT_W, PANEL_H - 128.0)
	_scroll.custom_minimum_size = _scroll.size
	_panel.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.custom_minimum_size = Vector2(LEFT_W - 18.0, 0.0)
	_list.add_theme_constant_override("separation", 4)
	_scroll.add_child(_list)
	# Die Puppe wird EINMAL gebaut und danach nur noch ein- und ausgehängt. `refresh()` leert
	# die linke Spalte bei jeder Änderung; wäre sie ein normales Kind, entstünde sie bei jedem
	# Anlegen neu und verlöre dabei ihre Auswahl.
	_doll = PaperDoll.new()
	_doll.picked.connect(_on_doll_picked)
	_build_grid_column()
	var hint := Label.new()
	hint.add_theme_font_size_override("font_size", 13)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0.0, PANEL_H - 24.0)
	hint.custom_minimum_size = Vector2(PANEL_W, 0.0)
	hint.text = "Fassung an der Puppe oder Teil im Raster antippen → Anlegen / Ablegen · ✕ oder [C]/[Esc] schließt"
	_panel.add_child(hint)
	# Der Schliessknopf sitzt IN der Tafel, oben rechts — dort, wo ihn jeder sucht, und innerhalb
	# von `hits_panel()`, damit der Tipp an ihn durchgereicht wird statt als „daneben" zu gelten.
	var zu := Button.new()
	zu.text = "✕"
	zu.focus_mode = Control.FOCUS_NONE
	zu.add_theme_font_size_override("font_size", 22)
	zu.position = Vector2(PANEL_W - 60.0, 8.0)
	zu.size = Vector2(48.0, 40.0)
	zu.custom_minimum_size = zu.size
	zu.pressed.connect(func() -> void: zu_machen.emit())
	_panel.add_child(zu)


## Rechte Spalte: Kopfzeile, Raster, Beschreibung des gewählten Teils, zwei Aktionen.
##
## Einmal gebaut und danach nur befüllt. Der Beutel wird bei jeder Aufnahme neu gezeichnet;
## fünfzig Steuerelemente je Öffnen neu zu erzeugen wäre ein Ruckler ohne Gegenwert.
func _build_grid_column() -> void:
	var x: float = PAD + LEFT_W + 22.0
	_cols = Control.new()      # Sammelknoten: einmal verstecken statt fuenfmal
	_cols.position = Vector2(x, 88.0)
	_cols.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_cols)
	_grid_head = Label.new()
	_grid_head.add_theme_font_size_override("font_size", 14)
	_grid_head.add_theme_color_override("font_color", Color(0.72, 0.66, 0.50))
	_grid_head.position = Vector2(0.0, -22.0)
	_grid_head.custom_minimum_size = Vector2(GRID_W + 200.0, 0.0)
	_cols.add_child(_grid_head)
	_grid = InventoryGrid.new()
	_grid.custom_minimum_size = InventoryGrid.grid_size()
	_grid.size = InventoryGrid.grid_size()
	_grid.picked.connect(_on_grid_picked)
	_cols.add_child(_grid)
	# Beschreibung UNTER dem Raster, nicht als Sprechblase am Finger: Auf dem Handy verdeckt
	# die Hand genau die Stelle, an der eine Sprechblase erscheinen würde.
	# Beschreibung RECHTS neben dem Raster, nicht darunter: Unter 12 Zeilen ist kein Platz mehr,
	# und auf dem Handy verdeckt die Hand genau die Stelle unter dem Finger.
	_detail = Label.new()
	_detail.add_theme_font_size_override("font_size", 13)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.position = Vector2(GRID_W + 18.0, 0.0)
	_detail.custom_minimum_size = Vector2(300.0, 150.0)
	_detail.size = Vector2(300.0, 150.0)
	_cols.add_child(_detail)
	_act_equip = Button.new()
	_act_equip.text = "Anlegen"
	_act_equip.position = Vector2(GRID_W + 18.0, 170.0)
	_act_equip.custom_minimum_size = Vector2(300.0, 46.0)
	_act_equip.add_theme_font_size_override("font_size", 15)
	_act_equip.pressed.connect(_equip_selected)
	_cols.add_child(_act_equip)
	_act_scrap = Button.new()
	_act_scrap.text = "▬ Verschrotten"
	_act_scrap.position = Vector2(GRID_W + 18.0, 224.0)
	_act_scrap.custom_minimum_size = Vector2(300.0, 46.0)
	_act_scrap.add_theme_font_size_override("font_size", 15)
	_act_scrap.pressed.connect(_scrap_selected)
	_cols.add_child(_act_scrap)
	_stats = Label.new()
	_stats.add_theme_font_size_override("font_size", 13)
	_stats.add_theme_color_override("font_color", Color(0.86, 0.84, 0.78))
	_stats.position = Vector2(GRID_W + 18.0, 292.0)
	_stats.custom_minimum_size = Vector2(300.0, 200.0)
	_cols.add_child(_stats)


## Beutel und Puppe sind EINE Auswahl, nicht zwei. Wer im Raster tippt, hebt die Fassung auf und
## umgekehrt — zwei gleichzeitig hervorgehobene Teile und ein Knopf „Anlegen" dazwischen wären
## nicht zu beantworten.
func _on_grid_picked(_index: int) -> void:
	_sel_slot = ""
	if _doll != null:
		_doll.selected = ""
		_doll.refresh()
	_refresh_selection()


func _on_doll_picked(slot: String) -> void:
	_sel_slot = slot
	if _grid != null:
		_grid.selected = -1
		_grid.refresh()
	_refresh_selection()


## Beschreibung und Knöpfe an die Auswahl anpassen. Knöpfe ohne Auswahl werden GESPERRT, nicht
## versteckt: Ein Knopf, der erscheint und verschwindet, verschiebt das Bild bei jedem Tipp.
func _refresh_selection() -> void:
	if _grid == null:
		return
	# Fall 1: eine Fassung an der Puppe. Dann heißt der erste Knopf „Ablegen", nicht „Anlegen".
	if _sel_slot != "":
		var worn: Dictionary = EquipManager.equipped(_sel_slot)
		var cat: String = String(ProgressionManager.GEAR_SLOTS[
			EquipManager.slot_type(_sel_slot)]["name"])
		if worn.is_empty():
			_detail.text = "%s — leer.\nLege hier ein Teil aus dem Beutel hinein." % cat
			_detail.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
			_act_equip.text = "Anlegen"
			_act_equip.disabled = true
			_act_scrap.disabled = true
			return
		_detail.text = "%s\n%s" % [cat, _describe(worn)]
		_detail.add_theme_color_override("font_color", _rarity_color(worn))
		_act_equip.text = "Ablegen"
		_act_equip.disabled = false
		_act_scrap.disabled = false
		return
	# Fall 2: ein Teil im Beutel.
	_act_equip.text = "Anlegen"
	var i: int = _grid.selected
	if i < 0 or i >= GameState.bag.size():
		_detail.text = "Nichts gewählt — tippe ein Teil im Raster oder eine Fassung an der Puppe an."
		_detail.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
		_act_equip.disabled = true
		_act_scrap.disabled = true
		return
	var g: Dictionary = GameState.bag[i]
	var f: Vector2i = BagManager.footprint(g)
	var slot: String = String(g.get("slot", ""))
	var getragen: Dictionary = EquipManager.equipped(slot)
	var text: String = "%s\n%s · %d×%d Plätze" % [_describe(g),
		String(ProgressionManager.GEAR_SLOTS[slot]["name"]), f.x, f.y]
	# Vergleich mit dem, was gerade an derselben Stelle sitzt — das ist die Frage, die man beim
	# Anlegen wirklich hat. Ohne sie muss man sich den alten Wert merken.
	if not getragen.is_empty():
		var alt: int = int(getragen["stat"]["val"])
		var neu: int = int(g["stat"]["val"])
		var pfeil: String = "▲" if neu > alt else ("▼" if neu < alt else "=")
		text += "\nGetragen: %d %s   %s" % [alt, String(getragen["stat"]["key"]), pfeil]
	_detail.text = text
	_detail.add_theme_color_override("font_color", _rarity_color(g))
	_act_equip.disabled = false
	_act_scrap.disabled = false


## Der erste Knopf tut zweierlei, je nachdem, was gewählt ist: Ein Teil im Beutel wird ANGELEGT,
## eine Fassung an der Puppe wird ABGELEGT. Zwei Knöpfe wären ehrlicher, aber einer von beiden
## wäre immer gesperrt — und der Knopf beschriftet sich ohnehin selbst.
func _equip_selected() -> void:
	if _sel_slot != "":
		if BagManager.unequip_to_bag(_sel_slot):
			refresh()
		return
	var i: int = _grid.selected
	if i >= 0 and BagManager.equip_from_bag(i):
		_grid.selected = -1
		refresh()


func _scrap_selected() -> void:
	# Getragenes wird erst in den Beutel gelegt und dann verschrottet. Direkt vom Körper zu
	# verschrotten spart einen Tipp und kostet die Rückholmöglichkeit — bei einem Fehlgriff auf
	# ein legendäres Teil ist das ein sehr teurer Tipp.
	if _sel_slot != "":
		if BagManager.unequip_to_bag(_sel_slot):
			_sel_slot = ""
			refresh()
		return
	var i: int = _grid.selected
	if i < 0:
		return
	BagManager.scrap_at(i)
	_grid.selected = -1
	refresh()


## Tipp aus `OverworldView` weiterreichen. `true`, wenn Puppe oder Raster ihn verbraucht haben —
## dann darf der Bildschirm nicht schliessen.
##
## Puppe ZUERST: Sie liegt links, das Raster rechts, die beiden überlappen sich nicht — die
## Reihenfolge entscheidet also nichts außer bei einem Tipp genau dazwischen, und dort ist die
## Puppe die größere Fläche.
func tap_panel(at: Vector2) -> bool:
	if not visible or tab != Tab.AUSRUESTUNG:
		return false
	if _doll != null and _doll.is_inside_tree() and _doll.tap(at):
		return true
	return _grid != null and _grid.tap(at)


func open(which: int = Tab.AUSRUESTUNG) -> void:
	tab = which
	visible = true
	refresh()


func close() -> void:
	visible = false


## Liegt der Punkt auf der Tafel? Ein Tipp DARAUF muss an die Knöpfe durchgereicht werden,
## ein Tipp DANEBEN schließt (dieselbe Trennung wie beim Laden).
func hits_panel(at: Vector2) -> bool:
	# Gegen die ECHTE Lage der Tafel gerechnet, nicht gegen nachgebaute Zahlen: Der Vorgaenger
	# rechnete mit festen 660 px Hoehe und lag nach jeder Aenderung der Tafel daneben.
	return _panel != null and Rect2(_panel.global_position, _panel.size).grow(10.0).has_point(at)


func refresh() -> void:
	if _list == null:
		return
	for c in _tabs.get_children():
		_tabs.remove_child(c)
		c.queue_free()
	for c in _list.get_children():
		_list.remove_child(c)
		if c == _doll:
			continue     # die Puppe überlebt, siehe `_ready`
		c.queue_free()
	_head.text = "★ Stufe %d   ¤ %d   %s %d/%d   %s %d/%d" % [
		GameState.level, GameState.gold,
		String(AmmoData.POOLS["muni"]["icon"]), AmmoData.amount("muni"), AmmoData.cap("muni"),
		String(AmmoData.POOLS["kristall"]["icon"]), AmmoData.amount("kristall"), AmmoData.cap("kristall")]
	_add_tab("▣ Ausrüstung", Tab.AUSRUESTUNG)
	_add_tab("✴ Fähigkeiten (%d)" % GameState.perk_points, Tab.FAEHIGKEITEN)
	# Die rechte Spalte gehört zur Ausrüstung. Im Fähigkeiten-Reiter wird sie versteckt und die
	# linke bekommt die ganze Breite — ein leeres Raster neben dem Perk-Baum wäre nur Ballast.
	var zeige_raster: bool = (tab == Tab.AUSRUESTUNG)
	if _cols != null:
		_cols.visible = zeige_raster
	# Die linke Spalte wird im Faehigkeiten-Reiter breit: dort gibt es keine rechte Spalte, und
	# zwoelf Perks mit Beschreibung brauchen den Platz.
	var breite: float = LEFT_W if zeige_raster else PANEL_W - PAD * 2.0
	_scroll.size = Vector2(breite, PANEL_H - 128.0)
	_scroll.custom_minimum_size = _scroll.size
	_list.custom_minimum_size = Vector2(breite - 18.0, 0.0)
	if zeige_raster:
		_grid.refresh()
		_grid_head.text = "▤ Beutel — %d/%d Zellen" % [
			BagManager.used_cells(), BagManager.total_cells()]
		_refresh_selection()
		_build_gear()
	else:
		_build_perks()


func _add_tab(text: String, which: int) -> void:
	var b := Button.new()
	b.text = text
	# Feste Breite, nicht halbe Tafel: Bei 1080 px Tafelbreite wären zwei Reiter 534 px breit und
	# stünden am Bildrand auseinander wie zwei Plakate. Reiter gehören zusammen, links oben.
	b.custom_minimum_size = Vector2(240.0, 40.0)
	b.add_theme_font_size_override("font_size", 15)
	b.disabled = (tab == which)
	b.pressed.connect(func() -> void:
		tab = which
		refresh())
	_tabs.add_child(b)


# ── Reiter „Ausrüstung" ───────────────────────────────────────────────────────

func _build_gear() -> void:
	_caption("Getragen — Fassung antippen")
	# Die Puppe ersetzt die frühere Textliste („Helm — leer", „Rüstung — …"). Dieselbe
	# Information, andere Frage: Die Liste beantwortet „was trage ich?", die Puppe „wo ist noch
	# eine Lücke?" — und das ist die Frage, mit der man den Bildschirm aufmacht.
	_doll.selected = _sel_slot
	_list.add_child(_doll)
	_doll.refresh()
	# Das Werte-Blatt steht RECHTS, unter den Knöpfen — nicht mehr unter der Puppe.
	# Puppe (436 px) plus sieben Zeilen ergaben 580 px in einer 518 px hohen Spalte: Man musste
	# scrollen, um zu sehen, ob ein Fund überhaupt etwas bewirkt hat. Rechts unter den Aktionen
	# lag ohnehin leerer Platz, und dort steht es genau da, wo man gerade hinschaut, wenn man
	# „Anlegen" erwägt.
	_stats.text = _stat_sheet()
	# Der Beutel steht rechts im Raster. Ihn hier NOCHMAL als Liste zu führen war der erste
	# Reflex und wäre falsch: zwei Darstellungen desselben Zustands, die man beide aktuell
	# halten muss, und der Spieler weiß nicht, welche gilt.


## Was die Ausrüstung tatsächlich bewirkt — die einzige Stelle, an der ein Fund messbar wird.
func _stat_sheet() -> String:
	var zeilen: Array = [
		["❤ Leben", "%d" % PlayerStats.max_hp()],
		["⚔ Schaden/Schuss", "%d" % PlayerStats.damage_per_bullet("karabiner")],
		["⚡ Feuerrate", "%d ms" % PlayerStats.fire_ms("karabiner")],
		["∗ Krit", "%.0f %% x%.1f" % [PlayerStats.crit_chance() * 100.0, PlayerStats.crit_mult()]],
		["♜ Rüstung", "%d" % PlayerStats.player_armor()],
		["» Tempo", "%.0f" % PlayerStats.move_speed()],
		["Ω Magnet", "%d" % PlayerStats.magnet_dist()],
	]
	var out: Array = ["Wirksame Werte"]
	for r in zeilen:
		out.append("%s: %s" % [String(r[0]), String(r[1])])
	return "\n".join(out)


func _describe(g: Dictionary) -> String:
	var out: String = "%s  (+%d %s)" % [String(g["name"]), int(g["stat"]["val"]),
		ProgressionManager.wert_name(String(g["stat"]["key"]))]
	# Die Stufenanforderung — und zwar NUR, wenn sie eine ist.
	#
	# Bei jedem gewoehnlichen Teil steht dort 1, und "ab Stufe 1" auf der Haelfte aller Zeilen
	# ist Rauschen, das man nach dem dritten Mal nicht mehr liest. Sichtbar wird sie erst, wo
	# sie etwas bedeutet: bei allem oberhalb der eigenen Stufe steht sie als Sperre da, sonst
	# als blosse Angabe.
	var noetig: int = EquipManager.stufe_fuer(g)
	if not EquipManager.darf_tragen(g):
		out += "   ⊘ ab Stufe %d" % noetig
	elif noetig > 1:
		out += "   ab Stufe %d" % noetig
	var extra: Array = g.get("affixes", [])
	if not extra.is_empty():
		var parts: Array = []
		for a in extra:
			parts.append("+%d %s" % [int(a["val"]), ProgressionManager.wert_name(String(a["key"]))])
		out += "  " + ", ".join(parts)
	return out


func _rarity_color(g: Dictionary) -> Color:
	return ProgressionManager.RARITY_COLOR.get(String(g.get("rarity", "common")), Color.WHITE)


# ── Reiter „Fähigkeiten" ──────────────────────────────────────────────────────

func _build_perks() -> void:
	_caption("%d Punkt(e) frei — steigen mit jedem Aufstieg" % GameState.perk_points)
	for branch in ProgressionManager.PERK_BRANCHES:
		var bid: String = String(branch["id"])
		_caption("%s — %s  (%d investiert)" % [String(branch["name"]), String(branch["blurb"]),
			ProgressionManager.branch_points(bid)])
		for pid in ProgressionManager.PERKS:
			var p: Dictionary = ProgressionManager.PERKS[pid]
			if String(p["branch"]) != bid:
				continue
			var id: String = String(pid)
			var rank: int = ProgressionManager.perk_rank(id)
			var maxr: int = int(p["max"])
			var t: Dictionary = ProgressionManager.PERK_TIER[int(p["tier"])]
			var text: String = "%s   Rang %d/%d" % [String(p["name"]), rank, maxr]
			if int(p["per"]) > 0:
				text += "   (je +%d)" % int(p["per"])
			var col := Color(0.90, 0.88, 0.80)
			var action: Callable = Callable()
			var btn: String = ""
			if rank >= maxr:
				btn = "voll"
			elif not ProgressionManager.perk_tier_ok(id):
				# Warum es zu ist, gehoert daneben: „gesperrt" allein ist eine Sackgasse.
				btn = "Stufe %d · %d Pkt" % [int(t["lvl"]), int(t["inv"])]
				col = Color(0.52, 0.52, 0.52)
				text = "⊘ " + text
			elif ProgressionManager.xor_blocked(id):
				btn = "anderer Kapstein"
				col = Color(0.52, 0.52, 0.52)
			elif GameState.perk_points <= 0:
				btn = "kein Punkt"
			else:
				action = func() -> void:
					if ProgressionManager.buy_perk(id):
						refresh()
			_row(text, col, "Wählen" if action.is_valid() else btn, action)


# ── Bausteine ─────────────────────────────────────────────────────────────────

func _caption(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color(0.72, 0.66, 0.50))
	_list.add_child(l)


## Eine Zeile: Text links, bis zu zwei Knöpfe rechts. Ein leerer Knopftext ohne Aktion ergibt
## eine reine Anzeigezeile.
func _row(text: String, col: Color, btn_text: String, action: Callable,
		btn2_text: String = "", action2: Callable = Callable()) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var l := Label.new()
	l.text = text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", col)
	row.add_child(l)
	if btn_text != "":
		var b := Button.new()
		b.text = btn_text
		b.custom_minimum_size = Vector2(132.0, 38.0)
		b.add_theme_font_size_override("font_size", 14)
		if action.is_valid():
			b.pressed.connect(action)
		else:
			b.disabled = true
		row.add_child(b)
	if btn2_text != "":
		var b2 := Button.new()
		b2.text = btn2_text
		b2.tooltip_text = "Verschrotten"
		b2.custom_minimum_size = Vector2(46.0, 38.0)
		b2.pressed.connect(action2)
		row.add_child(b2)
	_list.add_child(row)
