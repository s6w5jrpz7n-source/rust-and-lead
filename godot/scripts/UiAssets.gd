extends RefCounted
## Eine Stelle für alle Oberflächen-Grafiken (`assets/ui/*.png`).
##
## **Kein `class_name`, sondern `preload` beim Aufrufer.** Godot fuellt seinen Index globaler
## Klassennamen erst beim Durchsuchen des Projekts — geparst wird aber vorher. Eine frisch
## dazugekommene `class_name`-Datei ist deshalb genau einmal unbekannt: beim ersten Start nach
## dem Pull. Beim Auftraggeber sah das so aus:
##
##     Parse Error: Identifier "UiAssets" not declared in the current scope.
##     Failed to load script "res://scripts/OverworldView.gd"
##
## Also das ganze Spiel kaputt, bis man von Hand neu lädt. `preload("res://scripts/UiAssets.gd")`
## löst über den Pfad auf und kennt das Problem nicht. Für eine reine Hilfsklasse ohne eigenen
## Zustand ist der globale Name ohnehin kein Gewinn.
##
## Vier Bildschirme brauchen dieselben Bilder — Beutel-Raster und Puppe teilen sich die sechs
## Sinnbilder, Sprechtafel und Puppe je einen Rahmen, die Fußspur ihre Sohle. Ohne gemeinsame
## Stelle lädt jeder für sich, und dann liegt dasselbe 256er-Bild viermal im Speicher.
##
## **Alles ist optional.** Fehlt eine Datei, kommt `null` zurück und der Aufrufer zeichnet weiter
## selbst. Es gibt bewusst keinen roten Platzhalter und keine Fehlermeldung: Ein halber Satz
## Grafiken darf das Spiel nie unbenutzbar machen, und der Auftraggeber soll liefern können, wann
## er will, ohne dass vorher irgendwo etwas eingetragen werden muss.

const ORDNER: String = "res://assets/ui/"

## Bereits geladene Texturen und ihre bemalten Ausschnitte. `static var` statt Autoload: Das ist
## reiner Zwischenspeicher ohne Spielzustand, dafür lohnt kein Knoten im Baum.
static var _cache: Dictionary = {}
static var _regionen: Dictionary = {}


## Textur zu einem Namen ohne Endung ("icon_helmet"). `null`, wenn es sie nicht gibt.
static func texture(basename: String) -> Texture2D:
	if _cache.has(basename):
		return _cache[basename]
	# PNG zuerst, dann WEBP. Die gemalten Oberflaechen sind PNG; was aus einem Videobild kommt
	# (das Titelbild, das Heldenportraet), ist ein Foto und als PNG unnoetig gross — 1,5 MB
	# gegen 118 kB beim Titelbild, bei nicht unterscheidbarem Ergebnis.
	var tex: Texture2D = null
	for endung in [".png", ".webp"]:
		var pfad: String = ORDNER + basename + String(endung)
		if ResourceLoader.exists(pfad):
			tex = load(pfad) as Texture2D
			if tex != null:
				break
	_cache[basename] = tex
	return tex


## Gibt es überhaupt Oberflächen-Grafiken? Für Tests und für Anzeigen, die sich sonst doppelt
## aufbauen würden.
static func has(basename: String) -> bool:
	return texture(basename) != null


## Der wirklich bemalte Teil einer Textur.
##
## Bildgeneratoren legen das Motiv gern als kleineres Bild auf eine größere durchsichtige Fläche.
## Stur in ein Feld gezeichnet wäre das Sinnbild entsprechend kleiner, mit einem Rand aus Nichts —
## und bei sechs Sinnbildern mit unterschiedlich viel Luft wären sie untereinander verschieden
## groß, was in einem Raster sofort auffällt.
##
## `Image.get_used_rect()` beantwortet das in einem Aufruf. Gemerkt wird es trotzdem: Der Aufruf
## liest das ganze Bild, und das Beutel-Raster zeichnet bis zu sechzig Felder je Bild.
static func region(basename: String) -> Rect2:
	if _regionen.has(basename):
		return _regionen[basename]
	var leer := Rect2()
	var tex: Texture2D = texture(basename)
	if tex == null:
		_regionen[basename] = leer
		return leer
	var bild: Image = tex.get_image()
	if bild == null:
		_regionen[basename] = leer
		return leer
	var benutzt: Rect2i = bild.get_used_rect()
	var r: Rect2 = Rect2(benutzt) if benutzt.size.x > 0 and benutzt.size.y > 0 else leer
	_regionen[basename] = r
	return r


## Zeichnet eine Grafik MITTIG und SEITENVERHÄLTNISTREU in ein Feld. `false`, wenn es sie nicht
## gibt — dann ist der Aufrufer wieder dran.
##
## Verhältnistreu, weil die Felder quadratisch sind und die Bilder es nicht immer sind: Ein
## Karabiner ist doppelt so lang wie hoch, in ein Quadrat gequetscht wird er zum Stummel.
static func draw_fitted(ci: CanvasItem, basename: String, feld: Rect2,
		tint: Color = Color.WHITE) -> bool:
	var tex: Texture2D = texture(basename)
	if tex == null:
		return false
	var quelle: Rect2 = region(basename)
	if quelle.size.x <= 0.0:
		quelle = Rect2(Vector2.ZERO, tex.get_size())
	var faktor: float = minf(feld.size.x / quelle.size.x, feld.size.y / quelle.size.y)
	var gross := Vector2(quelle.size.x * faktor, quelle.size.y * faktor)
	ci.draw_texture_rect_region(tex,
		Rect2(feld.position + (feld.size - gross) * 0.5, gross), quelle, tint)
	return true


## Nur für Tests: Zwischenspeicher leeren, damit ein Lauf den nächsten nicht beeinflusst.
static func forget() -> void:
	_cache.clear()
	_regionen.clear()
