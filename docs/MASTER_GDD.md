# MASTER GAME DESIGN DOCUMENT — "Rust & Lead"
### Modernes 3D-Isometrisches Action-RPG- & Tycoon-Hybrid · Godot 4

> **Status dieses Dokuments:** Konsolidierte, verbindliche Referenz (Single Source of
> Truth). Der spielbare Phaser-Web-Prototyp validiert sämtliche hier beschriebenen
> Systeme; die Godot-4-Produktion setzt sie mit hochauflösender 3D-Grafik um.
>
> **Ton & Stil:** grim-dark Steampunk-Western (Fallout / Diablo IV). **Kein** Retro,
> **kein** Pixel-Art, **keine** 2D-Kacheln. **Keine** modernen Cyberpunk-Begriffe —
> stattdessen Zahnräder, galvanische Impulse, alchemistische Synthese,
> Kinetoskop-Projektion, Dampfdruck.

---

## INHALT
1. Technisches & Visuelles Fundament
2. Kern-Zustand & Township-Mechanik (`is_revealed`, asynchroner Tycoon, State-Schema)
3. Die 12-Kapitel-Kampagne (Akt I–III)
4. Fraktions-Quest-Matrix & NPC-Netzwerk
5. Modulares Mini-Quest-System (Grind & Boosts)
6. Kampf-Design & Code-Templates
7. Anhang: Ausrüstung, Progression, Wirtschaft, Gegner-Roster, Terminologie

---

# 1. TECHNISCHES & VISUELLES FUNDAMENT

## 1.1 Rendering-Pipeline
* **Engine:** Godot 4, **Forward+**-Renderer.
* **Materialien:** hochauflösende **PBR**-Materialien (Physically Based Rendering) für
  gritty-realistische Oberflächen: verwittertes Eisen, nasses Öl, korrodiertes Kupfer,
  Ruß, feuchter Sumpfschlamm, realistische organische Texturen (Fleisch, Leder, Fell).
* **Global Illumination:** **SDFGI** (Signed Distance Field Global Illumination) für
  weiche, realistische indirekte Beleuchtung großflächiger Innen- und Außenräume.
* **Atmosphäre:** **volumetrischer Nebel** (dient zugleich als Fog of War),
  dynamische, hochkontrastige **Echtzeit-Schatten**, grim-dark Farb-/Kontrast-Grading.

## 1.2 Fixe 3D-Isometrische Kamera
* **Winkel:** permanent fix, **nicht rotierbar** — Pitch **35°–45°** nach unten,
  Yaw **45°** auf der Y-Achse → klassischer, fokussierter Iso-Look.
* **Projektion:** orthografisch oder flach-perspektivisch, ausgelegt auf großflächige
  Exploration.
* **Folgemodus:** **weich interpoliert** (Lerp / Smooth Damp) auf die Spieler-Transform,
  ruckelfrei bei Sprints und plötzlichen Richtungswechseln.
* **Keine Spieler-Rotation:** manuelle Kameradrehung vollständig deaktiviert.

## 1.3 Dynamisches Sichtverdeckungs-System (Occlusion Handling)
Große industrielle Strukturen (Raffinerien, Schaufelradbagger, Fabrikwände, Felswände)
dürfen das Gameplay niemals verdecken.

* **1.3.1 Wand-Ausblenden (See-Through Alpha Masking).** Steht das Spieler-Mesh oder ein
  feindlicher Automat hinter einer Struktur, wirft die Engine einen **Raycast** von der
  Kamera zum Charakter. Alle geschnittenen Objekte wechseln transparent — **kein hartes
  Ausblenden**, sondern ein **Kreis-Dither-Shader (Screendoor Transparency)**, der exakt
  an der Charakterposition ein rundes „Loch" in die Wand schneidet. Die Architektur
  bleibt sichtbar, die Sicht aufs Gameplay frei.
* **1.3.2 Röntgen-Kontur (X-Ray Silhouette Outlines).** Ergänzend erhalten Charakter-Meshes
  einen **Silhouette-Glow-Shader**. Ist ein Charakter vollständig verdeckt, zeichnet die
  Engine eine leuchtende, farbige Kontur **durch die Wände**: gedimmtes **Messing-Gelb**
  für den Helden, **galvanisches Blau** für mechanische Gegner, **blutrot** für
  biologische Gegner.

## 1.4 Welt-Maßstab & Exploration
* **Dimensionen:** zusammenhängende, nahtlose **3D-Open-World, 2000 × 2000 Meter**
  (Godot Spatial Units), mit Streaming/LOD statt harter Kartenwechsel.
* **Reise-Metrik:** Laufgeschwindigkeit **4,7 m/s**; ein durchgehender diagonaler Sprint
  über die vollständig erkundete Welt dauert rund **5 Minuten** Echtzeit-Fußweg.
* **Fog of War:** volumetrisches Nebelsystem; Bewegung schneidet in Echtzeit Pfade in den
  Nebel — basierend auf der **3D-Sichtlinie (Line-of-Sight)** des Spielers.
* **Eingebettete Bereiche:** Rustwater (Township), Fraktionsbasen (Fort Freedom, Sektor 01,
  Rogue's Landing) und Dungeons (z. B. die Schrott-Minen) sind Bereiche derselben Welt.
  Konkrete Weltkoordinaten & Sektoren: §1.6; Progressions-Tore: §1.7.

## 1.5 Steuerung (Mobile-First, auch Desktop)
* **Linke Bildschirmhälfte:** dynamischer virtueller Touch-Joystick (erscheint bei
  Berührung), flüssige Bewegung.
* **Rechte Bildschirmhälfte:** großer Angriffs-Button (**Auto-Ziel** auf den nächsten
  Gegner — kein Zielen per Bewegung), Fähigkeiten-Buttons (Spezialschuss, Ausweich-Dash,
  Heiltrank, Säure-Granate, Elektrofeld-Granate) sowie ein Waffen-Umschalter (Schadensart).
* **World-Space-UI:** NPC-Namen und Interaktions-Status als **`Label3D`-Billboards** über
  den Charakter-Meshes.
* **Input-Debouncing:** strikter Software-Debouncer gegen Doppeltipps — verhindert
  duplizierte Dialog-/UI-Instanzen und inkonsistente Zustände.

## 1.6 Weltkoordinaten-System & POI-Layout

Die zusammenhängende 3D-Welt spannt eine Ebene von **2000 × 2000 Metern** (Godot Spatial
Units). Striktes Koordinatensystem, **Ursprung (0,0) in der Südwest-Ecke**:
* **X = West → Ost** (0 … 2000),
* **Y = Süd → Nord** (0 … 2000).

Die Welt ist in **3 Progressions-Sektoren** geteilt, die direkt an die Kampagnen-Akte
gebunden sind. Die Sektorgrenzen sind horizontale Linien (Y-Werte) mit mechanischen/
umweltbasierten Toren (§1.7) — **keine unsichtbaren Wände**.

### 1.6.1 Geografische POI-Master-Tabelle

| Sektor & Akt | POI | Koordinaten (X, Y) | Typ & Kernfunktion |
| :-- | :-- | :-- | :-- |
| **Sektor 1** (Kap. 1–4) | **Rustwater Hub & Basis** | (300, 300) | Zentraler Spieler-Hub / Tycoon-Basis |
| | **Die Schrott-Minen** | (150, 450) | Ressourcen-Dungeon (Schrott & Eisen farmen) — *multilevel* |
| | **Das Rattengestrüpp** | (500, 200) | Frühes Jagdrevier (Zielzone `q_rats`) |
| | **Iron Rail Zugdepot** | (450, 750) | **Hard Gate 1:** Boss-Arena des Kapitel-4-Zugüberfalls |
| **Sektor 2** (Kap. 5–8) | **Fort Freedom** | (200, 1200) | HQ Rebellengilde (Wehr-Festung) |
| | **Sektor 01** | (1700, 1300) | HQ Eiserne Gilde (hochmechanisierte Zone) |
| | **Rogue's Landing** | (950, 950) | HQ Schmugglergilde (versteckter Schwarzmarkt-Canyon) |
| | **Alchemie-Raffinerie** | (1000, 1450) | **Hard Gate 2:** Smog-Barriere / Nadelöhr |
| **Sektor 3** (Kap. 9–12) | **Goliath-Testgelände** | (600, 1750) | High-Level-Open-World (Elite- & Goliath-Spawns) |
| | **Schmelzöfen von Vulcan** | (1400, 1800) | Endgame-Ressourcen-Dungeon (legendäre Materialien) — *multilevel* |
| | **Das Eiserne Herz (HQ)** | (1000, 1950) | **Finaler Dungeon:** Kern des Iron-Rail-Konzerns — *multilevel* |

### 1.6.2 Dungeon-Struktur (Multilevel, verbindlich)
Alle als *multilevel* markierten POIs (Schrott-Minen, Schmelzöfen von Vulcan, Das Eiserne
Herz; die Zugdepot-Arena ist einstufig) bestehen aus **mehreren, absteigenden Ebenen**
(Floors). Der Spieler steigt über einen **Abstiegs-Schacht / Lastenaufzug** am Ende einer
Ebene tiefer; ein Aufzug/Ausgang führt zurück an die Oberfläche.

* **Tiefen-Skalierung:** Mit jeder Ebene steigen Gegner-Level, -Leben, -Panzerung und
  Pack-Dichte; tiefere Ebenen haben einen höheren Elite-Anteil. (Backend: `CombatTarget.
  from_type(type, { "depth": n })`.)
* **Beute-Skalierung:** Kisten-Tier und Ausrüstungs-Seltenheits-Bias steigen mit der
  Tiefe. Zwischen-Ebenen tragen ggf. einen **Mini-Boss**; die **tiefste Ebene** hält stets
  einen **einzigartigen, benannten Boss** (bzw. Superboss) plus einen reichen Cache.
* **Ebenen-Nebel:** Der volumetrische Fog of War wird **pro Ebene neu gesetzt**.
* **Wiedereinstieg:** Checkpoint am **Eingang der aktuellen Ebene** (kein Rückwurf zum
  Dungeon-Start beim Ausknocken).
* **Prozedural + handgesetzt:** Ebenen werden prozedural aus handgebauten 3D-Modulen
  zusammengesetzt; feste Anker (Boss-Arena, Schacht, Schatzkammer) sind garantiert.

> **Prototyp-Stand:** Die **Schrott-Minen** sind im Web-Prototyp als **3 absteigende
> Ebenen** umgesetzt (`dungeon1` → `dungeon2` → `dungeon3`). Abstieg per 🕳️-Portal,
> Aufstieg per 🪜-Portal, aus der Tiefe zusätzlich ein 🚪-Fluchtschacht zur Wüste.
> Tiefen-Skalierung: Gegner-HP ×`(1 + (Tiefe−1)·0.5)` (Ebene 1/2/3 = 1.0/1.5/2.0) und
> steigende Pack-Dichte/Elite-Zahl. Der **Superboss „Minen-Titan"** wartet **nur** auf der
> tiefsten Ebene und skaliert mit der Tiefe (`SUPERBOSS_MULT + (Tiefe−1)` → Ebene 3 = 6×
> Boss-HP, 4200 HP) plus reichem Beute-Cache.

## 1.7 Progressions-Gating & Umwelt-Barrieren
Narrativer Sog ohne immersionsbrechende unsichtbare Wände — stattdessen mechanische,
umweltbasierte und fraktionsbasierte Tore.

### 1.7.1 Tor Sektor 1 → 2: Die Iron-Rail-Sprengtore (Y = 800)
* **Barriere:** Die Nordgrenze von Sektor 1 ist durch eine massive, befestigte, gepanzerte
  Schienen-Mauer des Konzerns vollständig abgeriegelt.
* **Logik-Gate:** Die mechanischen Sprengtore sind **hart per Code verriegelt**. Einziger
  Durchbruch: Abschluss von **Kapitel 4 (Der Zugüberfall)**. Mit dem Sieg über den Zug-Boss
  **kracht der gekaperte Panzerzug physisch durch die Sprengtore** und öffnet die dauerhafte
  Transitroute nach Sektor 2 (`current_chapter >= 5`).

### 1.7.2 Tor Sektor 2 → 3: Die alchemistische Smog-Linie (Y = 1500)
* **Barriere:** Der gesamte Nordhorizont zum Industriekern ist von einer dichten, giftig-
  grünen Wolke aus überdrucktem Kühlmittel und alchemistischem Abgas erstickt — Quelle ist
  die **Alchemie-Raffinerie (1000, 1450)**.
* **Logik-Gate:** Betritt der Spieler die Zone **ohne Schutz**, tickt ein **tödlicher
  Umwelt-DOT** sein Leben **innerhalb von 3 Sekunden auf 0**.
* **Auflösungs-Mechanik:** Um das Umwelt-Tor zu passieren, investiert der Spieler seine
  angesammelten **Tycoon-Ressourcen** in Rustwater und baut das **Raffinerie-/Labor-Gebäude
  auf Stufe 3** aus. Das schaltet das **„Alchemie-Filter"-Upgrade** für das mechanische
  Chassis frei, das den Umweltschaden **vollständig neutralisiert** und den sicheren
  Zutritt zum Endgame von Sektor 3 gewährt.
* **Design-Abhängigkeit:** Das hierfür referenzierte „Raffinerie/Labor"-Gebäude ist im
  Tycoon-Roster (§2.2) als eigenständiges Gebäude bzw. als Umwidmung der Destille zu
  ergänzen; das Alchemie-Filter-Upgrade ist ein Chassis-Mod mit Freischalt-Bedingung
  „Gebäudestufe ≥ 3".

### 1.7.3 Dynamisches Fraktions-Feindseligkeits-Gating (Sektor 2)
* **Logik-Gate:** Mit der Gildenwahl in Kapitel 5 (`chosen_guild != null`) aktualisieren die
  Fraktionsbasen ihre **Feindseligkeits-Flags** in der Engine.
* **Auswirkung:** Verbündet sich der Spieler mit den **Rebellen**, löst das Annähern an die
  Wachen von **Sektor 01 (1700, 1300)** sofort **automatisches Geschützturm-Feuer** und
  schwere mechanische Verstärkungs-Aggro aus. Umgekehrt wird bei Wahl der **Eisernen Gilde**
  **Fort Freedom** zur aktiven Feind-Kampfzone — friedliche Interaktionen sind dann nur noch
  auf dem gewählten Pfad möglich.

---

# 2. KERN-ZUSTAND & TOWNSHIP-MECHANIK

## 2.1 Die zustandsgesteuerte UI-Regel: `is_revealed`
Der globale Boolean `is_revealed` steuert **die gesamte Darstellung von Begriffen,
Beschriftungen und Werten**. Er kippt einmalig am Ende von Kapitel 4 (Train-Raid-Reveal)
von `false` auf `true` und bleibt dann dauerhaft `true`.

* **`is_revealed = false` (Fleisch-Illusion):** Der Held hält sich für einen Menschen.
  Die UI spricht menschliche Sprache — Heilung, Ausdauer, Trank, „verarzten".
* **`is_revealed = true` (mechanische Wahrheit):** Die Illusion bricht. Dieselben Elemente
  morphen zu mechanischen Steampunk-Datenströmen — Kühlmittel, Kesseldruck,
  Chassis-Reparatur. Zusätzlich schaltet der Reveal **Körper-Modifikationen** und
  **fortgeschrittene Armaturen** frei (siehe §7).

**Verbindliche Begriffstabelle (`TERMS`, `[vor Reveal, nach Reveal]`):**

| Schlüssel | `is_revealed = false` | `is_revealed = true` |
| :-- | :-- | :-- |
| `potion`  | Kaktus-Schnaps | Synthetisches Kühlmittel |
| `stamina` | Ausdauer | Kesseldruck |
| `heal`    | verarzten | Chassis flicken |

Implementierungsregel: **jede** menschlich klingende Beschriftung durchläuft die
Auflösung `T(key) = TERMS[key][is_revealed ? 1 : 0]`. Neue Begriffe werden ausschließlich
über diese Tabelle eingeführt, nie hartkodiert.

## 2.2 Stadt-Gebäude: Primär Aufträge & Handel, Wirtschaft als Add-on
**Design-Leitsatz:** Die Gebäude der Township sind **kein reines Wirtschaftssystem**. Ihre
**Primärfunktion** ist es, **Aufträge zu starten** oder **Handel zu treiben**. Das
Tycoon-/Einkommens-System ist ein **optionales Investitions-Add-on** für Spieler mit
Gold-Überschuss — es ergänzt die Primärfunktion (bessere Kopfgelder, günstigere Waren),
ersetzt sie aber nicht und ist nie die Haupt-Interaktion.

| Gebäude | Rolle (primär) | Primär-Aktion | Investitions-Add-on (sekundär) |
| :-- | :-- | :-- | :-- |
| `saloon` Gatling-Saloon | **Auftragsbrett** | Wiederholbares **Kopfgeld** annehmen/abholen (Gold + XP); Umfang/Belohnung skalieren mit der Saloon-Stufe | Passives Einkommen; höhere Stufe = größere Kopfgelder |
| `forge` Eiserne Schmiede | **Handelsposten** | **Handeln** — öffnet den Händler (Materialien & Ausrüstung kaufen/verkaufen) | Passives Einkommen |
| `distillery` Mondschein-Destille | **Vorratslager** | **Vorrat** — Tränke kaufen (Preis sinkt je Stufe) | Passives Einkommen; höhere Stufe = günstigere Tränke |

Auch der **Händler** ist ein aktiver Handelsknoten: Er **verkauft** ein pro Basis
persistentes **Warenlager an Ausrüstung** (Qualität nach Basis-Tier gestaffelt) und kauft
Beute an — Handel ist damit beidseitig, nicht nur Verkauf.

### Wirtschafts-Tick (Add-on)
Das optionale Einkommen der Township läuft auf einem **eigenständigen
Hintergrund-Intervall-Tick** (1 Sekunde), der **ausschließlich während der aktiven
Spielzeit** feuert. Er ist entkoppelt von Kampf, Kapitel- oder Gildenwahl, aber an die
laufende In-Game-Simulation gebunden.

* **In-Game-Generierung:** Einkommen/Sek = Σ (`gebäude.level × incomePer`) über alle
  Gebäude — gebunden an die In-Game-Simulationsuhr.
* **Simulations-Bedingung:** Der Tick feuert in **jeder aktiven Gameplay-Sekunde** (im
  Kampf, im Dialog, im Menü), **pausiert jedoch vollständig**, sobald das Spiel beendet,
  minimiert oder pausiert wird.
* **Kein Offline-Ertrag:** Es findet **keinerlei** passive Progression oder Gold-
  Erwirtschaftung im Hintergrund statt, während der Spieler offline ist. Beim Neustart
  läuft die Wirtschaft exakt an dem Punkt und mit dem Kontostand weiter, an dem
  gespeichert wurde — es wird **weder verstrichene Realzeit geprüft noch rückwirkend Gold
  gutgeschrieben**.
* Kampagnen-Entscheidungen und Gildenzugehörigkeit verändern **niemals** direkt diesen
  Tick (nur indirekt über freigeschaltete Boost-Quests, §5.4).

**Township-Gebäude (Ausbaustufen; Kosten = `baseCost × (level + 1)`):**

| ID | Name | Icon | Basiskosten | Einkommen/Stufe/Sek | Max-Stufe |
| :-- | :-- | :-: | --: | --: | --: |
| `saloon`     | Gatling-Saloon      | 🍺 | 100 | +1 | 5 |
| `forge`      | Eiserne Schmiede    | 🔨 | 220 | +2 | 5 |
| `distillery` | Mondschein-Destille | 🥃 | 400 | +4 | 5 |

**Progressions-Kopplung (§1.7.2):** Zusätzlich zum passiven Einkommen dient ein
**Raffinerie-/Labor-Gebäude** als Freischalt-Bedingung für das Endgame: Ausbau auf
**Stufe 3** schaltet das Chassis-Upgrade **„Alchemie-Filter"** frei, das die tödliche
Smog-Linie (Y = 1500) neutralisiert. Dieses Gebäude ist als eigener Eintrag zu ergänzen
oder der Destille zuzuordnen (offene Design-Entscheidung).

## 2.3 Master-State-Management-Schema
Die vollständige Laufzeit-Zustandsstruktur. Persistente Felder werden zusätzlich im
Speicher-Schema (unten) serialisiert.

```json
{
  "map": "overworld",
  "cols": 80, "rows": 80,
  "bounds": { "minX": 0, "maxX": 0, "minY": 0, "maxY": 0 },
  "explored": { "<mapId>": ["<c,r>", "..."] },
  "discovered": ["<stationId>", "..."],
  "playerTile": { "c": 0, "r": 0 },

  "isRevealed": false,
  "currentChapter": 1,
  "chosenGuild": null,

  "level": 1,
  "xp": 0,
  "hp": 100, "maxHp": 100,

  "gold": 0,
  "inventory": { "schrott": 0, "zahnrad": 0, "dampfkern": 0 },
  "stash":     { "schrott": 0, "zahnrad": 0, "dampfkern": 0 },

  "weapon": "karabiner",
  "weaponLvl": { "karabiner": 0, "voltgun": 0, "saeure": 0, "brenner": 0 },
  "upgrades": { "damage": 0, "firerate": 0, "hp": 0, "speed": 0, "regen": 0, "magnet": 0 },

  "equip": {
    "helmet": null, "armor": null, "weapon": null, "gadget": null, "boots": null,
    "plate1": null, "plate2": null, "plate3": null
  },
  "gearBag": [
    {
      "uid": 1, "slot": "weapon", "rarity": "epic", "req": 7, "big": true,
      "icon": "🔫", "name": "Dampfbetriebener Schwere Waffe",
      "stat": { "key": "damage", "val": 24 }
    }
  ],

  "potions": 3,
  "cd": { "spread": 0, "dash": 0, "acid": 0, "shock": 0 },

  "economy": { "saloon": { "level": 0 }, "forge": { "level": 0 }, "distillery": { "level": 0 } },

  "quests":    { "<questId>": "available | active | done" },
  "questBase": { "<questId>": 0 },

  "boss": null,
  "ctx":  null,

  "flags_ui": {
    "inventoryOpen": false, "storeOpen": false, "workshopOpen": false,
    "tycoonOpen": false, "stashOpen": false, "travelOpen": false,
    "fullMapOpen": false, "dialogueOpen": false, "revealPlaying": false,
    "transitioning": false
  }
}
```

**Persistentes Speicher-Schema (`localStorage`, `SAVE_KEY = "rustlead_save_v1"`):**

```json
{
  "gold": 0,
  "economy": { "saloon": { "level": 0 }, "forge": { "level": 0 }, "distillery": { "level": 0 } },
  "kills": 0,
  "inv": { "schrott": 0, "zahnrad": 0, "dampfkern": 0 },
  "stash": { "schrott": 0, "zahnrad": 0, "dampfkern": 0 },
  "revealed": false,
  "chapter": 1,
  "guild": null,
  "level": 1, "xp": 0,
  "weapon": "karabiner",
  "weaponLvl": { "karabiner": 0, "voltgun": 0, "saeure": 0, "brenner": 0 },
  "upgrades": { "damage": 0, "firerate": 0, "hp": 0, "speed": 0, "regen": 0, "magnet": 0 },
  "equip": { "helmet": null, "armor": null, "weapon": null, "gadget": null, "boots": null, "plate1": null, "plate2": null, "plate3": null },
  "gearBag": [],
  "quests": {}, "questBase": {},
  "discovered": ["<stationId>"],
  "explored": { "<mapId>": ["<c,r>"] }
}
```
**Kein Zeitstempel:** Das Save-Schema enthält bewusst **kein** `t`/Zeitstempel-Feld. Der
Wirtschaftszustand ist vollständig durch die aktuellen **Gebäudestufen** und den aktiven
In-Game-Tick definiert (§2.2). Beim Laden wird **keine** verstrichene Realzeit geprüft und
**kein** rückwirkendes Gold vergeben.

---

# 3. DIE 12-KAPITEL-KAMPAGNE

**Prämisse.** Der Protagonist ist ein menschlicher Geist, den der **Iron-Rail-Konzern**
in ein eisernes Kriegs-Chassis verpflanzt hat. Sensor-Illusionen gaukeln ihm einen
Körper aus Fleisch und eine lebende Familie vor. Er glaubt, ein Mensch zu sein — bis der
Reveal in Kapitel 4 alles zerbricht. `is_revealed` steuert dabei die gesamte Wahrnehmung.

## AKT I — DIE FLEISCH-ILLUSION (Kapitel 1–4) · `is_revealed = false`

**Kapitel 1 — „Staub & Blei".**
Tutorial und Weltanschluss. Der Held erwacht am Rand der Wüste, scheinbar ein Mensch mit
Kopfschmerzen und lückenhafter Erinnerung. Er erreicht **Rustwater**, lernt Bewegung,
Auto-Ziel-Kampf, Loot-Magnet und die ersten Township-Funktionen (Händler, Werkstatt,
Truhe). Erste Kopfgelder von Mabel führen ihn in die Wüste. Menschliche UI durchgehend.

**Kapitel 2 — „Sand im Räderwerk".**
Der Held verdient sich Ruf, sammelt Schrott und Zahnräder, baut das erste
Einkommens-Gebäude (Gatling-Saloon) und erkundet die nähere Wüste. Erste Begegnungen mit
**Konzern-Patrouillen** deuten an, dass der Iron-Rail-Konzern die Region unter Kontrolle
hält. Kleinere Ungereimtheiten: Der Held wird nie müde, hat nie Hunger — abgetan als
„zähe Konstitution".

**Kapitel 3 — „Die Mine".**
Der erste Dungeon (die **Mine**) mit dem Superboss **Minen-Titan** als optionalem, aber
lohnendem Höhepunkt. Der Held sucht dort nach Antworten über seine Herkunft und findet
erste verschlüsselte Konzern-Kinetoskop-Rollen, die er (noch) nicht deuten kann.
Spannungsaufbau: Wer sind die Rebellen, wer der Konzern?

**Kapitel 4 — „Der Zugüberfall" · REVEAL.**
Höhepunkt von Akt I. Der Held stellt sich einem gepanzerten Konzern-Boss auf einem
fahrenden Zug. Die **hydraulische Ramme** des Bosses schleudert ihn durch die Waggonwand;
ein **Spiegel zerbricht** vor seinem Gesicht — er starrt in sein Spiegelbild und sieht:
**keinen Mann aus Fleisch, sondern einen rauchenden, einäugigen Stahl-Schädel, Zahnräder,
kochendes Öl.** Die Reveal-Sequenz spielt (`revealPlaying`), danach kippt
**`is_revealed → true`**, `currentChapter` springt auf 5. Ab jetzt: mechanische UI,
Körper-Mods & Spezialwaffen freigeschaltet, Konzern-Automaten treten häufiger auf.

> **Reveal-Sequenz (`REVEAL_LINES`):**
> 1. „Die hydraulische Ramme des Bosses schleudert dich durch die Waggonwand."
> 2. „Glas splittert. Ein Spiegel zerbricht vor deinem Gesicht."
> 3. „Du starrst in dein Spiegelbild —"
> 4. „kein Mann aus Fleisch. Ein rauchender, einäugiger STAHL-SCHÄDEL. Zahnräder. Kochendes Öl."
> 5. „SYSTEM_REBOOT … SENSOR_ILLUSION_DESYNC … PROTOKOLL: WAHRHEIT"
> 6. „Du bist keine Kreatur aus Fleisch. Du bist eine Maschine."

## AKT II — DIE KÜNSTLICHE FAMILIE (Kapitel 5–8) · `is_revealed = true`

**Kapitel 5 — „Erwacht" · Gildenwahl.**
Der Held verarbeitet die Wahrheit. Alle drei Fraktionen werben um den „wandelnden
Stahlkessel". Der Spieler **wählt eine Gilde** (Rebellen, Eiserne Gilde, Schmuggler) und
nimmt deren erste Fraktions-Quest an (Kapitel-5-Auftrag, siehe §4). Motiv des Helden:
Er will zu **seiner Familie** — deren Kinetoskop-Botschaften er weiter empfängt.

**Kapitel 6 — „Kupfer & Kesseldruck".**
Ausbau der eigenen Schlagkraft: Werkstatt-Körper-Mods, Waffen-Armaturen, erste epische
Ausrüstung. Der Held nutzt die Township-Wirtschaft, um Gilden-Operationen zu finanzieren.
Erste Hinweise, dass die „Familien-Botschaften" technische Artefakte enthalten.

**Kapitel 7 — „Das flackernde Bild".**
Der Held spürt eine Kinetoskop-Relaisstation auf. Die Botschaften seiner Familie sind zu
perfekt, zu wiederholt. Ein Techniker (gilden-abhängig) entdeckt Manipulations-Spuren —
die Bilder sind **künstlich zusammengesetzt** (alchemistisch-optische Fälschung; das
Steampunk-Äquivalent eines Deepfakes).

**Kapitel 8 — „Die Wahrheit im Kessel" · ZWEITER TWIST.**
Der Kapitel-8-Fraktions-Auftrag (§4) enthüllt aus Sicht der gewählten Gilde denselben
Kern: **Die Familie des Helden ist seit Jahren tot.** Die „Botschaften" waren
**gefälschte Kinetoskop-Projektionen** des Iron-Rail-Konzerns — ein Mittel, den
Stahl-Soldaten gefügig und loyal zu halten. Der emotionale Boden bricht weg; aus Suche
nach Familie wird kalter Zorn. `currentChapter → 12` wird durch Abschluss freigeschaltet.

## AKT III — DER EISERNE KREUZZUG (Kapitel 9–12) · `is_revealed = true`

**Kapitel 9 — „Kriegsmaschine".**
Der Held rüstet zum offenen Krieg gegen den Konzern. Elite-Automaten (Goliaths) und
Schützenlinien aus Konzern-Konstrukten bevölkern die Wüste. Der Spieler perfektioniert
das Zusammenspiel der Schadensarten (Galvanik gegen Automaten, Säure gegen Panzerung).

**Kapitel 10 — „Sabotage".**
Gezielte Schläge gegen die Infrastruktur der Iron Rail: Ölpipelines, Relaisstationen,
Waffenlager. Die Township floriert oder leidet je nach Fraktionslinie; Boost-Quests (§5.4)
verschieben die Wirtschaft. Der Konzern schlägt mit schweren Ernter-Einheiten zurück.

**Kapitel 11 — „Die letzte Bastion".**
Vorbereitung auf den Endschlag. Der Held sammelt Verbündete (oder Söldner/Schmuggler,
gilden-abhängig), maximiert Ausrüstung (legendäre Teile, Stufe 11+) und stellt sich den
stärksten Wächtern der Konzern-Zentrale.

**Kapitel 12 — „Sturm auf die Iron Rail" · FINALE.**
Der Kapitel-12-Fraktions-Auftrag (§4) ist das jeweilige Endgefecht. Je nach Gilde
unterschiedlicher Ausgang:
* **Rebellen:** Das Monopol fällt, die Arbeiter sind frei — ein neuer Anfang für Rustwater
  ohne Ketten.
* **Eiserne Gilde:** Der Konzern siegt und zementiert seine Ordnung; der Held ist sein
  treuestes Chassis, Rustwater läuft „wie ein geöltes Getriebe".
* **Schmuggler:** Weder Rebellen noch Konzern gewinnen — der Held und die Schmuggler
  kaufen sich aus dem Krieg heraus; Rustwater gehört fortan denen, die zahlen können.

---

# 4. FRAKTIONS-QUEST-MATRIX & NPC-NETZWERK

## 4.1 Fraktionen & Wahl-Logik
Drei Fraktionen; Beitritt **erst nach dem Reveal** möglich. Die Wahl ist **exklusiv** —
eine gewählte Gilde schließt die beiden anderen dauerhaft aus (deren Botschafter weisen
den Helden ab). Der Fraktions-Quest-Strang schaltet sich **kapitelweise** frei
(Kapitel 5 → 8 → 12); Abschluss eines Ketten-Auftrags hebt `currentChapter` auf das
nächste Kapitel.

| Fraktion (`chosenGuild`) | Basis | Botschafter | Ethos |
| :-- | :-- | :-- | :-- |
| **Rebellengilde** (`rebels`)   | Fort Freedom    | Gideon Cross      | Freiheit der Arbeiter, Sturz des Konzern-Monopols |
| **Eiserne Gilde** (`corp`)     | Sektor 01       | Aufseher Quentin  | Ordnung = Profit; Effizienz über alles |
| **Schmugglergilde** (`smugglers`) | Rogue's Landing | „Slick" Sterling | Reichtum kennt keine Fahnen |

## 4.2 Choice-Impact-Matrix (Kapitel 5 / 8 / 12)

| Kapitel | Rebellen (Gideon) | Eiserne Gilde (Quentin) | Schmuggler (Slick) |
| :-- | :-- | :-- | :-- |
| **5** | **Sand im Getriebe** — 12 Konzern-Schergen ausschalten · 250 💰 + Dampfkern | **Streikbrecher** — 12 Rebellen-Saboteure eliminieren · 250 💰 + Dampfkern | **Das Sumpf-Gold** — 3 Dampfkerne sammeln · 300 💰 |
| **8** | **Der Kinetoskop-Betrug** — 18 Projektoren-Wächter zerlegen · 500 💰 + Dampfkern → *„Deine Familie ist tot; alles nur Bilder."* | **Archiv-Säuberung** — 18 Diebe belastender Kinetoskop-Rollen vernichten · 500 💰 + Dampfkern → *„Deine Familie war ein Konstrukt aus Licht und Linse."* | **Heiße Ware, heiße Wahrheit** — 6 Dampfkerne besorgen · 700 💰 → *„Deine Familie ist längst Staub."* |
| **12** | **Sturm auf die Iron Rail** — 30 Elite-Chassis niederkämpfen · 1200 💰 + Dampfkern · *Monopol fällt* | **Der eiserne Frieden** — 30 Aufständische zerschlagen · 1200 💰 + Dampfkern · *Ordnung siegt* | **Der letzte Deal** — 10 Dampfkerne · 1600 💰 · *Freikauf aus dem Krieg* |

**Quest-IDs & Mechanik (verbindlich):**
* Rebellen: `q_rebels5` (kill 12), `q_rebels8` (kill 18), `q_rebels12` (kill 30).
* Eiserne Gilde: `q_corp5` (kill 12), `q_corp8` (kill 18), `q_corp12` (kill 30).
* Schmuggler: `q_smug5` (collect 3 dampfkern), `q_smug8` (collect 6), `q_smug12` (collect 10).
* Freischalt-Gate je Auftrag: `chapter` (5/8/12). Abschluss setzt `advanceTo`
  (5→8, 8→12). Kill-Fortschritt = `kills − questBase[id]`; Collect-Fortschritt =
  Inventarbestand, wird bei Abgabe abgezogen.

## 4.3 Hub-NPC-Profile

### Rustwater (neutrale Township)
* **Mamma „Rusty" Mabel** — Saloon-Wirtin. Vor Reveal: mütterlich, warnt vor der Wüste,
  spendiert Kaktus-Schnaps. Nach Reveal: erkennt den Automaten, reicht statt Schnaps eine
  Dose Schmieröl. **Quest `q_bounty` „Kopfgeld: Wegelagerer"** — 8 Wegelagerer besiegen ·
  120 💰 + Zahnrad.
* **Silas „Kupferauge" Finch** — einäugiger Schmied mit Kupferlinse. Braucht Baumaterial
  für den Stadtausbau; nach Reveal bietet er Chassis-Panzerplatten. **Quest `q_scrap`
  „Baumaterial: Schrott"** — 12 Schrott sammeln · 90 💰.
* **Doktor „Doc" Aris** — Feldarzt. Nach Reveal klopft er auf das Stahl-Chassis: „Bei dir
  spar ich mir das Verarzten." **Quest `q_rats` „Plage: Schrott-Ratten"** — 5 Ratten
  ausschalten · 70 💰 + Heiltrank.

### Fort Freedom (Rebellengilde)
* **Gideon Cross** — narbiger Anführer, kalter Blick. „Wir brechen das Monopol des
  Konzerns — oder sterben beim Versuch." Botschafter & Quest-Geber der Rebellen-Kette.
  Basis besitzt Händler (`store`) und Truhe (`stash`) sowie eine Funk-/Zugstation.

### Sektor 01 (Eiserne Gilde)
* **Aufseher Quentin** — kalter Mann in makelloser Uniform. „Ordnung ist Profit. Profit
  ist Ordnung." Botschafter & Quest-Geber der Konzern-Kette. Basis mit Ausgabe (`store`),
  Truhe (`stash`), Kontrollstation.

### Rogue's Landing (Schmugglergilde)
* **„Slick" Sterling** — Grinsen unter der Gaslampe. „Alles hat seinen Preis, Freund. Auch
  Schweigen." Botschafter & Quest-Geber der Schmuggler-Kette. Basis mit Hehler (`store`),
  Truhe (`stash`), Wett-Station.

**NPC-Interaktion (technisch):** World-Space-`Label3D` über dem Mesh; Annäherung zeigt den
Interaktions-Prompt; Dialog mit strengem Anti-Doppeltipp-Debouncer; Quest-Marker über dem
Kopf (⚙️ verfügbar, ⏳ aktiv, ❗ abgabebereit, 🤝 Gilde beitretbar).

---

# 5. MODULARES MINI-QUEST-SYSTEM (GRIND & BOOSTS)

Wiederholbare, prozedural instanziierte Aufträge, die den Kern-Loop tragen und
Progression (Gold, XP, Loot, Wirtschafts-Boosts) speisen. Vier Kategorien.

## 5.1 Suchen & Retten (Search & Rescue)
* **Fantasy:** Ein Siedler, Arbeiter oder Späher ist in einem umkämpften Sektor
  gestrandet; der Held muss ihn erreichen und lebend heraushol­en.
* **Mechanik:** Ziel-Marker in einem Gefahrengebiet; beim Erreichen schließt sich ein
  Eskort-/Verteidigungs-Fenster (Wellen von Gegnern, während der Gerettete folgt) oder
  ein einfacher Rückweg. Optionaler Timer.
* **Belohnung:** Gold + XP, gelegentlich Ausrüstung; bei Township-relevanten Geretteten
  ein kleiner, temporärer Wirtschafts-Impuls (§5.4).
* **Fehlschlag:** Stirbt der Gerettete (durch Gegner), gilt der Auftrag als gescheitert.

## 5.2 Transport & Logistik (mit Instabilitäts-Tracker)
* **Fantasy:** Volatile Fracht (z. B. **Dampfkerne**, alchemistische Gemische) von A nach
  B bringen, ohne dass sie hochgeht.
* **Instabilitäts-Tracker:** Ein Fracht-Instabilitätswert (0–100 %) steigt kontinuierlich
  über Zeit und **sprunghaft bei jedem Treffer**, den der Held einsteckt. Erreicht er
  100 %, **detoniert die Fracht** (Flächenschaden am Helden) und der Auftrag scheitert.
  Gegenmaßnahmen: schnelle, direkte Routen; Ausweich-Dash statt Treffer kassieren;
  optionale „Kühlmittel"-Ablasspunkte auf der Strecke senken den Wert.
* **Belohnung:** skaliert mit Restdistanz-Effizienz und **verbleibender Stabilität**
  (weniger Instabilität = mehr Gold/XP).
* **Design-Ziel:** belohnt sauberes, ausweichlastiges Fahren statt Dauer-Tanken.

## 5.3 Kopfgeld (Bounty) — benanntes Elite-Ziel im Saloon
* **Fantasy:** Ein benannter Gesetzloser (z. B. „Dynamit-Dolores", „Der Schakal") wird im
  **Gatling-Saloon** (Auftragsbrett, §2.2) zur Fahndung ausgeschrieben.
* **Mechanik (kein Kill-Zähler):**
  1. **Annehmen** am Saloon → ein **benanntes Kopfgeld-Ziel** wird erstellt (Belohnung
     skaliert mit Saloon-Stufe: `BOUNTY_BASE_GOLD + level·30`).
  2. Beim Betreten der **Wüste** erscheint das Ziel als **markierter Elite-Boss**
     (🎯-Marker über dem Kopf, ~1.8× Boss-HP, mit Gefolge), an zufälliger Position abseits
     des Spielers. Ein **HUD-Tracker** zeigt Name und Restdistanz. Es existiert immer nur
     **ein** aktives Ziel.
  3. **Erlegen** setzt das Kopfgeld auf „fällig". Der Spieler **kassiert die Belohnung**
     (Gold + XP ≈ 0.6× Gold) zurück im Saloon; danach ist ein neues Kopfgeld annehmbar.
* Zusätzlich droppt das Ziel (als Elite) ein Beute-Bündel (Loot-Kisten) und Ausrüstung.
* Der Kopfgeld-Zustand persistiert; das alte Kill-Zähler-Format wird beim Laden verworfen.

## 5.4 Tycoon-Booster (mit wirtschaftlichen Kettenreaktionen)
* **Fantasy:** Aufträge, die die Township direkt stärken — Rohstoff-Lieferungen,
  Schutz von Karawanen, Anwerben von Fachkräften.
* **Mechanik:** Abschluss gewährt einen **temporären Einkommens-Multiplikator** oder
  senkt Ausbaukosten eines Gebäudes für begrenzte Zeit.
* **Wirtschaftliche Kettenreaktion (Ripple):** Booster wirken **nicht isoliert** — ein
  Boost auf den **Saloon** hebt zusätzlich die Nachbar-Produktion (Schmiede) leicht an
  („mehr Kundschaft ⇒ mehr Aufträge"); ein Boost auf die **Schmiede** senkt kurzfristig
  Werkstatt-/Ausbaukosten; ein Boost auf die **Destille** erhöht den Verkaufswert von
  Loot beim Händler. So entsteht ein kleines Wirtschafts-Netz statt additiver
  Einzelboni. **Wichtig:** Booster verändern **Parameter** des asynchronen Tycoon-Ticks
  (§2.2), nie den Tick-Mechanismus selbst.

**Gemeinsame Struktur aller Mini-Quests:** `{ id, kategorie, kind: 'kill'|'collect'|'escort'|'transport'|'boost', ziel, count, timer?, instabilität?, rewardGold, rewardXp, rewardItem?, rippleEffect? }`.

---

# 6. KAMPF-DESIGN & CODE-TEMPLATES

## 6.1 Die 4 Kern-Schadensarten
| Schadensart | Farbe/VFX | Effektiv gegen | Ineffektiv gegen | Status-Effekt |
| :-- | :-- | :-- | :-- | :-- |
| **Kinetisch** (`KINETIC`) | Messing-Gelb / Mündungsfeuer | Biologisch | schwere Panzerung | **Verbluten** (DOT, organisch) |
| **Galvanisch** (`GALVANIC`) | Blau / Blitz-Funken | Mechanisch | Biologisch (Isolierung) | **Kurzschluss** (Stun 4 s) |
| **Alchemistisch** (`ALCHEMICAL`) | Säure-Grün / Korrosions-Dampf | Panzerung/Rüstung | (Basis) | **Korrosion** (Rüstungs-Debuff) |
| **Thermisch** (`THERMAL`) | Orange / dynamisches Feuer | Biologie & Leichtbau-Automaten | schwere Automaten (Goliath) | **Überhitzung** (DOT) |

## 6.2 Exakte Wechselwirkungs-Matrix
Zielklassen: **`BIOLOGICAL`** (blutend, verwundbar) und **`MECHANICAL`** (gepanzert,
schmerzfrei). Reihenfolge der Faktoren wie in der Engine implementiert.

**Gegen `MECHANICAL`:**
* `GALVANIC`  → Schaden × **2.5**; 40 % Chance auf `SHORT_CIRCUIT_STUN`.
* `KINETIC`   → `max(1, dmg − armor)`; bei front-immunen Einheiten (Goliath) **0**,
  solange `armor > 0`.
* `THERMAL`   → Goliath × **0.6** (widersteht), sonst × **1.2** (Leichtbau brennt).
* `ALCHEMICAL`→ reduziert `armor` um `acidPotency`, löst `ARMOR_CORRODED` aus.

**Gegen `BIOLOGICAL`:**
* `KINETIC`   → Schaden × **1.5**; 33 % Chance auf `BLEEDING_DOT`.
* `GALVANIC`  → Schaden × **0.4** (biologische Isolierung dämpft).
* `THERMAL`   → Schaden × **1.3**; 50 % Chance auf `OVERHEAT/BURN_DOT`.
* `ALCHEMICAL`→ Basisschaden (keine Rüstung vorhanden ⇒ kein Korrosionsbonus).

**Spieler-Verteidigung:** Angelegte Rüstung/Panzerplatten liefern `armor`; eingehender
Schaden wird mit `100 / (100 + armor·9)` multipliziert (steigende, gedeckelte Reduktion).

## 6.3 Code-Template — Damage Calculation Engine
```javascript
// Schadensberechnungs-Engine für "Rust & Lead" (modernes Steampunk-ARPG).
// Reine Funktion: Schadensart × Gegner-Klassifizierung -> {damage, effect, immune}.
const DamageEngine = {
  // Multiplikatoren & Status-Regeln der Wechselwirkungs-Matrix.
  calculate(damageType, target, baseDamage) {
    let dmg = baseDamage, effect = null, immune = false;
    const cls   = target.classification;   // 'BIOLOGICAL' | 'MECHANICAL'
    const armor = target.armorValue || 0;

    if (cls === 'MECHANICAL') {
      if (damageType === 'GALVANIC') {
        dmg *= 2.5;                                   // Automaten: massiver Bonus
        if (Math.random() < 0.40) effect = 'SHORT_CIRCUIT_STUN';
      } else if (damageType === 'KINETIC') {
        dmg = target.frontImmune                      // Goliath-Frontpanzerung
          ? (armor > 0 ? 0 : dmg)                     // Blei prallt ab, bis Säure ätzt
          : Math.max(1, dmg - armor);                 // Panzerung schluckt Blei
      } else if (damageType === 'THERMAL') {
        dmg *= (target.sub === 'goliath') ? 0.6 : 1.2;
      } else if (damageType === 'ALCHEMICAL' && armor > 0) {
        target.armorValue = Math.max(0, armor - (target.acidPotency || 10));
        effect = 'ARMOR_CORRODED';                    // Rüstung zersetzt (für nächste Treffer)
      }
    } else if (cls === 'BIOLOGICAL') {
      if (damageType === 'KINETIC') {
        dmg *= 1.5;                                   // Fleisch: Bonus
        if (Math.random() < 0.33) effect = 'BLEEDING_DOT';
      } else if (damageType === 'GALVANIC') {
        dmg *= 0.4;                                   // biologische Isolierung dämpft
      } else if (damageType === 'THERMAL') {
        dmg *= 1.3;
        if (Math.random() < 0.50) effect = 'OVERHEAT_DOT';
      }
    }

    if (dmg <= 0) immune = true;
    return { damage: Math.max(0, Math.round(dmg)), effect, immune };
  },

  // Anwendung eines Status-Effekts auf ein Ziel (DOT/Stun/Korrosion).
  applyStatus(target, effect, now, acidPotency = 10) {
    if (!target || target.health <= 0) return;
    if (effect === 'SHORT_CIRCUIT_STUN')      target.stunUntil = now + 4000;
    else if (effect === 'BLEEDING_DOT')       target.dot = { type: 'BLEED', dps: Math.max(4, target.maxHealth * 0.04), until: now + 3000 };
    else if (effect === 'OVERHEAT_DOT')       target.dot = { type: 'BURN',  dps: Math.max(5, target.maxHealth * 0.05), until: now + 3000 };
    else if (effect === 'ARMOR_CORRODED')     target.armorValue = Math.max(0, target.armorValue - acidPotency);
  }
};

// Beispiel: Konzern-Wach-Einheit trifft galvanischer Volt-Karabiner.
const corporateAutomaton = { name: 'Sektor-01-Wach-Einheit', classification: 'MECHANICAL',
                             sub: 'konstrukt', armorValue: 15, health: 200, maxHealth: 200 };
const voltKarabiner = { damageType: 'GALVANIC', baseDamage: 40, acidPotency: 0 };
const result = DamageEngine.calculate(voltKarabiner.damageType, corporateAutomaton, voltKarabiner.baseDamage);
// -> { damage: 100, effect: 'SHORT_CIRCUIT_STUN' (40% Chance), immune: false }
```

## 6.4 Code-Template — World Map Encounter System
```javascript
// Encounter-System der offenen Welt: verteilt Gegner, Elite-Bosse, Loot-Kisten
// und (in Dungeons) einen Superboss. Bosse "stehen" in der Welt statt nach Kill-Zähler
// zu spawnen. Nach dem Reveal treten mechanische Automaten häufiger auf.
const EncounterSystem = {
  // Gewichteter Gegner-Pool je nach Reveal-Status.
  pickEnemyType(isRevealed) {
    const pool = isRevealed
      ? [['outlaw', 3], ['fauna', 2], ['revolver', 2], ['konstrukt', 4]]   // Automaten dazu
      : [['outlaw', 4], ['fauna', 3], ['revolver', 2], ['konstrukt', 1]];
    let total = 0; for (const p of pool) total += p[1];
    let x = Math.random() * total;
    for (const p of pool) if ((x -= p[1]) <= 0) return p[0];
    return 'outlaw';
  },

  // Standard-Population einer Kampfzone + verteilte Elite-Bosse mit Gefolge.
  populate(zone, world) {
    const count = Math.min(world.ENEMY_MAX, Math.round(zone.area / world.ENEMY_PER_AREA));
    for (let i = 0; i < count; i++) {
      const pos = zone.randomPoint();
      if (pos.distanceTo(world.player) < world.SAFE_RADIUS) continue;   // Startbereich frei
      world.spawnEnemy(this.pickEnemyType(world.isRevealed), pos);
    }
    // Elite-Bosse stehen verteilt (kein Kill-Zähler) — je mit kleinem Gefolge.
    const elites = zone.elites ?? world.ELITE_PER_ZONE;
    for (let i = 0; i < elites; i++) {
      const pos = zone.randomPoint();
      if (pos.distanceTo(world.player) < world.ELITE_SAFE_RADIUS) continue;
      const boss = world.spawnElite(pos);                              // Boss-Statistik, elite = true
      for (let k = 0; k < 3; k++) world.spawnEnemy(this.pickEnemyType(world.isRevealed), pos.jitter(60));
    }
    // Beute: verstreute Kisten + gebündelte Caches an Spezialorten.
    this.scatterChests(zone, world);
    // Dungeon: ein besonders starker Superboss (4x Boss) wartet.
    if (zone.superboss) world.spawnSuperBoss(zone.superboss, { hpMult: 4, armor: 25, frontImmune: true });
  },

  // Loot-Kisten: Zufalls-Kisten in Kampfzonen + Cache-Bündel (z. B. Mine-Schatzkammer).
  scatterChests(zone, world) {
    for (const cache of (zone.caches || []))
      for (let i = 0; i < cache.count; i++) world.spawnChest(cache.pos.jitter(34), cache.tier || 'rare');
    if (!zone.combat) return;
    const n = Math.round(zone.area / world.CHEST_PER_AREA);
    for (let i = 0; i < n; i++) {
      const pos = zone.randomPoint();
      if (pos.distanceTo(world.player) < world.SAFE_RADIUS) continue;
      world.spawnChest(pos, Math.random() < 0.22 ? 'rare' : 'normal');
    }
  },

  // Tod eines Elite/Superboss: Beute-Bündel (Kisten) + garantierte Ausrüstung + XP;
  // erster Elite-/Boss-Tod vor dem Reveal löst den Kapitel-4-Reveal aus.
  onDefeat(enemy, world) {
    world.dropGold(enemy.pos, enemy.gold);
    world.dropLootFor(enemy);                                          // Material + Ausrüstung nach Tier
    world.gainXp(enemy.isSuperBoss ? 300 : enemy.elite ? 50 : Math.max(3, Math.round(enemy.maxHealth / 11)));
    if (enemy.isSuperBoss || enemy.elite) {
      world.spawnChest(enemy.pos.jitter(40), 'boss');
      world.spawnChest(enemy.pos.jitter(40), 'rare');
      if (!world.isRevealed) world.triggerReveal();                    // Ende Kapitel 4
    }
  }
};
```

---

# 7. ANHANG

## 7.1 Waffen-Loadout (Schadensart-Umschalter)
Karabiner immer verfügbar; die übrigen drei erst **nach dem Reveal** (Steampunk-Armaturen).
| ID | Name | Schadensart | Basis | Feuertakt (ms) | Sonder |
| :-- | :-- | :-- | --: | --: | :-- |
| `karabiner` | Blei-Karabiner | KINETIC | 20 | 200 | immer verfügbar |
| `voltgun`   | Leydener Volt-Karabiner | GALVANIC | 16 | 240 | Anti-Automat |
| `saeure`    | Säure-Sprüher | ALCHEMICAL | 12 | 210 | Säure-Potenz 10 (skaliert mit Level) |
| `brenner`   | Dampf-Brenner | THERMAL | 14 | 170 | schnellster Takt |

Waffen-Armaturen (Werkstatt): pro Waffe +5 Basisschaden/Stufe (max 5); Säure-Sprüher
zusätzlich +2 Säure-Potenz/Stufe.

### 7.1.1 Munition & Energiekristalle (begrenzter Vorrat)
Feuern verbraucht Vorrat — **Dauerfeuer ist nicht möglich**. Zwei Munitions-Pools:

| Typ | Icon | Für | Cap | Start | Preis (Pack) |
| :-- | :-: | :-- | --: | --: | :-- |
| `muni` Munition | 🧨 | Blei-Karabiner (KINETIC) | 180 | 90 | 24 💰 (+30) |
| `kristall` Energiekristalle | 🔷 | Volt / Säure / Brenner (Energiewaffen) | 120 | 45 | 36 💰 (+20) |

* **Verbrauch:** 1 pro Schuss aus dem Pool der getragenen Waffe; bei 0 kein Schuss
  (gedrosselter „nachladen"-Hinweis). Der aktuelle Vorrat steht unter dem Schuss-Button
  (gelb ≤ 10, rot bei 0).
* **Nachschub:** (a) **Gegner-Drops** — meist der getragene Typ, Elite/Boss beide; als
  aufsammelbare Stern-Pickups (Magnet). (b) **Kisten** — Munition/Kristalle automatisch
  als Bonus (wie Gold), Menge nach Truhen-Tier. (c) **Händler** — Nachschub-Kauf beider
  Typen. Vorrat persistiert im Spielstand.

## 7.2 Fähigkeiten & Granaten
* **Spezialschuss (Spread):** Fächer aus 7 Projektilen der aktuellen Schadensart.
* **Ausweich-Dash:** kurze Sprint-Ausweichrolle mit I-Frames.
* **Heiltrank:** stellt Leben her (`T('potion')`-Begriff je nach Reveal).
* **Säure-Granate** *(nach Reveal)*: Flächen-Korrosion — garantierter `ARMOR_CORRODED`
  im Radius (knackt Goliath-Panzerung).
* **Elektrofeld-Granate** *(nach Reveal)*: Flächen-`SHORT_CIRCUIT_STUN` — legt ganze
  Konzern-Schützenlinien für 4 s lahm.

## 7.3 Gegner-Roster
| Typ | Klasse | Verhalten | Panzerung | Besonderheit |
| :-- | :-- | :-- | --: | :-- |
| Grenzgänger (`outlaw`)   | BIOLOGICAL | Nahkampf-Verfolger | 0 | Standard-Gesetzloser |
| Ölfresser-Ratte (`fauna`)| BIOLOGICAL | schneller Melee-Schwarm | 0 | umzingelt, keine Deckung |
| Revolverheld (`revolver`)| BIOLOGICAL | Fernkämpfer, hält Abstand & kitet | 0 | feuert Projektile |
| Konzern-Konstrukt (`konstrukt`) | MECHANICAL | Schützenlinie, feuert | 15 | galvanik-anfällig (Stun) |
| Schwerer Ernter / Goliath (`goliath`) | MECHANICAL | langsamer Koloss (Boss/Elite) | 30 | **frontimmun** ggü. Kinetik bis Korrosion |
| Minen-Titan (Superboss) | MECHANICAL | Dungeon-Wächter | 25 | **4× Boss-Leben**, frontimmun, riesige Beute |

**KI-Prinzipien:** biologische Gegner bluten und fliehen ggf.; Fernkämpfer halten eine
Distanz-Bandbreite (heranrücken/zurückweichen), feuern auf Cooldown; Automaten kennen
keine Flucht/Heilung. Kern-Kampf: **Auto-Ziel** auf den nächsten Gegner (kein Zielen per
Bewegung), Aggro/Leash-Radien, Kontakt- und Projektilschaden.

## 7.4 Ausrüstung, Seltenheit & Grid-Inventar
**Ausrüstungs-Slots (Paper-Doll):** Helm (`hp`), Rüstung (`armor`), Waffe (`damage`),
Gadget (`firerate`), Stiefel (`speed`) + **drei Panzerplatten** (`plate1/2/3`, je `armor`,
stapelbar).

**Seltenheit (Stat-Multiplikator & Level-Voraussetzung):**
| Seltenheit | Farbe | Stat-Mult | Mindest-Level |
| :-- | :-- | --: | --: |
| Gewöhnlich | Grau | ×1.0 | 1 |
| Selten | Blau | ×1.8 | 3 |
| Episch | Violett | ×2.8 | 7 |
| Legendär | Gold | ×4.2 | 11 |

**Grid-Fußabdruck (Inventar-Plätze):** Rüstung **2×2 (4)**, Waffe **2×1 (2)**, sehr große
Waffe **3×1 (3)** (ca. 30 % der Waffen, +40 % Schaden), Helm/Stiefel/Gadget/Panzerplatte
sowie Material-/Trank-Stapel je **1×1 (1)**. Vollbild-Charakter-Panel: Ausrüstung + Werte
links, gepacktes Grid-Inventar rechts; Anlegen per Ziehen oder Antippen.

**Verkauf:** Händler kauft Ausrüstung im Bulk je Seltenheit (Gewöhnlich/Selten/Episch);
**legendäre Teile sind geschützt** und werden nie im Bulk verkauft.

## 7.5 Progression (Level & Erfahrung)
* XP aus **Kills** (Standard `max(3, maxHp/11)`, Elite 50, Superboss 300) und
  **Quest-Abgaben** (`max(25, rewardGold·0.5)`).
* Aufstiegskurve: `xpToNext(level) = 40 + level·30`; **+8 max. Leben pro Stufe**;
  Levelaufstieg heilt voll. Level-Cap **30**.
* Level gated hochwertige Ausrüstung (siehe 7.4) und ist die Kern-Fortschrittsachse
  neben Ausrüstung, Waffen-Armaturen und Werkstatt-Körper-Mods.

## 7.6 Werkstatt-Modifikationen
Waffen-Tuning immer erlaubt; **Körper-Mods (`bodyMod`) erst nach dem Reveal**. Namen als
`[vor Reveal, nach Reveal]`:
| ID | Vor Reveal | Nach Reveal | Wirkung |
| :-- | :-- | :-- | :-- |
| `damage`   | Revolver-Kaliber | Ballistische Kalibrierung | Schaden |
| `firerate` | Schneller Hahn | Kolben-Frequenz | Feuerrate |
| `hp`       | — | T-4 Torso-Panzerung | max. Leben |
| `speed`    | — | Hydraulik-Laufbeine | Tempo |
| `regen`    | — | Kühlsystem | Regeneration |
| `magnet`   | — | Magnet-Spule | Loot-Magnet |

## 7.7 Loot-Kisten
| Tier | Icon | Inhalt |
| :-- | :-: | :-- |
| `normal` | 📦 | 2–4 Schrott, Chance Zahnrad, kleine Ausrüstungs-Chance |
| `rare`   | 🧰 | 3–5 Schrott, Zahnräder, gute Dampfkern-Chance, Ausrüstung (bessere Seltenheit) |
| `boss`   | 💰 | 4–7 Schrott, Zahnräder, garantierter Dampfkern, hochwertige Ausrüstung |

Kisten liegen verstreut in Kampfzonen, gebündelt an Spezialorten (Schatzkammer-Ebenen der
Multilevel-Dungeons, z. B. Schrott-Minen & Schmelzöfen von Vulcan) und um Elite-/Superbosse.

## 7.8 Verbindliche Terminologie
**Erlaubt (Steampunk):** Zahnräder, Kupferleitungen, Dampfdruck, Kesseldruck, galvanische
Impulse, alchemistische Synthese, Kinetoskop-Projektion, Chassis, Automat, Rechenkern
(„per alchemistischer Synthese überbrücken" statt „hacken").
**Verboten (Cyberpunk/Modern):** Chips, Cyberware, Neural Network, Hack, Neon-Data,
Firewall, Download — sowie jegliche Retro-/Pixel-/16-Bit-/2D-Kachel-Referenz.
```
