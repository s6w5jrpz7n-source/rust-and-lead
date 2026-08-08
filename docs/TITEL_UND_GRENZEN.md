# Titelbildschirm, der erste Gegner, der Riss

Alle drei sind **gebaut**. Was hier steht, ist die Begründung — und die verworfenen Anläufe,
weil die mehr erklären als das Ergebnis.

---

## 1. Der Titelbildschirm

**Damit startet das Spiel immer**, nicht nur wenn es Spielstände gibt. Ein Titelbild, das je nach
Speicherstand mal da ist und mal nicht, ist kein Anfang, sondern ein Dialogfeld.

### Das Bild steht — und ist das letzte Bild des Films

Der erste Entwurf ließ die echte Welt hinter dem Menü rotieren: Rustwater bei Nacht, 2,4°/s.
Das Argument dafür war gut — ein gerendertes Standbild altert gegen das Spiel, sobald jemand die
Palisade umbaut. Es wiegt trotzdem leichter als das Ergebnis: **Ein Titelbild soll stehen.** Es ist
das erste Versprechen, das ein Spiel gibt, und ein Versprechen, das sich dreht, ist eine
Bildschirmschoner-Ansicht.

Genommen wird das **letzte Bild des Intro-Films**. Das ist keine Notlösung, sondern die bessere
Idee: Wer *Neues Spiel* wählt, sieht den Film laufen — und der endet genau dort, wo der Titel
angefangen hat. Das Standbild ist damit kein Aushang neben dem Spiel, sondern sein erster
Bildinhalt.

Nebeneffekt: Die Welt wird gar nicht mehr geladen. Der Titel startet sofort, und die Overworld
hat keinen Sonderzustand mehr zu kennen — die Flagge `im_titel` ist mit diesem Entwurf wieder
weggefallen.

### Der Aufbau

Titel oben links, Menü rechtsbündig. Dahinter **zwei weiche Schleier** statt eines Kastens: einer
von oben, einer von rechts. Nachgemessen liegt die Bildhelligkeit dort bei 64 bzw. 85 von 255 —
hell genug, dass helle Schrift ohne Hilfe verschwände, dunkel genug, dass ein Schleier reicht. Ein
flächiges Abdunkeln hätte dem Bild genau das genommen, wofür es da ist.

Das Bild füllt den Rahmen mit `KEEP_ASPECT_COVERED` und nicht mit `SCALE`: Auf einem Telefon im
Hochformat würde ein gestrecktes Bild die Figur in die Breite ziehen, und ein Titelbild mit
verzerrtem Gesicht ist schlimmer als ein beschnittenes.

### Die Einträge

| | Eintrag | |
|---|---|---|
| 1 | **Neues Spiel** | löscht den Spielstand und setzt den Prolog zurück |
| 2 | **Spiel laden** | **ausgegraut**, solange es keinen Stand gibt — nicht versteckt. Ein Eintrag, der auftaucht und verschwindet, lässt den Bildschirm springen |
| 3 | **Tutorial** | derselbe Prolog mit Hinweistafeln, kein zweiter Inhalt: Zwei Anfänge zu pflegen heißt, dass einer davon schlechter wird |
| 4 | **Einstellungen** | Lautstärke gesamt / Musik / Effekte / Sprache |
| 5 | **Steuerung** | |
| 6 | **Credits** | |
| 7 | **Beenden** | nur auf dem Desktop |

Die drei, nach denen nicht gefragt war, sind die interessanten:

* **Einstellungen** sind Pflicht. Ohne Lautstärkeregler ist ein Spiel mit Schusswaffen auf einem
  Telefon unzumutbar. Die Regler gehen auf **echte Audio-Busse** — ein Regler, der nur eine Zahl
  in einer Einstellungsdatei verschiebt, ist eine Attrappe, und die fällt spätestens auf, wenn
  jemand sie benutzt. Bei null wird stummgeschaltet statt auf −inf gerechnet: `linear_to_db(0)`
  ist minus unendlich, und damit rechnet Godots Mischer nicht sauber weiter.
* **Steuerung**, weil das Spiel auf Handy *und* Tastatur läuft. Wer am Rechner sitzt, sucht sonst
  blind nach `[E]`, `[R]`, `[Tab]`, `[Q]`, `[M]`.
* **Beenden** nur auf dem Desktop. Auf dem Handy beendet man Apps anders, und ein Knopf, der dort
  nichts Sinnvolles tut, ist schlimmer als keiner.

Nicht aufgenommen: ein *Fortsetzen* neben *Spiel laden*. Beim ersten Start wäre es tot, danach
dasselbe wie der zweite Eintrag mit einem anderen Wort.

> **Ein Fehler, den erst das Bild gezeigt hat.** Der erste gerenderte Titel war taghell, obwohl er
> nachts spielen sollte. `_ready()` der Overworld lädt den Spielstand, und darin steht die
> Uhrzeit der letzten Runde — wer abends aufgehört hatte, bekam einen Titel im Abendrot. Mit dem
> festen Bild ist die Frage weg; die Beobachtung bleibt trotzdem gültig für alles andere, was
> sich auf `GameState.hour` verlässt, bevor der Spielstand geladen ist.

---

## 2. Der erste Gegner

**Wann:** beim Verlassen des Kraters (34 m hinter seinem Rand), und nur mit Waffe in der Hand —
ohne wäre es eine Hinrichtung ohne Werkzeug. Genau einmal; was erklärt ist, muss nicht noch
einmal erklärt werden.

### Der Ablauf

1. **Einer, und eine Maschine.** Nicht das übliche Rudel. Er taucht **seitlich** vor ihm auf und
   hat ihn noch nicht gesehen — frontal wäre es ein Duell, so ist es eine Begegnung.
2. **Die Kamera** setzt sich seitlich hinter seine Schulter, Bildwinkel 44° statt 78°. Hier ist
   die Frage nicht *wo bin ich*, sondern *was ist das*.
3. **Er schießt selbst.** Der Spieler drückt nicht. Die Figur kann etwas, was der Spieler noch
   nicht kann, und weiß selbst nicht, woher — dieselbe Frage wie beim Karabiner in der Truhe
   (*„als hättest du das schon tausendmal gemacht"*).
4. **Der Tote** kippt auf die Seite und läuft in `idle` weiter. Das ist ein Platzhalter und sieht
   auch so aus — besser als eine Leiche, die steht.
5. **Die Kamera fährt auf ihn zu**, 4,6 Sekunden, bis er das Bild füllt.
6. **Erst jetzt** liegt Beute da.

### Warum eine Maschine

Zuerst stand hier ein **Grenzgänger** — ein Mensch, weil die Frage *„was bist du gewesen"* bei
etwas Menschlichem am stärksten trägt. Das war die falsche Rechnung: Ein bewaffneter Mann in der
Wüste ist keine Überraschung, sondern genau das, was man dort erwartet. Ein zweibeiniger Kessel,
der aus dem Blech kommt, ist eine — und er stellt die Frage, um die es im ganzen Spiel geht,
gleich in der ersten Minute: **Was ist hier Mensch und was Maschine.** Der Held weiß es von sich
selbst noch nicht.

Der **Kessel-Kläffer** wäre das schönere Tier gewesen: vierbeinig, hundegroß, mechanisch. Es gibt
ihn als Gegnertyp mit Werten — nur nicht als **Modell**; `klaeffer.glb` steht noch auf der Liste
der fehlenden Sachen. Also das nächstliegende, das da ist: das **Konzern-Konstrukt**. Zwei Meter
hoch, gepanzert, mechanisch — keine Ratte, kein Mensch.

> Ein Test hält das fest: Er prüft, dass es *kein* Kläffer-Modell gibt. Taucht eines auf, fällt er
> um und erinnert daran, hier noch einmal hinzusehen. Eine Notlösung, die niemanden mehr erinnert,
> ist keine Notlösung mehr, sondern der Stand.

Dass dieses eine mit einem Schuss fällt und ein späteres nicht, **trägt der Text**: Es ist ein
Wrack, das halb im Schrott gelegen hat, und der Held sagt es (*„Ein heiler hätte gestanden"*). Wer
später einem heilen begegnet, ist gewarnt worden.

Die Beute ist aus einer Maschine außerdem selbsterklärend — Schrauben, ein Zahnrad, ein
**Dampfkern**. Aus einem Menschen wäre sie eine Erklärung gewesen, die man hätte liefern müssen.
Der Dampfkern wird nicht ausgewürfelt: Der Held spricht ihn aus (*„ein Kern, der noch warm ist"*),
und was ausgesprochen wird, muss auch dort liegen.

Punkt 6 ist der Sinn der ganzen Szene: Wer vorher einsammeln kann, lernt nichts.

> **DER NAMENLOSE:** „…was zum."
> „Das läuft. Das ist Blech, und es läuft."
> *(er schießt)*
> „Das ging schnell. Zu schnell."
> „Ich hab nicht nachgedacht. Meine Hände schon."
> „…und woher weiß ich, wo man so ein Ding trifft?"
> „Der war halb hin. Rost bis zum Kessel. Ein heiler hätte gestanden."
> „Es zischt noch. Ein Ding, das zischt, wenn es liegt."
> „Da drin klappert was. Schrauben. Ein Zahnrad. Und ein Kern, der noch warm ist."
> „Das hat jemand gebaut. Jemand baut so was und lässt es hier laufen."
> „Also nehm ich, was drin ist. Es braucht das nicht mehr, und ich schon."

Die letzte Zeile ist der Punkt: **Plündern wird begründet, nicht als Spielfunktion erklärt.** Ein
Spiel, in dem man Leichen durchsucht, sollte einmal aussprechen, was das ist.

**Offen:** die Schuss-Animation und `klaeffer.glb`. Bis die Animation da ist, läuft der
vorhandene Angriffs-Clip; der Rest der Szene hängt nicht daran — Mündungsfeuer, Leuchtspur und
Ton stehen.

---

## 3. Der Riss

Ein Spalt quer durch die Karte bei x = 700, **10 m breit, 1900 m lang, 40 m tief**. Er liegt rund
einen Kilometer östlich von Rustwater: weit genug, dass der Prolog ihn nie berührt (Grube, Fels
und Stadt liegen alle westlich), nah genug, dass man ihn findet, sobald man sich umsieht.

### Warum er mehr ist als eine Mauer

Sektor 1 und 2 trennen die **Sprengtore**, Sektor 2 und 3 die **Smog-Linie**. Beides sind
Bauwerke des Konzerns — Grenzen, die jemand gezogen hat. Der Riss ist die dritte Sorte und die
interessanteste: eine Grenze, die **niemand** gezogen hat. Das gibt ihm eine Aufgabe, die die
anderen beiden nicht haben können — er ist der erste Hinweis darauf, dass mit dieser Welt etwas
nicht stimmt, lange bevor jemand erklärt, wer den Krater gemacht hat.

### Als Geländeform, nicht als Modell

Aus demselben Grund wie beim Ausguck: `height_at()` ist die einzige Wahrheit für Bodenhöhe im
ganzen Spiel — daran hängen Laufen, Fußspuren, Streuung, jede Figur und jede Kiste. Ein
aufgestelltes Modell wüsste davon nichts; man liefe hindurch, die Fußspur ginge darüber weg,
Gegner ständen in der Luft.

Gerechnet wird der Abstand zu einer **Linie** statt zu einem Punkt — sonst dieselbe Formel.

### Was dabei am Rest zu ändern war

Er ist die erste Geländeform, die nicht rund ist, und damit die erste, bei der **Reichweite und
Ausdehnung auseinanderfallen**:

* **`feature_halb()`** ist neu. Als Quadrat um seine Reichweite gerechnet wäre sein Loch im Boden
  1900 × 1900 m groß — ein Drittel der Welt. Alles, was eine *Fläche* braucht (das Loch, der
  Geländeflicken), fragt jetzt dort nach.
* **Die Auflösung des Flickens rechnet je Achse.** Quer zählt jeder halbe Meter, längs sieht man
  auf zweihundert nichts. Ohne die Trennung hätte ein 1900-m-Streifen bei 0,5 m Punktabstand
  45 Millionen Dreiecke.

### Er ist kein Graben

`schlenker` 26 m über zwei Sinuswellen, deren Längen nicht ineinander aufgehen — nachgemessen
34 m Versatz über die Länge. Und an den Enden läuft er über 110 m aus: Ein Abgrund mit
senkrechter Stirnwand mitten in der Ebene wäre ein Bauteil, kein Riss.

### Die Sperre

Die **Steigungsgrenze hilft hier nicht** — sie sperrt nur bergauf, damit sich niemand festsetzt,
der schon auf einem steilen Stück steht. An einem Riss läuft man *hinunter*. Es braucht also eine
eigene Sperre, und sie hängt an der Höhe: 1,2 m unter der Ebene ist Schluss. Dort ist man noch
keinen halben Schritt hinein und kommt jederzeit zurück; einen Schritt weiter wäre man im freien
Fall.

Dazu ein **Warnband** entlang beider Kanten. Eine unsichtbare Sperre an einem Abgrund ist derselbe
Fehler wie damals an der Palisade, wo die Fußspur vor der Mauer endete: Man läuft dagegen und weiß
nicht, warum. Die Kante wird dafür **gesucht, nicht gerechnet** — von außen nach innen getastet,
bis der Boden abfällt —, damit das Band auch dann noch stimmt, wenn jemand den Schlenker ändert.

> **Ein Fehler, den der Test gefunden hat, bevor ihn jemand spielen musste.** Die Sperre fragte
> zuerst *nur* die Höhe ab. Die Schrottgrube ist fünf Meter tief, und der Held erwacht an ihrem
> Grund — jeder Schritt dort wäre ein Schritt „in den Riss" gewesen, und das Spiel hätte mit einer
> bewegungslosen Figur angefangen. Jetzt wird zuerst die Nähe geprüft und erst dann die Höhe.

### Und wie man hinüberkommt

Ein **gestürzter Kessel** — eine umgekippte Werkslok, die quer im Spalt liegt. Eine Brücke wäre
die naheliegende Antwort und die langweiligste: Sie sagt *„hier ist der Übergang vorgesehen"*.
Ein Waggon, der irgendwann irgendwo hineingestürzt ist, sagt etwas anderes — dass hier einmal
etwas passiert ist, und dass der Weg ein **Fund** ist und keine Freischaltung.

Deshalb liegt er auch **von Anfang an** da. Nichts wird aufgeschlossen; man muss nur die richtige
Stelle finden. Und die liegt bei **38 % der Risslänge**, nicht in der Mitte: Die Mitte wäre die
Stelle, an der man zuerst nachsieht, und dann wäre das Suchen keins.

Auf dem Steg ist der Riss kein Riss — sonst wäre er Deko. Die Figur steht dabei **darauf** und
nicht im Boden darunter: `_boden_hoehe()` liefert die Steghöhe statt der Geländehöhe, überall dort,
wo sonst `height_at()` stünde.
