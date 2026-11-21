# Dr. Gurke erklärt – Folge 1 (TikTok, 9:16, ~93 s)

Animiertes Erklärvideo: Warum manche ewig das Klo blockieren – Handy, Sitzhaltung,
Beckenbodentraining und Tipps. Komplett im Code erzeugt (Canvas-Animation + Stimme + SFX).

## Dateien
| Datei | Inhalt |
|---|---|
| `script.py` | Sprechertext, Szenen, Cues (Untertitel-Anzeige `{Anzeige\|gesprochen}`) |
| `build_audio.py` | Stimmen (Piper lokal oder ElevenLabs), Soundeffekte, Mix, `build/timeline.js` |
| `scene.js` / `index.html` | Animation (1080×1920), alle Szenen, Lippen-Sync, Untertitel |
| `render.js` | Rendert Frames mit Playwright → ffmpeg |
| `make_video.sh` | Alles in einem Rutsch → `out/dr-gurke-folge-1-<engine>.mp4` |

## Rendern
```bash
./make_video.sh                     # Piper-Stimmen (kostenlos, lokal)
ENGINE=elevenlabs ./make_video.sh   # ElevenLabs-Stimmen
```
Braucht: Python 3 + numpy, Node + Playwright (Chromium), ffmpeg (mit rubberband), Schrift „Inter Display“.

## ElevenLabs-Stimmen
1. API-Key holen: elevenlabs.io → einloggen → links unten **Developers** (bzw. Profil-Menü) →
   **API Keys** → **Create API Key** → Berechtigung „Text to Speech“ reicht → Key kopieren
   (wird nur einmal angezeigt).
2. Key hinterlegen – **nicht** in den Chat oder ins Repo:
   - Claude-Code-Cloud: Umgebungsmenü in der Titelleiste der Session → **Edit** →
     **Network secrets**: Host `api.elevenlabs.io`, Header `xi-api-key`, Wert = Key.
   - lokal: `export ELEVENLABS_API_KEY=...`
3. `ENGINE=elevenlabs ./make_video.sh`

Stimmen/Modell per Umgebungsvariable änderbar: `EL_VOICE_N` (Erzähler, Standard „Claas“),
`EL_VOICE_G` (Dr. Gurke, Standard „Tyrax“), `EL_MODEL` (Standard `eleven_v3`).
Kosten ca. 1.600 Credits pro kompletter Vertonung; Antworten werden in `build/el_cache/`
zwischengespeichert, damit ein erneutes Rendern nichts mehr kostet.

## Quellen der Zahlen
- +46 % Hämorrhoiden-Risiko bei Handy-Nutzung auf dem Klo: Ramprasad et al., PLOS ONE 2025 (n = 125), Querschnittsstudie.
- Hocke ~51 s vs. Sitzen ~2 Min.: Sikirov, Digestive Diseases and Sciences 2003 (n = 28).
