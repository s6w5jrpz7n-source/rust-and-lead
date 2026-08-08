# Prolog & Kapitel 1 — der spielbare Anfang

Was hier steht, ist der **Fluss**: wo man aufwacht, was man findet, mit wem man spricht, wohin
man geschickt wird. Die Zahlen und Tabellen dahinter stehen im MASTER_GDD (§3 Kampagne,
§4.3 NPCs, §5 Mini-Quests); dieses Blatt ist die Reihenfolge.

Stand: Der Prolog **läuft** von vorn bis hinten — Titelbildschirm, Intro-Film, Aufwachen, erste
Sätze, leere Hände, Truhe, Pferd, **der erste Gegner**, Fußspur, Ausguck mit Rundsicht,
Nachtwerden, Anflug auf Rustwater, Abschluss beim Betreten der Stadt. Die **Dialoge sind Daten**
(`DialogData.gd`), der **Ton** ist da (`assets/audio/`).

Was fehlt, ist nichts Erzählerisches mehr, sondern Material:

* die **Schuss-Animation** — bis dahin läuft in der Erst-Gegner-Szene der vorhandene
  Angriffs-Clip, und der Tote kippt als sichtbarer Platzhalter auf die Seite;
* die **Sprachaufnahmen** — die Standzeit jeder Zeile wird bis dahin aus der Zeichenzahl
  geschätzt (`speech_dauer()`) statt aus der Cliplänge genommen;
* die **Modelle**, die in `docs/PROMPTS_ITEMS.md` und `assets/CREDITS.md` aufgelistet sind.

---

## Der Prolog — „Was vom Menschen übrig ist"

**Die Grube liegt südöstlich von Rustwater** (world 400/120), nicht mehr nordwestlich. Das ist
eine Lichtfrage, und sie lässt sich ausrechnen: Sonne und Mond stehen fest (`DayCycle`), die
Sonne im Südosten. Der Prolog ist ein 515-m-Fußmarsch zur Stadt, und der lief vorher genau in sie
hinein — Übereinstimmung von Laufrichtung und Lichtrichtung **−0,99**, also volle Gegenlichtlage.
Die Kamera steht hinter der Figur, sah also die ganze Zeit ihre Schattenseite, und Rustwater lag
als Silhouette im Dunst. Von Südosten aus geht man mit dem Licht im Rücken: **+0,99**. Dasselbe
gilt für den Blick vom Ausguck ins Tal — er geht jetzt vom Licht weg statt hinein.

Der Fels ist mitgezogen (348/214) und **mitgedreht**: Seine drei Buckel stehen in Metern vom
Mittelpunkt und damit in Weltachsen. Lässt man sie stehen, während er umzieht, ist es derselbe
Fels aus einer anderen Richtung — Aufstieg an einer Flanke, höherer Gipfel links statt rechts,
kein Platz mehr für den Leuchtring an der Kante. Um −164,2° gedreht (genau der Winkel, um den
sich die Anlaufrichtung ändert) sind alle Messwerte wieder die alten: Gipfel 16,0 m, Ring 3,0 m
rechts der Achse, Rampe 39°, Klippe 77°. Auch der Ausgang der Grube zeigt jetzt zum Fels (119°)
statt irgendwohin.

**Davor läuft der Film.** `intro_muellkippe.ogv` spielt vor dem Erwachen und mündet hinein —
nicht als Vorspann *neben* dem Spiel, sondern als sein erster Satz. Nahtlos heißt dabei zweierlei,
und das zweite ist das schwierigere:

* **Kein Schnitt ins Helle.** Der Film endet, das Bild geht über 1,2 s ins Schwarze, hält dort
  0,7 s, und aus dem Schwarz kommt die Grube hoch. Ein harter Wechsel wäre ein Sprung zwischen
  zwei Bildqualitäten — genau daran erkennt man eine eingeklebte Sequenz. Der Moment Schwarz
  nimmt dem Auge den Vergleich ab.
* **Kein Wechsel der Erzählhaltung.** Der Film zeigt die Müllkippe; das Erwachen fängt dicht am
  Gesicht an. Das eine geht ins andere über, weil beide dieselbe Frage stellen — *wer liegt da* —
  und nicht, weil sie aneinandergeklebt sind. Deshalb läuft der Text erst **nach** dem Film an.

Solange er läuft, ruht die Welt vollständig: keine Bewegung, keine Gegner, keine Auslöser. Sonst
spielte das Spiel hinter dem Film weiter, und wer ihn zu Ende sieht, fände die Figur woanders vor
als der, der ihn wegtippt. Ein Tipp überspringt ihn — dieselbe Regel wie bei jeder Kamerafahrt.
Fehlt die Videodatei, fällt der Vorspann still aus und das Spiel fängt beim Erwachen an: Ein
Intro darf nie zwischen dem Spieler und dem Spiel stehen.

Der Held erwacht **in der Lache am Grund der Schrottgrube**. Kein Menü, keine Erklärung. Die
Lache ist der einzige freie Fleck im Schutt — der einzige Ort, an dem man liegen kann; genau
deshalb wird sie beim Füllen ausgespart.

**0. Es ist Abendrot.** Eine Runde beginnt um **18:36** (`DayCycle.START_HOUR`). Das ist keine
Kosmetik, sondern der Bauplan des Prologs: Der Held erwacht in der Dämmerung, und während er
Richtung Rustwater geht, wird es Nacht. Zu Fuß dauert der Kilometer vier Minuten — acht
Spielstunden, Ankunft gegen **01:40**. Im Sattel reicht es gerade für die Dämmerung.

**1. Aufwachen.** Gut eine Minute — die Szene dauert so lange, wie der Held zu reden hat, nicht
andersherum. Eine Kamerafahrt mit fester Länge zwingt den Text in ihr Korsett, und dabei kommen
vier Halbsätze heraus.

**Die Kamera bleibt am Kopf, und zwar von vorn.** Sie fängt dicht am Gesicht an — man sieht
einen Mann im Dreck, bevor man sieht, wo er liegt. Zwei Dinge mussten dafür stimmen:

* Die Wegpunkte hängen am **Kopfknochen**, nicht an festen Punkten. Der Kopf wandert beim
  Aufstehen über anderthalb Meter durch den Raum (0,79 m im Sitzen, 1,63 m im Stehen, gemessen);
  feste Zielpunkte zielten zwangsläufig daneben — der erste Versuch punktgenau auf seine Stiefel.
* Die Versätze stehen in **seinem** Bezugssystem, nicht in Weltachsen (−Z ist vorn). Sonst hängt
  es vom Zufall der Figurendrehung ab, ob man ihr ins Gesicht oder auf den Rücken sieht — und
  beim ersten Versuch war es der Rücken. Dasselbe gilt für das Szenenlicht: Von hinten liegt
  genau das im Schatten, was die Szene zeigen soll.

Während er hochkommt, wächst der Abstand von 1,2 auf 4,2 m — der Kopf bleibt in der Bildmitte
(nachgemessen: Bildpunkt 640/360), der Ausschnitt wird weit.

**Er hält zwischendurch inne.** `Stand_Up1` ist eine durchlaufende Bewegung: jemand steht auf,
fertig. Wer nach Stunden im Schutt aufwacht, tut das nicht am Stück. Zwei **Haltepunkte**, an
denen der Clip stehenbleibt, plus ein Grundtempo unter eins — aus acht Sekunden Animation wird
eine halbe Minute Aufstehen. Das Tempo rechnet sich aus der echten Cliplänge; ein neues Rig
muss nicht neu eingestellt werden.

**Er ist beleuchtet.** Der Prolog beginnt um 18:36, und die Schrottgrube hat 66°-Wände: In
einem Krater ist tief stehendes Licht genau das, was *nicht* ankommt. Der Grubenboden bekam nur
Umgebungslicht, die Figur war eine Silhouette ohne Gesicht — im Augenblick, in dem man ihr am
nächsten ist. Deshalb hat die Szene ein eigenes Licht: warm, tief, von der Seite, wie die letzte
Sonne über dem Kraterrand. Es geht am Ende mit der Kamerafahrt unter.

**Er redet, und die Tafel läuft von selbst weiter.** Sechzehn Zeilen, jede so lange stehend,
wie sie zu lesen braucht; ein Tipp überspringt die Restzeit. Erst der Körper, dann der Ort,
dann die Frage nach ihm selbst — und die bleibt offen:

> **DER NAMENLOSE:** „…hh."
> „Mein Schädel. Als hätte mir jemand einen Kessel drübergezogen und draufgeschlagen."
> „Öl im Mund. Rost in der Nase. Und irgendwas Klebriges im Haar."
> „…das ist Blut. Meins, nehm ich an."
> „Wo bin ich hier? Blech. Fässer. Ein halber Zug."
> „Eine Kippe. Ich lieg auf einer Müllkippe, in einer Pfütze aus irgendwas."
> „Wie komm ich hierher? Denk nach. Irgendwas."
> „Nichts. Kein Weg, kein Gesicht, kein gestern."
> „Wer bringt einen Mann auf eine Halde und lässt ihn liegen? Und wofür?"
> „Wie heiße ich eigentlich."
> „…"
> „Auch das noch nicht. Gut. Später."
> „Wasser. Ich brauch Wasser, und was zu essen, und was zum Festhalten."
> „Aber zuerst muss ich mich orientieren. Ich weiß ja nicht mal, wo ich hier bin."
> „Da drüben ragt was aus dem Sand. Ein Fels, hoch genug."
> „Von da oben sehe ich vielleicht mehr als Blech und Dreck."


Dass die Frage nach dem Namen unbeantwortet stehenbleibt, ist der ganze Aufbau der Geschichte
in einem Satz.

Die letzten drei Zeilen sind der **Auftrag an den Spieler**: Er sagt selbst, dass er sich
orientieren muss, und er sagt selbst, wohin — auf den Fels. Danach zeigt die Fußspur genau
dorthin. Ohne diese Zeilen wäre die Spur eine Anweisung von außen; mit ihnen ist sie sein
eigener Entschluss.

**Und erst danach.** Die Spur lag zunächst schon da, während er sechzehn Zeilen lang sagt, dass
er nicht weiß, wo er ist — der Weg war vor der Entscheidung da, die ihn erklärt. Sie wartet
jetzt das Erwachen ab, und ebenso jede Kamerafahrt: Ein Hinweis für den Spieler am Steuer ist
sinnlos, solange die Kamera anderswo ist.

**Die Hände sind auch wirklich leer.** Das Waffenmodell wird beim Aufbau der Welt einmal erzeugt
und danach nur ein- und ausgeblendet — nur stand die Sichtbarkeit auf dem Vorgabewert *sichtbar*,
und im Prolog gibt es keinen Waffenwechsel, der das korrigiert hätte. Der Karabiner hing also von
Anfang an an der Schulter. Beim Aufwachen fiel es besonders auf: Die Waffe hängt an einem festen
Punkt im Spielerknoten, nicht an einem Knochen, und während die Figur am Boden liegt, bleibt der
Knoten stehen — sie schwebte dort in der Luft, wo die Schulter wäre, wenn sie schon stände.

Die **Lache**, auf der er liegt, zeigt den Himmel — abends kupfern, nachts blaugrau. Ohne das
war sie ein schwarzes Loch, das die Figur verschluckte: `metallic` ohne Himmelsreflexion ist
schwarz, und der Grubengrund liegt im Schatten der Wand.

**2. Leere Hände.** Wer den Schuss-Knopf drückt, bekommt „🚫 Leere Hände. Such dir etwas."
Das ist der erste Lehrsatz des Spiels und braucht keinen Text darüber hinaus.

**3. Die Truhe.** Steht am **Rand der Lache**, in Richtung des Lokomotivenwracks — nicht in der
Mitte: Dort liegt der Held, und die Truhe stand buchstäblich auf ihm. Die Richtung kommt aus der
Szene, wer das Wrack im Editor verschiebt, nimmt die Truhe mit. Darin liegt der **Blei-Karabiner** —
garantiert, nicht ausgewürfelt. Der Anfang einer Geschichte darf nicht auswürfeln, ob sie
stattfindet. Dazu Gold, Munition, ein Ausrüstungsteil.

Und er **sagt es auch** — eine kurze Nahaufnahme, sechs Sekunden, kein Rundflug: Hier geht es um
einen Gegenstand in zwei Händen, nicht um einen Ort.

> **DER NAMENLOSE:** „Ein Karabiner. Lauf voller Sand."
> „Er passt in meine Hand, als hätte ich das schon tausendmal gemacht."
> „Woher weiß ich das?"

Das ist die erste Stelle, an der die Figur etwas kann, was sie sich nicht erklären kann —
dieselbe Frage, die beim ersten Gegner wiederkommt (*„…und woher weiß ich, wo man so ein Ding
trifft?"*) und die die ganze Geschichte trägt. Der Satz stand seit Langem in diesem Blatt und
wurde im Spiel nie gesprochen; ohne ihn ist der Fund eine Ausrüstungsmeldung.

**4. Das Pferd.** Steht am Kraterrand, auf der Seite von Rustwater, mit Namensschild. Aus 4 m
erscheint **🐎 Aufsitzen** in der Aktionsleiste (oder `[E]`): **dreifaches Tempo, kein Schuss aus
dem Sattel.** Der Weg in die Stadt ist gut einen Kilometer weit; zu Fuß sind das vier Minuten,
im Sattel gut eine.

**4b. Der erste Gegner.** Beim Verlassen des Kraters, und nur mit Waffe in der Hand. Einer statt
des üblichen Rudels, seitlich vor ihm, hat ihn noch nicht gesehen — und eine **Maschine**: ein
zwei Meter hohes Konzern-Konstrukt. Ein bewaffneter Mann wäre in dieser Wüste keine Überraschung;
ein Kessel, der aus dem Blech kommt, ist eine, und er stellt die Frage des ganzen Spiels in der
ersten Minute. **Er schießt selbst** — der Spieler drückt nicht. Danach die Kamera langsam auf den Toten, und **erst dann** liegt Beute da.
Die ganze Szene steht in `docs/TITEL_UND_GRENZEN.md`; der Kern ist die letzte Sprechzeile, die
das Plündern begründet statt es als Spielfunktion zu erklären.

**4c. Die erste Steuerwalze.** Aus dem Konstrukt, garantiert. Sechzehn Erinnerungen stehen in
`MemoryManager` und waren bis jetzt unerreichbar — sie kommen aus **mechanischen** Gegnern
(3 %, beim Boss 50 %), und das ist keine Willkür: Was der Held von sich selbst nicht weiß, steckt
in Maschinen derselben Bauart. Wer eine aufschneidet, findet ein Stück von sich.

Gezeigt wird sie unter dem Heldennamen und nicht als Fundmeldung — eine Erinnerung ist kein
Gegenstand, den man einsteckt, sie fällt jemandem ein.

> **DER NAMENLOSE:** „Da ist eine Walze drin. Sie dreht sich noch."
> *(die erste Erinnerung — „Der Nagel")*
> „…das war nicht meine Erinnerung. Das ist sie aber."

**5. Der Weg.** Die Fußspur führt aus der Grube **zuerst auf den Ausguck**, danach nach
Rustwater — und dort, seit die Palisade steht, **durch das Tor** statt gegen die Mauer.

Vorher gab es während des ganzen Prologs *gar keine* Spur: Der Wegweiser hing an der verfolgten
Quest, und die erste Quest bekommt man in Rustwater — also genau dann, wenn man den Weg schon
gefunden hat.

Solange er noch draußen ist, zeigt sie auf den **Fuß der Rampe**, nicht auf den Gipfel. Der Fels
ist rundum 77° steil; eine Spur, die geradewegs nach oben weist, führt gegen eine Wand —
dasselbe Problem wie bei der Palisade, wo sie vor der Mauer endete statt durchs Tor zu gehen.
Erst wenn er am Fels steht, zeigt sie hinauf.

**5b. Der Ausguck.** Auf halbem Weg (269 m von der Grube, 246 m vor der Stadt) ragt ein
**15 m hoher Fels** aus dem Sand: zwei Kuppen mit einer Senke dazwischen, ringsum steile Kante,
auf der Grubenseite ein Sporn, über den man hinaufkommt. Wer aus der Grube kommt, sieht ihn vor
sich und steigt hinauf, um sich zu orientieren.

**Der Aufstieg ist eine Flanke, keine Spalte.** Der Rampensektor war mit 54° zu eng: Weil
`_rampen_anteil` von der Mitte nach außen ausblendet, war davon nur der innere Kern voll
wirksam, und was man beim Hochlaufen sah, waren zwei Felswände links und rechts und eine Rinne
dazwischen. Mit **96°** geht man eine breite Flanke hinauf. Die Steigung in der Mitte ändert
sich dadurch nicht — dort ist der Rampenanteil in beiden Fällen 1 —, nur die Breite, auf der
sie gilt.

**Und man bleibt nicht mehr hängen.** Das ist eine andere Frage als *„ist der Hang begehbar"* —
gemessen war er das die ganze Zeit. Zwei Dinge zusammen sperrten den Weg:

* **Das Maßband war zu kurz.** Gemessen wurde der Einzelschritt eines Bildes: 4,7 m/s bei
  60 Bildern sind 7,8 cm. Auf acht Zentimetern entscheidet nicht der Hang, sondern die Körnung —
  die aufgesetzten Buckel wellen den Fels um anderthalb Meter, und ein Kiesel darin überschreitet
  45°, obwohl der Weg drumherum bequem ist. Gemessen wird jetzt auf **0,7 m**, gut eine
  Schrittlänge.
* **Ausgewichen wurde nur achsenweise.** Das ist für Hausecken gebaut und dort richtig: Wände
  stehen achsenparallel, also gleitet man an ihnen entlang. Ein Berg hat keine Achsen — wer gegen
  eine zu steile Stelle lief, bekam beide Achsenkandidaten ebenfalls als zu steil zurück und
  blieb stehen, obwohl zwanzig Grad daneben ein bequemer Weg lag. Jetzt wird erst **schräg zum
  Hang** ausgewichen (22°, 45°, 68° nach beiden Seiten), dann achsenweise. Genau so geht man
  einen Hang auch wirklich hinauf: nicht in der Falllinie.

Nachgemessen wird das, indem der Marsch vom Rampenfuß in den Ring **simuliert** wird — die
Steigung einer einzelnen Stelle sagt darüber nichts. Ergebnis: Mit der alten Regel bleibt die
Figur unterwegs stecken und kommt nie an; mit der neuen erreicht sie den Ring ohne eine einzige
Stockung. Und die Simulation sagt auch, dass **keine der beiden Änderungen allein reicht** —
weder das längere Maßband noch das schräge Ausweichen für sich bringt sie hinauf.

**Ein Fels, kein Hügel** — der Unterschied steckt in drei Dingen:

* **Der Umriss ist nicht rund** (`kerb` 0,27): Der Radius schwankt je nach Richtung zwischen 18
  und 30 m, mit Vorsprüngen und Einbuchtungen. Ein Kegel liest sich als Hügel, egal wie steil er
  ist. Der größte Vorsprung liegt auf dem Aufstieg — wo ein Fels einen Sporn hat, läuft der Weg
  hinauf, und dort ist er am flachsten.
* **Die Oberkante ist eine Kante.** `smoothstep` setzt an beiden Enden waagerecht an — für eine
  ausgewaschene Erdwand richtig, für Fels falsch: Genau diese abgerundete Oberkante macht ihn im
  Bild zur Kuppel. Stattdessen `(1−u)^1,8`: am Rand am steilsten (63–74°), nach unten
  abflachend, wo sich der Sand anlegt. Das ist die Silhouette einer Tafelberg-Kuppe.
* **Er ist steinfarben.** Scheitelfarben auf dem vorhandenen Sand-Shader, über die Höhe
  eingeblendet: unten Sand, ab gut vier Metern Stein. Keine zweite Textur, kein zweites Netz.

**15 m, nicht 24.** Man will darüber stehen, nicht darauf thronen: Aus 15 m liegt Rustwater in
255 m Entfernung 3,4° unter der Waagerechten — die Kamera schaut also praktisch geradeaus unter
der Felskante hindurch in die Ebene, statt von oben auf eine Landkarte.

Und es ist **Gelände, kein 3D-Objekt** — ein *umgedrehter Krater*: dieselbe Formel, `depth`
negativ. Das Höhenprofil eines Kraters ist ein flacher Boden, eine steile Wand und ein
Sektor, in dem die Wand fehlt; Vorzeichen gedreht ergibt genau das Gesuchte. `height_at()` ist
die einzige Wahrheit für Bodenhöhe im ganzen Spiel — daran hängen Laufen, Fußspuren, Streuung,
jede Figur und jede Kiste. Ein aufgestelltes Modell wüsste davon nichts: Man liefe hindurch, die
Fußspur ginge darunter her, Gegner ständen in der Luft.

Gemessen: **Kante 63–74°, Aufstieg 38°.** Dazwischen liegt die neue **Steigungsgrenze von 45°** — bis
jetzt gab es keine, man lief die 66°-Wand der Schrottgrube hoch wie eine Fliege und ihre Rampe
war reine Deko. Gesperrt wird nur *bergauf*; wer von der Kante springt, hat sich dafür
entschieden.

**Sie startet erst ganz vorn — und man sieht, wo.** Zwei Auslöser wurden verworfen, beide aus
derselben Sorte Fehler. Der erste fragte nur den *waagerechten* Abstand zur Felsmitte ab: Auf der
Rampe steht man dort erst auf halber Höhe (8,2 m über dem Sand, knapp sieben Meter unter dem
Gipfel), die Fahrt fing an, und die Kamera kreiste auf Gipfelhöhe um einen Punkt weiter unten —
also durch den Berg. Der zweite zählte zusätzlich die Höhe. Besser, aber immer noch geraten: Das
Plateau ist breit, und *oben* heißt nicht *vorn*.

Falsch war nicht die Formel, sondern der Ansatz. **Ein Auslöser, den der Spieler nicht sehen
kann, zwingt ihn zu raten, wo „richtig" liegt** — und wenn er danebensteht, gibt er sich selbst
die Schuld. Also steht dort jetzt ein **leuchtender Ring**, die Fußspur läuft hinein, und die
Bedingung lautet: *Stehst du drin?* Mehr nicht. Der Ring atmet langsam, damit er als Ziel gelesen
wird und nicht als Verzierung, und verschwindet mitsamt Beschriftung, sobald die Rundsicht einmal
gelaufen ist.

Wo er liegt, wird **gemessen**, nicht eingetragen: der **höchste Punkt der rechten Kuppe**, auf
dem der Ring noch ganz aufliegt. „Rechts" ist dabei nicht willkürlich, sondern das Kreuzprodukt
aus Blickrichtung und Hochachse — dieselbe Rechnung, mit der auch eine Kamera ihren Rechtsvektor
bildet. Gemessen kommt dabei heraus: **16,1 m**, gut einen Meter über dem Gipfelmittelpunkt und
3,0 m rechts der Achse; der tiefste Punkt des Reifens liegt noch auf 15,3 m, und acht Meter
Richtung Rustwater fällt der Fels auf 8,3 m ab.

**Die Fußspur nimmt dabei den Umweg über die Kuppe.** Solange der Ring auf der Blickachse lag,
brauchte es das nicht — die Rampe zeigt dorthin, wer ihr folgt, kommt an. Seit er auf der
rechten Kuppe sitzt, läuft die gerade Linie vom Rampenfuß zum Ring quer über die Flanke, und die
steht mit **72°** weit jenseits der Steigungsgrenze: Die Spur zeigte auf eine Wand. Derselbe
Fehler wie damals an der Palisade, wo sie vor der Mauer endete statt durchs Tor zu gehen. Jetzt
zeigt sie erst auf die Felsmitte — den Kopf der Rampe — und von dort in den Ring; über den
Sattel dazwischen ist der steilste Schritt 39°.

Ein Höhenmaximum allein reicht dafür nicht: Eine Spitze ist der höchste Punkt und trägt keinen
Ring von 1,8 m. Jeder Kandidat wird deshalb mit seinen acht Ringpunkten geprüft, und es gewinnt
der höchste, auf dem der Reif nicht wegsackt. Weil das gerechnet und nicht eingetragen ist,
wandert der Punkt mit, wenn jemand den Fels umbaut.

> **Ein vierter verworfener Anlauf**, der beinahe stehen geblieben wäre: die Messung der
> Vorderkante Richtung Rustwater — nach außen bis zum Abbruch, dann um den Ringradius zurück.
> Sie funktionierte und lag trotzdem falsch, weil der Fels **zwei Kuppen** hat und die
> Vorderkante genau in die Senke dazwischen fällt: 14,7 m, während zwei Schritte weiter rechts
> 16,6 m gewesen wären. Eine korrekte Rechnung auf die falsche Frage.

> Zwei Zwischenlösungen, die sich nicht bewährt haben, stehen hier als Warnung. **Erstens:** Weil
> der Standplatz nur 2,6 m vor dem Gipfelpunkt landete, sah das nach einer *Rinne* aus — die
> Kerbung schneidet Spalten in die Kuppe, und ein einzelner Messstrahl bleibt an der ersten
> hängen. Ein Fächer aus fünf Strahlen sollte darüber hinweglaufen und verschob den Punkt um
> keinen Zentimeter: Die Rustwater-Seite ist keine Rinne, sondern eine Schulter, die sofort
> weggeht. **Zweitens:** Der Ring hatte zuerst keinen Tiefentest, damit er auf welligem Fels
> nicht halb versinkt. Im Bild trug die Figur ihn dann wie einen Hula-Hoop um die Hüfte — ein
> Kreis, den der Spieler nicht verdeckt, wenn er darin steht, liest sich als Bedienelement und
> nicht als Ort. Beides war am Screenshot in einer Minute zu sehen und an der Formel gar nicht.

**Und drittens: keine Füllscheibe.** In der Mitte des Rings lag eine schwache Scheibe, damit der
bloße Umriss sich nicht „als Loch liest". Sie stand in drei Fassungen (0,16 / 0,24 / 0,07 Alpha)
und war in jeder falsch — additiv über hellem Fels addiert sich eine Fläche zu einer Fläche, und
heraus kam eine leuchtende Scheibe statt eines Kreises. Die Begründung stimmt für einen dünnen
Strich; ein 32 cm breites Band ist keiner. Lesbar wird es durch eine schmale, dunklere
**Innenkante** dicht am inneren Rand: Die gibt dem Band Tiefe, statt die Mitte zu füllen.

Oben übernimmt die Kamera ein zweites Mal — **rund 25 Sekunden**, und zwar als **eine einzige
Bewegung**:

1. Sie fährt dort los, wo sie schon steht — die Spielkamera hinter ihm. Kein eigener
   Anfangspunkt, also am Anfang gar keine Naht.
2. Eine **ganze Runde** um ihn (360°, 14 s = 26°/s), und dabei schraubt sie sich hinaus und
   hoch: am weitesten bei 55 % der Drehung (34 m Abstand, 15 m Höhe). Der Bildwinkel zieht dabei
   von 50° auf 78° auf — das ist das Rauszoomen, und es passiert über die halbe Drehung statt
   in einem Schnitt.
3. Zum Ende der Runde kommt sie wieder heran (11 m) und wird langsamer.
4. Schwenk über seine Schulter **hinunter ins Tal auf Rustwater** (2,6 s), Bildwinkel zieht auf
   52° zu.
5. Und dann **bleibt sie sechs Sekunden stehen**. Sonst nichts.
6. Zurück in die Ausgangshaltung (2,4 s).

**Warum eine Bewegung und nicht fünf.** Vorher waren es fünf Etappen — von unten am Fels hoch,
eng herum, in einem Zug weit hinaus, zurück über die Schulter ins Tal, heim. Jede für sich war
begründet, und zusammen ruckelte es: An jeder Naht sprang die Richtung, und `_flight_frame` fährt
jeden Abschnitt für sich sanft an und wieder aus. Aus fünf sauberen Bewegungen wurden vier
Bremsungen. Dazu tauchte die erste Etappe neun Meter *unter* den Standplatz — ein Hoch-Runter,
bevor die Fahrt überhaupt anfing.

Jetzt laufen Winkel, Radius, Höhe und Bildwinkel alle über **denselben Parameter**. Es gibt keine
Stelle, an der etwas springen könnte. Nachgemessen: Das Tempo ändert sich von einem Stützpunkt
zum nächsten um höchstens **4,5 % des Spitzentempos** der Fahrt.

> Die erste Fassung dieser Messung verglich jeden Schritt mit seinem Vorgänger und meldete 195 %
> — was nichts bedeutete. Am Anfang steht die Kamera fast still, und von 0,02 auf 0,06 m/s sind
> nun einmal 200 %, ohne dass ein Auge das je bemerkt. Wahrgenommen wird eine Tempoänderung im
> Verhältnis zur *ganzen* Bewegung.

> **DER NAMENLOSE:** „Von hier oben sieht man wenigstens etwas."
> „Wüste. Wüste. Und noch mal Wüste."
> „…da. Ganz hinten im Tal."
> „Dächer. Ein Turm. Und Licht — da lebt jemand."
> „Ein Fußmarsch. Aber der erste Weg, der irgendwohin führt."

**Warum das der richtige Ort dafür ist:** Ein Überblick, den man sich *ergeht*, ist etwas anderes
als einer, den man geschenkt bekommt. Der Held weiß nicht, wo er ist; er sucht sich den höchsten
Punkt und steigt hoch. Das ist eine Handlung, keine Zwischensequenz — die Kamera bestätigt sie
nur. Der Anflug bei 95 m (Punkt 6) bleibt davon unberührt: Der Ausguck sagt *„dahin"*, der
Anflug sagt *„da bin ich"*.

**6. Der Anblick.** Auf **95 m** übernimmt die Kamera, einmal im ganzen Spiel — **rund
sechsundzwanzig Sekunden**, jederzeit mit einem Tipp abbrechbar. Rund, weil die Dauer keine
feste Zahl mehr ist: Der Rückweg rechnet sich aus dem Standort der Figur. Solange die Fahrt läuft, steht die Figur; sonst
liefe sie weiter, während die Kamera anderswo ist, und die Fahrt endete dreißig Meter hinter ihr.

Die 95 m sind gemessen, nicht geschätzt: Bei 200 m ist Rustwater nachts ein schwarzer Streifen
am Horizont. Die Nachtlichter reichen 11 bis 23 m weit; was davon auf 200 m ankommt, sind ein
paar Pixel unter der Nebelgrenze. Bei 95 m steht der Wasserturm als Silhouette im Bild, die vier
Torfackeln sind einzeln zu erkennen, und der Sand vor der Palisade glüht.

| | Etappe | Dauer | Tempo |
|---|---|---|---|
| 1 | **In seine Sicht** — auf Augenhöhe, Blick auf die Stadt | 2,0 s | steht |
| 2 | **Anflug** — über Wüste und Palisade hinauf auf Turmhöhe, in einem Zug | 2,8 s | 14 m/s |
| 3 | **Um die Palisade** — eine ganze Runde, Blick nach innen, von 24 auf 40 m steigend | 13,3 s | 27°/s |
| 4 | **Rückwärts hinaus** — Blick bleibt auf Rustwater | ~4,6 s | 14 m/s |
| 5 | **Figur und Ort in einem Bild** — von hinten über ihre Schulter | 1,6 s | steht |
| 6 | **Einschwenken** in die Spielperspektive | 1,6 s | — |

**Die Verteilung ist der Inhalt.** Nicht jede Etappe bekommt gleich viel, sondern so viel, wie
ihr Tempo sein soll. Die Umrundung bekommt die Hälfte der Fahrt und wirkt dadurch ruhig, obwohl
sie sich dauernd bewegt.

**Der Rückweg ist der Hinweg rückwärts.** Er ist als einziger Abschnitt keine feste Zahl,
sondern eine Rechnung: Weg geteilt durch das Tempo des Anflugs. Vorher standen dort 1,2 s, und
weil die Umrundung mit 230° auf der *gegenüberliegenden* Seite endete, wurde daraus ein Sprung —
rund 48 m/s gegen 14 m/s beim Hereinfliegen. Im Bild sah das aus, als hätte jemand die Fahrt
abgebrochen.

Eine feste Zahl kann das nicht lösen: Wo die Umrundung endet, hängt am Bogenwinkel, und wie weit
es von dort nach Hause ist, am Standort der Figur. Beides darf sich ändern, ohne dass das Tempo
kippt.

**Deshalb ist die Runde jetzt geschlossen.** 250° schwenkten mit knapp 30°/s — die Grenze, ab
der eine Establishing-Fahrt schmiert —, also wurden daraus 230°; beide endeten aber gegenüber,
und der Heimweg war 173 m lang. Bei **360°** endet die Umrundung dort, wo sie angefangen hat, auf
der Seite der Figur: Der Rückweg ist dieselbe Strecke, dieselbe Dauer, dasselbe Tempo. Das ist
nicht nur kürzer als die 230°-Fassung (26 s statt 30 s), es ist auch der einzige Bogen, bei dem
*„zurück wie hin"* überhaupt eine Bedeutung hat.

**Gemessen wird der Schwenk, nicht die Bahn.** Solange die Fahrt den Wasserturm auf 27 m Abstand
umkreiste, hieß „langsam in m/s" auch „langsam im Bild". Um die Palisade herum liegt die Kamera
64 m draußen, und dort ergibt derselbe Bogen in derselben Zeit zwangsläufig die doppelte
Bahngeschwindigkeit, obwohl das Motiv genauso schnell vorbeizieht — ein Maß, das sich mit dem
Radius ändert, sagt nichts über den Bildeindruck. Wahrgenommen wird die
**Winkelgeschwindigkeit**: Über etwa 30°/s verwischt eine Establishing-Fahrt, darunter hat das
Auge Zeit mitzugehen. Die Fahrt bleibt bei 27°/s.

**Und am Ende steht der Satz, den die ganze Fahrt sagen soll.** Die Kamera fährt rückwärts hinaus
und behält Rustwater im Bild — das letzte, was man vom Ort sieht, soll der Ort sein und nicht der
Hinterkopf der Figur. Dann steht sie hinter ihr, 26 m zurück und 13 m hoch, und zeigt beides in
einem Bild: die Figur im Vordergrund, die Lichter am Horizont. *Da will er hin, und da steht er.*
Erst danach kippt und zieht sie in die Spielperspektive — 1,6 s, nicht 0,8 wie vorher, weil sie
jetzt von weiter hinten und höher kommt.

Der Rückweg ist mit zwei Sekunden der **kürzeste** Abschnitt. Schneller als der Hinflug ist er
in Metern je Sekunde nicht, und kann es nicht sein: Die Umrundung endet auf der Seite, auf der
die Figur steht, es sind also nur noch gut 40 m nach Hause gegenüber 95 m auf dem Hinweg.

Er **endet exakt in der Ausgangshaltung** — nicht „über der Figur nachgerechnet", sondern die
beim Start gemerkte Kamera-Transform. Das ist dieselbe Zusage auch dann noch, wenn jemand
zwischendurch den Zoom verstellt hat.

**Umrundet wird die Palisade, nicht der Wasserturm.** Der erste Entwurf kreiste um den Turm,
weil er die Landmarke ist. Im Bild war das eine Fahrt um ein Fass: Der Turm füllte den Rahmen,
die Stadt lag als Streifen dahinter, und weil er am *Ortsrand* steht, schaute die halbe
Umrundung nach draußen in die Wüste.

Um die Mauer herum, mit dem Blick nach **innen**, zeigt jede Sekunde dasselbe Motiv aus einer
neuen Richtung: den beleuchteten Ort. Der Turm ist dabei nicht weg — er dreht sich als
Silhouette durch das Bild, so wie man ihn beim Herangehen auch sieht.

Der Radius kommt aus dem **tatsächlichen** Umriss der Palisade plus 22 m Abstand; eine feste
Zahl wäre in dem Moment falsch, in dem jemand im Editor ein Mauerstück versetzt.

Dazu die Zeile: *„🌙 Rustwater. Licht in der Wüste."* Der Flug merkt sich in
`GameState.saw_rustwater`, dass er gelaufen ist — er kommt nicht wieder.

**Abschluss des Prologs:** Betreten von Rustwater setzt `GameState.prolog_done = true`. Ab dann
beginnt eine Runde wieder in der Stadt; niemand soll nach dem zweiten Kapitel wieder auf der
Kippe aufwachen.

### Den Prolog noch einmal sehen

Das Spiel speichert **automatisch**. Es gibt also keinen Zustand „noch nicht gespeichert" — wer
einmal gestartet ist, fängt beim nächsten Mal mit Spielstand an.

**Der einfache Weg: `[F9]`, zweimal.** Der erste Druck fragt nach, der zweite setzt den Prolog
zurück und lädt die Szene neu. Fortschritt (Level, Gold, Quests, Nebel) bleibt; zurückgesetzt
werden nur Prolog-Marken, Uhrzeit und Waffen — mit dem Karabiner im Arm wäre „leere Hände" keine
Aussage mehr. Zweimal drücken, weil `F9` neben `F10` und `F11` liegt und ein Fehlgriff nicht
rückgängig zu machen wäre.

Dass das überhaupt möglich ist, hängt an `GameState.saw_wake`: Die Aufwach-Szene hängt an
diesem Merkmal, **nicht** daran, ob ein Spielstand geladen wurde. Sonst bekäme man sie nach dem
allerersten Start nie wieder zu sehen — auch nicht nach einem Zurücksetzen.

Für den Start von außen gibt es zusätzlich zwei Schalter:

| Schalter | Wirkung |
|---|---|
| `--prolog` | wie `[F9]`: Spielstand behalten, nur den Prolog zurücksetzen |
| `--neu` | Spielstand **löschen**. Wirklich von vorn. |

Sie stehen in den **Editor**-Einstellungen (nicht den Projekteinstellungen):
*Editor → Editor-Einstellungen → Ausführen → Main Run Args* (`editor/run/main_run_args`). Auf
der Kommandozeile direkt anhängen. Von Hand geht es auch: Die Datei heißt
`rustlead_save_0.json` und liegt im Godot-Benutzerordner (`%APPDATA%\Godot\app_userdata\Rust & Lead\`
unter Windows, `~/Library/Application Support/Godot/app_userdata/Rust & Lead/` auf dem Mac).

---

## Erste Begegnung: Mabel

Die Kette in Akt I steht schon im GDD: **Mabel → Silas → Doc → Mabel**. Der erste Dialog gehört
deshalb **Mamma „Rusty" Mabel**, der Saloon-Wirtin.

Sie ist die richtige Erste, weil sie die Einzige ist, die einen Fremden ohne Frage hereinlässt —
und weil ihre Rolle vor dem Reveal *mütterlich* ist. Der Held wird umsorgt wie ein Mensch. Genau
das macht den Reveal in Kapitel 4 zur Ohrfeige.

> **Mabel:** „Du siehst aus wie durchgekaut und wieder ausgespuckt. Setz dich, bevor du umfällst."
>
> **Mabel:** „Von der Kippe rauf, ja? Da liegen normalerweise nur Blech und Knochen. Du bist mir
> ein hübsches drittes."
>
> **Mabel:** „Namen brauch ich keinen. Wer aus dem Schrott kommt, hat meistens keinen mehr.
> Trink das hier und hör mir zu."

Danach die erste Quest, unverändert aus dem GDD:

**`q_bounty` — „Kopfgeld: Wegelagerer"** · 8 Wegelagerer · 120 💰 + Zahnrad

> **Mabel:** „Draußen sitzen Wegelagerer auf der Piste und nehmen sich, was durchkommt. Acht
> Stück, sagt der Aushang. Bring mir den Beweis, dann bring ich dir was Ordentliches zu essen."

Von da an trägt die vorhandene Kette: `q_bounty` → Silas `q_scrap` → Doc `q_rats` → Mabel
„Hinab in die Schrott-Mine", und jeder NPC weist zum nächsten.

---

## Was noch fehlt, damit das läuft

Der Prolog steht mechanisch. Was ihn zur **Erzählung** macht, fehlt noch:

| | Was | Aufwand |
|---|---|---|
| ~~1~~ | ~~**Dialoge als Daten.**~~ **Erledigt** — `DialogData.gd`, sechs Personen, fünf Anlässe, eigene Zeilen nach dem Reveal. |  |
| ~~3~~ | ~~**Erstbegegnung mit Mabel erzwingen**~~ **Erledigt** — die Fußspur führt in der Stadt zu ihr, bis man mit ihr geredet hat. |  |
| 1 | **Alte Dialoge als Daten (Rest).** Bisher liefert `OverworldView._npc_line()` je NPC einen Satz aus einer `if`-Kette. Für eine Story braucht es mehrseitige Gespräche mit Zustand („erstes Mal", „Quest läuft", „abgabebereit") — also eine `DialogData`-Tabelle wie `QuestManager.QUESTS`, und die Sprechtafel blättert durch. | mittel |
| 2 | **Weitere skriptierte Momente.** Der Mechanismus steht (`_play_flight` für die Kamera, `_play_beats` für den Text, beides an Aufwachen und Ankunft schon verdrahtet). Was fehlt, sind die übrigen Auslöser — vor allem die Truhe. | klein |
| 3 | **Erstbegegnung mit Mabel erzwingen** — Marker über ihrem Kopf, Fußspur zu ihr statt zum Quest-Ort. (`prolog_done` wird inzwischen gesetzt.) | klein |
| 5 | **Codex/Erinnerung** — die Kinetoskop-Walzen (§8.3) sind im Backend fertig, aber im Prolog noch nicht angefasst. Die erste Walze gehört in die Grube. | klein |

Reihenfolge-Vorschlag: **1 → 3 → 4 → 2 → 5.** Ohne (1) ist alles andere Text in einer
Meldungszeile.

---

## Waffen: was er wann hat

`GameState.weapons` führt, was er **gefunden** hat. Vorher trug er alle fünf von der ersten
Sekunde an — damit ist jede Beute wertlos und die vier Schadensarten (§6.1) haben keinen Aufbau.

| Waffe | Art | woher | wann |
|---|---|---|---|
| **Blei-Karabiner** | Kinetik | Truhe in der Schrottgrube | Prolog, garantiert |
| Messing-Gatling | Kinetik | Werkstatt / Beute | Kap. 2 |
| Leydener Volt-Karabiner | Galvanik | Beute Konzern-Patrouille | Kap. 2–3 |
| Säure-Sprüher | Alchemie | Doc / Labor-Ausbau | Kap. 3 |
| Dampf-Brenner | Thermik | Mine, Boss-Beute | Kap. 3–4 |

**Es gibt keinen Umschalter mehr.** `[Tab]` schaltete früher durch eine feste Liste von fünf
Gattungen — eine zweite Wahrheit neben dem Inventar, die nichts von Seltenheiten und Werten
wusste. Angelegt wird im **Beutel**, wie jedes andere Ausrüstungsteil; `[Tab]` öffnet ihn.

Ohne Waffe: kein Schuss, kein Munitionszähler, und die Meldung sagt warum.
