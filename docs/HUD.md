# Die Oberfläche — Stand, Plan, und was dafür fehlt

## Wo es steht

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
│  72 px │  ██████░░░░░░░░░░░░░░  ⭐ Lv 1
└────────┘  💰 340   🎽 4/6   🌙 Nacht
```

* **Porträt** im Rahmen, klickbar → Rucksack. *(steht)*
* **Lebensbalken**, darunter schmaler der **Erfahrungsbalken**. *(steht)*
* Darunter eine Zeile: Gold, getragene Ausrüstung, Tageszeit. *(noch Text — soll Symbole
  bekommen)*
* **Statusmarken** unter dem Porträt: Vergiftung, Blutung, Kurzschluss, Betäubung. Die gibt es im
  Kampfsystem längst (`CombatEngine`), aber der Spieler sieht sie nirgends — **das ist die
  auffälligste Lücke im ganzen HUD.**

### Oben rechts — wo ich bin

Karte, Zoom. Bleibt, bekommt aber denselben Rahmen wie das Porträt, damit beide Ecken
zusammengehören.

### Unten — was ich tue

* Links der Joystick *(steht, zeichnet nur beim Ziehen)*
* Rechts der Abzug mit Munition darunter *(steht)*
* Mitte die Aktionsleiste, die nur erscheint, wenn etwas in Reichweite ist *(steht)*
* **Neu: eine Gürtelleiste** für Heiltrank und die zwei, drei Dinge, die man im Kampf braucht.
  Zurzeit gibt es Tränke im Spielstand (`potions`) und keinen Weg, sie zu benutzen.

### Was verschwinden soll

* Der Hinweis **„[Tab] Inventar"** — schon raus. Ein Bild braucht keine Beschriftung, und auf
  dem Handy gibt es kein Tab.
* Die **Ortszeile** als Dauertext. Der Ort gehört an die Karte, nicht in eine Textzeile; nur beim
  *Betreten* soll sein Name groß über die Mitte ziehen — das gibt es bereits (`_zone_lbl`).
* Die **Emoji als Symbole**. ❤ 💰 ⭐ 🎽 🌙 sind Platzhalter und sehen auf jedem Gerät anders aus.

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
* Keine Schriftart, solange nichts dagegen spricht: Godots Vorgabe ist lesbar, und eine eigene
  Schrift bringt Lizenzfragen mit, die sich später schwer zurücknehmen lassen.
* Keine Hintergründe für Tafeln. Ein Rahmen plus eine dunkle Fläche reicht; ein gemalter
  Hintergrund macht jede Tafel schwer und altert schnell.

### Wie du sie lieferst

Einfach in den Chat ziehen. Ich lege sie ab, verdrahte sie und rendere ein Kontrollbild. Wenn
etwas fehlt, fällt das Spiel **nicht** aus — `UiAssets.texture()` liefert `null`, und jede Stelle,
die eine Grafik benutzt, hat einen gezeichneten Ersatz. Das ist Absicht: Eine fehlende Datei darf
nie den Start verhindern.

---

## Die Reihenfolge, die ich vorschlagen würde

1. **Statusmarken.** Größte Lücke: Das Kampfsystem verteilt Zustände, die man nicht sehen kann.
2. **Die Gürtelleiste.** Tränke existieren und sind unbenutzbar.
3. **Rahmen für Karte und Tafeln.** Macht aus zusammenhanglosen Kästen eine Oberfläche.
4. **Symbole statt Emoji.** Am sichtbarsten, aber am wenigsten folgenreich — deshalb zuletzt.
