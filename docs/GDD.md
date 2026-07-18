# Game Design Document (GDD): "Rust & Lead"
## Fokus: Modernes 3D-Isometrisches ARPG (Godot 4) · Mobile-First Prototyping

> **Aktualisierte Vision (Stand: Refactoring-Direktive):** "Rust & Lead" wird als
> **modernes, hochauflösendes 3D-isometrisches Action-RPG- & Tycoon-Hybrid** auf Basis
> von **Godot 4** entwickelt. Sämtliche Referenzen auf "16-Bit", "Retro-Stil" oder
> "Pixel-Art" sind ausdrücklich **gestrichen**. Der visuelle Zielstil ist grim-dark,
> gritty und realistisch (Fallout/Diablo-Atmosphäre).

---

## 1. Executive Summary & Vision

**Rust & Lead** ist ein isometrisches Action-RPG (ARPG) mit Tycoon-Anteil im
Steampunk-Western-Stil (*Weird West* / *Fallout*). Der Zielbau ist eine moderne,
hochauflösende **3D**-Produktion – keine 2D-Sprite-/Tilemap-Optik.

Die Entwicklung läuft zweistufig:

1. **Phase 1 (Gameplay-Prototyp, Web):** Ein leichtgewichtiger, sofort spielbarer
   Prototyp als einzelne HTML5-Datei (Phaser.js). Er dient **ausschließlich der
   Validierung von Spielmechanik, Systemen und Balancing** (Bewegung, Kampf, Loot,
   Wirtschaft, Ausrüstung, Level, Quests). Die Darstellung nutzt bewusst **neutrale
   geometrische Platzhalter** – dies ist *kein* angestrebter Kunststil, sondern ein
   funktionaler Abstraktions-Layer zum schnellen Testen am Smartphone.
2. **Phase 2 (Produktion in Godot 4):** Die im Prototyp erprobten Systeme werden in ein
   vollwertiges **3D-Projekt in Godot 4** überführt. Platzhalter-Geometrie wird durch
   hochauflösende 3D-Meshes mit PBR-Materialien ersetzt; die Atmosphäre entsteht durch
   moderne Echtzeit-Beleuchtung.

---

## 2. Kritische visuelle & technische Direktiven (Godot 4)

1. **Moderne 3D-Rendering-Pipeline:** Godot 4 **Forward+**-Renderer. Welt, Figuren und
   Umgebung als **hochauflösende 3D-Meshes mit PBR-Materialien** (Physically Based
   Rendering), die gritty-realistische Oberflächen betonen: verwittertes Eisen, nasses
   Öl, korrodiertes Kupfer, realistische organische Texturen.
2. **Grim-Dark-Atmosphäre (Fallout/Diablo-Vibe):** Dunkle, bedrückende Stimmung über
   moderne Lichttechnik. **SDFGI** (Signed Distance Field Global Illumination),
   **volumetrischer Nebel** für den Fog of War sowie dynamische, kontrastreiche
   Echtzeit-Schatten.
3. **Moderne Kamera:** **fixe, nicht rotierbare** 3D-isometrische Kamera (orthografisch
   oder flach-perspektivisch), weich folgend, ausgelegt auf großflächige Exploration
   (Details siehe 3.3) – inkl. automatischem Sichtverdeckungs-System (3.4).
4. **Visceral Combat & Physik:** Wuchtiger, moderner Kampf. **Voll-3D-Skelett­animationen**
   statt kachelbasierter Animationen, **Ragdoll-Physik** für besiegte Gegner, sowie
   **GPU-Partikeleffekte** für elementare Treffer (galvanische Funken, alchemistische
   Säure-Korrosion, dynamisches Feuer).

---

## 3. Weltkarte & Exploration (3D-Umgebung)

### 3.1 Maßstab & Koordinaten
Die Spielwelt ist eine **zusammenhängende, nahtlose 3D-Open-World**.
* **Dimensionen:** Massive 3D-Ebene von **2000 × 2000 Metern** (Godot Spatial Units).
* **Reise-Metrik:** Bei moderner Laufgeschwindigkeit von **4,7 m/s** dauert ein
  durchgehender diagonaler Sprint über die vollständig erkundete Karte rund
  **5 Minuten** Echtzeit-Fußweg.
* **Exploration:** Die Karte wird durch ein **volumetrisches Nebelsystem** verhüllt.
  Bewegung durch die Welt schneidet in Echtzeit Pfade in den Nebel – basierend auf der
  **3D-Sichtlinie (Line-of-Sight)** des Spielers.

### 3.2 Struktur
Nahtlose Open-World mit Streaming/LOD statt harter Kartenwechsel; Stadt (Rustwater),
Fraktionsbasen und Dungeons sind eingebettete Bereiche derselben Welt.

### 3.3 Kamera – Fixe isometrische Perspektive
Permanent fixierte, **nicht rotierbare** 3D-Kamera für das klassische, fokussierte
ARPG-Spielgefühl.
* **Winkel:** starr, Pitch ca. **35°–45°** nach unten, Yaw um **45°** auf der Y-Achse →
  perfekter isometrischer Look.
* **Folgemodus:** folgt der Spieler-Transform **weich interpoliert** (Lerp / Smooth Damp),
  ruckelfrei bei Sprints und plötzlichen Richtungswechseln.
* **Keine Spieler-Rotation:** manuelle Kameradrehung ist vollständig deaktiviert.

### 3.4 Dynamisches Sichtverdeckungs-System (Occlusion Handling)
Große industrielle Strukturen (Raffinerien, Schaufelradbagger, Felswände) können die
Achsen-bedingte Sicht blockieren. Ein automatisiertes Shader-/Ausblend-System hält das
Gameplay stets sichtbar:

**3.4.1 Wand-Ausblenden (See-Through Alpha Masking).** Befinden sich Spieler-Mesh oder
ein feindlicher Automat hinter einer Struktur, wirft Godot einen automatischen **Raycast**
von der Kamera zum Spieler. Alle Objekte, die diesen Strahl schneiden, wechseln in einen
transparenten Zustand – **kein hartes Ausblenden**, sondern ein **Kreis-Dither-Shader
(Screendoor Transparency)**, der exakt an der Spielerposition ein „Loch" in die Wand
schneidet. Die Architektur bleibt sichtbar, die Sicht aufs Gameplay ist frei.

**3.4.2 Röntgen-Kontur (X-Ray Outlines).** Ergänzend erhalten Charakter-Meshes einen
**Silhouette-Glow-Shader**. Ist der Spieler komplett verdeckt, zeichnet die Engine eine
leuchtende, farbige Kontur **durch die Wände** – z. B. gedimmtes **Messing-Gelb** für den
Helden, **galvanisches Blau** für mechanische Gegner. So bleibt auch im dichtesten
Fabrik-Gefecht die volle Kontrolle über Positionen und Hitboxen erhalten.

---

## 4. Moderne NPC-Interaktion

### 4.1 Dynamische 3D-UI-Overlays
* **World-Space-UI:** NPC-Namen und Interaktions-Status schweben als **3D-Billboard-
  UI** (`Label3D` bzw. screen-space-projizierte UI) direkt über den Charakter-Meshes.
* **Input-Debouncing (Anti-Doppeltipp):** Ein strikter Software-Debouncer fängt schnelle
  Touch-/Klick-Eingaben ab und verhindert duplizierte UI-Instanzen oder inkonsistente
  Zustände in der 3D-Interaktions-Pipeline.

---

## 5. Core Gameplay Loop

1. **Combat & Loot:** Der Spieler bekämpft Gegner (Auto-Ziel-Fernkampf, Fähigkeiten,
   Wurf-Granaten) und sammelt Beute – Gold, Material, Loot-Kisten und Ausrüstung.
2. **Charakter-Progression:** Erfahrung durch Kills & Quests → Level → höhere
   Ausrüstungs-Stufen; anlegbare Ausrüstung (Helm, Rüstung, Waffe, Gadget, Stiefel,
   drei Panzerplatten) mit Seltenheitsstufen und Grid-Inventar.
3. **Rustwater-Wirtschaft (Tycoon):** Gold fließt in passive Einkommens-Gebäude, die
   im Hintergrund unabhängig weiterlaufen (auch offline).

Diese Systeme sind im Web-Prototyp (Phase 1) bereits implementiert und dienen als
verbindliche Spezifikation für die Godot-Produktion.

---

## 6. Der Übergang vom Prototyp zu Godot 4

* **Was der Prototyp liefert:** eine erprobte, ausbalancierte **Spiel-Logik** –
  Bewegung, Auto-Ziel-Kampf, Schadensarten & Gegner-Matrix, Status-Effekte, Loot &
  Kisten, Inventar/Ausrüstung, Level-System, Quests/Fraktionen, Wirtschaft.
* **Was in Godot neu entsteht (Produktion):**
    * **Figuren & Gegner:** hochauflösende 3D-Meshes mit PBR, **3D-Skelett­animationen**
      (Blender → glTF), Ragdoll bei Tod.
    * **Umgebung:** modellierte 3D-Level statt Kacheln; PBR-Bodenmaterialien
      (Sand, Fels, Metallböden), platzierte 3D-Props (Palisaden, Gebäude, Wracks).
    * **Beleuchtung/Atmosphäre:** SDFGI, volumetrischer Nebel (Fog of War),
      Echtzeit-Schatten; grim-dark Farb- und Kontrast-Grading.
    * **VFX:** GPU-Partikel für elementare Treffer (galvanisch/alchemistisch/thermisch)
      und Umwelt (Dampf, Funken, Rauch).
    * **Steuerung/UI:** virtueller Touch-Joystick + Action-/Fähigkeiten-Buttons,
      World-Space-`Label3D` für NPCs, 3D-isometrische Kamera.

---

## 7. Steuerung

* **Linke Bildschirmhälfte:** dynamischer virtueller Touch-Joystick (erscheint bei
  Berührung), flüssige Bewegung.
* **Rechte Bildschirmhälfte:** großer Action-Button (Angriff, Auto-Ziel auf nächsten
  Gegner) plus Fähigkeiten-Buttons (Spezialschuss, Ausweich-Dash, Heiltrank,
  Säure-/Elektrofeld-Granate) und Waffen-Umschalter (Schadensart).

---

## 8. Terminologie & Ton

Steampunk-Western, grim-dark. Konsequent Steampunk-Begriffe (Zahnräder, Kupferleitungen,
Dampfdruck, Alchemistische Synthese, Kinetoskop-Projektion). **Keine** modernen
Cyberpunk-Begriffe. Der visuelle Ton ist realistisch-gritty (Fallout/Diablo), **nicht**
retro, nicht Pixel-Art.
