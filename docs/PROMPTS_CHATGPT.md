# Sprite-Prompts für ChatGPT — alles in einer Datei

Einundzwanzig Bilder: **sechs Figuren**, **dreizehn Gegenstände** und **zwei Portraits**. Alle sind im Spiel
bereits angemeldet — Pfad, Fußpunkt und Größe stehen fest. Es fehlen nur die Bilder.

---

## So benutzt du diese Datei

ChatGPT ist kein Dienst, bei dem jeder Aufruf für sich steht — dort etabliert man den Stil
**einmal** und sagt danach nur noch, wer als Nächstes dran ist. Deshalb ist diese Datei
zweigeteilt.

1. **Teil A einmal einfügen**, am Anfang eines neuen Chats. Häng, wenn du kannst, die
   Datei `godot/assets/figuren/held_stand.webp` als Bild mit an — dann hat ChatGPT den
   Stil vor Augen und muss ihn nicht aus Worten rekonstruieren.

2. **Dann je eine Zeile aus Teil B oder C** einfügen, eine nach der anderen. Immer nur
   eine. Zwei Sprites in einem Bild kannst du nicht freistellen.

3. Bild herunterladen, umbenennen wie angegeben, in den richtigen Ordner legen.

**Wenn der Stil abdriftet** — und er driftet nach acht, zehn Bildern — schreib einfach
*„Erinnere dich an die Stilvorgaben von oben“* und häng nochmal ein gelungenes Sprite an.


---

## TEIL A — einmal am Anfang einfügen

```text
Ich baue ein 2D-Point-and-Click-Adventure im Stil von „Baphomets Fluch" (Broken Sword,
Revolution Software). Du erzeugst mir dafür nacheinander einzelne freigestellte Sprites.
Bitte merke dir die folgenden Vorgaben und wende sie auf JEDES Bild an, das ich gleich
anfordere, ohne dass ich sie wiederhole.

STIL
Handgemalt, sichtbarer Pinselduktus, klare lesbare Formen. KEIN Foto, KEIN 3D-Render,
KEIN Pixel-Art, KEINE Vektorgrafik, KEIN Anime. Setting: Steampunk-Western, spätes
19. Jahrhundert, amerikanische Grenze — Zahnräder, Nieten, Messing, Kesseldruck, öliges
Leder. Keine modernen Gegenstände, keine Elektrik, keine Neonfarben.

FARBEN
Ausschließlich eine warme Ocker-Rost-Leiter, keine anderen Farbtöne:
#090201 #140a06 #1e110b #2b1b13 #3f291b #583d27 #6f4c31 #865c3c #a57950 #c19769 #e2bf91
Mitteltöne tragen das Bild. Schatten bleiben offen und lesbar, niemals abgesoffenes
Schwarz. Getrennt wird über Helligkeit und Silhouette, nicht über Buntheit.

LICHT
Flach und gleichmäßig, weiches Fülllicht, keine dramatischen Schlagschatten. Grund: Das
Sprite muss sowohl vor heller Wüste als auch in einem dunklen Stollen lesbar sein. Es
bekommt sein Licht später aus der Szene, nicht aus sich selbst.

FORMAT — das ist das Wichtigste
Vollständig TRANSPARENTER Hintergrund (echtes Alpha, PNG). Kein Boden, kein Schlagschatten,
keine Kulisse, keine Vignette, kein Rahmen, kein Text. Ein einzelnes Motiv, zentriert,
komplett im Bild mit etwas Luft ringsum.
Falls du keinen transparenten Hintergrund erzeugen kannst: dann auf reinem Magenta
(#FF00FF) als Hintergrundfarbe, damit ich es sauber freistellen kann. Sag mir in dem Fall
bitte dazu, dass du Magenta benutzt hast.

FIGUREN
Dreiviertelansicht, ganzer Körper, aufrecht stehend, Füße auf einer gedachten Standlinie,
Arme entspannt. Kopf bis Schuhe vollständig im Bild. Hochformat.

GEGENSTÄNDE
Einzelnes Objekt, leicht von oben im Dreiviertelwinkel, so wie es in der Welt liegen oder
stehen würde. Quadratisch oder leicht breiter, Objekt möglichst formatfüllend.

AM ENDE
Wenn ich alle Motive durch habe, sage ich „fertig". Dann packst du mir ALLE erzeugten
Bilder in EIN zip-Archiv mit genau dieser Ordnerstruktur und gibst es mir zum
Herunterladen:

  godot/assets/figuren/   mabel.png silas.png doc.png gideon.png quentin.png dolores.png
  godot/assets/dinge/     revolver.png brecheisen.png schraubstock.png oellampe.png
                          linse.png signallampe.png walze.png akte.png grubenstahl.png
                          halstuecher.png kesselschluessel.png psalm_rolle.png
                          kinderjacke.png
  godot/assets/ui/        portrait_gideon.png portrait_jack.png

Die Dateinamen müssen exakt so lauten — sie stehen so im Quelltext des Spiels. Die
Ordner müssen im Archiv enthalten sein, nicht nur die Dateien. Transparenz (Alpha)
muss dabei erhalten bleiben; pack die Bilder unverändert ein, skaliere oder
komprimiere sie nicht nach.

Falls du an die erzeugten Bilder zum Packen nicht herankommst, sag mir das bitte
ehrlich, statt ein leeres oder unvollständiges Archiv zu bauen.

Bestätige mir kurz, dass du das übernommen hast. Danach schicke ich dir die Motive einzeln.
```


---

## TEIL B — die sechs Figuren

Jeweils einzeln einfügen. Ablage: `godot/assets/figuren/<dateiname>`


### Mamma „Rusty“ Mabel  →  `mabel.webp`

*Saloon-Wirtin*

```text
Nächste Figur, nach den Vorgaben von oben:

A woman of about fifty behind a bar. Heavy-boned, square-shouldered, forearms like anchor chains with the sleeves rolled past the elbow. Stained apron over a dark work dress, grey-streaked hair pulled back hard. She holds a glass in one hand and a cloth in the other and is wiping a glass that is already dry. Unimpressed, entirely unafraid.
```


### Silas „Kupferauge“ Finch  →  `silas.webp`

*Schmied*

```text
Nächste Figur, nach den Vorgaben von oben:

An old blacksmith, sixty or more, lean and sinewy, in a scarred leather apron over a collarless shirt, sleeves rolled, hands like tools. His LEFT eye is artificial — copper and lens glass with fine brass workings at the rim, set slightly crooked in the socket. Weight on one leg, a pair of tongs hanging from one hand.
```


### Doc Aris  →  `doc.webp`

*Feldscher*

```text
Nächste Figur, nach den Vorgaben von oben:

A gaunt man of about forty-five in a surgeon's apron on which two different kinds of blood have dried. Shirtsleeves rolled above the elbow, wire-rimmed spectacles pushed up on his forehead, thinning hair. He is drying his hands on a cloth and has been at it longer than necessary. Precise, nervous, not quite meeting the viewer's eye.
```


### Gideon Cross  →  `gideon.webp`

*Rebellenführer*

```text
Nächste Figur, nach den Vorgaben von oben:

A broad, heavy-set man in his fifties. Long dark coat over a bandolier, wide hat, a deep scar running from temple to jaw on one side. Arms folded, feet planted. Cold, appraising stare. Nothing theatrical about him — he looks like a man who has already decided.
```


### Quentin Vale  →  `quentin.webp`

*Konzernaufseher*

```text
Nächste Figur, nach den Vorgaben von oben:

A gaunt, clean-shaven man in his forties in an immaculate dark company uniform with brass buttons, high stiff collar and polished boots, hair combed flat. A slim leather document case under one arm. Perfectly polite posture, entirely unbothered, not a speck of dust on him.
```


### Dolores  →  `dolores.webp`

*blinde Drehorgelspielerin*

```text
Nächste Figur, nach den Vorgaben von oben:

A blind woman in her seventies, small and stooped, weathered face, milky unfocused eyes looking past the viewer. Worn headscarf over grey hair, a shawl, a long dark skirt. A barrel organ on a strap hangs at her front, one hand resting on its crank. She is listening, not looking.
```



> **Der Held ist schon da** (`held_stand.webp`, `held_walk_left.webp`,
> `held_walk_right.webp`). Falls du die NPCs auch laufend brauchst: dieselbe Zeile noch
> zweimal mit dem Zusatz *„walking to the left, mid-stride"* bzw. *„walking to the
> right, mid-stride"*. Nötig ist das nicht — die NPCs stehen im Spiel.


---

## TEIL C — die dreizehn Gegenstände

Jeweils einzeln einfügen. Ablage: `godot/assets/dinge/<dateiname>`


### Abgegriffener Revolver  →  `revolver.webp`

```text
Nächster Gegenstand, nach den Vorgaben von oben:

A worn six-shot revolver of the 1870s, blued steel gone grey at the edges, the wooden grip polished smooth by long use. Lying flat.
```


### Brecheisen  →  `brecheisen.webp`

```text
Nächster Gegenstand, nach den Vorgaben von oben:

A crowbar about an arm's length, flat forged steel with a clawed end, the grip wrapped in strips of dark cloth worn shiny.
```


### Schwerer Schraubstock  →  `schraubstock.webp`

```text
Nächster Gegenstand, nach den Vorgaben von oben:

A heavy cast-iron bench vice, twelve pounds, square jaws, long screw handle, old paint flaking off the body. Unbolted, standing free.
```


### Grubenlampe  →  `oellampe.webp`

```text
Nächster Gegenstand, nach den Vorgaben von oben:

A brass miner's safety lamp, dented, the glass smoked, a wire gauze cage around the flame, a hook at the top. Unlit.
```


### Kinetoskop-Linse  →  `linse.webp`

```text
Nächster Gegenstand, nach den Vorgaben von oben:

A thick ground glass lens the size of a palm in a decorated brass mount, with three small rivets where it was prised out of its housing.
```


### Signallampe  →  `signallampe.webp`

```text
Nächster Gegenstand, nach den Vorgaben von oben:

The same brass miner's lamp with a palm-sized ground glass lens clamped in a brass mount directly in front of its glass, held by a bent strip of metal. Clearly assembled from two things by hand.
```


### Gesprungene Musikwalze  →  `walze.webp`

```text
Nächster Gegenstand, nach den Vorgaben von oben:

A wooden music-box cylinder the length of a forearm, studded with small brass pins. A crack runs along its length; about a third of the pins are missing and the rest sit crooked.
```


### Akte „Projekt Mantel“  →  `akte.webp`

```text
Nächster Gegenstand, nach den Vorgaben von oben:

A thin medical file in a buff card cover, dog-eared, tied with cloth tape, a few pages fanning out. Any writing is illegible scribble and faded stamps — no readable words.
```


### Grubenstahl  →  `grubenstahl.webp`

```text
Nächster Gegenstand, nach den Vorgaben von oben:

Three short bars of rough mine steel, stacked, cold grey-blue under the rust, one edge crusted with something dark that is not ore.
```


### Acht Halstücher  →  `halstuecher.webp`

```text
Nächster Gegenstand, nach den Vorgaben von oben:

A bundle of eight dark red neckerchiefs knotted together, each with a small stitched mark in one corner. Dusty and sweat-stained.
```


### Sechskantschlüssel  →  `kesselschluessel.webp`

```text
Nächster Gegenstand, nach den Vorgaben von oben:

A short steel hex key with a cross handle, machine-made, out of place among surgical tools. Bright metal at the working end, oil-darkened at the grip.
```


### Kinetoskop-Rolle „PSALM“  →  `psalm_rolle.webp`

```text
Nächster Gegenstand, nach den Vorgaben von oben:

A cylindrical brass canister the size of a forearm, sealed at one end with a disc of dark red wax. Pressed into the wax: a cog-wheel crest and the number 13. Heavy, machined, cold.
```


### Kinderjacke  →  `kinderjacke.webp`

```text
Nächster Gegenstand, nach den Vorgaben von oben:

A child's canvas jacket for a seven-year-old, patched at both elbows with mismatched cloth, the patches sewn by hand and sewn well. Dusty, folded once.
```


---

## TEIL D — die zwei fehlenden Portraits

Portraits sind etwas anderes als Figuren: Sie erscheinen **in der Sprechtafel**, nicht im Ort.
Brustbild, quadratisch, dunkler Grund statt Transparenz. Sechs liegen schon vor
(`held`, `mabel`, `silas`, `doc`, `quentin`, `dolores`) — diese beiden fehlen.

Ablage: `godot/assets/ui/portrait_<name>.webp`

### Gideon Cross  →  `portrait_gideon.webp`

```text
Nächstes Bild, aber diesmal ein PORTRAIT statt einer Figur — andere Regeln:
Brustbild, Kopf und Schultern, Dreiviertelansicht, Blick leicht an der Kamera vorbei.
Quadratisch (1:1). Schlichter dunkler Hintergrund statt Transparenz. Weiches frontales
Licht, offene Schatten. Stil und Farbleiter wie gehabt.

A broad, heavy-set man in his fifties, a deep scar running from temple to jaw on one side,
wide hat, long dark coat over a bandolier. Cold, appraising, entirely unimpressed.
```

### Kolben-Jack  →  `portrait_jack.webp`

```text
Nächstes Bild, wieder ein PORTRAIT nach denselben Regeln wie eben.

A huge foreman in his forties in company grey, built like a boiler, soaked through with
rain, water running off his jaw. He is grinning — a man who finds all of this funnier than
he should. At the edge of the frame, the shoulder end of a heavy riveted steam piston
where his right arm should be, venting pressure.
```

> **Kolben-Jack braucht keine Ganzkörperfigur.** Er steht in keinem Ort herum — er bricht in
> der Schlussszene von Kapitel 4 durch die Wand, und das läuft über die Sprechtafel. Ein
> Sprite für ihn wäre Arbeit, die niemand zu sehen bekommt.

---

## TEIL E — wenn alle Bilder da sind

Einfügen, sobald du alle Motive durch hast:

```text
fertig — bitte jetzt das zip-Archiv wie oben vereinbart, mit der Ordnerstruktur
godot/assets/figuren/, godot/assets/dinge/ und godot/assets/ui/, Dateinamen exakt wie
angegeben, Transparenz erhalten.
```

**Falls ChatGPT das Archiv nicht bauen kann** — das kommt vor, je nachdem ob die erzeugten
Bilder in seiner Arbeitsumgebung liegen oder nur im Chat hängen —, lad die Bilder einzeln
herunter und pack sie selbst. Wichtig ist nur die Struktur: Die drei Ordner müssen im
Archiv enthalten sein, nicht bloß die Dateien nebeneinander.

Dann schick mir das Archiv hier. Ich entpacke es, prüfe Maße und Alpha, wandle nach `.webp`
und messe jede Figur an ihrem Ort ein — genau wie bei den Hintergründen.

---

## Danach

Ablage, Dateiname **exakt** so wie oben (die Namen stehen so im Code):

```
godot/assets/figuren/   mabel.webp  silas.webp  doc.webp  gideon.webp
                        quentin.webp  dolores.webp
godot/assets/ui/        portrait_gideon.webp  portrait_jack.webp
godot/assets/dinge/     revolver.webp  brecheisen.webp  schraubstock.webp
                        oellampe.webp  linse.webp  signallampe.webp  walze.webp
                        akte.webp  grubenstahl.webp  halstuecher.webp
                        kesselschluessel.webp  psalm_rolle.webp  kinderjacke.webp
```

PNG ist richtig so — schick es als PNG, ich wandle nach `.webp` um und behalte dabei
das Alpha. Umwandeln vor dem Verschicken bringt nichts und kostet nur Qualität.


Du musst **nicht alle zwanzig** auf einmal machen. Jedes einzelne Bild erscheint sofort
im Spiel, sobald es im Ordner liegt; was fehlt, bleibt unsichtbar und anklickbar.
Fang mit denen an, die man am frühesten sieht: **Mabel, Silas, Doc, Dolores** und
**Revolver, Brecheisen, Grubenlampe**. Die beiden Portraits lohnen sich früh, weil ein
Gespräch ohne Portrait leerer wirkt als ein Ort ohne Figur.

