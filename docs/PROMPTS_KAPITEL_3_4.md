# Hintergrund-Prompts — Kapitel 3 und 4

Sieben Stück: drei Minenebenen, Zugdepot, fahrender Zug, Salonwaggon und derselbe
Salonwaggon nach dem Einschlag. **Jeder Prompt ist vollständig.**

Ablage: `godot/assets/orte/<kennung>.webp`, exakt 1280×720.

## Eine Abweichung, zum ersten Mal

Bei den sieben Orten vorher waren **vier von fünf Absätzen wortgleich**. Hier ändert sich
zusätzlich der **LIGHT**-Absatz — und zwar notwendig: Untertage gibt es keine Sonne von
links, und ein Nachtsturm hat kein Nachmittagslicht. Alles andere bleibt gleich, besonders
COLOUR.

**Wichtig: Nacht wird in Ocker gemalt, nicht in Blau.** Der naheliegende Reflex eines
Bildmodells bei „night" ist ein kalter Blaustich. Damit fiele die halbe zweite Hälfte des
Spiels aus unserem Farbraum. Deshalb steht es in jedem Nacht-Prompt ausdrücklich dabei.

**Und weiterhin: offene Schatten.** Eine Mine ist dunkel, aber ein Hotspot, den man nicht
findet, ist kein Hotspot. Licht kommt von Lampen im Bild, nicht von überall.


---


## `mine_ebene1.webp` — Schrott-Mine, Ebene 1

*Kapitel 3 — der Abstieg beginnt*

```text
Hand-painted 2D background plate for a classic point-and-click adventure game, in the visual
tradition of Revolution Software's "Broken Sword" — painted backdrop with genuine architectural
perspective, rich material detail, cinematic staging. NOT photorealistic, NOT a 3D render, NOT
pixel art, NOT flat vector art, NOT concept art.

SCENE: A timbered mine gallery one level below the surface, the shaft opening still visible far behind as a pale square. Heavy pit props and crown bars, a rail track on rotten sleepers, a line of rusted company crates stacked against the wall with faded stencils. A ventilation pipe runs along the ceiling, patched with cloth. Fallen rock narrows the gallery halfway along. Foreground: a leaning pit prop, cropped by the left edge.

COMPOSITION: one-point perspective with a clear vanishing point placed off-centre, camera at
adult standing eye level and only slightly elevated. Structures set at an angle so their surfaces
recede into depth. THREE DEPTH LAYERS: a dark out-of-focus foreground element cropped by the edge
of the frame; the midground, which is the playable set and carries the detail; and a background
that opens real distance behind it. Keep an open, unobstructed strip of ground across the lower
third for characters to walk on — quiet, low detail, no clutter. Asymmetric: unequal masses left
and right. 16:9 widescreen, exactly 1280x720.

LIGHT: a single hanging oil lamp mid-gallery and a pale spill of daylight from the shaft far behind. The lamp is the brightest thing in frame; everything falls off from it, but the shadows stay open and brown, never black. Dust hangs thick in the lamp's cone.

COLOUR: strictly limited to one warm ochre/rust ramp, no other hues — #090201 #140a06 #1e110b
#2b1b13 #3f291b #583d27 #6f4c31 #865c3c #a57950 #c19769 #e2bf91. Mid-tone painting. Shadows stay
open and readable, never crushed to flat black. Objects separate by local contrast and silhouette,
not by darkness. At most one single cool accent.

NO people, NO characters, NO animals, NO readable lettering, NO lens flare, NO modern objects,
NO symmetrical composition, NO empty foreground. Empty set only.
```


## `mine_ebene2.webp` — Schrott-Mine, Ebene 2

*Kapitel 3 — die Kinderzeichnung*

```text
Hand-painted 2D background plate for a classic point-and-click adventure game, in the visual
tradition of Revolution Software's "Broken Sword" — painted backdrop with genuine architectural
perspective, rich material detail, cinematic staging. NOT photorealistic, NOT a 3D render, NOT
pixel art, NOT flat vector art, NOT concept art.

SCENE: A deeper, older mine gallery, the timbers blacker and more warped, no daylight at all. A collapsed side drift to one side, choked with rubble. An abandoned ore cart off its rails. On one broad pit prop, drawn in charcoal by a child's hand: a family of four beside a small house — father, mother, two children — and the father is drawn taller than the house, with square shoulders and pipes on his back. The drawing is the only thing in the frame that is not industrial. Foreground: a snapped cable hanging into frame from above, cropped by the top edge.

COMPOSITION: one-point perspective with a clear vanishing point placed off-centre, camera at
adult standing eye level and only slightly elevated. Structures set at an angle so their surfaces
recede into depth. THREE DEPTH LAYERS: a dark out-of-focus foreground element cropped by the edge
of the frame; the midground, which is the playable set and carries the detail; and a background
that opens real distance behind it. Keep an open, unobstructed strip of ground across the lower
third for characters to walk on — quiet, low detail, no clutter. Asymmetric: unequal masses left
and right. 16:9 widescreen, exactly 1280x720.

LIGHT: lamplight only, from a lamp hanging just out of frame at the left, raking across the timbers. Deep but still readable shadow in the collapsed drift. The charcoal drawing catches the light squarely — it is the brightest small thing in the picture.

COLOUR: strictly limited to one warm ochre/rust ramp, no other hues — #090201 #140a06 #1e110b
#2b1b13 #3f291b #583d27 #6f4c31 #865c3c #a57950 #c19769 #e2bf91. Mid-tone painting. Shadows stay
open and readable, never crushed to flat black. Objects separate by local contrast and silhouette,
not by darkness. At most one single cool accent.

NO people, NO characters, NO animals, NO readable lettering, NO lens flare, NO modern objects,
NO symmetrical composition, NO empty foreground. Empty set only.
```


## `mine_ebene3.webp` — Die Schatzkammer

*Kapitel 3 — Schlussszene „PSALM“*

```text
Hand-painted 2D background plate for a classic point-and-click adventure game, in the visual
tradition of Revolution Software's "Broken Sword" — painted backdrop with genuine architectural
perspective, rich material detail, cinematic staging. NOT photorealistic, NOT a 3D render, NOT
pixel art, NOT flat vector art, NOT concept art.

SCENE: A natural chamber at the bottom of the mine, far larger than the galleries above, the ceiling lost in darkness. Walls of broken ore shot through with metallic veins. In the middle of the floor: a crushed company shipping crate, its lid split open, the stencilled seal broken. Around it, scattered ore boulders and older crates half buried in scree. A black shaft mouth gapes at the far side, going further down. Everything is silent and undisturbed, as if nobody has stood here in years. Foreground: a split ore boulder, cropped by the lower right corner.

COMPOSITION: one-point perspective with a clear vanishing point placed off-centre, camera at
adult standing eye level and only slightly elevated. Structures set at an angle so their surfaces
recede into depth. THREE DEPTH LAYERS: a dark out-of-focus foreground element cropped by the edge
of the frame; the midground, which is the playable set and carries the detail; and a background
that opens real distance behind it. Keep an open, unobstructed strip of ground across the lower
third for characters to walk on — quiet, low detail, no clutter. Asymmetric: unequal masses left
and right. 16:9 widescreen, exactly 1280x720.

LIGHT: the only light is a miner's lamp standing on the floor beside the crushed crate, throwing long cones of light up the walls and leaving the ceiling in darkness. One single cool accent is permitted here: a faint galvanic blue (#4a86a0) glimmer deep inside the black shaft mouth, barely there.

COLOUR: strictly limited to one warm ochre/rust ramp, no other hues — #090201 #140a06 #1e110b
#2b1b13 #3f291b #583d27 #6f4c31 #865c3c #a57950 #c19769 #e2bf91. Mid-tone painting. Shadows stay
open and readable, never crushed to flat black. Objects separate by local contrast and silhouette,
not by darkness. At most one single cool accent.

NO people, NO characters, NO animals, NO readable lettering, NO lens flare, NO modern objects,
NO symmetrical composition, NO empty foreground. Empty set only.
```


## `zugdepot.webp` — Das Iron-Rail-Zugdepot

*Kapitel 4 — Nachtansatz*

```text
Hand-painted 2D background plate for a classic point-and-click adventure game, in the visual
tradition of Revolution Software's "Broken Sword" — painted backdrop with genuine architectural
perspective, rich material detail, cinematic staging. NOT photorealistic, NOT a 3D render, NOT
pixel art, NOT flat vector art, NOT concept art.

SCENE: A company railway depot at night under heavy rain. A water tower on stilts, a coaling stage, floodlight masts with caged lamps, a signal gantry. An armoured train stands under steam at the platform: a locomotive with a riveted cowcatcher and sealed freight cars behind it, their doors wax-sealed. Puddles between the rails. A chain-link company fence with a gate runs along the left. Foreground: a stack of sleepers, cropped by the lower left corner.

COMPOSITION: one-point perspective with a clear vanishing point placed off-centre, camera at
adult standing eye level and only slightly elevated. Structures set at an angle so their surfaces
recede into depth. THREE DEPTH LAYERS: a dark out-of-focus foreground element cropped by the edge
of the frame; the midground, which is the playable set and carries the detail; and a background
that opens real distance behind it. Keep an open, unobstructed strip of ground across the lower
third for characters to walk on — quiet, low detail, no clutter. Asymmetric: unequal masses left
and right. 16:9 widescreen, exactly 1280x720.

LIGHT: night. Caged floodlights on masts, the firebox glow of the locomotive, lamplight catching the falling rain in streaks. Wet surfaces throw long reflections. Shadows stay warm and open — this is night painted in ochre, not in blue.

COLOUR: strictly limited to one warm ochre/rust ramp, no other hues — #090201 #140a06 #1e110b
#2b1b13 #3f291b #583d27 #6f4c31 #865c3c #a57950 #c19769 #e2bf91. Mid-tone painting. Shadows stay
open and readable, never crushed to flat black. Objects separate by local contrast and silhouette,
not by darkness. At most one single cool accent.

NO people, NO characters, NO animals, NO readable lettering, NO lens flare, NO modern objects,
NO symmetrical composition, NO empty foreground. Empty set only.
```


## `zug_dach.webp` — Auf dem fahrenden Zug

*Kapitel 4 — Kolben-Jack*

```text
Hand-painted 2D background plate for a classic point-and-click adventure game, in the visual
tradition of Revolution Software's "Broken Sword" — painted backdrop with genuine architectural
perspective, rich material detail, cinematic staging. NOT photorealistic, NOT a 3D render, NOT
pixel art, NOT flat vector art, NOT concept art.

SCENE: The roof and flatcar of an armoured train in motion at night in a storm, seen from along the train: a flatcar deck of riveted steel plate with tie-down rings and a stack of chained crates, the sealed freight car rising at the far end with its door marked by a broken wax seal, and beyond it more cars receding into rain and darkness. The desert tears past as motion-blurred streaks to both sides. Everything is wet, every rivet catches light. Foreground: a vent stack and a taut brake chain, cropped by the right edge.

COMPOSITION: one-point perspective with a clear vanishing point placed off-centre, camera at
adult standing eye level and only slightly elevated. Structures set at an angle so their surfaces
recede into depth. THREE DEPTH LAYERS: a dark out-of-focus foreground element cropped by the edge
of the frame; the midground, which is the playable set and carries the detail; and a background
that opens real distance behind it. Keep an open, unobstructed strip of ground across the lower
third for characters to walk on — quiet, low detail, no clutter. Asymmetric: unequal masses left
and right. 16:9 widescreen, exactly 1280x720.

LIGHT: storm night. A hard raking light from the locomotive's firebox ahead, the rest lit by irregular lightning that picks out wet steel. Rain in sheets. High contrast but shadows still readable — never a black silhouette on black.

COLOUR: strictly limited to one warm ochre/rust ramp, no other hues — #090201 #140a06 #1e110b
#2b1b13 #3f291b #583d27 #6f4c31 #865c3c #a57950 #c19769 #e2bf91. Mid-tone painting. Shadows stay
open and readable, never crushed to flat black. Objects separate by local contrast and silhouette,
not by darkness. At most one single cool accent.

NO people, NO characters, NO animals, NO readable lettering, NO lens flare, NO modern objects,
NO symmetrical composition, NO empty foreground. Empty set only.
```


## `spiegel_wagen.webp` — Der Salonwaggon

*Kapitel 4 — DER SPIEGEL, die wichtigste Szene*

```text
Hand-painted 2D background plate for a classic point-and-click adventure game, in the visual
tradition of Revolution Software's "Broken Sword" — painted backdrop with genuine architectural
perspective, rich material detail, cinematic staging. NOT photorealistic, NOT a 3D render, NOT
pixel art, NOT flat vector art, NOT concept art.

SCENE: The interior of a private railway saloon carriage, luxurious and entirely out of place: panelled walnut walls, brass oil lamps in gimbals, a card table with a green baize top, upholstered armchairs bolted to the floor, crystal decanters in a rack. Windows along one side with the black night streaking past. On the far wall, facing the viewer across the carriage, hangs a TALL FULL-LENGTH WARDROBE MIRROR in a heavy brass frame — intact, empty, reflecting only the opposite wall and lamplight. The mirror is the focal point of the composition. Foreground: the corner of the card table, cropped by the lower left corner.

COMPOSITION: one-point perspective with a clear vanishing point placed off-centre, camera at
adult standing eye level and only slightly elevated. Structures set at an angle so their surfaces
recede into depth. THREE DEPTH LAYERS: a dark out-of-focus foreground element cropped by the edge
of the frame; the midground, which is the playable set and carries the detail; and a background
that opens real distance behind it. Keep an open, unobstructed strip of ground across the lower
third for characters to walk on — quiet, low detail, no clutter. Asymmetric: unequal masses left
and right. 16:9 widescreen, exactly 1280x720.

LIGHT: interior night. Warm oil lamps in the carriage, their light caught and doubled in the mirror glass, the brass and the decanters. Outside the windows is darkness with occasional lightning. Rich, warm, and far too comfortable for this world.

COLOUR: strictly limited to one warm ochre/rust ramp, no other hues — #090201 #140a06 #1e110b
#2b1b13 #3f291b #583d27 #6f4c31 #865c3c #a57950 #c19769 #e2bf91. Mid-tone painting. Shadows stay
open and readable, never crushed to flat black. Objects separate by local contrast and silhouette,
not by darkness. At most one single cool accent.

NO people, NO characters, NO animals, NO readable lettering, NO lens flare, NO modern objects,
NO symmetrical composition, NO empty foreground. Empty set only.
```


## `spiegel_wagen_zerbrochen.webp` — Der Salonwaggon, danach

*Variante — derselbe Raum nach dem Einschlag*

```text
Hand-painted 2D background plate for a classic point-and-click adventure game, in the visual
tradition of Revolution Software's "Broken Sword" — painted backdrop with genuine architectural
perspective, rich material detail, cinematic staging. NOT photorealistic, NOT a 3D render, NOT
pixel art, NOT flat vector art, NOT concept art.

SCENE: EXACTLY the same railway saloon carriage from EXACTLY the same camera position as the intact version: same panelled walls, same lamps, same card table, same mirror on the far wall. But now a hole has been smashed through the carriage wall on one side, splintered panelling hanging inwards, rain blowing in. The card table is burst apart and the cards lie scattered. The tall mirror has shattered in a star pattern, the shards still in the frame, each one catching the lamplight at a different angle. No blood, no body, no figure — only the aftermath. Foreground: the same corner of the card table, now splintered, cropped by the lower left corner.

COMPOSITION: one-point perspective with a clear vanishing point placed off-centre, camera at
adult standing eye level and only slightly elevated. Structures set at an angle so their surfaces
recede into depth. THREE DEPTH LAYERS: a dark out-of-focus foreground element cropped by the edge
of the frame; the midground, which is the playable set and carries the detail; and a background
that opens real distance behind it. Keep an open, unobstructed strip of ground across the lower
third for characters to walk on — quiet, low detail, no clutter. Asymmetric: unequal masses left
and right. 16:9 widescreen, exactly 1280x720.

LIGHT: interior night, as before, but one lamp has been knocked askew and swings, so the light is uneven and raking. The mirror shards each throw a separate highlight. Rain blows through the breach and catches the light.

COLOUR: strictly limited to one warm ochre/rust ramp, no other hues — #090201 #140a06 #1e110b
#2b1b13 #3f291b #583d27 #6f4c31 #865c3c #a57950 #c19769 #e2bf91. Mid-tone painting. Shadows stay
open and readable, never crushed to flat black. Objects separate by local contrast and silhouette,
not by darkness. At most one single cool accent.

NO people, NO characters, NO animals, NO readable lettering, NO lens flare, NO modern objects,
NO symmetrical composition, NO empty foreground. Empty set only.
```


---

## Zwei Hinweise zur Reihenfolge

**Die beiden Salonwaggon-Bilder müssen aus genau derselben Kameraposition kommen.** Das
Spiel tauscht beim Einschlag nur die Textur; wackelt die Perspektive, wirkt es wie ein
Szenenwechsel statt wie ein Einschlag. Erzeuge das zerbrochene am besten als **Bearbeitung**
des intakten, nicht als neues Bild.


**Der Spiegel bleibt leer.** Kein Spiegelbild, keine Figur, nichts. Was darin zu sehen
ist, ist der Inhalt der wichtigsten Szene des Spiels und gehört nicht in den Hintergrund.


## Was die Daten erwarten

`mine_ebene3`, `zug_dach` und `spiegel_wagen` stehen schon in `KapitelDaten.gd` als Start-
und Schlussorte von Kapitel 3 und 4. Die anderen drei (`mine_ebene1`, `mine_ebene2`,
`zugdepot`) sind Verbindungsorte — ein Kapitel aus einem einzigen Raum wäre zu dünn.
Sobald die Bilder da sind, messe ich jeden Ort ein wie die sieben davor.

