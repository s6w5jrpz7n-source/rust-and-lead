# Rust & Lead — Punkt-und-Klick-Fassung

Bauform: **Baphomets Fluch** (Revolution Software, 1996). Gemalte Bühnenbilder, flache
Aufsicht, Figur in Dreiviertelansicht davor, Gesprächsauswahl über Sinnbilder.
Farbraum: der unsere, gemessen an Titelbild und Intro.

Diese Datei ist die verbindliche Beschreibung. Was hier steht, gilt; was im
`MASTER_GDD.md` über Iso-Kamera, Kampf und Tycoon steht, gilt für die **Action-Fassung**,
die im Titelmenü unter „Action-Fassung (alt)" erreichbar bleibt.

---

## 1. Was anders ist als vorher

| | Action-Fassung (alt) | Abenteuer (neu) |
|---|---|---|
| Kamera | 3D-isometrisch, 35–45° von oben | flache Bühne, Augenhöhe |
| Figur | klein, Überblick zählt | ~210 px, knapp ein Drittel Bildhöhe |
| Tiefe | 85 % Größenunterschied | **20 %** — ein Ort ist ein Raum, keine Landschaft |
| Fortschritt | Gegner, Beute, Stufen | Gegenstände finden, verbinden, anwenden |
| Gespräch | Sprechtafel blättert Sätze | Baum mit Antworten, Auswahl über Sinnbilder |
| Aufträge | Zähler („8 erledigen") | Rätsel mit genau einer Lösung |
| Struktur | offene Welt | Kapitel: Hauptstrang + Seitenstränge, **alle Pflicht** |

---

## 2. Die Bedienung

| Eingabe | Rechner | Telefon |
|---|---|---|
| hingehen / benutzen | Linksklick | tippen |
| ansehen | Rechtsklick | halten (0,45 s) |
| Inventar | Maus an den oberen Rand | von oben wischen |
| Gegenstand in die Hand | Klick in der Leiste | tippen |
| anwenden | mit Gegenstand in der Hand auf Ziel klicken | dasselbe |
| Gegenstand weglegen | Rechtsklick ins Leere | — |
| Tagebuch | `Tab` oder `J` | Knopf |

Jeder Klick überspringt einen laufenden Satz. Das ist die wichtigste Taste des Spiels und
darf nie belegt sein.

---

## 3. Die Kapitelform

```
┌─ Hauptstrang ───────────────────────────┐
│  verpflichtend, in Reihenfolge          │
├─ Seitenstrang A ────────────────────────┤
│  verpflichtend, Reihenfolge egal        │
├─ Seitenstrang B ────────────────────────┤
│  verpflichtend, Reihenfolge egal        │
└──────────────┬──────────────────────────┘
               ▼
        SCHLUSSSZENE  — alle Stränge treffen sich an einem Ort
               ▼
        nächstes Kapitel
```

**Alle Stränge sind Pflicht.** Ein optionaler Nebenauftrag ist Arbeit, die man einmal macht
und fünfmal nicht gespielt bekommt. Weil hier jeder Strang gespielt wird, darf jeder etwas
erzählen, das im nächsten Kapitel vorausgesetzt wird.

### Kapitel 1 — „Staub & Blei" (ausgespielt)

* **Hauptstrang** `q_wegelagerer` — Acht Wegelagerer von der Piste bekommen.
  Lösung: Grubenlampe (Automatenkadaver, Kippe) **+** Kinetoskop-Linse (Säule auf dem Platz,
  mit dem Brecheisen herausgehebelt, sichtbar erst nach dem Kurbeln) = **Signallampe**.
  Damit den Felsen das Konzernzeichen geben. Wegelagerer überfallen Fuhrwerke, nie den Konzern.
* **Seitenstrang** `q_achse` — Quentin Vales gebrochene Achse. Silas' Schraubstock holen.
  Führt den Konzern ein, ohne dass geschossen wird.
* **Seitenstrang** `q_walze` — Dolores' gesprungene Musikwalze. Erst Silas, **dann** Dolores.
  Legt den ersten Hinweis darauf, was der Held ist.
* **Schlussszene** „Erster Abend" im Saloon: Mabel zahlt aus, Dolores spielt die gerichtete
  Walze, und draußen hält der Karren, den man geflickt hat — leer, obwohl er beladen war.

### Kapitel 2–12

Struktur steht in `scripts/KapitelDaten.gd` (Titel, Stränge, Schlussort). Ausgespielt ist
bisher Kapitel 1; Kapitel 2 hat seinen ersten Ort (`vorschacht`) und seine Rätsel.

---

## 4. Die Regeln, die nicht gebrochen werden

Diese fünf stehen als Testfälle in `tests/TestRunner.gd` und machen den Lauf rot:

1. **Jeder Hotspot hat einen Ansehen-Text.** Ein Hotspot ohne ist ein Loch in der Welt.
2. **Jeder Gesprächsknoten hat einen Ausweg.** Sonst kommt der Spieler nur über das
   Hauptmenü heraus.
3. **Jeder Ort ist vom Anfang aus erreichbar**, und jeder Standpunkt liegt im begehbaren Feld.
4. **Kein unlösbarer Zustand.** Ein Gegenstand, der verbraucht wird, darf keinen
   Missionsschritt tragen, und eine Wirkung, die etwas endgültig weggibt, braucht `nur_wenn`.
   (`walze_dolores` vor `walze_silas` hätte das Spiel unlösbar gemacht — ohne dass man es merkt.)
5. **Das Gehfeld beginnt unterhalb des Bühnenhorizonts** (y ≥ 430) und die Tiefe bleibt
   unter 25 %. Beides zusammen ist die Perspektive von Baphomets Fluch.

---

## 5. Der Farbraum

Gemessen mit `ffmpeg -vf palettegen` an `assets/ui/titelbild.webp` und
`assets/video/intro_muellkippe.mp4`. Beide liegen auf **derselben** warmen Leiter:

```
#090201  #140a06  #1e110b  #2b1b13  #3f291b  #583d27
#6f4c31  #865c3c  #a57950  #c19769  #e2bf91
```

Ton 22°–28°, von Ruß bis Sandlicht durchgezogen. In `scripts/Palette.gd` tragen die Stufen
Materialnamen (`OELSCHWARZ`, `ROSTERDE`, `MESSING`, `SANDLICHT`), damit man ein Bild
beschreiben kann, ohne Hexzahlen zu nennen.

**Weil es praktisch nur einen Ton gibt, wird über Helligkeit getrennt, nicht über Buntheit.**
Baphomets Fluch stellt einen roten Mantel vor eine grüne Hecke; das geht hier nicht. Mindest-
abstand zwischen Figur und Grund: 0,18 (siehe `Palette.ABSTAND_MIN`). `Palette.abheben()`
erzwingt ihn, und die Testsuite prüft ihn für **jede** Stufe des Keils.

**Höchstens ein kühler Akzent je Bild.** Es gibt drei, jeder mit fester Bedeutung:
`GALVANISCH #4a86a0` (Konzern-Energie), `GRUENSPAN #5c7a63` (Fäulnis, Sumpf),
`LEICHENBLAU #6b7a8c` (Mondlicht, Kälte). Ein blauer Schein heißt immer dasselbe.

---

## 6. Hintergrundbilder — die Rezeptur

Die Bilder sind der Engpass dieses Genres, nicht der Code. Das Spiel ist **ohne sie
vollständig spielbar**: Fehlt die Datei, zeichnet `AbenteuerView` eine Bühne aus dem Farbkeil
und zeigt die Hotspots als Kästen. Jedes Rätsel, jeder Weg, jedes Gespräch funktioniert damit.
Ein Bild nachzureichen ändert keine Zeile Logik.

Ablage: `godot/assets/orte/<kennung>.webp`, Seitenverhältnis 16:9, mindestens 1280×720.
Die Kennung steht im Feld `bild` in `scripts/OrtDaten.gd`.

### Warum erzeugte Hintergründe billig aussehen

Das ist der Teil, der über die Qualität entscheidet, und er steht vor der Vorlage, weil die
Vorlage ihn umsetzt. Ein Bildmodell liefert auf „painted adventure background" ein
Konzeptbild: hübsch, flach, ohne Bühne. Was fehlt, ist immer dasselbe:

1. **Keine Tiefenstaffelung.** Ein Spielhintergrund hat drei Ebenen — einen **Vordergrund**,
   der angeschnitten am Bildrand steht (Balken, Torbogen, Fasskante, Wagenrad), dunkel und
   unscharf; die **Mittelebene**, in der gespielt wird; und einen **Hintergrund**, der Raum
   dahinter öffnet. Der angeschnittene Vordergrund ist der größte einzelne Unterschied
   zwischen „KI-Bild" und „Adventure-Hintergrund". Baphomets Fluch hat ihn in fast jeder Szene.
2. **Kein Licht, nur Helligkeit.** Eine benannte Lichtrichtung, in allen Bildern dieselbe,
   mit Schlagschatten, die in dieselbe Richtung fallen. Ohne das sieht jeder Ort aus wie aus
   einem anderen Spiel.
3. **Überall gleich viel Detail.** Dicht in der Mittelebene, **ruhig im Laufstreifen** und
   ruhig im Himmel. Ein gleichmäßig durchdetailliertes Bild ermüdet und verschluckt die Figur.
4. **Kein Blickpunkt.** Ein Ort hat eine Sache, auf die das Auge zuerst fällt.
5. **Symmetrie.** Mittig gebaute Bilder wirken wie Kulissen. Die Flucht sitzt außerhalb der
   Mitte, die Massen links und rechts sind ungleich.

### Die Vorlage

Vier Absätze. **COMPOSITION, LIGHT, COLOUR und das Schluss-NO bleiben wortgleich bei jedem
Ort** — nur SCENE wird getauscht. Das ist der Grund, warum die Bilder später zusammenpassen:
nicht der Stil im Prompt hält sie zusammen, sondern dass drei Viertel des Prompts identisch
sind.

> Hand-painted 2D background plate for a classic point-and-click adventure game, in the
> visual tradition of Revolution Software's "Broken Sword" — painted backdrop with genuine
> architectural perspective, rich material detail, cinematic staging. NOT photorealistic,
> NOT a 3D render, NOT pixel art, NOT flat vector art, NOT concept art.
>
> SCENE: *(hier der Ort — siehe unten)*
>
> COMPOSITION: one-point perspective with a clear vanishing point placed off-centre, camera
> at adult standing eye level and only slightly elevated. Buildings set at an angle so their
> facades recede into depth. THREE DEPTH LAYERS: a dark out-of-focus foreground element
> cropped by the edge of the frame (a beam, an archway, a barrel rim, a cart wheel); the
> midground, which is the playable set and carries the detail; and a background that opens
> real distance behind it. Keep an open, unobstructed strip of ground across the lower third
> for characters to walk on — quiet, low detail, no clutter. Asymmetric: unequal masses left
> and right. 16:9 widescreen.
>
> LIGHT: a single low sun from the left, late afternoon, raking across the facades. All cast
> shadows fall to the right and are long. Soft bounced light fills the shadows — they are
> open and readable, never crushed to black. Dust hangs in the air and catches the light.
>
> COLOUR: strictly limited to one warm ochre/rust ramp, no other hues — #090201 #140a06
> #1e110b #2b1b13 #3f291b #583d27 #6f4c31 #865c3c #a57950 #c19769 #e2bf91. Evenly lit,
> mid-tone painting. Objects separate by local contrast and silhouette, not by darkness.
> Hazy pale-gold sky at the horizon. Sun-bleached and grim, but readable. At most one single
> cool accent.
>
> NO people, NO characters, NO animals, NO readable lettering, NO lens flare, NO modern
> objects, NO symmetrical composition, NO empty foreground. Empty set only.

### Die sieben SCENE-Absätze

> **kippe** — A vast slag heap of scrap metal at the rim of a desert crater, late afternoon.
> Twisted sheet steel, broken boiler drums, the ribcage of a gutted mechanical automaton with
> its chest plate cut open, gears spilled in the dust. A bleached enamel sign bolted to a bent
> post. The ground falls away to the right towards a track far below. Foreground: the rusted
> curve of a boiler drum, cropped by the left edge.
>
> **piste** — A rutted desert track running left to right through flat scrub, late afternoon.
> A broken-axled steam cart listing on the verge, its boiler still breathing. A rock ridge
> rises above the track on the right, high enough to overlook it. Bones and a single boot at
> the roadside. A palisade gate of railway sleepers closes the far end. Foreground: a thorn
> bush, cropped by the right edge.
>
> **platz** — The central square of a small frontier town at the bottom of a desert crater,
> late afternoon. A dry stone well in the middle. A cast-iron kinetoscope viewing pillar with
> a crank on the left. A notice board thick with nailed-up papers on the right. Behind them,
> set at an angle: a two-storey saloon with swinging doors and a gatling barrel hung over the
> entrance, an open forge shed with glowing coals, a field-hospital tent on a stone
> foundation. Foreground: a hitching rail, cropped by the lower left corner.
>
> **saloon** — The interior of a frontier saloon, lit by low sun through a dusty window on the
> left. A long plank bar on two barrels, names carved into the wood and crossed out. A
> self-playing mechanical piano with an exposed brass-pinned roller. Tables, a staircase up
> into shadow, a corner table set against the back wall with a clear view of the door.
> Foreground: the back of a chair, cropped by the lower edge.
>
> **schmiede** — An open blacksmith's shed, late afternoon, the forge coals the brightest
> thing in frame. An anvil, a bellows, a workbench crowded with tongs and files and a heavy
> unbolted bench vice. A technical drawing nailed to the plank wall showing a joint in
> section. Racks of stock steel. Foreground: hanging chain, cropped by the upper left corner.
>
> **lazarett** — A field hospital under canvas on a stone foundation, low sun through the tent
> flap. A stretcher with leather straps worn through from the inside. An instrument cabinet
> whose lowest shelf holds engineers' tools, not surgeons': thread cutters, a feeler gauge, a
> hex key. A basin of grey water. Foreground: a tent pole and guy rope, cropped by the left edge.
>
> **vorschacht** — The head of a mine shaft cut into the crater wall, late afternoon light
> reaching only a few metres in. An iron cage hoist, chocked from above. A gallery mouth that
> goes black after ten metres. A chalked tin sign nailed to a prop. Scree, a dropped crowbar,
> abandoned tools. Foreground: a pit prop, cropped by the right edge.

### Entschieden: **A — Gaslicht**

Mitteltöne tragen das Bild, Schatten bleiben offen, Trennung über Silhouette und lokalen
Kontrast statt über Dunkelheit. Das ist die Behandlung, die dem echten Baphomets Fluch am
nächsten kommt, und die einzige, bei der die Hotspots im unteren Drittel auf einem Telefon
bei Tageslicht zuverlässig zu finden sind. Die COLOUR-Vorlage oben enthält sie bereits.

Verworfen, mit Grund:

* **B — Ölschwarz** hätte das Intro exakt getroffen (schwarze Massen, glühende Fenster, harter
  Lichtsaum), aber in Ölschwarz liegt die untere Bildhälfte bei einer Helligkeit um 0,03 —
  und genau dort liegen die anklickbaren Dinge. Eine Atmosphäre, die das Spiel unbedienbar
  macht, ist keine.
* **C — Blaupause** (A plus cyanfarbene Konzern-Risszeichnung) war der eigenständigste Look,
  kostet aber je Bild eine zweite Ebene und bricht die Regel „höchstens ein kühler Akzent".
  Die Idee bleibt verfügbar: Als **einzelner** Ort — das Walzen-Archiv in Kapitel 12 — wäre
  sie stark, gerade weil sie dann nicht überall ist.

### Die drei Richtungen im Vergleich

Gerendert mit `tools/StilProbe.gd` — derselbe Ort, dreimal behandelt. Was die Proben zeigen:
Helligkeitsverteilung, Kontrastumfang, wie viel kühler Akzent, ob die Figur lesbar bleibt.
Was sie nicht zeigen: Pinselduktus — den entscheidet das Bildmodell, nicht der Zeichner.

| | **A — Gaslicht** | **B — Ölschwarz** | **C — Blaupause** |
| :-- | :-- | :-- | :-- |
| Gebäudemasse | mittlere Töne (0,42) | fast Silhouette (0,08) | mittlere Töne (0,38) |
| Gegenlichtsaum | schwach (0,18) | stark (0,85) | schwach (0,22) |
| Vignette | 0,22 | 0,58 | 0,24 |
| Lesbarkeit der Hotspots | am besten | am schlechtesten | gut |
| Passt zu Titelbild/Intro | mittel | **genau** | mittel |
| Aufwand je Bild | normal | normal | höher (Linienebene) |
| Risiko | wirkt weniger grim-dark | halbes Bild verschwindet auf dem Handy bei Sonne | kann überladen wirken |

**Prompt-Zusatz je Richtung** (ersetzt bzw. ergänzt den COLOUR-Absatz der Vorlage):

* **A:** `Evenly lit, mid-tone painting. Shadows are soft and open, never crushed. Objects
  separate by local contrast and silhouette, not by darkness. Overcast dusty daylight.`
* **B:** `Strong backlight. Foreground architecture reads as near-black mass against a hot
  ochre sky; windows glow warm from inside. Deep crushed shadows, bright rim light on every
  edge facing the horizon. Heavy vignette.`
* **C:** `As A, plus a thin cyan technical overlay (#4a86a0, low opacity): dimension lines,
  gear schematics and survey grid drawn over the painting as if on a glass plate, plus a
  company stamp frame in one corner. The overlay is faint — it must never compete with the
  painting.`

### Welcher Dienst

Egal. Die Vorlage ist dienstneutral, und genau dafür steht sie hier.

* **ElevenLabs** (in dieser Sitzung angebunden) — `creative_generate_image`. Zur Zeit
  **gesperrt**: der Verbinder meldet „requires additional permissions". Lesen geht, Erzeugen
  nicht. Muss in den Verbinder-Einstellungen auf claude.ai neu verbunden werden.
* **Higgsfield** — Sammelplattform, die fremde Modelle unter einer Oberfläche anbietet
  (Bild: Nano Banana, FLUX, Seedream, eigenes „Soul"; Video: Sora, Kling, Veo). Der Ruf kommt
  von der **Video**seite, vor allem von den Kamerafahrt-Vorlagen. Für gemalte
  Hintergrundbilder bringt das nichts, was FLUX oder Seedream einzeln nicht auch bringen —
  es ist bequemer, nicht besser. Für ein Intro mit Kamerafahrt wäre es die erste Wahl.
* Alles andere, womit man schon arbeitet (Gemini hat die vorhandenen Bilder gemacht), tut es
  genauso. **Kein neues Konto nötig.**

### Was noch gebraucht wird

* Sieben Hintergründe: `kippe`, `piste`, `platz`, `saloon`, `schmiede`, `lazarett`,
  `vorschacht`.
* Figur in Dreiviertelansicht, Lauf nach links/rechts, ~210 px hoch, auf durchsichtigem Grund.
  Solange sie fehlt, zeichnet das Spiel eine Silhouette mit Hut.
* Portraits für `quentin` und `dolores` (`held`, `mabel`, `silas`, `doc` liegen in
  `assets/ui/`).

---

## 7. Die Stimmen sind schon da

`Stimme.kennung()` bildet den Dateinamen aus dem SHA-256 des Satzes. Alle Sätze, die
**wortgleich** aus `DialogData.gd` übernommen wurden, finden damit ihre schon gerenderte MP3
in `assets/voice/` — 106 Dateien, ohne eine Zeile Zuordnung. Übernommene Sätze sind in
`GespraechDaten.gd` mit `# vertont` markiert.

**Die Antworten des Helden sind absichtlich nicht vertont.** So hält es Baphomets Fluch auch:
Der Gegenüber spricht, der Spieler liest. Der Held bleibt stimmlich eine Leerstelle — das ist
sein ganzes Thema —, Antworten lassen sich jederzeit umschreiben, ohne eine Aufnahme zu
verlieren, und es halbiert die Vertonungsarbeit.

Neue Sätze vertonen:

```bash
python3 docs/build_spiel_stimmen.py     # Zeilen aus dem Quelltext sammeln
python3 docs/azure_tts.py --spiel       # rendern nach assets/voice/
```

---

## 8. Wo was liegt

| Datei | Inhalt |
|---|---|
| `scripts/OrtDaten.gd` | die Welt: Orte, Gehfelder, Hotspots, Ausgänge |
| `scripts/GespraechDaten.gd` | die Gesprächsbäume |
| `scripts/MissionDaten.gd` | Gegenstände, Missionen, Notizen, Wirkungen |
| `scripts/KapitelDaten.gd` | Kapitelstruktur, Stränge, Schlussszenen |
| `scripts/Welt.gd` | Weltzustand: Flaggen, Beutel, Wirkungen anwenden |
| `scripts/Palette.gd` | der Farbraum |
| `scripts/AbenteuerView.gd` | Bühne, Laufen, Klicks, Inventarleiste |
| `scripts/GespraechView.gd` | Portrait, Satz, Sinnbild-Reihe |
| `scripts/TagebuchView.gd` | Aufträge, Notizen, Gegenstände |
| `scripts/Sinnbild.gd` | die gezeichneten Zeichen |
| `scripts/AbenteuerWurzel.gd` | hält die drei Ansichten zusammen |
| `scenes/Abenteuer.tscn` | Einstiegsszene |
| `tools/AbenteuerShot.gd` | Bildschirmfotos der Bühne und der Gespräche |

## 9. Prüfen

```bash
# zwei Durchgänge, der erste importiert
godot --headless --path godot --editor --quit
godot --headless --path godot res://tests/TestRunner.tscn

# Bildschirmfotos (Texturen erscheinen dabei weiss — Grenze des Software-Renderers,
# kein Fehler im Spiel; gegengeprüft mit icon_gold.png)
xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 \
    --path godot res://tools/AbenteuerShot.tscn -- platz saloon reden:mabel_saloon
```
