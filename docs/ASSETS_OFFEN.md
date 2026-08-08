# Was wir noch brauchen

Stand nach dem Handy-Test. Sortiert nach **Wirkung pro Aufwand** — oben das, was am meisten
verändert, unten das Angenehme.

Alles, was hier steht, hat im Spiel schon einen Platz: Der Code fragt über `AssetRegistry` nach
einem logischen Namen und zeichnet einen Platzhalter, solange die Datei fehlt. Du kannst also in
beliebiger Reihenfolge liefern, und nichts geht dabei kaputt.

---

## Priorität 1 — Waffen (5 fehlen von 6)

Der größte Einzelposten. `CombatData.WEAPONS` kennt fünf Waffen, im Spiel steht ein Modell:
der Karabiner. Die anderen vier sehen aus wie er, obwohl sie sich völlig anders spielen — die
Gatling schießt zwölfmal so schnell und hat 60 Schuss im Gurt.

| Datei | Waffe | Werte im Spiel | Länge |
|---|---|---|---|
| `weapons/karabiner.glb` | Blei-Karabiner | 34 Schaden, 850 ms, 10 Schuss | ✅ da |
| `weapons/gatling.glb` | Kurbel-Gatling | 6 Schaden, **70 ms**, 60 Schuss, 4,5 s Nachladen | 1,3 m |
| `weapons/voltgun.glb` | Voltgewehr | 22 Schaden, 420 ms, Blitz | 1,1 m |
| `weapons/saeure.glb` | Säurewerfer | 11 Schaden, 240 ms, Ätzschaden | 1,0 m |
| `weapons/brenner.glb` | Dampf-Brenner | 9 Schaden, 130 ms, Flamme | 1,2 m |

**Was jede braucht:** Silhouette, die man am Rücken der Figur erkennt. Die Waffe hängt beim
Laufen sichtbar am Körper — eine Gatling muss von hinten als Trommel lesbar sein, ein
Säurewerfer als Tank mit Schlauch. 3 000–6 000 Dreiecke, 1k-Textur.

## Neu eingetroffen (2026-08-02)

| Datei | Rolle | Mass | Wo eingebaut |
|---|---|---|---|
| `props/locomotive.glb` | Gestrandete Werkslok | 13 m lang | **Schrottgrube** — das eine grosse Stueck, das der Halde einen Massstab gibt |
| `props/shelf.glb` | Industrieregal | 2,2 m | Schrottgrube |
| `props/desk.glb` | Rostiger Schreibtisch | 1,8 m | Schrottgrube |
| `props/office_chair.glb` | Lederdrehstuhl | 1,05 m | Schrottgrube |
| `props/oil_barrel.glb` | Oelfass | 0,95 m | Schrottgrube |
| `props/barbed_wire.glb` | Stacheldraht | 2,4 m | Schrottgrube |
| `props/medallion.glb` | Rostmedaillon | 1,4 m | Schrottgrube |
| `environment/monolith.glb` | Betonbrocken | 3,0 m | Schrottgrube |
| `environment/copper_plate_a.glb` | Kupfer-Bodenplatte OHNE Gruenspan | 2,6 m Kante | **Rustwaters Boden** (MultiMesh, rund 900 Stueck) |
| `environment/copper_plate_b.glb` | Aeltere Fassung mit Gruenspan | 2,6 m Kante | liegt bereit, nicht verlegt |
| `assets/video/intro_muellkippe.mp4` | Intro-Film | 11 MB | noch nicht — Godot spielt kein MP4, siehe `assets/video/README.md` |
| `unsortiert/figur_ohne_namen.glb` | Schreitende Messingmaschine | 1,8 m | **offen** — Rolle nicht vergeben |
| `unsortiert/figur_mit_animationen.glb` | Klauentraeger mit Hut, 5 Animationen | 1,8 m | **offen** — Rolle nicht vergeben |

`deadtree.glb` und `deadtree_b.glb` kamen erneut, sind aber dieselben Modelle, die schon im
Repo liegen (545 406 bzw. 430 360 Dreiecke roh, gleiche Masse) — nichts zu tun.

## Priorität 2 — Gegner (2 fehlen von 6, plus der Hund)

Ohne Modell zeichnet die Szene eine farbige Kapsel. Man kämpft also gegen Kapseln.

| Datei | Gegner | Höhe | Prompt |
|---|---|---|---|
| `enemies/fauna.glb` | Ölfresser-Ratte | 0,6 m | ✅ da |
| `enemies/konstrukt.glb` | Konzern-Konstrukt | 2,0 m | ✅ da |
| `enemies/outlaw.glb` | Grenzgänger | 1,6 m | ✅ da (9 Animationen — **keine Ruhepose**, sieben davon sind Angriffe; `AssetRegistry.rest()` hält ersatzweise das erste Bild) |
| `enemies/revolver.glb` | Revolverheld | 1,6 m | ✅ da (12 Animationen) |
| `enemies/klaeffer.glb` | Kessel-Kläffer | 0,8 m | `PROMPTS_GEGNER.md` |
| `enemies/goliath.glb` | Schwerer Ernter (Boss) | 4,0 m | `PROMPTS_GEGNER.md` (vorne + hinten) |
| `characters/bolzen.glb` | Bolzen, der Blechhund | 0,7 m | fehlt noch, sag Bescheid |

Die vier Prompts stehen fertig in `docs/PROMPTS_GEGNER.md`. **Animationen wären ein Riesengewinn**
(Laufen, Angriff, Tod) — der Code sucht sie über `AssetRegistry.CLIP_ALIASES` selbst und braucht
keine bestimmten Namen; ohne Animation stehen die Gegner steif da und gleiten.

## Priorität 3 — Der Sumpf ✅ erledigt

Alle drei Modelle sind da und eingebaut: `props/deadtree.glb` (5,5 m, steht und kippt leicht),
`props/deadtree_b.glb` (4,0 m, liegt — über die LÄNGE skaliert, nicht über die Höhe) und
`props/rad_barrel.glb` (1,1 m).

Sie teilen sich einen Streudurchgang, damit sie am selben Ort auftauchen und zusammen erzählen,
warum der Sumpf verseucht ist. Die Mischung ist bewusst schief — acht stehende Bäume auf einen
umgestürzten und ein Fass: Lauter Umgestürzte sähen aus wie nach einem Sturm, und ein Fass
hinter jedem Baum nähme dem einzelnen Fund seine Bedeutung. Nur was steht, sperrt den Weg; über
einen liegenden Stamm steigt man, ein Fass tritt man beiseite.

## Priorität 4 — Requisiten aus `PROMPTS_PROPS.md`

Handkarren (`props/handcart.glb`, 3,0 m) fehlt noch als einziger aus der Erstliste. Dazu die acht
Schrottteile aus `PROMPTS_SCHROTTGRUBE.md` — für die Grube nicht mehr nötig, aber als Streugut in
der Wüste und in Dungeons weiterhin nützlich.

## Priorität 5 — Gebäude

Zwei Wirtschaftsgebäude aus `TycoonManager` haben kein Modell: **Destille** und **Alchemie-Labor**.
Beide sind Ausbaustufen im Township und tauchen sonst im Ortsbild nicht auf. Prompts nach dem
Muster von `PROMPTS_GEBAEUDE.md`; Zielhöhe 6–7 m.

---

# Grafiken für die Oberfläche

> **Die fertigen Prompts stehen in `docs/PROMPTS_UI.md`** — mit dem gemeinsamen Stilsatz, den
> 9-Patch-Maßen und den zwei Dingen, die man ausdrücklich verbieten muss (Schrift im Bild und
> eigener Rahmen). Unten steht nur noch, warum es diese Bilder gibt.

Kurze Antwort: **Für das Inventar brauchst du nichts.** Es ist fertig — Beutel-Raster UND Puppe —
und funktioniert mit gezeichneten Feldern und Zeichen-Sinnbildern (⛑ 🧥 🔫 ⚙ 🥾). Das ist keine
Notlösung — Rasterfelder mit Rahmen in Seltenheitsfarbe lesen sich sauber, und die Zeichen sind
auf jedem Gerät scharf.

**Die Puppe** (getragene Ausrüstung als Figur, links im Charakter-Bildschirm) zeichnet ihre
Silhouette aus Grundformen. Ein gemaltes Chassis wäre schöner, ist aber ausdrücklich nicht nötig:
`ui/doll_body.png` (430×436, transparent, eine grimmige Automaten-Silhouette von vorn, Arme leicht
abgespreizt) würde sie ersetzen, ohne dass sich am Rest etwas ändert. Niedrige Priorität.

**Die Fußspur** benutzt schlichte Vierecke. Eine Textur `ui/footprint.png` (128×128, weißer
Abdruck auf transparent — ein Stiefelprofil mit Absatz) würde aus den Rechtecken echte Abdrücke
machen. Ebenfalls niedrige Priorität, aber der billigste sichtbare Gewinn in dieser Liste.

**Sinnvoll wären Grafiken an drei Stellen**, in dieser Reihenfolge:

### 1. Kategorie-Sinnbilder fürs Raster (6 Stück, je 128×128 PNG mit Alpha)

Ersetzen die Zeichen `⛑ 🧥 🔫 ⚙ 🥾 ▦`. Emoji sehen auf jedem Betriebssystem anders aus und
brechen den Ton — ein gemalter Helm passt zum Spiel, Apples Bauarbeiterhelm nicht.

Dateien: `ui/icon_helmet.png`, `icon_armor.png`, `icon_weapon.png`, `icon_gadget.png`,
`icon_boots.png`, `icon_plate.png`

Stil-Vorgabe für alle sechs (wichtig, dass sie als Satz wirken): *A single game inventory icon on
a fully transparent background, grim-dark steampunk western style. Rusted iron and brass, worn
leather, sun-bleached grey. Flat three-quarter view, thick readable silhouette, no background, no
frame, no text. The object fills the square with a small margin.* Dazu jeweils: `a riveted iron
helmet with a cracked glass visor` / `a heavy leather coat with iron shoulder plates` / `a lever
action rifle` / `a brass pressure gauge with copper coils` / `a pair of worn leather boots with
iron toecaps` / `a bolted steel plate`.

### 2. Knopf-Hintergründe (3 Stück, 9-Patch-fähig)

Die Knöpfe nutzen Godots Standarddesign — grau, rechteckig, unpassend. Drei Bilder ersetzen alle
Knöpfe im Spiel:

* `ui/btn_normal.png` — 96×48, gebürstetes Eisen mit Nieten in den Ecken, dunkel
* `ui/btn_hover.png` — dasselbe, eine Spur heller
* `ui/btn_disabled.png` — dasselbe, entsättigt und dunkler

*Wichtig:* Rand 12 px an allen Seiten glatt und einfarbig halten, damit Godot sie als 9-Patch
streckt. Sonst verzerren die Nieten.

### 3. Der Charakter-Knopf und der Schuss-Knopf (2 Stück, je 128×128)

`ui/btn_character.png` (eine Brustplatte oder ein Rucksack) und `ui/btn_fire.png` (ein
Fadenkreuz). Beide sind heute gezeichnet und funktionieren; ein Bild macht sie nur schöner.

**Was du NICHT brauchst:** Rahmen für die Tafeln, Rollbalken, Reiter, Nebel-Textur, Kartensymbole.
Alles gezeichnet und plattformunabhängig.

---

# Der Handy-Fehler ist behoben — und es war nicht der Knopf

Der Charakter-Knopf war da, oben links. Er war nur **winzig**: Das Projekt hatte keine
Bildschirm-Skalierung eingestellt, also zeichnete Godot die Oberfläche in echten Pixeln. Auf
einem Telefon mit 2400 px Breite ist ein 52-px-Knopf 2 % der Breite.

Behoben in `project.godot`: Bezugsauflösung 1280×720, `stretch/mode = canvas_items`,
`aspect = expand`. Damit sieht der HUD auf jedem Gerät aus wie am Computer, und ein 20:9-Telefon
bekommt den Überschuss als **zusätzliches Blickfeld** statt als kleinere Knöpfe.

Dabei ist noch ein zweiter Fehler aufgefallen, der alle Vollbild-Oberflächen betraf
(Inventar, Laden, Weltkarte, Joystick): `set_anchors_preset` setzt nur die Anker und lässt die
Ränder auf 0. Unter einem `CanvasLayer` blieben diese Bildschirme dadurch 0×0 groß — die
Abdunklung war unsichtbar, und alles mittig Verankerte zentrierte auf den Bildschirm-Nullpunkt
statt auf die Mitte. Jetzt überall `set_anchors_and_offsets_preset`.

---

## Die Bosstruhe (`items/chest_boss.glb`)

Es gibt jetzt **zwei** Truhenarten, und sie unterscheiden sich nicht nur im Inhalt:

| | gewöhnliche Truhe | Beutekammer |
|---|---|---|
| Registry-Name | `chest` ✅ da | `chest_boss` — **fehlt** |
| Höhe | 0,70 m | **0,95 m** |
| Gold | 18–45 | 95–170 |
| Stücke | 1–3 | 2–4 |
| Seltenheit | darf eine Niete sein | **mindestens `rare`**, nach oben offen |
| Trank | in der Hälfte der Fälle | **immer** |

Das garantierte Minimum ist der eigentliche Unterschied. Eine gewöhnliche Truhe *darf* leer
ausgehen — das ist der Grund, warum man sich über eine gute freut. Eine Truhe hinter einem Boss
darf das nicht: Wer einen Kampf übersteht und dann Hausmüll findet, lernt, dass Bosskämpfe sich
nicht lohnen.

Solange die Datei fehlt, zeichnet das Spiel einen Platzhalter aus drei Teilen — Sockel, Kasten,
Deckelband in Messing mit schwachem Glimmen. Er ist bewusst **nicht** dieselbe Kiste in Gold:
Im Dämmerlicht eines Stollens trägt die *Form* weiter als die Farbe, und man soll auf dreißig
Meter sehen, dass sich der Weg lohnt.

### Prompt

> *grim-dark steampunk western treasure chest, single connected object, seen from the front at a
> slight three-quarter angle, plain neutral mid-grey background, no ground plane, no cast
> shadows, entire object centered with margin, no people, no text, no logos, photorealistic PBR
> game asset, very low polygon count, high detail.*
>
> **Dazu:** *An ornate reinforced strongbox, roughly 1.2 metres wide and 0.95 metres tall on a
> low iron plinth. Dark oiled hardwood body bound with polished brass straps and corner caps, a
> heavy brass lid band with an engraved geometric pattern, a large mechanical combination lock
> with exposed cogs on the front, two riveted carrying handles at the sides. Worn but cared for
> — this one was built to hold something worth guarding. Closed lid.*

**Wohin:** `godot/assets/models/items/chest_boss.glb` (oder als Ordner
`items/chest_boss/chest_boss.gltf` — beide Pfade sind eingetragen).

Einfach in den Chat ziehen, ich lege sie ab. Das Spiel läuft auch ohne: Der Registry-Eintrag
steht schon, `resolve()` liefert `""`, und die Szene nimmt den gezeichneten Ersatz. Eine
fehlende Datei darf nie den Start verhindern — das prüft `_test_truhen()` mit.

### Wo sie steht

Bisher am **Ende der Kaverne** (Stollen, Ebene 2) — in der Kammer mit der Treppe, also am Ende
des Wegs. Weitere Plätze sind eine Zeile: `_spawn_chest_at(pos, ChestData.BOSS)`. Sobald es
richtige Bossgegner gibt, gehört je eine hinter jeden von ihnen.

### Und sie ist verschlossen

Drei **Schlüssel** braucht sie, und die gibt es ausschließlich bei **Anführern**. Damit steht
die beste Truhe im Spiel sichtbar da und lässt sich trotzdem nicht einfach einsammeln: Man muss
dreimal einen Kampf suchen, den man umgehen könnte.

Ein Anführer ist **kein eigener Gegnertyp**, sondern ein verstärkter gewöhnlicher — dreimal
Leben, doppelter Schaden, gemessen an *seinem* Typ. Ein Anführer der Ratten hat dreimal so viel
Leben wie eine Ratte; er ist immer der Stärkste *seiner* Gruppe und nie versehentlich ein Boss
(er bleibt deutlich unter `BOSS_HP`). Genau das ist der Reiz: Man erkennt ihn als das, was man
schon kennt, und merkt am dritten Schuss, dass diesmal etwas anderes davorsteht.

Erkennbar an einem **violetten Schimmer** und 25 % mehr Höhe. Violett, weil in dieser Welt
sonst nichts violett ist — Rost, Sand, Kupfer und Messing sind warm, die Nacht ist blau. Eine
kalte Buntfarbe fällt hier auf, ohne dass man sie erklären muss, und ist auch für
Rot-Grün-Blinde von allem anderen trennbar. Der Schimmer liegt als `material_overlay` **über**
dem Modell — ein `material_override` würde die Textur *ersetzen* und den Anführer zu einer
einfarbigen Silhouette machen.

**Für dich heißt das: kein zusätzliches Modell.** Anführer benutzen die Modelle ihrer
gewöhnlichen Artgenossen.

Im Stollen steht **einer je Ebene**, aber nur auf den ersten dreien — ab der vierten noch einen
zu stellen hieße, Schlüssel zu verteilen, für die es kein Schloss gibt. Draußen führt einer
jedes Rudel.
