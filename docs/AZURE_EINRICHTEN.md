# Azure Speech einrichten — Klick für Klick

> Ziel: `python3 docs/azure_tts.py --pruefen` sagt „Zugang steht". Von null an
> rund fünfzehn Minuten, davon zehn Warten auf Microsoft.

**Was du brauchst:** eine Kreditkarte, eine Handynummer, einen Browser. Die
Karte wird zur Identitätsprüfung verlangt und im Tarif F0 **nicht belastet** —
Azure schaltet auf Bezahlung erst um, wenn man das ausdrücklich tut.

**Wie teuer es wird:** gar nicht. F0 gibt 500.000 Zeichen im Monat. Die
Sprechzeilen des Spiels sind **5.446** — ein knappes Prozent. Du kannst
neunzigmal alles neu rendern.

Die Beschriftungen unten stehen zweisprachig (`Deutsch / English`), weil das
Portal sich nach deinem Konto richtet. Microsoft baut die Oberfläche
regelmäßig um: Wenn ein Knopf anders heißt, such nach dem, was er *tut* — die
Reihenfolge der Schritte ändert sich nicht.

---

## 1 · Konto anlegen

1. **portal.azure.com** öffnen.
2. **Kostenloses Konto erstellen / Start free**.
3. Mit einem Microsoft-Konto anmelden. Ein vorhandenes Outlook-, Hotmail- oder
   Xbox-Konto tut es — du brauchst kein neues.
4. Identität bestätigen: erst **Handynummer** (SMS-Code), dann **Karte**.
5. Vertragsbedingungen bestätigen.

Danach landest du im Portal. Wenn dort „Kostenlose Testversion / Free trial"
mit einem Guthaben steht: gut, aber egal — F0 läuft unabhängig davon weiter,
auch wenn das Testguthaben ausläuft.

---

## 2 · Die Speech-Ressource

Das ist der Schritt, in dem der einzige wirklich kritische Klick steckt.

1. Oben in die **Suchleiste** des Portals `Speech` tippen.
2. Unter **Dienste / Services** den Eintrag **Speech services / Sprachdienste**
   wählen. *Nicht* „Speech Studio", *nicht* „Azure AI services" (das ist die
   Sammelressource — sie funktioniert zwar auch, hat aber keinen F0-Tarif).
3. **Erstellen / Create**.

Dann das Formular:

| Feld | Was hinein |
| :-- | :-- |
| Abonnement / Subscription | das vorhandene |
| Ressourcengruppe / Resource group | **Neu erstellen** → `rust-and-lead` |
| Region | **Westeuropa / West Europe** |
| Name | `rust-and-lead-speech` (schon vergeben? Ziffern anhängen) |
| Tarif / Pricing tier | **Free F0** |

> **Der Tarif ist der Klick, auf den es ankommt.** Die Vorauswahl ist oft
> **S0**, und S0 rechnet pro Zeichen ab. Das Feld steht weit unten im Formular
> und heißt manchmal „Preisstufe". Wenn dort etwas anderes als **Free F0**
> steht, ändere es, bevor du weitergehst.

> **F0 ist einmalig.** Pro Abonnement gibt es genau *eine* kostenlose
> Speech-Ressource. Ist **Free F0** ausgegraut oder kommt beim Erstellen ein
> Fehler, hast du schon eine — such sie unter **Alle Ressourcen / All
> resources** und benutze die.

4. **Überprüfen + erstellen / Review + create**, dann **Erstellen / Create**.
5. Rund eine Minute warten („Bereitstellung wird ausgeführt").
6. **Zu Ressource wechseln / Go to resource**.

---

## 3 · Schlüssel und Region holen

1. Im linken Menü der Ressource: **Schlüssel und Endpunkt / Keys and Endpoint**
   (unter „Ressourcenverwaltung / Resource Management").
2. Dort stehen vier Dinge. Du brauchst zwei davon:
   - **SCHLÜSSEL 1 / KEY 1** — auf das Augensymbol klicken, dann kopieren.
     KEY 2 tut es genauso; zwei gibt es nur, damit man einen tauschen kann,
     ohne den Betrieb zu unterbrechen.
   - **Standort/Region / Location/Region** — dort steht `westeurope`. **Genau
     diese Schreibweise** brauchst du: klein, ohne Leerzeichen.

> **Die häufigste Verwechslung:** Nimm *nicht* den **Endpunkt / Endpoint**.
> Das ist eine vollständige Adresse (`https://westeurope.api.cognitive…`), und
> wer die als Region einträgt, bekommt einen 404, der nach einem kaputten
> Schlüssel aussieht.

Der Schlüssel ist ein Passwort. Er gehört **nicht** ins Repository, nicht in
eine Datei im Projektordner und nicht in einen Chat.

---

## 4 · Beides dem Rechner beibringen

### Windows (PowerShell)

Dauerhaft, überlebt den Neustart:

```powershell
setx AZURE_SPEECH_KEY "hier_dein_schluessel"
setx AZURE_SPEECH_REGION "westeurope"
```

> **Danach PowerShell schließen und neu öffnen.** `setx` schreibt die Variable
> für *künftige* Prozesse — das Fenster, in dem du es eingetippt hast, kennt
> sie noch nicht. Das ist der Grund, aus dem der nächste Schritt am häufigsten
> „Key FEHLT" meldet, obwohl man ihn gerade gesetzt hat.

### macOS und Linux (zsh)

```bash
echo 'export AZURE_SPEECH_KEY="hier_dein_schluessel"' >> ~/.zshrc
echo 'export AZURE_SPEECH_REGION="westeurope"' >> ~/.zshrc
source ~/.zshrc
```

Benutzt du bash statt zsh, dann `~/.bashrc` statt `~/.zshrc`.

---

## 5 · Prüfen, bevor irgendetwas gerendert wird

```bash
cd <dein-projektordner>
python3 docs/azure_tts.py --pruefen
```

So sieht „es steht" aus:

```
Region : westeurope
Key    : gesetzt (a1b2…32 Zeichen)

✓ Zugang steht. 480 Stimmen insgesamt, davon 12 deutsche.

  ✓ held                 de-DE-FlorianMultilingualNeural
  ✓ mabel                de-DE-KatjaNeural
  …
```

Dieser Aufruf rendert nichts und verbraucht kein Kontingent. Er beantwortet
in einer Sekunde, was sonst nur ein fehlgeschlagener Lauf beantwortet — und
zwar so, dass man weiß, *woran* es lag.

---

## 6 · Rendern

Erst eine einzige Zeile, zum Anhören:

```bash
python3 docs/azure_tts.py --spiel --probe
```

Die Datei liegt danach in `godot/assets/voice/`. Hör sie dir an. Wenn sie
trägt, der Rest:

```bash
python3 docs/azure_tts.py --spiel
```

107 Zeilen, rund sechs Minuten — die Pausen zwischen den Anfragen sind
Absicht (siehe unten). Ein Abbruch ist unschädlich: Fertige Dateien werden
beim nächsten Lauf übersprungen.

### Und dann einmal importieren

```bash
godot --headless --path godot --editor --quit
```

Godot lädt keine rohe Datei, sondern eine *importierte*: Neben jeder `.mp3`
muss eine `.mp3.import` liegen. Fehlt sie, verhält sich das Spiel exakt wie im
unvertonten Zustand — es zeigt den Text und schweigt. Wer gerade 107 Dateien
gerendert hat und nichts hört, sucht den Fehler überall, nur nicht im Import.

Das Projekt einmal im Godot-Editor zu öffnen tut dasselbe.

Ins Repository gehört nur die **`.mp3`**. Die `.mp3.import` steht in
`.gitignore` — Godot erzeugt sie beim ersten Öffnen neu, genau wie bei jedem
anderen Asset im Projekt.

Danach spricht das Spiel. Es findet die Dateien über den Zeilentext selbst.

---

## Wenn es klemmt

| Meldung | Was wirklich los ist | Was hilft |
| :-- | :-- | :-- |
| `Key FEHLT` | Die Variable ist in *diesem* Terminal nicht sichtbar | Windows: nach `setx` das Fenster neu öffnen. macOS: `source ~/.zshrc` |
| `401 — Schluessel abgelehnt` | Schlüssel aus einer anderen Ressource, oder beim Kopieren ein Leerzeichen mitgenommen | KEY 1 neu kopieren, auf Leerzeichen am Ende achten |
| `404 — Diese Region kennt den Dienst nicht` | `West Europe` statt `westeurope`, oder die Endpunkt-Adresse eingetragen | Feld **Standort/Region** in der Ressource, exakt abschreiben |
| `403 — Verboten` | Kontingent aufgebraucht, oder es ist keine Speech-Ressource | Im Portal unter **Metriken** nachsehen; nächster Monat oder andere Ressource |
| `429 — Gedrosselt` | F0 erlaubt nur wenige Anfragen je Minute | Macht das Skript selbst. Bleibt es hängen: `PAUSE_SEK` in `azure_tts.py` erhöhen |
| `Keine Verbindung` | Proxy oder Firewall, oder Regionsname falsch | In dieser Reihenfolge prüfen — die Meldung nennt sie |
| **Free F0** ausgegraut | Du hast schon eine kostenlose Speech-Ressource | Unter **Alle Ressourcen** suchen und die benutzen |
| Stimme fehlt in der Liste | Diese Stimme gibt es in deiner Region nicht | `--pruefen` druckt die verfügbaren deutschen Stimmen aus |

---

## Warum das Skript wartet

Der kostenlose Tarif erlaubt nur eine Handvoll Anfragen pro Minute. Wer 107
Zeilen ohne Pause abschickt, bekommt ab der zwanzigsten eine Wand aus
`429 Too Many Requests` — das sieht aus wie ein kaputter Schlüssel und ist
keiner. Deshalb pausiert das Skript von sich aus zwischen den Anfragen und
legt bei einer Drosselung noch einmal nach.

---

## Wenn dir eine Stimme nicht gefällt

Die Zuordnung Rolle → Stimme steht in `docs/build_spiel_stimmen.py` unter
`STIMMEN`. Ändern, dann:

```bash
python3 docs/build_spiel_stimmen.py
python3 docs/azure_tts.py --spiel --rolle held --neu
```

`--rolle` schneidet auf eine Figur zu, `--neu` überschreibt vorhandene Dateien.
Welche deutschen Stimmen es gibt, sagt `--pruefen`.

Die zweite Stellschraube ist die *Haltung*: `ROLE_PROSODY` in `azure_tts.py`
gibt je Figur Tempo, Tonhöhe und Lautstärke vor, `REGIE_RULES` reagiert auf
Schlüsselwörter wie „leise" oder „keuchend". Die Zeilen des Erwachens laufen
dort schon auf *müde, heiser, leise*.
