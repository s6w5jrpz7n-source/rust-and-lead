class_name OverworldView extends Node3D
## OverworldView — begehbarer Kraterboden im Produktions-Maßstab (Master-GDD §1.4/§1.6).
##
## Erste sichtbare Szene des Godot-Ports (Xogot-/Editor-tauglich, nur Primitives — keine
## Assets, lädt sofort). Alles wird zur Laufzeit aus den kanonischen `WorldManager`-Daten
## generiert: 5000×5000-m-Boden, Biom-Zonen, Sektor-Linien (Sprengtore/Smog), Kraterrand
## mit Rand-Tunnel, alle POIs als Landmarken. Dazu ein steuerbarer Spieler (4,7 m/s,
## virtueller Joystick + Tastatur), ein Gegner-Rudel bei Rustwater und Auto-Feuer über
## die ECHTEN Systeme (PlayerStats → CombatEngine → CombatTarget → GameState-XP/Gold).

const AGGRO_M: float = 45.0          # Gegner erwachen in dieser Distanz
const SHOOT_RANGE_M: float = 32.0    # Auto-Ziel-Reichweite des Spielers
const CONTACT_RANGE_M: float = 2.2   # Nahkampf-Kontakt
const ENEMY_SPEED_MS: float = 3.4    # Rudel etwas langsamer als der Spieler (4,7)

var _player: Node3D
var _cam: Camera3D
var _hp: float = 100.0
var _fire_cd: float = 0.0
var _enemies: Array = []             # { node, target: CombatTarget, bar: MeshInstance3D }
var _hud: Label
var _toast: Label
var _toast_until: float = 0.0
var _touch_id: int = -1
var _touch_start: Vector2 = Vector2.ZERO
var _touch_vec: Vector2 = Vector2.ZERO


func _ready() -> void:
	_build_environment()
	_build_ground_and_biomes()
	_build_sector_lines_and_rim()
	_build_pois()
	_build_player()
	_build_hud()
	_spawn_pack()
	_hp = float(PlayerStats.max_hp())
	_say("🤠 Willkommen im Krater — 5000 m Kante zu Kante. Rustwater liegt hinter dir.", 5.0)


# ── Weltaufbau ────────────────────────────────────────────────────────────────

func _mat(color: Color, unshaded: bool = false, alpha: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color.r, color.g, color.b, alpha)
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _box(size: Vector3, pos: Vector3, color: Color, alpha: float = 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = _mat(color, false, alpha)
	mi.position = pos
	add_child(mi)
	return mi


func _build_environment() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, 35.0, 0.0)
	sun.light_energy = 1.15
	add_child(sun)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.55, 0.42)   # grüner Bronzehimmel (Story-Bibel)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.72, 0.62)
	env.ambient_light_energy = 0.8
	we.environment = env
	add_child(we)


func _build_ground_and_biomes() -> void:
	var half: float = WorldManager.WORLD_METERS / 2.0
	# Kraterboden: Wüsten-Sand über die volle Produktionsfläche.
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(WorldManager.WORLD_METERS, WorldManager.WORLD_METERS)
	ground.mesh = plane
	ground.material_override = _mat(Color(0.76, 0.64, 0.42))
	ground.position = Vector3(half, 0.0, -half)
	add_child(ground)
	# Benannte Biom-Kreiszonen (WorldManager.BIOMES) als getönte Scheiben.
	var tint: Dictionary = {
		"oasis": Color(0.31, 0.56, 0.31), "salt": Color(0.85, 0.84, 0.78),
		"rostwald": Color(0.54, 0.29, 0.18), "kupfer_hochland": Color(0.61, 0.42, 0.24),
	}
	for id in WorldManager.BIOME_ZONE_ORDER:
		var b: Dictionary = WorldManager.BIOMES[id]
		var disc := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		var r_m: float = float(b["radius"]) * WorldManager.METERS_PER_UNIT
		cyl.top_radius = r_m
		cyl.bottom_radius = r_m
		cyl.height = 0.3
		disc.mesh = cyl
		disc.material_override = _mat(tint[id])
		disc.position = WorldManager.world_to_scene(Vector2(float(b["cx"]), float(b["cy"]))) + Vector3(0.0, 0.15, 0.0)
		add_child(disc)
	# Smog-Senke: alles nördlich der Smog-Linie liegt unter giftgrünem Schleier.
	var smog_depth_m: float = (float(WorldManager.WORLD_SIZE) - float(WorldManager.SMOG_LINE_Y)) * WorldManager.METERS_PER_UNIT
	var smog_z: float = -(float(WorldManager.SMOG_LINE_Y) * WorldManager.METERS_PER_UNIT + smog_depth_m / 2.0)
	_box(Vector3(WorldManager.WORLD_METERS, 0.4, smog_depth_m), Vector3(half, 0.35, smog_z), Color(0.35, 0.65, 0.30), 0.35)


func _build_sector_lines_and_rim() -> void:
	var w: float = WorldManager.WORLD_METERS
	var half: float = w / 2.0
	var blast_z: float = -float(WorldManager.BORDER_S1_S2_Y) * WorldManager.METERS_PER_UNIT
	var smog_z: float = -float(WorldManager.SMOG_LINE_Y) * WorldManager.METERS_PER_UNIT
	# Gate 1 — Iron-Rail-Sprengtore (dunkle Stahlwand quer über den Krater).
	_box(Vector3(w, 22.0, 5.0), Vector3(half, 11.0, blast_z), Color(0.24, 0.16, 0.13))
	_label(Vector3(half, 30.0, blast_z), "⛔ IRON-RAIL-SPRENGTORE", Color(1.0, 0.55, 0.35), 160)
	# Gate 2 — Smog-Linie (durchscheinend, giftgrün).
	_box(Vector3(w, 28.0, 4.0), Vector3(half, 14.0, smog_z), Color(0.35, 0.75, 0.30), 0.45)
	_label(Vector3(half, 38.0, smog_z), "☣ SMOG-LINIE", Color(0.6, 1.0, 0.5), 160)
	# Kraterrand: 350 m Fels an allen vier Horizonten — die diegetische Außengrenze.
	var rock := Color(0.28, 0.22, 0.18)
	_box(Vector3(w + 300.0, 350.0, 150.0), Vector3(half, 175.0, 75.0), rock)            # Süd
	_box(Vector3(w + 300.0, 350.0, 150.0), Vector3(half, 175.0, -w - 75.0), rock)       # Nord
	_box(Vector3(150.0, 350.0, w + 300.0), Vector3(-75.0, 175.0, -half), rock)          # West
	_box(Vector3(150.0, 350.0, w + 300.0), Vector3(w + 75.0, 175.0, -half), rock)       # Ost
	# Rand-Tunnel (§1.7.4): das eine, verriegelte Tor durch die Nordwand.
	_box(Vector3(60.0, 80.0, 40.0), Vector3(half, 40.0, -w - 20.0), Color(0.08, 0.07, 0.06))
	_label(Vector3(half, 95.0, -w + 5.0), "🚪 RAND-TUNNEL (verriegelt)", Color(0.95, 0.85, 0.6), 140)


func _label(pos: Vector3, text: String, color: Color, size: int = 120) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.05
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.outline_size = int(size / 8.0)
	l.position = pos
	add_child(l)
	return l


func _build_pois() -> void:
	var sector_color: Dictionary = {
		1: Color(0.83, 0.63, 0.27), 2: Color(0.36, 0.56, 0.83), 3: Color(0.78, 0.30, 0.24) }
	for id in WorldManager.POIS.keys():
		var p: Dictionary = WorldManager.POIS[id]
		var pos: Vector3 = WorldManager.poi_scene_position(id)
		var col: Color = sector_color[int(p["sector"])]
		if id == "eisernes_herz":
			# Zentrale Landmarke: hoher, dunkler Turm — von überall am Horizont sichtbar.
			_box(Vector3(120.0, 420.0, 120.0), pos + Vector3(0.0, 210.0, 0.0), Color(0.15, 0.13, 0.14))
			_label(pos + Vector3(0.0, 460.0, 0.0), "🖤 " + String(p["name"]), Color(1.0, 0.45, 0.35), 260)
			continue
		var pillar := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 4.0
		cyl.bottom_radius = 6.0
		cyl.height = 36.0
		pillar.mesh = cyl
		pillar.material_override = _mat(col)
		pillar.position = pos + Vector3(0.0, 18.0, 0.0)
		add_child(pillar)
		_label(pos + Vector3(0.0, 46.0, 0.0), String(p["name"]), col.lightened(0.35), 150)


func _build_player() -> void:
	_player = Node3D.new()
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.5
	cap.height = 1.8
	body.mesh = cap
	body.material_override = _mat(Color(0.23, 0.51, 0.96))
	body.position = Vector3(0.0, 0.9, 0.0)
	_player.add_child(body)
	_player.position = WorldManager.poi_scene_position("rustwater")
	add_child(_player)
	_cam = Camera3D.new()
	_cam.position = Vector3(0.0, 46.0, 34.0)
	_cam.rotation_degrees = Vector3(-54.0, 0.0, 0.0)
	_cam.far = 8000.0   # Kraterrand & Herz bleiben am Horizont sichtbar (Landmark-Navigation)
	_player.add_child(_cam)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(14.0, 10.0)
	_hud.add_theme_font_size_override("font_size", 15)
	layer.add_child(_hud)
	_toast = Label.new()
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.position = Vector2(0.0, 64.0)
	_toast.add_theme_font_size_override("font_size", 16)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(_toast)


func _spawn_pack() -> void:
	# Grenzgänger-Rudel + ein Kessel-Kläffer südöstlich von Rustwater (echter Biom-Leitmix).
	var base: Vector3 = WorldManager.poi_scene_position("rustwater") + Vector3(40.0, 0.0, 55.0)
	for i in 4:
		var type_id: String = "klaeffer" if i == 3 else "outlaw"
		var target: CombatTarget = CombatTarget.from_type(type_id)
		var node := Node3D.new()
		var body := MeshInstance3D.new()
		if target.classification == CombatData.MECHANICAL:
			var bm := BoxMesh.new()                      # Kampf-Lesbarkeit: eckig = Maschine
			bm.size = Vector3(1.1, 1.4, 1.1)
			body.mesh = bm
			body.material_override = _mat(Color(0.49, 0.83, 0.99))
			body.position = Vector3(0.0, 0.7, 0.0)
		else:
			var cm := CapsuleMesh.new()                  # rund = organisch
			cm.radius = 0.45
			cm.height = 1.6
			body.mesh = cm
			body.material_override = _mat(Color(0.97, 0.44, 0.44))
			body.position = Vector3(0.0, 0.8, 0.0)
		node.add_child(body)
		var bar := MeshInstance3D.new()                  # simple Lebensleiste
		var bar_mesh := BoxMesh.new()
		bar_mesh.size = Vector3(1.4, 0.12, 0.12)
		bar.mesh = bar_mesh
		bar.material_override = _mat(Color(0.52, 0.80, 0.09), true)
		bar.position = Vector3(0.0, 2.1, 0.0)
		node.add_child(bar)
		node.position = base + Vector3(float(i) * 5.0 - 7.5, 0.0, float(i % 2) * 6.0)
		add_child(node)
		_enemies.append({ "node": node, "target": target, "bar": bar })


# ── Eingabe: virtueller Joystick (Touch) + Tastatur ───────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id == -1:
			_touch_id = event.index
			_touch_start = event.position
			_touch_vec = Vector2.ZERO
		elif not event.pressed and event.index == _touch_id:
			_touch_id = -1
			_touch_vec = Vector2.ZERO
	elif event is InputEventScreenDrag and event.index == _touch_id:
		var v: Vector2 = event.position - _touch_start
		_touch_vec = Vector2.ZERO if v.length() < 12.0 else (v / 100.0).limit_length(1.0)


func _move_vector() -> Vector2:
	var kb: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	return kb if kb.length() > 0.05 else _touch_vec


# ── Spielschleife ─────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	_process_movement(delta)
	_process_combat(delta)
	_process_enemies(delta)
	_process_hazards(delta)
	_update_hud()


func _process_movement(delta: float) -> void:
	var mv: Vector2 = _move_vector()
	if mv.length() < 0.05:
		return
	var step: Vector3 = Vector3(mv.x, 0.0, mv.y) * WorldManager.PLAYER_SPEED_MS * delta
	var next: Vector3 = _player.position + step
	# Weltgrenzen (Kraterrand).
	next.x = clampf(next.x, 2.0, WorldManager.WORLD_METERS - 2.0)
	next.z = clampf(next.z, -(WorldManager.WORLD_METERS - 2.0), -2.0)
	# Gate 1: Sprengtore blocken die Nord-Querung, bis Kapitel 5 (WorldManager entscheidet).
	var from_rel: Vector2 = WorldManager.scene_to_world(_player.position)
	var to_rel: Vector2 = WorldManager.scene_to_world(next)
	if not WorldManager.can_cross_blast_line(from_rel.y, to_rel.y):
		next.z = maxf(next.z, -(float(WorldManager.BORDER_S1_S2_Y) * WorldManager.METERS_PER_UNIT - 1.5))
		_say("⛔ Die Sprengtore sind zu. Erst der Panzerzug (Kapitel 4) bricht sie auf.", 2.5)
	_player.position = next
	if Vector2(step.x, step.z).length() > 0.001:
		_player.rotation.y = atan2(-step.x, -step.z)


func _nearest_enemy(max_dist: float) -> Dictionary:
	var best: Dictionary = {}
	var best_d: float = max_dist
	for e in _enemies:
		var d: float = _player.position.distance_to(e["node"].position)
		if d < best_d:
			best_d = d
			best = e
	return best


func _process_combat(delta: float) -> void:
	_fire_cd -= delta
	if _fire_cd > 0.0:
		return
	var e: Dictionary = _nearest_enemy(SHOOT_RANGE_M)
	if e.is_empty():
		return
	_fire_cd = float(PlayerStats.fire_ms("karabiner")) / 1000.0
	var target: CombatTarget = e["target"]
	var res: Dictionary = CombatEngine.resolve_hit(
		CombatData.KINETIC, target, PlayerStats.damage_per_bullet("karabiner"), 0, Time.get_ticks_msec())
	_spawn_tracer(e["node"].position)
	var frac: float = clampf(float(target.health) / float(target.max_health), 0.0, 1.0)
	(e["bar"] as MeshInstance3D).scale.x = maxf(frac, 0.02)
	if bool(res["killed"]):
		GameState.add_gold(target.gold)
		GameState.add_kill()
		GameState.add_xp(CombatData.xp_for_kill(target))
		_say("☠ %s erlegt — +%d Gold" % [CombatData.ENEMY_TYPES[target.type_id]["name"], target.gold], 2.0)
		(e["node"] as Node3D).queue_free()
		_enemies.erase(e)


func _spawn_tracer(to_pos: Vector3) -> void:
	var from_pos: Vector3 = _player.position + Vector3(0.0, 1.2, 0.0)
	var tracer := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.07, 0.07, from_pos.distance_to(to_pos))
	tracer.mesh = mesh
	tracer.material_override = _mat(Color(0.98, 0.75, 0.14), true)
	add_child(tracer)
	tracer.position = (from_pos + Vector3(to_pos.x, 1.0, to_pos.z)) / 2.0
	tracer.look_at(Vector3(to_pos.x, 1.0, to_pos.z))
	get_tree().create_timer(0.07).timeout.connect(tracer.queue_free)


func _process_enemies(delta: float) -> void:
	for e in _enemies:
		var node: Node3D = e["node"]
		var d: float = _player.position.distance_to(node.position)
		if d > AGGRO_M:
			continue
		if d > CONTACT_RANGE_M:
			var dir: Vector3 = (_player.position - node.position).normalized()
			node.position += dir * ENEMY_SPEED_MS * delta
		else:
			var target: CombatTarget = e["target"]
			_hp -= float(target.contact_dps) * delta * CombatEngine.player_damage_taken_mul(0)
			if _hp <= 0.0:
				_respawn()
				return


func _process_hazards(delta: float) -> void:
	# Smog-DOT (Gate 2): WorldManager rechnet, die Szene wendet nur an.
	var dot: int = WorldManager.smog_dot_damage(WorldManager.scene_to_world(_player.position), delta)
	if dot > 0:
		_hp -= float(dot)
		if _hp <= 0.0:
			_respawn()


func _respawn() -> void:
	_hp = float(PlayerStats.max_hp())
	_player.position = WorldManager.poi_scene_position("rustwater")
	_say("💀 Ausgeknockt — zurück in Rustwater.", 3.0)


func _say(text: String, secs: float) -> void:
	if _toast == null:
		return
	_toast.text = text
	_toast_until = Time.get_ticks_msec() / 1000.0 + secs


func _update_hud() -> void:
	var rel: Vector2 = WorldManager.scene_to_world(_player.position)
	var biome: Dictionary = WorldManager.biome(WorldManager.biome_at(rel))
	var poi_id: String = WorldManager.nearest_poi(rel)
	var poi_d: int = roundi(_player.position.distance_to(WorldManager.poi_scene_position(poi_id)))
	_hud.text = "❤ %d/%d   💰 %d   ⭐ Lv %d   Sektor %d · %s\n➡ %s (%d m)" % [
		maxi(0, roundi(_hp)), PlayerStats.max_hp(), GameState.gold, GameState.level,
		WorldManager.sector_of_pos(rel), String(biome["name"]),
		String(WorldManager.POIS[poi_id]["name"]), poi_d]
	if Time.get_ticks_msec() / 1000.0 > _toast_until:
		_toast.text = ""
