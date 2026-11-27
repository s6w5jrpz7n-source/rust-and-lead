# Arbeitsanweisung für Claude — Rust & Lead

## Was das Spiel ist

Seit der Umstellung: ein **Punkt-und-Klick-Abenteuer in der Bauform von Baphomets Fluch**.
Gemalte Bühnenbilder, flache Aufsicht, Sinnbild-Gespräche, Kapitel aus Hauptstrang und
Pflicht-Seitensträngen. Die Beschreibung steht in `docs/ABENTEUER.md` — **die lesen, bevor
etwas am Abenteuer geändert wird.**

Die alte 3D-Action-Fassung ist fertig und bleibt im Titelmenü erreichbar. `docs/MASTER_GDD.md`
beschreibt sie, nicht das Abenteuer.

Deutsch: Spieltexte, Kommentare, Commit-Nachrichten. Ton grim-dark, Fallout/Diablo IV.
Keine modernen Cyberpunk-Begriffe — Zahnräder, galvanische Impulse, Dampfdruck.

## Arbeite zu Ende

Nicht nachfragen, wenn die Antwort im Repo steht oder eine vernünftige Vorgabe existiert.
Eine Aufgabe ist fertig, wenn sie läuft und getestet ist, nicht wenn der Code geschrieben ist.
Wenn ein Teil blockiert ist: den Rest fertig machen und klar sagen, was offen blieb und warum.

## Nachmessen statt vermuten

Das ist die Methode, die in diesem Projekt jedes Mal funktioniert hat:

* 116 zu enge Gassen gefunden, indem die Stadt auf 1 m gerastert wurde — nicht durch Lesen.
* 89 von 122 Sekunden Ladezeit gefunden, indem der Aufbau vermessen wurde.
* 50 Sekunden Bewegungssperre gefunden, indem `speech_gesamt` ausgerechnet wurde.
* Den Farbraum des Spiels bestimmt mit `ffmpeg -vf palettegen` auf Titelbild und Intro —
  nicht nach Gefühl.

**Bildschirmfotos zeigen, was Codelesen nicht zeigt.** `tools/AbenteuerShot.gd` und
`tools/Shot.gd`. Bei „sieht falsch aus" immer zuerst ein Bild machen.

## Nach jeder Änderung

```bash
godot --headless --path godot --editor --quit            # importiert
godot --headless --path godot res://tests/TestRunner.tscn
```

Schnellprüfung einer einzelnen Datei:
`godot --headless --path godot --check-only --script res://scripts/X.gd`
(`Identifier "Y" not declared` für `class_name`-Klassen ist dabei normal.)

Wenn die Suite meldet „TEST_UMFANG darf nach", die Zahlen eintragen. Das ist keine Formalie:
Ein Laufzeitfehler bricht eine Testfunktion stumm ab, und nur diese Zahlen fangen das.

## Committen

Kleine, abgeschlossene Commits. Nachricht: erste Zeile was, Rumpf warum. Deutsch.
Branch `claude/rust-lead-game-setup-35213z`, dann Pull Request.

## Sparsam arbeiten

* Keine Datei zweimal lesen. Mit `grep`/`sed -n` gezielt lesen statt ganze Dateien.
* Keine langen Code-Blöcke in der Antwort wiederholen.
* Kurz antworten. Der Nutzer liest am Telefon und mag keine Aufsätze.

---

# Fehler, die schon passiert sind

Jeder hier hat echte Zeit gekostet. Die Liste ist der eigentliche Wert dieser Datei.

## Godot

1. **`class_name` ist beim ersten Start nach einem Pull unbekannt.** Godot füllt den globalen
   Klassenindex erst beim Projekt-Scan, parst aber vorher. Eine frisch hinzugefügte
   `class_name`-Klasse ist genau einmal unbekannt — beim ersten Start nach dem Pull, also
   immer beim Nutzer und nie bei mir.
   → **Immer `const X = preload("res://scripts/X.gd")`.** Es gibt dafür einen Ratschen-Test.

2. **`ThemeDB.fallback_font` ist nicht die Projektschrift.** Sie ist Godots Notlösung und gibt
   auf dem Telefon leere Kästchen. → `Schrift.schrift()` benutzen (oder in einem `Control`
   `get_theme_default_font()`). Auch dafür gibt es einen Test, und er hat zugeschlagen.

3. **`size` vor `add_child` wird überschrieben.** Reihenfolge: erst `add_child`, dann
   `custom_minimum_size`, dann `size`. Unter einem `CanvasLayer` bekommt ein Control sonst
   ~36 px. Ein 9-px-Balken wurde so 14 px hoch, ein 4-px-Balken 22.

4. **`Rect2.has_point` schließt die rechte und untere Kante aus.** Ein Standpunkt genau auf
   `rect.end.x` liegt *außerhalb*. Hat eine Testmeldung gekostet, die aussah wie ein Datenfehler.

5. **Ein Element, das schon ein Elternteil hat, lässt sich nicht noch einmal anhängen.**
   `_box()` rief selbst `add_child` — das Pferd blieb leer, seine sieben Kästen lagen im
   Weltursprung. → `_box_frei()`.

6. **Headless rendert nicht.** Eine 3D-Szene ohne Rendering-Treiber zu laden hängt.
   → `xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 …`

7. **Unter `xvfb` sind alle Texturen weiß.** Portraits, Sinnbilder, Hintergründe — alles, was
   aus einer Datei kommt. Das ist der Software-Renderer, **kein Fehler im Spiel**;
   gegengeprüft mit `icon_gold.png`, das nachweislich funktioniert. Auf diesen Bildern kann
   man Anordnung, Größen und Umbruch prüfen — nicht, ob ein Bild gut aussieht.

8. **Typisierte Variablen beim Zuweisen prüfen.** `var n: MeshInstance3D = tr["node"]` stürzt
   ab, wenn dort ein `Node3D` liegt. Die Truhe ließ sich deshalb nicht öffnen.

9. **Ein Ternär mit `void` ist kein gültiger Ausdruck.**
   `_saetze.remove_at(0) if not _saetze.is_empty() else null` parst nicht. Normales `if`.

10. **Ein Skript ohne `class_name` kann sich selbst nicht adressieren.**
    `Callable(Welt, "flagge")` schlägt innerhalb von `Welt.gd` fehl. → Lambdas.

## Deutsche Texte in GDScript

11. **Ein mit `„` geöffnetes Zitat muss mit `“` schließen, nicht mit ASCII `"`.** Sonst endet
    der String mitten im Satz. Das ist mir in einer einzigen Datei **sieben Mal** passiert.
    Prüfregex: `„[^"„“]*"` darf nirgends treffen.

## Adventure-Bau (neu, und genau die Fehler, die man nicht sieht)

12. **Ein Gesprächsknoten ohne Ausweg ist eine Falle.** Der Spieler kommt nur über das
    Hauptmenü heraus. → `GespraechDaten.hat_ausweg()`, für jeden Knoten geprüft.

13. **Ein Missionsschritt darf nicht am Besitz eines Gegenstands hängen, den ein späterer
    Schritt verbraucht.** Der Schritt fällt wieder auf, und weil Schritte eine Reihenfolge
    sind, wird die Mission nie fertig. Genau so war `q_walze` gebaut; beim Lesen nicht zu
    sehen, nur beim Durchspielen.

14. **Kein unlösbarer Zustand.** Wer Dolores die gesprungene Walze gibt, bevor Silas sie
    richtet, verliert sie — eine zweite gibt es nicht. → `nur_wenn` auf der Wirkung.
    Ebenso: Die Grubenlampe geht in der Signallampe auf, also nimmt der Stollen **beide**
    (`braucht` darf eine Liste sein).

15. **Eine Quest mit Abschuss-Zähler ist in einem Adventure unlösbar.** `q_wegelagerer` und
    `q_ratten` waren aus der Action-Fassung übernommen und hatten keine Quelle, die den
    Zähler hochsetzt. → zu Rätseln umgebaut.

16. **Eine Sicht-Flagge, die niemand setzt, lässt eine Figur nie erscheinen.** Dolores stand
    hinter `sicht: "dolores_da"` — und diese Flagge gab es nirgends.

17. **Angefangene Sätze gehören zum alten Ort.** Beim Ortswechsel und beim Öffnen eines
    Gesprächs leeren, sonst steht im Saloon „Die Schrottkippe".

## Tests

18. **Ein Test, der Fundstellen über die ganze Datei vergleicht, prüft das Scrollen.**
    Der Ladebildschirm-Test verglich `q.find("_laden_zeigen()") < q.find("change_scene_to_packed")`.
    Eine zweite Startfunktion weiter oben in der Datei ließ ihn fehlschlagen, ohne dass etwas
    kaputt war. → Immer den Rumpf der betroffenen Funktion prüfen, nicht den Dateitext.

19. **Grüne Tests heißen nicht, dass die Funktion stimmt.** Neun Tests zu `orbit_punkte` waren
    grün, während die Funktion abstürzte — sie bauten sich ihre Daten selbst, statt sie zu
    holen. Tests müssen den **echten** Aufruf machen.

## Über das Spiel reden

20. **Nichts über das Spiel behaupten, was nicht in dieser Sitzung nachgesehen wurde.**
    Zwei falsche Aussagen gingen so raus: dass Praxis und Waffenlager am Nordtor liegen (gilt
    nur für die im Code gebaute Ersatzstadt) und dass die Portraits nie erscheinen (sie
    erscheinen, `DialogBox.show_line` lädt sie).

## Umgebung

21. **Der Azure-Schlüssel ist ein Passwort.** Nicht ins Repo, nicht in eine Datei im
    Projektordner, nicht in den Chat.

22. **`s6w5jrpz7n-source` ist ein Sitzungskonto, nicht das Konto des Nutzers.** Dessen eigener
    GitHub-Name ist `donlocky` und hat auf dieses Repo **keinen Schreibzugriff**.

23. **Was nicht gepusht ist, ist weg.** Ein Commit im Arbeitsordner einer Sitzung überlebt die
    Sitzung nicht. Der Commit mit dem gemeinsamen HUD ging so verloren, und diese Datei
    gleich mit.

---

## Wo steht, was offen ist

`docs/OFFEN.md`. Dort nachtragen, nicht in neuen Dateien.
