# Auf dem Handy spielen — Klick für Klick

> Ziel: eine `rust-and-lead.apk` auf dem Telefon. Beim ersten Mal rund
> fünfundvierzig Minuten, davon dreißig Herunterladen. Danach dauert ein
> neuer Stand zwei Minuten.

Die Anleitung geht davon aus, dass auf dem Rechner **nichts** vorbereitet
ist — neuer Computer, frisches Godot. Wer Teile davon schon hat, überspringt
den Abschnitt.

**Kurzfassung für später**, wenn alles einmal steht:

```
Projekt ▸ Exportieren… ▸ Android ▸ Projekt exportieren ▸ rust-and-lead.apk
```

---

## 0 · Was am Ende gebraucht wird

| Ding | Wozu | Größe |
| :-- | :-- | :-- |
| Godot (deine Version) | das Projekt | 120 MB |
| Export-Vorlagen, **dieselbe** Version | der Android-Teil der App | 900 MB |
| **JDK 17** | Godot ruft Javas Signierwerkzeug | 180 MB |
| Android SDK (Platform-Tools + Build-Tools) | baut und signiert die APK | 1,5 GB |
| Debug-Schlüssel | Android installiert nichts Unsigniertes | 2 KB |

> **Die Version muss genau stimmen — mit DEINEM Editor, nicht mit einer Zahl
> aus dieser Anleitung.** Export-Vorlagen aus 4.4 funktionieren in einem
> 4.5-Editor nicht; die Fehlermeldung heisst dann „Export template not found"
> und meint „falsche Version". Welche du hast, steht unter **Hilfe ▸ Über** und
> in der Titelleiste des Projektmanagers.
>
> Das Projekt selbst ist mit 4.3 angelegt (`config/features` in
> `project.godot`). Eine neuere 4.x oeffnet es und rechnet es still hoch — das
> ist in Ordnung. Daran erkennst du es auch: Ab 4.4 legt Godot beim ersten
> Öffnen für jedes Skript eine `.uid`-Datei an und meldet dabei einmalig
> „Missing .uid file … re-created from cache". Das ist keine Warnung über einen
> Fehler, sondern eine über eine Neuerung, und sie kommt genau einmal.

---

## 1 · Godot einrichten

1. **godotengine.org/download** öffnen, **Godot Engine 4.3** (Standard, nicht
   .NET/Mono) laden und entpacken. Godot installiert sich nicht; die
   entpackte Datei **ist** das Programm.
2. Godot starten. Im Projektmanager: **Importieren / Import**.
3. Auf die Datei **`godot/project.godot`** im Projektordner zeigen und
   **Importieren & Bearbeiten**.
4. Beim ersten Öffnen importiert Godot alle Assets — Modelle, Töne, die 110
   Sprachdateien. Das dauert ein bis zwei Minuten und passiert genau einmal.

> **Auf `godot/project.godot` zeigen, nicht auf den Projektordner darüber.**
> Die Projektwurzel ist der Unterordner `godot/`; `res://` entspricht ihm.
> Wer eine Ebene zu hoch importiert, bekommt ein leeres Projekt.

### Die Export-Vorlagen

5. Menü **Editor ▸ Export-Vorlagen verwalten / Manage Export Templates**.
6. **Herunterladen und installieren / Download and Install**. 900 MB, je nach
   Leitung fünf bis zwanzig Minuten. Läuft es auf einen Fehler, unten den
   **Spiegelserver wechseln** und erneut.

---

## 2 · Java (JDK 17)

**Für diesen Aufbau reicht jede aktuelle LTS-Fassung — nimm 21.** Die
verbreitete Regel „es muss 17 sein" gilt für den *Gradle-Build*, und der ist
hier ausgeschaltet (Schritt 6). Ohne ihn benutzt Godot vom JDK nur `keytool`,
um den Schlüssel anzulegen und zu prüfen, und ein PKCS12-Keystore aus JDK 21
ist derselbe wie einer aus 17.

Adoptium bietet 17 auf der Startseite inzwischen nicht mehr an; es liegt unter
*Other platforms and versions* im Versions-Auswahlfeld und unter
`github.com/adoptium/temurin17-binaries/releases`. Brauchen wirst du es nur,
wenn du später „Use Gradle Build" einschaltest. Dann will Godot **genau 17**;
mit JDK 21 bricht der
Build mit einer Gradle-Meldung ab, die nach allem klingt, nur nicht nach der
Java-Version.

- **adoptium.net** öffnen → **Temurin 17 (LTS)** → das Paket für dein System.
- Installieren, Vorgaben übernehmen.
- Merken, wohin es installiert wurde. Typisch:
  - Windows `C:\Program Files\Eclipse Adoptium\jdk-17.0.x-hotspot`
  - macOS `/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home`

---

## 3 · Das Android SDK

Der bequeme Weg ist Android Studio — es bringt SDK, Build-Tools und den
Paketmanager mit und trägt sich selbst richtig ein.

1. **developer.android.com/studio** → herunterladen, installieren, starten.
2. Der Einrichtungsassistent lädt beim ersten Start das SDK. **Standard /
   Standard installation** genügt, einfach durchklicken.
3. Danach steht in **More Actions ▸ SDK Manager** oben der **Android SDK
   Location**. Diesen Pfad merken. Typisch:
   - Windows `C:\Users\<du>\AppData\Local\Android\Sdk`
   - macOS `/Users/<du>/Library/Android/sdk`
4. Im Reiter **SDK Tools** muss **Android SDK Build-Tools** und **Android SDK
   Platform-Tools** ein Häkchen haben. Beides ist nach der
   Standardinstallation gesetzt; nachsehen kostet zehn Sekunden und spart
   eine halbe Stunde Suchen.

Android Studio selbst wird danach nie wieder gebraucht. Es ist hier nur der
Installateur.

---

## 4 · Der Debug-Schlüssel

Android installiert keine unsignierte App. Für den Hausgebrauch reicht ein
Wegwerf-Schlüssel, den man einmal erzeugt.

**Windows (PowerShell):**

```powershell
cd $env:USERPROFILE
& "C:\Program Files\Eclipse Adoptium\jdk-17.0.9-hotspot\bin\keytool.exe" -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore debug.keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12
```

**macOS / Linux:**

```bash
cd ~
keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android \
  -keystore debug.keystore -storepass android \
  -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12
```

Die Zeile ist lang und muss vollständig sein. Sie legt `debug.keystore` im
Benutzerordner ab — Pfad merken.

> Passwort und Alias sind **absichtlich** die Android-Vorgaben
> (`androiddebugkey` / `android`). Das ist kein Geheimnis und darf keins
> sein; es ist der Schlüssel, mit dem jede Testversion der Welt signiert ist.
> Für den Play Store bräuchte es einen echten — der gehört dann nicht ins
> Repository.

---

## 5 · Beides in Godot eintragen

**Editor ▸ Editor-Einstellungen / Editor Settings**, links unten in der Suche
`android` tippen. Vier Felder unter **Export ▸ Android**:

| Feld | Was hinein |
| :-- | :-- |
| Java SDK Path | der JDK-17-Ordner aus Schritt 2 |
| Android SDK Path | der SDK-Ordner aus Schritt 3 |
| Debug Keystore | die `debug.keystore` aus Schritt 4 |
| Debug Keystore User | `androiddebugkey` |
| Debug Keystore Pass | `android` |

Die Einstellungen gehören zum **Editor**, nicht zum Projekt: einmal gesetzt,
gelten sie für jedes Godot-Projekt auf diesem Rechner.

---

## 6 · Die Export-Voreinstellung

**Projekt ▸ Exportieren… / Project ▸ Export…**

1. **Hinzufügen… / Add…** → **Android**.
2. Rechts erscheint eine Liste. Diese Felder setzen:

| Feld | Wert |
| :-- | :-- |
| Name | `Android` |
| Unique Name (unter *Package*) | `de.rustandlead.game` |
| Name (unter *Package*) | `Rust & Lead` |
| Architectures ▸ **arm64-v8a** | ✔ |
| Architectures ▸ armeabi-v7a, x86_64 | ✘ |

3. Ganz oben muss **grün** stehen, dass alles gefunden wurde. Steht dort rot
   etwas von fehlenden Vorlagen oder SDK, dann fehlt Schritt 1.5 oder 5.

> **Nur arm64-v8a.** Jede zusätzliche Architektur verdoppelt die APK, und
> jedes Telefon der letzten acht Jahre ist arm64. Die anderen anzuhaken
> macht die Datei größer und ändert sonst nichts.

> **„Use Gradle Build" bleibt AUS.** Es wird erst gebraucht, wenn Plugins ins
> Spiel kommen (Werbung, Play-Dienste). Angeschaltet zieht es einen
> vollständigen Gradle-Build nach sich — mehrere Minuten und eine
> Fehlerquelle mehr, für nichts.

Die Voreinstellung landet in `godot/export_presets.cfg`. Diese Datei steht in
`.gitignore` und gehört dort auch hin: Sie kann Schlüsselpfade und Passwörter
enthalten. Eine fertige Vorlage ohne Geheimnisse liegt unter
`docs/export_presets_android.cfg` — wer sie nach `godot/export_presets.cfg`
kopiert, überspringt diesen ganzen Abschnitt.

---

## 7 · Exportieren

1. Im selben Fenster unten: **Projekt exportieren… / Export Project…**
2. Ordner wählen, Dateiname `rust-and-lead.apk`.
3. **„Debug exportieren" angehakt lassen.** Ohne Haken verlangt Godot einen
   Freigabe-Schlüssel, den es hier nicht gibt.
4. **Speichern.** Eine halbe Minute später liegt die APK da, rund 90 MB.

---

## 8 · Auf das Telefon

### Der einfache Weg (Kabel, ohne Einstellungen)

Telefon per USB anstecken, **Entwickleroptionen** und **USB-Debugging** an
(Einstellungen ▸ Über das Telefon ▸ siebenmal auf **Build-Nummer** tippen).
Godot zeigt dann oben rechts neben dem Play-Knopf ein Android-Symbol:
**einmal darauf, und das Spiel startet auf dem Telefon.** Kein Kopieren, kein
Installieren.

### Der Weg über die Datei

1. APK auf das Telefon bringen — Kabel, Google Drive, an sich selbst mailen.
2. Auf dem Telefon im Dateimanager antippen.
3. Android fragt: *„Installation aus unbekannten Quellen"*. Erlauben — für
   den Dateimanager, aus dem heraus installiert wird.
4. Installieren, öffnen.

> Beim Aktualisieren muss die alte Version nicht deinstalliert werden,
> **solange der Unique Name gleich bleibt**. Ändert er sich, liegen zwei
> Spiele nebeneinander auf dem Telefon.

---

## Wenn es klemmt

| Meldung | Was wirklich los ist | Was hilft |
| :-- | :-- | :-- |
| `Export template not found` | Vorlagen fehlen oder sind aus einer anderen Godot-Version | Editor ▸ Export-Vorlagen verwalten, neu laden |
| `Android SDK path is invalid` | auf den falschen Ordner gezeigt (z. B. auf `platform-tools` statt auf `Sdk`) | den Pfad aus dem SDK Manager abschreiben |
| `Could not find keytool` | JDK nicht gefunden | Java SDK Path prüfen — auf den JDK-Ordner zeigen, nicht auf dessen `bin` |
| `Missing .uid file … re-created from cache` | keine Warnung über einen Fehler: Ab Godot 4.4 bekommt jedes Skript eine `.uid`-Datei, das Projekt stammt aus 4.3 | nichts tun, kommt genau einmal. Die neuen Dateien dürfen mit eingecheckt werden |
| `Invalid public key for APK expansion` | leeres Feld an einer Stelle, die nur mit Expansion gebraucht wird | *APK Expansion* ausschalten |
| APK baut, Telefon sagt „App nicht installiert" | alte Version mit anderem Schlüssel drauf | alte deinstallieren |
| Startet und bleibt schwarz | Hauptszene fehlt im Export | `run/main_scene` steht auf `res://scenes/Title.tscn`; Export-Filter auf **Alle Ressourcen im Projekt** |
| Steuerung reagiert nicht | — | sollte nicht passieren, siehe unten |

### Warum die Steuerung auf dem Telefon funktioniert

Das ist keine Selbstverständlichkeit und war zweimal kaputt: Der Stollen gab
jede Berührung an den Joystick weiter, sodass der Schussknopf nie ansprach,
und sein Ausgang hing an der Taste `[E]`. Beides ist behoben, und beides hat
seither eine Prüfung (`_test_stollen_bedienbar`). Wer die Steuerung ändert,
sollte sie nicht umgehen — auf einem Telefon gibt es keine Tastatur, mit der
man sich behelfen kann.

Dasselbe gilt für die Bildschirme: Rucksack und Läden schließen über das **✕**
oben rechts, nicht nur über `[Esc]`.
