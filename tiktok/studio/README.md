# TikTok-Studio (9:16)

Kurzvideos komplett im Code: Canvas-Animation, Stimmen, Soundeffekte, Musik.

| Folge | Format | Thema | Länge |
|---|---|---|---|
| `katze1`–`katze6` | Serie „der drang, …“ (Katze, ~9 s, Schleife, ohne Sprache) | Glas, 3 Uhr nachts, Tastatur, Karton, 5 Uhr Frühstück, Weihnachtsbaum | je ~9 s |
| `katze7`–`katze10` | „der drang“ mit Serien-Badge und Teilen-Aufforderung | Tür (raus und doch nicht), Videocall, Kratzbaum ignorieren, Sonnenfleck | je ~9 s |
| `katzewissen1` | Speicher-Video „5 Katzen-Signale, die du kennen musst“ | Blinzeln, Schwanz hoch, Bauch, Treteln, Köpfchen | 17 s |
| `philo1`–`philo3` | Philosophie-Serie im Stil griechischer Vasenmalerei (`antik.js`, Lyra-Musik) | Diogenes, Epiktet, Schiff des Theseus | je ~60 s |
| `hist1`, `hist2` | Geschichte, Zweiteiler mit Cliffhanger (`see.js`, Drama-Musik) | Titanic-Bäcker Charles Joughin → Violet Jessop „die Unsinkbare“ | ~75 s |
| `comedy1` | Archivfilm-Comedy „Lehrfilm 1950 – ehrlich synchronisiert“ (gemeinfreier Prelinger-Film, `film_cut.py`) | Familienessen | ~56 s |
| `sk1`–`sk5` | Animierte Sketche nach Nutzer-Skript (`sitcom.js`) | Ein letztes Mal, Die Hölle hat sich verändert, Gemeinsame Interessen, Omas Lieblingsenkel, Bis dass der Tod uns scheidet | 13–21 s |
| `iw1` | Parodie „Wie Infinity War hätte enden sollen“ (eigene Cartoon-Figuren, keine Filmbilder/-musik) | Titan-Szene: Handschuh ab, bevor Star-Lord zuschlägt | ~46 s |
| `auto1` | Kinder-Serie „Die Rettungsflitzer“ (eigene Auto-Figuren, `autos.js`, verspielte Musik) | Folge 1: Flitzi steckt fest | ~44 s |
| `baum1` | Trend „Tag 1 vs. später“ | Weihnachtsbaum | ~26 s |
| `emc1` | Wissenschaft | Herleitung E = mc² (Lichtkasten) | ~72 s |
| `klartext1` | KLARTEXT: dunkle Übersetzer-App, zynisch | Stellenanzeigen, ehrlich übersetzt | ~41 s |
| `klartext2` | KLARTEXT | Wohnungsanzeigen, ehrlich übersetzt | ~40 s |
| `quiz2` | Quiz (gezeichnete Flaggen) | Flaggen-Quiz | ~62 s |
| `quiz3` | Quiz (Emoji-Bilder) | Weltraum-Quiz | ~67 s |
| `quiz4` | Quiz (Emoji-Bilder) | Körper-Quiz | ~68 s |
| `quiz1` | Quiz-Gameshow (Ländersilhouetten, Countdown) | Hauptstädte-Quiz, 10 Fragen | ~59 s |
| `erbe1` | Sitcom-Sketch, schwarzer Humor (Chatterbox-Stimmen) | Opas Testament | ~69 s |
| `tod1` | Animierter Sketch, schwarzer Humor | Der Tod hat Montag | ~48 s |
| `gurke1` | Dr. Gurke erklärt: Cartoon-Erklärvideo | Klo-Blockierer | ~93 s |
| `gurke2` | Dr. Gurke erklärt | Der Klamottenstuhl | ~86 s |

## Aufbau
| Datei | Inhalt |
|---|---|
| `<folge>/script.py` | Sprechertext, Sprecher (`SPEAKERS`), Musik (`MUSIC`), Cues; `{Anzeige\|gesprochen}`, `*Wort*` = hervorgehoben |
| `<folge>/scenes.js` | Szenen der Folge (`window.EP_SCENES`) oder ein eigener `renderFrame` |
| `engine.js` | Gemeinsam: Primitive, Untertitel (Sprecher-Namen/-Farben per `EP_NAMES`/`EP_CAPCOL`), Mund pro Sprecher (`mouthOf`), Szenenwechsel, Dr. Gurke |
| `build_audio.py` | Stimmen (Piper lokal oder ElevenLabs), Soundeffekte, Mix, `build/<folge>/timeline.js` |
| `storylib.py` | Erzähl-Folgen: Zeilen mit Inline-Cues (`^name:sfx` vor einem Wort) und Erzähler-Stimmen |
| `film_cut.py` | Schneidet Archivfilm passend zur Timeline (ein JPG pro Frame; Film vorher nach `build/` laden) |
| `autos.js` | Rettungsflitzer: Autos mit Augen/Mund (Mini, Abschleppwagen, Feuerwehr), Räderstadt, Matsch, Wasserstrahl, Regenbogen |
| `sitcom.js` | Sitcom-Figuren (stehend/sitzend, Geist, Teufel, Frisuren), Kamera-Zooms, Schnitte, Titel- und Endkarte |
| `antik.js`, `see.js` | Zeichen-Baukästen: Vasenmalerei (Figuren, Pithos, Säulen, Galeere) bzw. Schiffe, Meer, Cartoon-Figuren |
| `render.js` | Rendert Frames mit Playwright → ffmpeg |
| `klartext.js` | Format KLARTEXT (eigener `renderFrame`); Texte/Farben pro Folge in `<folge>/scenes.js` (`window.KT`) |
| `quiz.js` + `quizlib.py` | Quiz-Format: Fragen stehen nur in `script.py` (`EXPORT`), Bild/Stimme lesen daraus; neue Quiz-Folge = neue Fragenliste |
| `catlib.js` + `catsfx.py` | Katzen-Serie: Katze (sitzen, rennen, liegen, Kopf) und synthetische Geräusche (Miau, Schnurren, Klirren …) |
| `render_ep.sh` | Nur Video neu rendern (Audio vorhanden): `./render_ep.sh quiz2` |
| `make_video.sh` | Alles in einem Rutsch → `out/<folge>-<engine>.mp4` |

## Rendern
```bash
./make_video.sh klartext1                     # Piper-Stimmen (kostenlos, lokal)
ENGINE=elevenlabs ./make_video.sh klartext1   # ElevenLabs-Stimmen
```
Braucht: Python 3 + numpy, Node + Playwright (Chromium), ffmpeg (mit rubberband), Schrift „Inter Display“.

Neue KLARTEXT-Folge: `klartext2/` kopieren, in `script.py` die Liste `ITEMS` und das Outro, in `scenes.js` die Texte/Farben ändern.

## Natürlichere lokale Stimmen (Chatterbox)
Folgen mit `ENGINE = 'chatterbox'` im Skript nutzen Chatterbox Multilingual (MIT-Lizenz) mit Referenzstimmen aus `refs/`.
Jede Zeile wird mit Whisper gegengeprüft und bei Fehlern bis zu 3× neu erzeugt; die Wortzeiten für Untertitel
stammen aus der Transkription.
```bash
uv venv -p 3.11 cbx && uv pip install --extra-index-url https://download.pytorch.org/whl/cpu chatterbox-tts faster-whisper "setuptools<81"
CBX_PY=$PWD/cbx/bin/python ./make_video.sh erbe1
```
Rechenzeit auf 4 CPU-Kernen: etwa 7× Echtzeit (60 s Sprache ≈ 7–10 min).

## ElevenLabs-Stimmen
1. API-Key holen: elevenlabs.io → einloggen → links unten **Developers** (bzw. Profil-Menü) →
   **API Keys** → **Create API Key** → Berechtigung „Text to Speech“ reicht → Key kopieren
   (wird nur einmal angezeigt).
2. Key hinterlegen – **nicht** in den Chat oder ins Repo:
   - Claude-Code-Cloud: Umgebungsmenü in der Titelleiste der Session → **Edit** →
     **Network secrets**: Host `api.elevenlabs.io`, Header `xi-api-key`, Wert = Key.
   - lokal: `export ELEVENLABS_API_KEY=...`
3. `ENGINE=elevenlabs ./make_video.sh klartext1`

Stimmen/Modell per Umgebungsvariable änderbar: `EL_VOICE_N` (Erzähler, Standard „Claas“),
`EL_VOICE_G` (Dr. Gurke, Standard „Tyrax“), `EL_MODEL` (Standard `eleven_v3`).
Kosten ca. 1.500–1.600 Credits pro Folge; Antworten werden in `build/el_cache/`
zwischengespeichert, damit ein erneutes Rendern nichts mehr kostet.

## Quellen der Zahlen (Folge 1)
- +46 % Hämorrhoiden-Risiko bei Handy-Nutzung auf dem Klo: Ramprasad et al., PLOS ONE 2025 (n = 125), Querschnittsstudie.
- Hocke ~51 s vs. Sitzen ~2 Min.: Sikirov, Digestive Diseases and Sciences 2003 (n = 28).

`gurke2`, `tod1` und die KLARTEXT-Folgen sind Satire: Alle „Studien des Gurkologischen Instituts“ und Zahlen darin sind frei erfunden.
