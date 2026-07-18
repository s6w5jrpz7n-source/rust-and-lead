# Rust & Lead

Isometrisches **Steampunk-Western ARPG** (*Weird West* / *Fallout*-Stil), Mobile-First.

Dieses Repository enthält den **Web-Prototyp (Phase 1)** des Spiels. Die eigentliche
Spiel-Logik wird schrittweise in `index.html` implementiert.

---

## Vision (Kurzfassung)

Zielbau ist ein **modernes, hochauflösendes 3D-isometrisches Action-RPG** mit grim-dark
Atmosphäre (Fallout/Diablo-Vibe) – **kein** Retro-/Pixel-Look. Entwicklung in zwei Phasen:

1. **Phase 1 – Gameplay-Prototyp (Web):** Leichtgewichtiger, spielbarer Prototyp als
   **einzelne `index.html`** (Phaser.js). Dient der **Validierung von Mechanik &
   Balancing** und nutzt dafür neutrale geometrische Platzhalter (kein angestrebter
   Kunststil). Sofort am Smartphone per Touch-Joystick testbar.
2. **Phase 2 – Produktion in Godot 4:** Die erprobten Systeme werden in ein vollwertiges
   **3D-Projekt** überführt (Godot 4, Forward+, PBR, SDFGI, volumetrischer Nebel,
   Ragdoll, GPU-Partikel). Die Platzhalter-Geometrie weicht hochauflösenden 3D-Meshes.

Das vollständige Game Design Document liegt unter [`docs/GDD.md`](docs/GDD.md).

---

## Projektstruktur

```
rust-and-lead/
├── index.html      # Single-File Web-Prototyp (Phaser.js via CDN) – wird von Fable befüllt
├── docs/
│   └── GDD.md       # Game Design Document
├── .gitignore
└── README.md
```

Bewusst als **Einzeldatei** gehalten: `index.html` enthält HTML, CSS und JavaScript in
einer Datei. So lässt sich der Prototyp direkt in mobile Web-Editoren (CodePen, JSFiddle)
kopieren oder auf itch.io / GitHub Pages veröffentlichen.

---

## Testen

Es wird **kein Build-Schritt** benötigt.

- **Lokal:** `index.html` direkt im Browser öffnen.
- **Am Handy:** Inhalt von `index.html` in CodePen/JSFiddle einfügen und die Vorschau öffnen.
- **Veröffentlicht:** Über GitHub Pages ausliefern (Settings → Pages → Branch `main`).

Technik: **HTML5 + CSS3 + JavaScript**, Rendering über **Phaser.js** (per CDN eingebunden).

---

## Roadmap (Web-Prototyp)

- [ ] **Schritt 1 – Grundgerüst:** Mobile-Viewport, Auto-Resize, sandfarbenes iso-Grid,
      blauer Kreis als Spieler.
- [ ] **Schritt 2 – Touch-Steuerung:** Virtueller Joystick unten links, flüssige
      isometrische Bewegung (8 Richtungen).
- [ ] **Schritt 3 – Gegner & Kampf:** Rote Gegner spawnen, Schuss-Button rechts,
      Projektile, Lebensbalken, Schadenszahlen.
- [ ] **Schritt 4 – Rustwater-Wirtschaft:** Tab-Wechsel Dungeon ⇄ Rustwater,
      "Gatling-Saloon" (100 Gold) generiert +1 Gold/Sekunde.

---

## Status

✅ **Gameplay-Prototyp spielbar.** Bewegung, Auto-Ziel-Kampf mit Schadensarten &
Gegner-Matrix, Status-Effekte, Loot & Kisten, Grid-Inventar mit Ausrüstung, Level-System,
Quests/Fraktionen und Rustwater-Wirtschaft sind implementiert (Systeme als Spezifikation
für die Godot-Produktion). Darstellung: neutrale Platzhalter-Geometrie – der finale
Kunststil ist modernes 3D (siehe [`docs/GDD.md`](docs/GDD.md)).
