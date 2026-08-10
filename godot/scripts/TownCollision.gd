extends RefCounted
## Aus einer Stadt-Szene werden Sperrflächen: eine Liste gedrehter Rechtecke.
##
## Steht hier und nicht in `OverworldView`, weil zwei Stellen dieselbe Ableitung brauchen — das
## Spiel, um den Spieler aufzuhalten, und der Test, um zu prüfen, dass Rustwater begehbar
## BLEIBT, wenn jemand im Editor die Stadt umbaut. Zwei Nutzer, eine Wahrheit.
##
## ## Die Regel: jedes eingefügte Modell trägt sich SELBST ein
##
## Vorher galt ein Knoten mit `scene_file_path` als fertiges Teil und wurde als EIN Kasten über
## seinen ganzen Unterbaum vermessen; nur namenlose Ordnerknoten wurden durchlaufen. Das geht
## gut, solange niemand etwas an ein Modell dranhängt.
##
## Im Editor hängt man aber laufend etwas dran: Wer ein Palisadenstück dupliziert, während das
## erste ausgewählt ist, bekommt es als KIND des ersten. Vier Generationen tief ist das keine
## Seltenheit — und dann spannte dieser eine Kasten über die halbe Stadt. Genau daran war
## Rustwater dicht: Die äußerste Palisade war eine 90 × 60 m große unsichtbare Wand.
##
## Deshalb wird jetzt IMMER durchlaufen, und jeder Knoten misst nur seine eigenen Meshes — alles,
## was in einem eingehängten Modell steckt, gehört diesem Modell und wird dort gezählt.
##
## ## Warum Welt-Transform und nicht `rotation.y`
##
## Aus demselben Grund: Sobald etwas verschachtelt steht, ist die lokale Drehung nicht die
## Drehung, die man im Spiel sieht. Die Sperre wird deshalb aus der zusammengesetzten Transform
## abgeleitet, und ihr Mittelpunkt aus der MITTE der Modellhülle statt aus dem Knotenursprung —
## bei einem Modell, dessen Ursprung nicht in seiner Mitte sitzt, sind das zwei verschiedene
## Punkte.

## Mindesthöhe, ab der ein Modell überhaupt sperrt. Darunter liegt Flachzeug (Bodenplatten,
## Decals, Pfützen), über das man selbstverständlich läuft.
const MIN_HOEHE_M: float = 0.35
## Gebäude-Kollision etwas kleiner als die Bounding-Box: Vordächer, Schornsteine und Anbauten
## stecken darin, und man soll am Haus entlanglaufen können, nicht an dessen Luftraum.
const GEBAEUDE_SCHRUMPF: float = 0.82
## Notfall-Regel für Bauteile ohne feststellbaren Asset-Namen (rohe Meshes): Ab diesem
## Seitenverhältnis der Grundfläche gilt eines als WAND und wird nicht geschrumpft. Gemessen
## liegen die Häuser bei 1,01–1,56:1 und die Mauerstücke bei 2,13–16,22:1 — die Grenze sitzt
## genau in dieser Lücke. Der Regelfall läuft über `AssetRegistry.is_wall`.
const WAND_VERHAELTNIS: float = 1.85
## Anteil der Torbreite, den EIN Pfosten einnimmt.
##
## Ein Tor ist keine Mauer, auch wenn `is_wall` es der Kollision wegen so behandelt: Zwischen
## seinen Pfosten ist ein Durchgang, und der ist der einzige Weg in die Stadt. Gemessen an
## `gate.glb` (8,06 m Einbaubreite): Die Pfosten stehen bei 0–2,0 m und 6,0–8,1 m, dazwischen
## liegen 3,9 m, in denen nur das 30 cm dünne Torblatt hängt. 26 % je Seite decken die Pfosten
## und lassen den Durchgang frei.
const TOR_PFOSTEN_ANTEIL: float = 0.26


## Alle Sperren einer Stadt-Szene, in den Koordinaten, in denen `welt` die Wurzel absetzt.
##
## Jeder Eintrag:
##   `c`      Mittelpunkt der Grundfläche (Vector2 = x/z)
##   `h`      halbe Kantenlängen, OHNE Spielerradius — den schlägt der Aufrufer auf
##   `yaw`    Drehung um Y
##   `deckel` Oberkante in Metern (für die Beschriftung)
##   `asset`  logischer Name ("" = nicht feststellbar)
##   `label`  Beschriftung aus den Metadaten ("" = keine)
##   `name`   Knotenname, für Fehlermeldungen
static func rects(town: Node3D, welt: Transform3D = Transform3D.IDENTITY) -> Array:
	var out: Array = []
	for child in town.get_children():
		if child is Node3D:
			_sammle(child as Node3D, welt, out)
	return out


## Ein Knoten und alles darunter. Der Knoten trägt seine eigenen Meshes ein, danach kommen die
## Kinder an die Reihe — jedes mit seinem eigenen Eintrag.
static func _sammle(node: Node3D, welt: Transform3D, out: Array) -> void:
	var w: Transform3D = welt * node.transform
	var b: AABB = eigene_huelle(node)
	var eigenes: bool = b.size.y >= MIN_HOEHE_M
	if eigenes:
		_eintragen(node, b, w, out)
	for child in node.get_children():
		if not (child is Node3D):
			continue
		var c: Node3D = child as Node3D
		# In den INNENBAU eines eingefuegten Modells wird nicht hineingelaufen — der ist mit
		# der Huelle schon erfasst, und ein zweiter Eintrag darauf waere nicht nur doppelt,
		# sondern falsch: Das Innere eines Tores heisst `mesh_node` und nicht `gate`, also
		# griffe die Torregel dort nicht und der Durchgang waere wieder zu.
		#
		# Angehaengte MODELLE dagegen sind eigene Bauteile (`scene_file_path` gesetzt), und
		# reine Ordnerknoten haben gar keine eigene Huelle — durch beide wird durchgelaufen.
		if eigenes and c.scene_file_path == "":
			continue
		_sammle(c, w, out)


## Hülle der Meshes, die WIRKLICH zu diesem Knoten gehören — im Raum des Knotens, ohne dessen
## eigene Transform. Alles, was in einer eingehängten Szene steckt, bleibt draußen: Dieser
## Unterbaum trägt sich selbst ein, und ihn hier mitzuzählen wäre die Doppelzählung, die den
## Kasten über die halbe Stadt aufgespannt hat.
static func eigene_huelle(node: Node3D) -> AABB:
	var treffer: Array = []
	_eigene_meshes(node, Transform3D.IDENTITY, treffer, true)
	var box := AABB()
	var gefunden: bool = false
	for e in treffer:
		var a: AABB = (e[1] as Transform3D) * (e[0] as MeshInstance3D).get_aabb()
		box = a if not gefunden else box.merge(a)
		gefunden = true
	return box if gefunden else AABB()


static func _eigene_meshes(node: Node3D, lokal: Transform3D, treffer: Array, wurzel: bool) -> void:
	if not wurzel and node.scene_file_path != "":
		return
	if node is MeshInstance3D:
		treffer.append([node, lokal])
	for child in node.get_children():
		if child is Node3D:
			var c: Node3D = child as Node3D
			_eigene_meshes(c, lokal * c.transform, treffer, false)


static func _eintragen(node: Node3D, b: AABB, w: Transform3D, out: Array) -> void:
	var skalierung: Vector3 = w.basis.get_scale().abs()
	var grund := Vector2(b.size.x * skalierung.x, b.size.z * skalierung.z)
	var mitte: Vector3 = w * (b.position + b.size * 0.5)
	var yaw: float = w.basis.get_euler().y
	var hoehe: float = b.size.y * skalierung.y
	var asset: String = asset_name(node)
	if _ist_tor(asset):
		_tor_eintragen(node, grund, mitte, yaw, hoehe, asset, out)
		return
	# Der Schrumpf-Faktor gilt Gebäuden, nicht Mauern (Begründung in `AssetRegistry.is_wall`).
	# Erst am Namen entscheiden — der ist exakt. Nur wenn keiner zu holen ist (rohes Mesh von
	# Hand gebaut), zählt die Form.
	var wandartig: bool = AssetRegistry.is_wall(asset)
	if asset == "":
		var schmal: float = minf(grund.x, grund.y)
		wandartig = schmal > 0.01 and maxf(grund.x, grund.y) / schmal >= WAND_VERHAELTNIS
	out.append(_eintrag(node, mitte, grund * 0.5 * (1.0 if wandartig else GEBAEUDE_SCHRUMPF),
		yaw, hoehe, asset, true))


## Zwei Pfosten statt eines Riegels. Ohne das ist die Stadt zwar von einer schönen Mauer
## umgeben, hat aber keinen Eingang mehr.
static func _tor_eintragen(node: Node3D, grund: Vector2, mitte: Vector3, yaw: float,
		hoehe: float, asset: String, out: Array) -> void:
	var quer: bool = grund.x >= grund.y          # liegt die lange Seite auf X?
	var laenge: float = maxf(grund.x, grund.y)
	var tiefe: float = minf(grund.x, grund.y)
	var pfosten: float = laenge * TOR_PFOSTEN_ANTEIL
	var versatz: float = (laenge - pfosten) * 0.5
	var halb := Vector2(pfosten, tiefe) * 0.5 if quer else Vector2(tiefe, pfosten) * 0.5
	var erster: bool = true
	for s in [-1.0, 1.0]:
		var lokal := Vector3(s * versatz, 0.0, 0.0) if quer else Vector3(0.0, 0.0, s * versatz)
		out.append(_eintrag(node, mitte + Basis(Vector3.UP, yaw) * lokal, halb, yaw, hoehe,
			asset, erster))
		erster = false


static func _eintrag(node: Node3D, mitte: Vector3, halb: Vector2, yaw: float, hoehe: float,
		asset: String, mit_schild: bool) -> Dictionary:
	var schild: String = ""
	if mit_schild and node.has_meta("label"):
		schild = String(node.get_meta("label"))
	# Wem gehoert das Haus? `metadata/npc` in der Szene, sonst leer.
	#
	# Damit steht der Wirt vor SEINEM Haus, auch nachdem jemand es im Editor verschoben hat.
	# Vorher standen die Standorte als feste Zahlen im Code, gemessen an der Stadt, die der
	# Code selbst baut — und seit `Rustwater.tscn` die Wahrheit ist, stimmten sie nicht mehr:
	# Der Saloon war um sieben Meter gewandert, die Schmiede um vier, und Doc und Wanda hatten
	# ueberhaupt kein Haus mehr, weil Destille und Labor in der Szene gar nicht vorkommen.
	# Die Figuren standen daraufhin auf der Strasse herum.
	var wirt: String = ""
	if mit_schild and node.has_meta("npc"):
		wirt = String(node.get_meta("npc"))
	return {
		"c": Vector2(mitte.x, mitte.z),
		"h": halb,
		"yaw": yaw,
		"deckel": mitte.y + hoehe * 0.5,
		"asset": asset,
		"label": schild,
		"npc": wirt,
		"name": node.name,
	}


## Ist das ein Tor mit Durchgang?
static func _ist_tor(asset: String) -> bool:
	return asset.begins_with("gate") or asset.begins_with("tor")


## Logischer Asset-Name eines Stadt-Knotens ("" = nicht feststellbar).
##
## Zwei Quellen, weil es zwei Wege in die Szene gibt: Die erzeugten Knoten tragen `asset` als
## Metadatum, ein aus dem Dateisystem gezogenes Modell nicht — dessen Herkunft steht dafür in
## `scene_file_path` (`…/palisade_a.glb` → `palisade_a`). Damit ist ein von Hand gestelltes
## Mauerstück genauso erkennbar wie ein erzeugtes, ohne dass man im Editor etwas eintragen muss.
static func asset_name(node: Node3D) -> String:
	if node.has_meta("asset"):
		return String(node.get_meta("asset"))
	if node.scene_file_path != "":
		return node.scene_file_path.get_file().get_basename()
	return ""


## Steht dieser Punkt in einer der Sperren? `radius` ist der Spielerradius.
##
## Dieselbe Prüfung wie im Spiel (`OverworldView._blocked`), hier als reine Funktion, damit der
## Test die Stadt abrastern kann, ohne die Welt zu bauen.
static func blockiert(sperren: Array, p: Vector2, radius: float) -> bool:
	return wer_blockiert(sperren, p, radius) != ""


## Wie `blockiert`, nennt aber den Schuldigen ("" = frei). Ein Test, der nur „hier geht es
## nicht" sagt, schickt einen auf die Suche; einer, der das Bauteil nennt, nicht.
static func wer_blockiert(sperren: Array, p: Vector2, radius: float) -> String:
	for r in sperren:
		var lokal: Vector2 = (p - Vector2(r["c"])).rotated(-float(r["yaw"])).abs()
		var h: Vector2 = Vector2(r["h"]) + Vector2(radius, radius)
		if lokal.x <= h.x and lokal.y <= h.y:
			return String(r["name"])
	return ""
