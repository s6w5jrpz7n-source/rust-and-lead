# Die Oberfläche — Stand, Plan, und was dafür fehlt

## Wo es steht

> **Zwei Fehler, die erst das Kontrollbild gezeigt hat.** Der Porträtrahmen stand 470 px groß über
> dem halben Bildschirm, obwohl ihm 72 zugewiesen waren: Godots Vorgabe für `TextureRect` ist
> `EXPAND_KEEP_SIZE`, die Textur bestimmt also die Mindestgröße und zieht ein gesetztes `size`
> beim Eintritt in den Baum wieder hoch. Und die Biom-Tönung zog eine harte Linie quer durch die
> Wüste — sie war ein Zylinder mit gleichmäßiger Deckkraft. Ein Biom ist aber keine
> Verwaltungsgrenze: Es hört nicht auf, es wird weniger. Jetzt ein Fächer mit Alpha-Verlauf, die
> inneren 62 % satt, das äußere Drittel läuft aus.

Gebaut ist bisher der **erste Schritt**: das Porträt oben links, ein Rahmen darum, Leben und
Erfahrung als Balken daneben. Alles andere ist noch Text auf schwarzem Grund.

**Das Porträt ist der Knopf für den Rucksack.** Vorher gab es dafür nur `[Tab]` — also
ausgerechnet auf der Zielplattform gar nichts. Und ein Porträt ist der Ort, an dem jeder danach
sucht: Wo man sich selbst sieht, greift man nach seinen Sachen. Der Rahmen liegt darüber und
schluckt keine Tipps, sonst wäre der Knopf darunter tot.

Das Bild ist aus dem letzten Bild des Intro-Films geschnitten. Damit ist die Figur oben links
dieselbe, die man im Film gesehen hat und die auf dem Titel steht — **drei Stellen, ein Gesicht**,
ohne dass jemand etwas malen musste.

---

## Wie es aussehen soll

Der Leitgedanke ist nicht „mehr Grafik", sondern **weniger Lesen**. Der jetzige Kopfbereich sind
drei Zeilen Text mit vierzehn Zahlen darin. Im Gefecht liest die niemand. Was man im Gefecht
*sieht*, sind Farbe, Länge und Form.

### Oben links — wer ich bin

```
┌────────┐
│ Porträt│  ████████████████░░░░  ❤ 128/128
│  72 px │  ██████░░░░░░░░░░░░░░  ★ Lv 1
└────────┘  ¤ 340   ▣ 4/6   ☾ Nacht
```

* **Porträt** im Rahmen, klickbar → Rucksack. *(steht)*
* **Lebensbalken**, darunter schmaler der **Erfahrungsbalken**. *(steht)*
* Darunter eine Zeile: Gold, getragene Ausrüstung, Tageszeit. *(noch Text — soll Symbole
  bekommen)*
* **Statusmarken** — *(steht, aber am Gegner statt am Spieler)*. Das Kampfsystem verteilt seit
  Langem Zustände, und der Spieler konnte **keinen** davon sehen. Wer eine Säureflasche wirft und
  nichts passiert, lernt daraus nur, dass Säureflaschen nichts tun; dass sie gerade die Panzerung
  aufgelöst hat, stand nirgends. Jetzt steht ⚡ (Kurzschluss), ☣ (DOT) und ‼ (zerfressene
  Panzerung) über der Lebensleiste des Gegners — dorthin geht der Blick beim Zielen ohnehin.
  ~~*Noch offen:* dieselben Marken für den **Spieler**.~~ **Erledigt** — und dort wiegen sie
  schwerer. Ein Gegner, der Schaden nimmt, ist erklärt: man hat geschossen. Leben, das ohne
  sichtbaren Grund sinkt, liest sich als *Fehler des Spiels* — und genau das passierte im
  Smog (☣) und im Strahlensumpf (☢). Dazu gab es nur alle 2,2 Sekunden einen Satz; wer den
  verpasst, sieht bloß Leben verschwinden. Die Marke steht jetzt rechts neben der
  Lebensleiste, solange es frisst, mit 1,2 s Nachlauf — der Schaden fällt schubweise an, und
  ohne Nachlauf ginge die Warnung im Sekundentakt an und aus.

### Oben rechts — wo ich bin

Karte, Zoom. Bleibt, bekommt aber denselben Rahmen wie das Porträt, damit beide Ecken
zusammengehören.

### Unten — was ich tue

* Links der Joystick *(steht, zeichnet nur beim Ziehen)*
* Rechts der Abzug mit Munition darunter *(steht)*
* Mitte die Aktionsleiste, die nur erscheint, wenn etwas in Reichweite ist *(steht)*
* **Die Gürtelleiste** über dem Abzug — Heiltrank. *(steht)* Sie sitzt dort und nicht neben dem
  Joystick: Wer trinkt, hat gerade Schaden genommen und den Daumen an der Schusshand. Der Knopf
  wird **ausgegraut**, wenn nichts zu holen ist, statt zu verschwinden — ein Knopf, der
  verschwindet, lässt die Ecke springen, und man greift daneben, weil der Daumen die alte Stelle
  kennt. Auf der Tastatur `[F]`.

### Was verschwinden soll

* Der Hinweis **„[Tab] Inventar"** — schon raus. Ein Bild braucht keine Beschriftung, und auf
  dem Handy gibt es kein Tab.
* Die **Ortszeile** als Dauertext. Der Ort gehört an die Karte, nicht in eine Textzeile; nur beim
  *Betreten* soll sein Name groß über die Mitte ziehen — das gibt es bereits (`_zone_lbl`).
* Die **Schriftzeichen als Symbole**. ❤ ¤ ★ ▣ ☾ sind Platzhalter — jetzt immerhin *sichtbare*
  (siehe unten), aber ein gezeichnetes Symbol bleibt schärfer und trägt die Farbe besser.

---

## Was ich dafür brauche

Der Ordner `assets/ui/` hat schon einen brauchbaren Grundstock: `portrait_frame`, `dialog_frame`,
`btn_normal/hover/disabled`, `btn_fire`, `btn_character`, die sechs Slot-Symbole, `doll_body`,
`footprint`. Es fehlen:

### Rahmen (9-Patch, PNG mit Transparenz)

| Datei | Größe | wofür |
|---|---|---|
| `frame_panel.png` | 96 × 96, Rand 24 | Rucksack, Charakterschirm, Läden — ein Rahmen für alle Tafeln |
| `frame_slot.png` | 48 × 48, Rand 12 | ein Rucksackfach |
| `frame_slot_rare.png` … `_legendary.png` | 48 × 48 | dieselbe Form, andere Farbe je Seltenheit |
| `bar_frame.png` | 64 × 24, Rand 8 | Fassung für Leben und Erfahrung |

> **9-Patch heißt:** Der Rahmen wird in der Mitte gestreckt, die Ecken bleiben scharf. Deshalb
> reichen 96 px auch für eine Tafel von 900 px Breite. Wichtig ist nur, dass **der Rand
> gleichmäßig** ist — sonst wandert die Ecke beim Strecken.

### Symbole (PNG, 64 × 64, weiß auf transparent)

Weiß deshalb, weil die Farbe im Spiel gesetzt wird — dasselbe Symbol wird gelb bei Knappheit und
rot bei leer, und dafür darf es keine eigene Farbe mitbringen.

`icon_hp`, `icon_xp`, `icon_gold`, `icon_ammo`, `icon_potion`, `icon_time_day`, `icon_time_night`,
`icon_quest`, `icon_map`, `icon_backpack`

### Statusmarken (PNG, 48 × 48, farbig)

`status_poison`, `status_bleed`, `status_shock`, `status_stun` — die vier, die das Kampfsystem
kennt.

### Was ich **nicht** brauche

* Keine Porträts der Spielfigur — das kommt aus dem Film.
* ~~Keine Schriftart, solange nichts dagegen spricht: Godots Vorgabe ist lesbar, und eine
  eigene Schrift bringt Lizenzfragen mit.~~ **Falsch gewesen** — Godots Vorgabe war eben *nicht*
  genug: Sie kennt kein einziges Symbol, und das ganze HUD zeigte leere Kästchen. DejaVu Sans
  liegt jetzt im Projekt, die Lizenzfrage ist mit einer gemeinfreien Schrift beantwortet. Wenn
  später eine Schrift mit mehr Charakter kommen soll, ist der Platz dafür vorbereitet.
* Keine Hintergründe für Tafeln. Ein Rahmen plus eine dunkle Fläche reicht; ein gemalter
  Hintergrund macht jede Tafel schwer und altert schnell.

### Wie du sie lieferst

Einfach in den Chat ziehen. Ich lege sie ab, verdrahte sie und rendere ein Kontrollbild. Wenn
etwas fehlt, fällt das Spiel **nicht** aus — `UiAssets.texture()` liefert `null`, und jede Stelle,
die eine Grafik benutzt, hat einen gezeichneten Ersatz. Das ist Absicht: Eine fehlende Datei darf
nie den Start verhindern.

---

## Die Reihenfolge, die ich vorschlagen würde

1. ~~Statusmarken. Größte Lücke: Das Kampfsystem verteilt Zustände, die man nicht sehen kann.~~
   **Erledigt** für Gegner — als Zeichen und nicht als Bild, solange keine Symbole da sind. Ein
   Zeichen, das man sieht, ist besser als ein Bild, das noch niemand gemalt hat; kommen die
   Symbole, wird hier eine Zeile ausgetauscht.
2. ~~Die Gürtelleiste. Tränke existieren und sind unbenutzbar.~~ **Erledigt.** Ein Trank heilt
   **35 % des Höchstwerts** und nicht eine feste Zahl: Eine feste Zahl ist auf Stufe 1 ein halbes
   Leben und auf Stufe 20 ein Tropfen. Bei vollem Leben wird keiner verbraucht — auf dem Handy
   ist das sonst ein Fehlgriff, den niemand rückgängig machen kann.
3. **Rahmen für Karte und Tafeln.** Macht aus zusammenhanglosen Kästen eine Oberfläche.
4. **Symbole statt Emoji.** Am sichtbarsten, aber am wenigsten folgenreich — deshalb zuletzt.

---

## Die Schrift — und warum das HUD monatelang leere Kästchen zeigte

Beim Bauen des Trankknopfes fiel eine Frage an, die vorher niemand gestellt hatte: *Kann die
Schrift das Symbol überhaupt?*

`Font.has_char()` antwortete: **nein**. Und dann bei jedem weiteren Symbol wieder: nein.

Godots eingebaute Ersatzschrift ist ein schmaler Latin-Ausschnitt — Buchstaben, Ziffern,
Umlaute, sonst nichts. Im Quelltext standen aber **54 verschiedene Emoji**, quer durch das
ganze Spiel: der Geldsack an der Beute, das Reagenzglas am Trank, das Pferd am Pferd, der
Kompass an der Auftragsspur, der Rucksack am vollen Beutel, die Lok am Bahnhof. Beim Lesen des
Codes sahen sie alle richtig aus. **Im Spiel war jedes einzelne ein leeres Kästchen.**

Aufgefallen war es nie, weil man es beim Lesen nicht sehen *kann* — der Editor zeigt die Emoji
ja an. Nur das laufende Spiel zeigt das Loch, und dort sieht man ein fehlendes Symbol leicht
als „da ist halt noch keine Grafik".

### Was jetzt gilt

1. **Die Schrift liegt im Projekt** — `godot/assets/fonts/DejaVuSans.ttf`, eingetragen als
   `gui/theme/custom_font`. Sie deckt Umlaute, Typografie und die Symbolblöcke ab. Was sie
   *nicht* hat, hat keine gewöhnliche Schrift: den Emoji-Bereich ab U+1F300 — Emoji sind
   Farbbilder, keine Buchstaben. (Lizenz: Bitstream Vera, `assets/fonts/LIZENZ_DejaVu.txt`.)
2. **Alle Emoji sind ersetzt** durch Symbole, die die Schrift kennt: ¤ Gold, ⚗ Trank,
   ▬ Schrott, ⚙ Zahnrad, ◉ Dampfkern, ♞ Pferd, ⇄ Iron Rail, ⊕ Wegweiser, ✦ Auftrag,
   ⚔ Waffe, ★ Stufe, ☠ Tod, ⌂ Ortschaft, ≈ offene Wüste.
3. **`ThemeDB.fallback_font` ist verboten.** Das ist *nicht* die eingestellte Schrift, sondern
   genau die eingebaute Notlösung — fünf Dateien, die ihre Symbole selbst malen, holten sich
   damit die leeren Kästchen zurück, egal was im Projekt steht. Jetzt überall
   `get_theme_default_font()`.
4. **Der Trankknopf malt sein Symbol selbst** (`HudGlyph.zeichne_flakon()`). Er liegt unter dem
   Daumen und muss im Gefecht auf einen Blick lesbar sein; gemalte Punkte hängen an keiner
   Schrift und können nie wieder zu einem Kästchen werden.

### Der Wächter

`TestRunner._test_zeichen()` liest **jede Zeile jedes Skripts und jeder Szene** (88 Dateien),
wirft die Kommentare weg und fragt die Schrift zu jedem übrigen Zeichen einzeln. Ein neues
Emoji fällt beim nächsten Testlauf auf — nicht erst dem Spieler.

Kommentare bleiben ausgenommen, und das mit Absicht: Sie müssen erklären dürfen, *welches*
Zeichen früher dort stand.
