# Rust & Lead

Isometrisches **Steampunk-Western ARPG** (*Weird West* / *Fallout* / *Diablo*-Stil), Mobile-First.

Dieses Repository enthält den **spielbaren Web-Prototyp (Phase 1)** — eine einzelne
`index.html` (Phaser.js) — sowie die Design-Dokumente. Der Prototyp validiert Mechanik,
Balancing und die komplette Story; die Produktion (Phase 2) erfolgt in Godot 4.

▶ **Direkt spielen:** `index.html` im Browser öffnen (Desktop oder Handy). Kein Build nötig.

---

## Die Kampagne

Ein vollständiger, wiederspielbarer Story-Bogen — vom Titelbildschirm bis zu drei Enden:

**Titelbildschirm → Cold Open → Reveal → Gildenwahl → Kapitel-10-Sabotage → Vane-Showdown → drei Enden → New Game+**

- **Der Reveal:** Nach dem Stadt-Bogen erfährst du in einer Kino-Sequenz die Wahrheit —
  du bist keine Kreatur aus Fleisch, sondern **Einheit 13** des PSALM-Programms. Die
  UI mutiert mit (Ausdauer → Kesseldruck).
- **Drei Gilden:** Rebellen, Eiserne Gilde, Schmuggler — jede mit eigenem Questbogen,
  eigener Kapitel-10-Sabotage und eigenem Ende.
- **Finale:** Ein Zwei-Phasen-Bosskampf gegen **Direktor Cornelius Vane** (das Wachs
  schmilzt, die Maschine tritt hervor), dann das gildenspezifische Ende.
- **New Game+:** Nach dem Ende bleiben Ausrüstung, Stufe und Perks — die Story startet
  neu (andere Gilde wählbar), die Gegner werden pro Zyklus +60 % zäher.

Acht erfundene **Nebenstories** (Garten aus Rost, Pip der Schutzengel, die Rivalin Vesper
Kane, die Kirche der Fleischwerdung, der blinde Projektionist, die Witwe & der Automat,
Dolores' letzte Trommel, das Uhrwerk-Herz) sind als NPCs mit vollem Quest-Zyklus spielbar.

Die vollständige Story-Bibel (alle Dialoge, Kinoszenen, Casting-Notizen) liegt unter
[`docs/STORY_BIBLE.md`](docs/STORY_BIBLE.md).

---

## Systeme

- **Kampf:** Auto-Ziel-Schießen, 4 Schadensarten (Kinetisch/Galvanisch/Thermisch/Alchemisch)
  × Gegner-Klassifizierung (Biologisch/Mechanisch), Status-Effekte, Munition/Energiekristalle.
- **Sechs Gegnertypen** inkl. dem schnellen mechanischen Schwarm *Kessel-Kläffer*, plus
  Elite-Bosse, Dungeon-Superboss und benannte Boss-Wächter.
- **Itemization (Diablo-Achse):** Seltenheiten, Affixe mit Roll-Varianz, legendäre Kräfte —
  inkl. boss-exklusiver Legendaries (Vane → *Wachsherz-Kürass*, Golem → *Golem-Faust*).
- **Perk-Baum (Fallout-Achse):** Zweige, Tiers, Capstones mit Exklusivität, Respec.
- **Tech-Module** in acht Platten-Slots (Diablo-Immortal-Panel-Layout).
- **Bosse:** telegrafierte Flächenschläge, Add-Rufe, Zwei-Phasen-Finale.
- **Endlosmodus „Der Abstieg":** skalierende Tiefe mit Modifikatoren, Tiefen-Ausrufer.
- **Zwei Nebengebiete:** Garten aus Rost (Smog-Linie) und Kessel-Friedhof (Schrott-Golem).
- **Wirtschaft:** Rustwater-Gebäude generieren Einkommen; Händler mit Drag-Handel.
- **Atmosphäre-Barks:** schwebende Story-Sprüche aus der Bibel (Stadt/Held/Gegner/Tiefe).

## Menü & Panels

| Aufruf | Funktion |
|---|---|
| ⏸ / `ESC` / `P` | Pause-Menü (Status, Statistik, Erfolge, Ton, Zum Titel) |
| 🎒 / `I` | Inventar & Charakter-Ausrüstung (Paper-Doll + Drag) |
| 📜 / `J` | Auftragsbuch (karten-übergreifend, Schnellreise per ➤) |
| 📖 / `K` | Story-Codex (nachlesbare, freischaltbare Lore-Einträge) |
| 🗺 / `M` | Vollbild-Karte |
| 📊 (Pause) | Statistik (Kills, Bosse, Beute, Codex-%, Rekorde) |
| 🏆 (Pause) | Erfolge (12 Spielziele) |

**Steuerung:** links ziehen = Bewegung (Touch-Joystick), rechts halten = angreifen,
Ziffern/Buttons für Spezialfähigkeiten. Vollständig Touch- und Tastatur-tauglich.

---

## Projektstruktur

```
rust-and-lead/
├── index.html               # Single-File Web-Prototyp (Phaser.js)
├── docs/
│   ├── MASTER_GDD.md         # Game Design Document (Systeme, Balancing, Spezifikation)
│   └── STORY_BIBLE.md        # Story-Bibel (Haupt- & Nebenstories, alle Dialoge)
├── godot/                    # Phase-2-Produktion (Godot 4)
├── .gitignore
└── README.md
```

Der Prototyp ist bewusst eine **Einzeldatei** (HTML + CSS + JS) — direkt im Browser
lauffähig, ohne Build-Schritt, per CDN-Phaser.

---

## Entwicklung & Qualitätssicherung

- **Spielen/Testen:** `index.html` im Browser öffnen.
- **Verifikation:** Eine Playwright-Harness fährt das Spiel headless und prüft die Systeme
  end-to-end (aktuell **150+ Checks**, u. a. Kampf, Itemization, Perks, Quests, Reveal,
  Finale, Enden, New Game+, Codex, Erfolge) und schlägt bei jeder Konsolen-Exception an.
- **Artefakt-Build:** Ein kleines Skript inlint Phaser in eine eigenständige, verteilbare
  `rust-and-lead-play.html` (kein CDN nötig).

Design-Referenz für Phase 2 (Godot) ist das [`docs/MASTER_GDD.md`](docs/MASTER_GDD.md);
alle Systeme im Prototyp dienen zugleich als ausführbare Spezifikation.

---

## Status

✅ **Vollständige, wiederspielbare Kampagne.** Titelbildschirm, Story von Cold Open bis zu
drei Enden, Zwei-Phasen-Endboss, New Game+, acht spielbare Nebenstories, zwei Nebengebiete,
Auftragsbuch, Story-Codex, Statistik & Erfolge, Endlosmodus. Darstellung: neutrale
Platzhalter-Geometrie — der finale Kunststil ist modernes 3D (siehe
[`docs/MASTER_GDD.md`](docs/MASTER_GDD.md)).
