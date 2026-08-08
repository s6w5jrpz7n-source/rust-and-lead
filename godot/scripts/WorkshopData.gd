class_name WorkshopData
## Werkstatt-Ausbauten — die Gold-Senke für Kampfkraft (GDD §7.5, Prototyp `UPGRADES`).
##
## Rein statische Daten- und Regelklasse, kein Node: Der Bildschirm liest hier, was es gibt und
## was es kostet, `PlayerStats` liest die gekauften Stufen aus `GameState.upgrades`. Zwischen
## beiden steht nichts.
##
## **1:1 aus dem validierten Web-Prototyp portiert**, samt Kostenkurve, Höchststufen und der
## Doppelbenennung. Erfundene Zahlen wären hier besonders schädlich: An diesen sechs Werten
## hängt die gesamte Kampfbalance, und die ist im Prototyp durchgespielt.

## Reihenfolge = Anzeigereihenfolge im Bildschirm.
const ORDER: Array = ["damage", "firerate", "reload", "hp", "speed", "regen", "magnet"]

## `name` trägt ZWEI Bezeichnungen: vor und nach dem Reveal. Das ist kein Kosmetikwechsel,
## sondern die zentrale Wendung der Geschichte — der Held hält sich für einen Menschen und
## kauft „Schneller Hahn"; danach weiß er, was er ist, und dasselbe Teil heißt
## „Kolben-Frequenz". Der Werkstattbildschirm erzählt die Wendung dadurch mit.
##
## `body` markiert Eingriffe am eigenen Körper. Die sind vor dem Reveal GESPERRT: Wer sich für
## einen Menschen hält, lässt sich keine Hydraulik-Laufbeine einbauen.
const UPGRADES: Dictionary = {
	"damage":   { "name": ["Revolver-Kaliber", "Ballistische Kalibrierung"],
		"icon": "⚔", "desc": "Schaden pro Schuss", "base": 40, "max": 6, "body": false },
	"firerate": { "name": ["Schneller Hahn", "Kolben-Frequenz"],
		"icon": "⚡", "desc": "Feuerrate", "base": 50, "max": 5, "body": false },
	"hp":       { "name": ["—", "T-4 Torso-Panzerung"],
		"icon": "♜", "desc": "Panzerung (Leben)", "base": 60, "max": 6, "body": true },
	"speed":    { "name": ["—", "Hydraulik-Laufbeine"],
		"icon": "»", "desc": "Tempo", "base": 60, "max": 5, "body": true },
	"regen":    { "name": ["—", "Kühlsystem"],
		"icon": "❄", "desc": "Regeneration", "base": 50, "max": 5, "body": true },
	# Nicht aus dem Prototyp uebernommen, sondern neu: Dort gab es kein Nachladen, also auch
	# nichts zu beschleunigen. Basis und Hoechststufe folgen der Kurve der uebrigen Eintraege.
	"reload":   { "name": ["Schnellader", "Auswurf-Servo"],
		"icon": "↻", "desc": "Nachladedauer (−8 % je Stufe)", "base": 55, "max": 5, "body": false },
	"magnet":   { "name": ["—", "Magnet-Spule"],
		"icon": "Ω", "desc": "Loot-Magnet", "base": 40, "max": 4, "body": false },
}


## Ausbaukosten der NÄCHSTEN Stufe: Basis × (aktuelle Stufe + 1).
## Linear-progressiv — Stufe 5→6 kostet das Sechsfache der ersten.
static func cost(id: String) -> int:
	return int(UPGRADES[id]["base"]) * (level(id) + 1)


static func level(id: String) -> int:
	return int(GameState.upgrades.get(id, 0))


static func max_level(id: String) -> int:
	return int(UPGRADES[id]["max"])


static func is_maxed(id: String) -> bool:
	return level(id) >= max_level(id)


## Körper-Eingriffe bleiben zu, solange der Held sich für einen Menschen hält.
static func is_locked(id: String) -> bool:
	return bool(UPGRADES[id]["body"]) and not GameState.is_revealed


## Anzeigename in der aktuellen Erzählstufe.
static func label(id: String) -> String:
	return String(UPGRADES[id]["name"][1 if GameState.is_revealed else 0])


## Kaufen. Liefert `true` bei Erfolg; prüft Sperre, Höchststufe und Gold in dieser Reihenfolge,
## damit der Aufrufer nichts doppelt prüfen muss.
static func buy(id: String) -> bool:
	if not UPGRADES.has(id) or is_locked(id) or is_maxed(id):
		return false
	if not GameState.spend_gold(cost(id)):
		return false
	GameState.upgrades[id] = level(id) + 1
	return true
