# Der erste Mini-Dungeon — zwei Ebenen zwischen Stadt und Schrottplatz

## Was wir dafür brauchen

Kurz: **wenig Kunst, ein Stück Technik.** Die Technik ist der eigentliche Posten, und sie zahlt
sich für jeden weiteren Dungeon aus.

### Technik (mache ich)

1. **Szenenwechsel.** Es gibt bisher genau eine Spielszene, `Overworld.tscn`. Ein Dungeon braucht
   das Umschalten mit Rückweg: Position und Zustand der Oberwelt merken, Dungeon laden, beim
   Verlassen zurück an den Eingang. Das ist der größte Einzelposten und einmalig.
2. **Raumgenerator.** Kein handgebautes Labyrinth — ein Erzeuger, der aus einem Startwert Räume
   und Gänge zusammensetzt. Zwei Ebenen à 6–9 Räume. Damit ist der zweite Dungeon eine
   Zeilenänderung und nicht dieselbe Arbeit von vorn.
3. **Wände als Kollision.** Draußen ist die Welt offen, drinnen ist sie eng — die
   `_solid_rect_rot`-Sperren aus der Stadt lassen sich direkt weiterverwenden.
4. **Treppe nach unten und Ausgang.** Zwei Interaktionspunkte, dieselbe Mechanik wie beim
   Bahnsteig.
5. **Dunkelheit.** Ein Dungeon ohne Licht ist kein Dungeon. Eine Lampe am Spieler
   (`OmniLight3D`, 9 m Reichweite), Umgebungslicht stark herunter, ein paar Wandlampen als
   Orientierung. Das CC0-Modell `industrial_wall_lamp_1k` liegt schon ungenutzt im Projekt.
6. **Beute und Gegner.** Beides steht: `EncounterManager` mischt Gegner nach Biom,
   `_build_chests` setzt Truhen. Der Dungeon braucht nur eigene Zahlen — dichter als draußen,
   eine garantierte Truhe am Ende von Ebene 2.

### Kunst (brauche ich von dir)

Erstaunlich wenig, weil ein Dungeon aus wenigen Teilen besteht, die man oft wiederholt.
**Vier Modelle** reichen für einen vollständigen Dungeon:

| Datei | Was | Maß |
|---|---|---|
| `dungeon/wall.glb` | Wandsegment, genietetes Blech auf Holzstützen | 4 m breit, 3,5 m hoch |
| `dungeon/wall_prop.glb` | Zweite Fassung mit Rohren/Streben — bricht die Wiederholung | 4 m breit |
| `dungeon/pillar.glb` | Stützpfeiler mit Querbalken | 3,5 m hoch |
| `dungeon/stairs.glb` | Treppe nach unten, in eine Wand eingelassen | 4 m breit |

Prompt-Grundgerüst für alle vier: *grim-dark steampunk western mine interior, single connected
object, seen straight on from the front at eye level, plain neutral mid-grey background, no ground
plane, no cast shadows, entire object centered with margin, no people, no text, no logos,
photorealistic PBR game asset, very low polygon count, high detail.* Dazu jeweils:

* **Wand:** *A mine tunnel wall section, riveted iron sheets bolted onto rough timber props, water
  stains and rust streaks running down, one sheet buckled outward, exactly 4 metres wide and 3.5
  metres tall, flat back.*
* **Wand mit Aufbau:** *The same wall section but with a bundle of corroded pipes running
  horizontally across it, a closed valve wheel, and a broken conduit hanging loose.*
* **Pfeiler:** *A mine support pillar: two heavy squared timbers with an iron collar and a cross
  beam at the top, splintered at one corner, 3.5 metres tall.*
* **Treppe:** *A steep mine staircase leading down into darkness, iron treads on a timber frame
  with a single pipe handrail, set into a wall opening 4 metres wide.*

**Boden und Decke brauchst du nicht** — beides sind Flächen mit Textur, dafür hole ich CC0-PBR-Sets
(nasser Fels, Schotter) von Poly Haven.

## Wo er liegt

Zwischen Rustwater (world 300/300) und den Schrott-Minen (150/450) — also am Weg, den man in den
ersten Minuten sowieso läuft. Vorschlag: ein Stolleneingang bei **world 210/380**, sichtbar als
verschalter Einschnitt im Boden mit Balkenrahmen.

Er kommt damit **vor** dem Strahlensumpf und passt in die verkleinerte Startwelt.

## Wie er sich spielt

**Ebene 1 — „Der Vorschacht"**, 6 Räume, hell genug zum Sehen. Ölfresser-Ratten und ein
Grenzgänger-Trupp. Zwei Truhen. Am Ende die Treppe.

**Ebene 2 — „Die Kaverne"**, 9 Räume, richtig dunkel. Kessel-Kläffer im Schwarm und ein
Konzern-Konstrukt als Abschluss. Eine garantierte Truhe mit angehobener Seltenheit.

Länge: acht bis zwölf Minuten für beide Ebenen. Klein genug, dass man ihn zweimal am Abend
läuft; groß genug, dass man mit vollem Beutel herauskommt und deshalb ins Inventar schaut.

## Reihenfolge, in der ich es baue

1. ~~Szenenwechsel mit Rückweg (ohne Inhalt, nur rein und raus)~~ **Erledigt.**
2. ~~Raumgenerator + Wände + Dunkelheit, mit Kisten-Platzhaltern~~ **Erledigt.**
3. Gegner und Beute — *offen*
4. Deine vier Modelle ersetzen die Platzhalter — *offen, wartet auf dich*

Nach Schritt 1 kann man schon hineingehen, nach Schritt 3 ist er spielbar. Deine Modelle sind der
letzte Schritt und blockieren nichts.

---

## Stand nach Schritt 2

**Man kann hineingehen.** Der Stollenmund liegt bei world 210/380 als Einschnitt mit
Balkenrahmen und Schild; `[E]` bzw. der Knopf in der Aktionsleiste steigt hinab. Drinnen: sechs
bzw. neun Kammern, Gänge, Gürtellampe mit 9 m, Nebel, Treppe nach unten und der Weg zurück —
und man kommt **dort** wieder heraus, wo man hineingestiegen ist.

**Der Grundriss ist eine Rechnung** (`DungeonLayout`) und kennt keine Szene. Das ist der Grund,
warum der Test 200 Grundrisse erzeugen und bei jedem mit einer Flutfüllung nachlaufen kann, ob
vom Eingang wirklich jedes Feld erreichbar ist. Eine Treppe hinter einer Wand sieht auf jedem
Bild in Ordnung aus — nur nachlaufen findet sie.

**Was jetzt drinsteht, sind Kisten.** Die Plätze für Truhen und Gegner rechnet der Grundriss
bereits aus; an ihnen stehen Würfel. Das ist Schritt 3.

### Zwei Dinge, die erst das Kontrollbild gezeigt hat

Die Draufsicht blieb dreimal hintereinander schwarz, und jedes Mal aus einem anderen Grund:
erst fehlte das Licht, dann fraß der **Nebel** alles (bei 0,035 Dichte bleibt über 108 m
Kamerahöhe rund ein Fünfzigstel übrig), und schließlich lief `look_at()` ins Leere, weil die
Kamera beim Ausrichten **noch nicht im Baum hing** — Godot bricht dann mit „Node not inside
tree" ab und behält die Ausgangslage. Erst das dritte Bild zeigte den Grundriss.

Das ist genau der Grund für Kontrollbilder: Die Erreichbarkeit ist bewiesen, aber ob man in
einem dunklen Stollen überhaupt etwas *sieht*, beantwortet keine Rechnung.
