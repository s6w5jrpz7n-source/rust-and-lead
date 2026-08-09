# Stimmen — die gesprochenen Sprechzeilen des Spiels

Hier liegen die Aufnahmen. **Nicht von Hand benennen.** Der Dateiname ist die
Kennung der Zeile: die ersten zwölf Stellen des SHA-256 ihres Textes.

Erzeugt wird das in drei Schritten:

```bash
python3 docs/build_spiel_stimmen.py    # Zeilen aus dem Quelltext einsammeln
python3 docs/azure_tts.py --pruefen    # Zugang testen, kostet nichts
python3 docs/azure_tts.py --spiel      # rendern, hierher

godot --headless --path godot --editor --quit    # importieren
```

**Den dritten Schritt nicht vergessen.** Godot lädt keine rohe Datei, sondern
eine *importierte* — neben jeder `.mp3` muss eine `.mp3.import` liegen. Fehlt
sie, verhält sich das Spiel exakt wie im unvertonten Zustand: Es zeigt den Text
und schweigt. Wer gerade 107 Dateien gerendert hat und nichts hört, sucht den
Fehler überall, nur nicht im Import. Ein Öffnen des Projekts im Godot-Editor
tut dasselbe.

Ins Repository gehört nur die `.mp3`. Die `.mp3.import` steht in `.gitignore`
und wird von Godot beim ersten Öffnen neu erzeugt — so wie bei jedem anderen
Asset hier.

Die Testsuite passt auf: Sobald hier Dateien liegen, besteht sie darauf, dass
das Spiel sie auch findet und dass sie eine Länge liefern.

Warum der Text und nicht eine Nummer die Kennung ist, steht ausführlich in
`godot/scripts/Stimme.gd`. Die kurze Fassung: Das Spiel hat den Text ohnehin in
der Hand, wenn es ihn anzeigt — es braucht also keine Zuordnungstabelle. Und
wer eine Zeile umschreibt, verliert ihre Aufnahme, statt die alte weiter zu
hören, während der neue Satz dasteht.

**Ohne Aufnahme fällt nichts aus.** Fehlt eine Datei, zeigt die Sprechtafel den
Text und die Figur schweigt — genau wie vor der Vertonung. Das Spiel ist immer
nur eine Zeile weiter vertont als vorher.
