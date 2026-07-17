# Rust & Lead

Isometrisches **Steampunk-Western ARPG** (*Weird West* / *Fallout*-Stil), Mobile-First.

Dieses Repository enthält den **Web-Prototyp (Phase 1)** des Spiels. Die eigentliche
Spiel-Logik wird schrittweise in `index.html` implementiert.

---

## Vision (Kurzfassung)

Ein isometrisches Action-RPG, optimiert für mobile Browser. Entwicklung in zwei Phasen:

1. **Phase 1 – Web-Prototyp:** Leichtgewichtiger, spielbarer Prototyp als **einzelne
   `index.html`** (Phaser.js). Nutzt programmgesteuerte Platzhalter (geometrische
   Formen/Farben) und ist sofort auf dem Smartphone per Touch-Joystick testbar.
2. **Phase 2 – Godot-Portierung:** Nach erfolgreichem Gameplay-Test wird das Projekt in
   die **Godot Engine 4.x** übertragen und die Platzhalter durch echte 2D-Sprites ersetzt.

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

🚧 **Setup / Gerüst.** Die Spiel-Programmierung erfolgt anschließend in `index.html`.
