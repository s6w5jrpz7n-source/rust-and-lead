# Dr. Gurke erklärt – TikTok-Serie (9:16)

Animierte Erklärvideos mit Dr. Gurke, komplett im Code erzeugt (Canvas-Animation, Stimme, Soundeffekte).

| Folge | Thema | Länge |
|---|---|---|
| `folge1` | Klo-Blockierer: Handy, Sitzhaltung, Beckenbodentraining | ~93 s |
| `folge2` | Der Klamottenstuhl: Schrödingers Pullover, Schwerkraft, der zweite Stuhl | ~86 s |

## Aufbau
| Datei | Inhalt |
|---|---|
| `folgeN/script.py` | Sprechertext, Szenen, Cues (Untertitel-Anzeige `{Anzeige\|gesprochen}`) |
| `folgeN/scenes.js` | Szenen der Folge (`window.EP_SCENES`) |
| `engine.js` | Gemeinsam: Dr. Gurke (Stimmungen, Gurke-Cam), Primitive, Untertitel, Szenenwechsel |
| `build_audio.py` | Stimmen (Piper lokal oder ElevenLabs), Soundeffekte, Mix, `build/<folge>/timeline.js` |
| `render.js` | Rendert Frames mit Playwright → ffmpeg |
| `make_video.sh` | Alles in einem Rutsch → `out/dr-gurke-<folge>-<engine>.mp4` |

## Rendern
```bash
./make_video.sh folge2                     # Piper-Stimmen (kostenlos, lokal)
ENGINE=elevenlabs ./make_video.sh folge2   # ElevenLabs-Stimmen
```
Braucht: Python 3 + numpy, Node + Playwright (Chromium), ffmpeg (mit rubberband), Schrift „Inter Display“.

Neue Folge: `folge3/` mit `script.py`, `scenes.js` und `index.html` (wie in `folge2/`) anlegen.

## ElevenLabs-Stimmen
1. API-Key holen: elevenlabs.io → einloggen → links unten **Developers** (bzw. Profil-Menü) →
   **API Keys** → **Create API Key** → Berechtigung „Text to Speech“ reicht → Key kopieren
   (wird nur einmal angezeigt).
2. Key hinterlegen – **nicht** in den Chat oder ins Repo:
   - Claude-Code-Cloud: Umgebungsmenü in der Titelleiste der Session → **Edit** →
     **Network secrets**: Host `api.elevenlabs.io`, Header `xi-api-key`, Wert = Key.
   - lokal: `export ELEVENLABS_API_KEY=...`
3. `ENGINE=elevenlabs ./make_video.sh folge2`

Stimmen/Modell per Umgebungsvariable änderbar: `EL_VOICE_N` (Erzähler, Standard „Claas“),
`EL_VOICE_G` (Dr. Gurke, Standard „Tyrax“), `EL_MODEL` (Standard `eleven_v3`).
Kosten ca. 1.500–1.600 Credits pro Folge; Antworten werden in `build/el_cache/`
zwischengespeichert, damit ein erneutes Rendern nichts mehr kostet.

## Quellen der Zahlen (Folge 1)
- +46 % Hämorrhoiden-Risiko bei Handy-Nutzung auf dem Klo: Ramprasad et al., PLOS ONE 2025 (n = 125), Querschnittsstudie.
- Hocke ~51 s vs. Sitzen ~2 Min.: Sikirov, Digestive Diseases and Sciences 2003 (n = 28).

Folge 2 ist Satire: Alle „Studien des Gurkologischen Instituts“ und Zahlen darin sind frei erfunden.
