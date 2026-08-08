class_name Minimap extends Control
## Karte des Kraters (Master-GDD §1.4/§1.6) — in zwei Betriebsarten aus einer Zeichenroutine.
##
## `full_world = false` — die kleine Karte oben rechts. Sie zeigt einen Ausschnitt von
## LOCAL_RADIUS_M um den Spieler. Der ganze Krater taugt dafür nicht: 5000 m auf 190 px sind
## 0,038 px pro Meter, die Figur rückt also erst nach 26 gelaufenen Metern um ein einziges
## Pixel weiter, Rustwater ist 4 px groß und sämtliche Gegner sitzen im selben Punkt. Als
## Nahansicht sind es 0,475 px/m — damit werden Straße, Gegner und Laufrichtung wirklich
## lesbar, und die Karte reagiert sichtbar auf jeden Schritt.
##
## `full_world = true` — die Vollbildkarte, die per Tippen auf die kleine Karte aufgeht. Erst
## dort ergibt der ganze Krater Sinn, weil er dann auch die Fläche dafür bekommt: Sektoren,
## Biome, Bahntrasse und alle Orte mit Namen.
##
## Beide benutzen DIESELBE Projektion, nur mit anderem Mittelpunkt und Maßstab. Deshalb ist es
## ein Skript und nicht zwei: eine Orientierungsregel, ein Satz Tests. Rein zeichnend (`_draw`),
## keine 3D-Abhängigkeit — die Daten kommen aus `WorldManager`, die Spielerposition von außen.

const MAP_PX: float = 190.0          # Kantenlänge der kleinen Karte
const LOCAL_RADIUS_M: float = 200.0  # Sichtweite der kleinen Karte: Mitte bis Kante
const DOT_POI: float = 3.0
const DOT_PLAYER: float = 4.5

var full_world: bool = false             # true = Vollbild-Weltkarte statt Nahansicht
var player_pos: Vector3 = Vector3.ZERO   # Szenenposition (Meter)
var player_dir: float = 0.0              # Blickrichtung (rad, wie Node3D.rotation.y)
var enemy_positions: Array = []          # Array[Vector3] — Szenenpositionen

var _sector_color: Dictionary = {
	1: Color(0.83, 0.63, 0.27), 2: Color(0.36, 0.56, 0.83), 3: Color(0.78, 0.30, 0.24) }
var _biome_tint: Dictionary = {
	"oasis": Color(0.31, 0.56, 0.31, 0.5), "salt": Color(0.85, 0.84, 0.78, 0.4),
	"rostwald": Color(0.54, 0.29, 0.18, 0.5), "kupfer_hochland": Color(0.61, 0.42, 0.24, 0.5) }


func _ready() -> void:
	if not full_world:
		custom_minimum_size = Vector2(MAP_PX, MAP_PX)
		size = Vector2(MAP_PX, MAP_PX)
	# Klicks fängt `OverworldView._input` ab, damit Karte und Joystick nicht beide auf denselben
	# Tipp reagieren (sonst öffnet sich die Karte UND die Figur läuft los).
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Die Nahansicht zeigt einen Ausschnitt: Biom-Scheiben und Trassen ragen zwangsläufig über
	# den Rahmen hinaus und müssen abgeschnitten werden.
	clip_contents = true


# ── Projektion ────────────────────────────────────────────────────────────────

## Kürzere Kante der Karte in Pixeln — der Maßstab hängt an ihr, damit ein nicht-quadratischer
## Rahmen die Karte nicht verzerrt.
func map_px() -> float:
	return minf(size.x, size.y)


## Mittelpunkt der Ansicht in Szenenmetern: die Weltmitte bzw. der Spieler.
func view_center() -> Vector3:
	if full_world:
		var h: float = WorldManager.WORLD_METERS * 0.5
		return Vector3(h, 0.0, -h)
	return Vector3(player_pos.x, 0.0, player_pos.z)


## Pixel pro Meter in der aktuellen Betriebsart.
func pixels_per_meter() -> float:
	if full_world:
		return map_px() / WorldManager.WORLD_METERS
	return map_px() / (LOCAL_RADIUS_M * 2.0)


## Szenenposition (Meter) → Pixel auf der Karte. X wächst nach Osten, −Z nach Norden.
##
## Zwei Vorzeichen treffen hier aufeinander und heben sich auf: Norden ist in der Szene −Z, in
## Godots Zeichenfläche wächst Y aber nach UNTEN. Norden oben heißt also NICHT „Z spiegeln"
## (das dreht die Karte auf den Kopf) — die Z-Differenz wandert unverändert in die Y-Achse.
func world_to_map(p: Vector3) -> Vector2:
	var c: Vector3 = view_center()
	return size * 0.5 + Vector2(p.x - c.x, p.z - c.z) * pixels_per_meter()


## Blickrichtung des Spielers als Richtungsvektor auf der Karte (Länge 1).
##
## Bewusst eine eigene Methode und nicht inline in `_draw`: So prüft die Test-Suite exakt die
## Rechnung, die auch gezeichnet wird. Der alte Fehler war nämlich, dass Karte UND Strich
## gemeinsam verdreht waren — untereinander stimmig, gegenüber der Welt beide falsch.
func facing_on_map() -> Vector2:
	# Node3D-Rotation um Y: die Blickrichtung ist (−sin, −cos) in der XZ-Ebene — gemessen, nicht
	# geraten (`rotation.y = atan2(-step.x, -step.z)` in OverworldView macht die Figur exakt zum
	# Laufvektor schauen). Umrechnung wie in `world_to_map`: Z wandert unverändert in Y.
	return Vector2(-sin(player_dir), -cos(player_dir))


# ── Zeichnen ──────────────────────────────────────────────────────────────────

func _draw() -> void:
	var k: float = pixels_per_meter()
	var m: float = WorldManager.METERS_PER_UNIT
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.10, 0.09, 0.08, 0.72))
	# Biom-Kreiszonen (dieselben Daten wie die 3D-Scheiben).
	for id in WorldManager.BIOME_ZONE_ORDER:
		var b: Dictionary = WorldManager.BIOMES[id]
		var at: Vector2 = world_to_map(
			WorldManager.world_to_scene(Vector2(float(b["cx"]), float(b["cy"]))))
		draw_circle(at, float(b["radius"]) * m * k, _biome_tint[id])
	# Smog-Senke: alles nördlich der Smog-Linie, also alles ÜBER ihr. Geklemmt statt abgefragt —
	# liegt die Linie außerhalb des Ausschnitts, wird von selbst nichts oder alles eingefärbt.
	var smog_y: float = world_to_map(Vector3(0.0, 0.0, -float(WorldManager.SMOG_LINE_Y) * m)).y
	var blast_y: float = world_to_map(Vector3(0.0, 0.0, -float(WorldManager.BORDER_S1_S2_Y) * m)).y
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, clampf(smog_y, 0.0, size.y))),
		Color(0.35, 0.72, 0.30, 0.30))
	# Strahlensumpf: eine Fläche, kein Strich. Er ist begehbar (und tödlich), keine Grenzlinie —
	# das muss die Karte zeigen, sonst hält man ihn für eine Wand und sucht einen Weg herum.
	# Seit er ein Rechteck ist statt eines Bandes über die ganze Breite, zeigt die Karte auch,
	# wo er AUFHÖRT — und das ist die eigentliche Information beim Blick auf die Karte.
	var sw: Rect2 = WorldManager.swamp_rect()
	var sw_a: Vector2 = world_to_map(Vector3(sw.position.x * m, 0.0, -sw.position.y * m))
	var sw_b: Vector2 = world_to_map(Vector3((sw.position.x + sw.size.x) * m, 0.0,
		-(sw.position.y + sw.size.y) * m))
	var sw_feld := Rect2(Vector2(minf(sw_a.x, sw_b.x), minf(sw_a.y, sw_b.y)),
		Vector2(absf(sw_b.x - sw_a.x), absf(sw_b.y - sw_a.y)))
	if sw_feld.intersects(rect):
		draw_rect(sw_feld.intersection(rect),
			Color(0.30, 0.78, 0.24, 0.34 if WorldManager.has_rad_suit() else 0.46))
	# Sektorgrenzen als Linien — nur, wenn sie im Ausschnitt liegen.
	if blast_y > 0.0 and blast_y < size.y:
		draw_line(Vector2(0.0, blast_y), Vector2(size.x, blast_y), Color(1.0, 0.55, 0.35, 0.85), 1.5)
	if smog_y > 0.0 and smog_y < size.y:
		draw_line(Vector2(0.0, smog_y), Vector2(size.x, smog_y), Color(0.6, 1.0, 0.5, 0.85), 1.5)
	# Die Karte zeigt nur noch die Trasse. Vorher lag darunter für jede Route eine blasse
	# Pisten-Linie — die gibt es in der Welt nicht mehr, und eine Straße auf der Karte, die
	# draußen nirgends liegt, ist schlimmer als gar keine: Man läuft hin und sucht sie.
	var road_w: float = 1.0 if full_world else 3.0
	# Iron-Rail-Trasse: die Reiseachse der Karte.
	for seg in WorldManager.rail_segments():
		draw_line(world_to_map(WorldManager.poi_scene_position(String(seg[0]))),
			world_to_map(WorldManager.poi_scene_position(String(seg[1]))),
			Color(0.90, 0.82, 0.55, 0.85), road_w * 2.0)
	_draw_fog(rect)
	_draw_pois(rect)
	# Gegner in der Umgebung. Auf der Nahansicht sind sie endlich mehr als ein gemeinsamer
	# Punkt — der Spawnradius von 45 m misst hier 21 px statt 1,7.
	for e in enemy_positions:
		draw_circle(world_to_map(e), 2.6 if full_world else 3.4, Color(0.95, 0.35, 0.30, 0.9))
	_draw_quest_marker(rect)
	_draw_player()
	# Rahmen zuletzt, damit nichts über ihn läuft.
	draw_rect(rect, Color(0.55, 0.44, 0.28, 0.9), false, 2.0)
	_draw_scale_hint()


## Der Nebel: alles Unerkundete wird zugedeckt.
##
## Gezeichnet wird der NEBEL, nicht das Erkundete — also die Gegenrichtung zum Speicher. Das
## klingt umständlich, ist aber der einzige Weg, der bei einem Wörterbuch besuchter Zellen
## funktioniert: Über den sichtbaren Kartenausschnitt laufen und jede Zelle zudecken, die nicht
## darin steht. Der Aufwand hängt damit an der Bildschirmgröße, nicht an der Weltgröße.
##
## Auf der Nahansicht (200 m Umkreis) ist eine 40-m-Zelle 38 px groß, auf der Weltkarte 1,5 px.
## Beides ist brauchbar: nah als grobe Kachel, weit als Körnung.
func _draw_fog(rect: Rect2) -> void:
	var m_pro_zelle: float = float(FogOfWar.CELL) * WorldManager.METERS_PER_UNIT
	var px: float = m_pro_zelle * pixels_per_meter()
	if px < 0.7:
		return   # feiner als ein Pixel — dann wäre es nur Rauschen
	var mitte: Vector3 = view_center()
	var halb_m: float = (size.x * 0.5) / maxf(pixels_per_meter(), 0.0001)
	var von: Vector2i = FogOfWar.cell_of(WorldManager.scene_to_world(
		mitte + Vector3(-halb_m, 0.0, halb_m)))
	var bis: Vector2i = FogOfWar.cell_of(WorldManager.scene_to_world(
		mitte + Vector3(halb_m, 0.0, -halb_m)))
	var nebel := Color(0.05, 0.05, 0.06, 0.88)
	for cy in range(von.y, bis.y + 1):
		for cx in range(von.x, bis.x + 1):
			if GameState.fog.has(cy * 10000 + cx):
				continue
			var ecke: Vector3 = WorldManager.world_to_scene(
				Vector2(float(cx) * float(FogOfWar.CELL), float(cy + 1) * float(FogOfWar.CELL)))
			var at: Vector2 = world_to_map(ecke)
			# Eine Zehntel-Zelle Überlappung: Sonst blitzen zwischen den Kacheln helle Fugen
			# durch, weil Kartenpixel und Zellengrenzen nie ganzzahlig zueinander passen.
			draw_rect(Rect2(at, Vector2(px, px) * 1.1), nebel)


## Orte. Was aus dem Ausschnitt fällt, wird auf der Nahansicht als blasse Marke an den Rand
## geklemmt: So bleibt die Richtung zum nächsten Ort ablesbar, ohne die Karte zuzukleistern.
func _draw_pois(rect: Rect2) -> void:
	var font: Font = get_theme_default_font()
	for id in WorldManager.POIS.keys():
		# Unentdeckte Orte gibt es auf der Karte NICHT. Sie blass zu zeichnen waere schlimmer
		# als sie wegzulassen: Ein grauer Punkt mit Namen ist verraten, ein grauer Punkt ohne
		# Namen ist eine Aufforderung, jeden davon abzulaufen.
		if not FogOfWar.poi_known(String(id)):
			continue
		var p: Dictionary = WorldManager.POIS[id]
		var sec: int = int(p["sector"])
		var col: Color = _sector_color[sec]
		if not WorldManager.can_enter_sector(sec):
			col = Color(col.r, col.g, col.b, 0.35)
		var at: Vector2 = world_to_map(WorldManager.poi_scene_position(id))
		if not rect.has_point(at):
			if not full_world:
				var edge := Vector2(clampf(at.x, 5.0, size.x - 5.0), clampf(at.y, 5.0, size.y - 5.0))
				draw_circle(edge, 2.2, Color(col.r, col.g, col.b, col.a * 0.6))
			continue
		var r: float = DOT_POI * (1.8 if id == "eisernes_herz" else 1.0)
		if not full_world:
			r *= 1.6   # in der Nahansicht ist Platz, und der Ort ist das Ziel
		draw_circle(at, r, col)
		draw_arc(at, r + 1.0, 0.0, TAU, 12, Color(0.0, 0.0, 0.0, 0.6), 1.0)
		# Bahnhöfe bekommen einen hellen Ring — man sieht auf einen Blick, wo man fahren kann.
		if WorldManager.has_station(String(id)):
			draw_arc(at, r + 3.0, 0.0, TAU, 16, Color(0.95, 0.86, 0.58, 0.9), 1.4)
		# Namen nur auf der Vollbildkarte: dort ist Platz dafür, und genau dafür macht man sie auf.
		if full_world and font != null:
			draw_string(font, at + Vector2(r + 5.0, 4.0), String(p["name"]),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.93, 0.88, 0.75, 0.92))


## Die Quest-Marke: wohin der verfolgte Auftrag zeigt.
##
## Eine Raute, kein Punkt — auf der Karte liegen schon Ortspunkte, Gegnerpunkte und der Spieler,
## alles rund. Eine andere FORM liest sich schneller als eine andere Farbe, und sie bleibt
## lesbar, wenn sie über einem Ortspunkt derselben Größe sitzt (was sie meistens tut).
##
## Fällt das Ziel aus dem Ausschnitt, wird die Marke an den Rand geklemmt und zeigt als DREIECK
## in die Richtung. Genau dafür ist sie da: Die Nahansicht reicht 200 m weit, das Ziel liegt
## fast immer weiter weg — ohne Randmarke wäre der Wegweiser auf der kleinen Karte nie zu sehen.
const QUEST_COLOR: Color = Color(1.0, 0.86, 0.28)
func _draw_quest_marker(rect: Rect2) -> void:
	var qid: String = QuestManager.tracked_quest()
	if qid == "":
		return
	var ziel: String = QuestManager.quest_target(qid)
	if ziel == "" or not WorldManager.has_poi(ziel):
		return
	var at: Vector2 = world_to_map(WorldManager.poi_scene_position(ziel))
	if rect.has_point(at):
		_draw_diamond(at, 6.0, QUEST_COLOR)
		draw_arc(at, 10.0, 0.0, TAU, 20, Color(QUEST_COLOR.r, QUEST_COLOR.g, QUEST_COLOR.b, 0.55), 1.4)
		return
	# Außerhalb: an den Rand klemmen und als Pfeil in die Richtung zeigen.
	var mitte: Vector2 = size * 0.5
	var richtung: Vector2 = (at - mitte).normalized()
	var rand := Vector2(clampf(at.x, 9.0, size.x - 9.0), clampf(at.y, 9.0, size.y - 9.0))
	_draw_arrow(rand, richtung, 7.0, QUEST_COLOR)


func _draw_diamond(at: Vector2, r: float, col: Color) -> void:
	var p := PackedVector2Array([at + Vector2(0.0, -r), at + Vector2(r, 0.0),
		at + Vector2(0.0, r), at + Vector2(-r, 0.0)])
	draw_colored_polygon(p, col)
	draw_polyline(PackedVector2Array([p[0], p[1], p[2], p[3], p[0]]), Color(0.1, 0.08, 0.05, 0.8), 1.2)


func _draw_arrow(at: Vector2, dir: Vector2, r: float, col: Color) -> void:
	var quer := Vector2(-dir.y, dir.x)
	draw_colored_polygon(PackedVector2Array([at + dir * r, at - dir * r * 0.6 + quer * r * 0.7,
		at - dir * r * 0.6 - quer * r * 0.7]), col)


func _draw_player() -> void:
	var me: Vector2 = world_to_map(player_pos)
	draw_circle(me, DOT_PLAYER, Color(0.30, 0.62, 1.0))
	draw_arc(me, DOT_PLAYER + 1.0, 0.0, TAU, 16, Color(1.0, 1.0, 1.0, 0.9), 1.2)
	draw_line(me, me + facing_on_map() * (DOT_PLAYER + 7.0), Color(1.0, 1.0, 1.0, 0.95), 1.6)


## Maßstab unten links. Auf der Nahansicht zusätzlich der Reichweitenkreis: Er läuft genau
## durch die Kantenmitten und macht damit sichtbar, was „200 m" auf dieser Karte heißt.
func _draw_scale_hint() -> void:
	if not full_world:
		draw_arc(size * 0.5, LOCAL_RADIUS_M * pixels_per_meter(), 0.0, TAU, 48,
			Color(0.85, 0.78, 0.60, 0.22), 1.0)
	var font: Font = get_theme_default_font()
	if font == null:
		return
	var text: String = "5 km" if full_world else "%d m" % int(LOCAL_RADIUS_M)
	draw_string(font, Vector2(6.0, size.y - 6.0), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.86, 0.80, 0.62, 0.75))
