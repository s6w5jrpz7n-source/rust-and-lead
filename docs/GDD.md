# Game Design Document (GDD): "Rust & Lead"
## Focus: Mobile-First Web Prototyping & Future Godot Transition

---

## 1. Executive Summary & Vision

**Rust & Lead** ist ein isometrisches Action-RPG (ARPG) im Steampunk-Western-Stil (*Weird West* / *Fallout*), optimiert für mobile Endgeräte.

Da die Entwicklung vollständig mobil-freundlich und ohne eigene Grafik-Erstellung starten soll, nutzen wir eine **zweistufige Entwicklungs-Pipeline**:
1. **Phase 1 (Web-Prototyp):** Ein leichtgewichtiger, spielbarer Prototyp als einzelne HTML5-Datei (Phaser.js). Dieser nutzt programmgesteuerte Platzhalter (geometrische Formen/Farben) und ist sofort über mobile Web-Editoren (wie CodePen) auf dem Smartphone-Bildschirm per Touch-Joystick testbar.
2. **Phase 2 (Godot-Portierung):** Nach erfolgreichem Gameplay-Test im Web wird das Projekt in die **Godot Engine 4.x** übertragen. Hier werden die geometrischen Platzhalter durch echte 2D-Spritesheets (z.B. aus Blender vorgerendert oder von Kenney.nl) und Tilemaps ersetzt.

---

## 2. Technische Spezifikationen & Steuerung

### Web-Prototyp (Phase 1)
* **Technologie:** HTML5, CSS3, JavaScript (Phaser.js Engine).
* **Hosting:** Single-File-Setup für einfache Vorschau via CodePen, JSFiddle oder itch.io.
* **Mobil-Optimierung:** Automatisches Resizing auf Hochkant- oder Querformat (Querformat empfohlen), Touch-Eingaben priorisiert.
* **Grafik-Platzhalter:**
    * *Spieler:* Blauer Kreis (mit einer kleinen Nase, um die Blickrichtung anzuzeigen).
    * *Gegner:* Rote Quadrate oder Kreise.
    * *Boden/Wände:* Einfarbige Kacheln (z.B. Sandgelb für Wüste, Grau für Dungeons).

### Mobile Steuerung (Virtual Joystick)
* **Linke Bildschirmhälfte:** Ein dynamischer virtueller Joystick. Sobald der Daumen den Bildschirm berührt, erscheint der Joystick und steuert die Bewegung des Spielers (isometrisch, 8 Richtungen).
* **Rechte Bildschirmhälfte:** Großer roter Action-Button zum Schießen/Schlagen, daneben kleinere Buttons für Fähigkeiten (Heiltrank/Whiskey).

---

## 3. Core Gameplay Loop

1. **Dungeon-Run (Combat & Loot):** Der Spieler steuert den Charakter durch einen zufällig generierten Raum, weicht Gegnern aus und besiegt sie per Knopfdruck.
2. **Loot-System:** Gegner lassen Goldmünzen fallen, die automatisch per Magnet-Effekt zum Spieler gezogen werden.
3. **Rustwater Base (Wirtschaft):** Der Spieler wechselt per Button in die Stadt "Rustwater" und investiert sein gesammeltes Gold in ein passives Einkommens-Gebäude (z. B. "Gatling-Saloon"). Dieses generiert fortlaufend Gold (auch offline/während des Kampfes).

---

## 4. Vom Web-Prototyp zu Godot (Grafik-Transition)

* **Wie funktionieren die Platzhalter?**
    Im Web-Prototyp generiert die Phaser-Engine die Grafiken live aus Code (`graphics.fillCircle`, `graphics.fillRect`). Das spart Ladezeiten und Asset-Verwaltung.
* **Der Übergang zu Godot:**
    In Godot nutzen wir das `CharacterBody2D`-Node für den Spieler. Anstatt der Phaser-Kreise importieren wir in Godot **Spritesheets** (2D-Bilderrahmen-Animationen).
    * *Beispiel:* Du erstellst einen Charakter in Blender, renderst ihn aus 8 Kameraperspektiven (isometrisch) beim Laufen und Angreifen als PNG-Bilder und importierst diese als `AnimatedSprite2D` in Godot.
    * Gleiches gilt für den Boden: In Godot bauen wir ein `TileMap`-System auf, bei dem die sandgelben Phaser-Vierecke durch detaillierte Wüsten-Bodenplatten-Grafiken ersetzt werden.

---

## 5. Strukturierte Roadmap (Web-Prototyp Fokus)

### Schritt 1: Das lauffähige Grundgerüst (HTML5 Single File)
* Erstellung einer kompletten `index.html` mit eingebundener Phaser.js Engine.
* Implementierung des Viewports für mobile Bildschirme.
* Zeichnen des Spielers (Blauer Kreis) und des Bodens (sandfarbenes Gitter).

### Schritt 2: Touch-Steuerung (Virtual Joystick)
* Implementierung eines voll funktionsfähigen virtuellen Touch-Joysticks auf der linken Seite.
* Flüssige Bewegung des Spielers in isometrischer Perspektive.

### Schritt 3: Erste Gegner & Kampfsystem
* Spawnen von roten Gegner-Kreisen.
* Hinzufügen eines "Schießen"-Buttons auf der rechten Seite, der Projektile (gelbe Punkte) in Blickrichtung abfeuert.
* Gegner-Lebensbalken und Schadenszahlen, die hochploppen.

### Schritt 4: Das Rustwater-Wirtschafts-Tab
* Ein einfacher UI-Wechsel zwischen "Dungeon" und "Rustwater".
* In "Rustwater" kann man für 100 Gold den "Gatling-Saloon" kaufen, der jede Sekunde +1 Gold generiert.

---

## 6. Erste Anweisung für die Implementierung (Web-Prototyp, Schritt 1)

> Erstelle als ersten Schritt eine einzige, vollständige `index.html` Datei (inklusive Phaser.js über CDN und CSS für Fullscreen-Mobile). Es soll folgendes enthalten sein:
> 1. Eine sandfarbene isometrische Bodenfläche (Grid).
> 2. Ein blauer Kreis als Spieler in der Mitte.
> 3. Ein voll funktionsfähiger, virtueller Touch-Joystick unten links, der den Spieler flüssig in alle Richtungen bewegt.
> 4. Automatische Anpassung an die Displaygröße des Handys.
