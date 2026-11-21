#!/usr/bin/env bash
# Rendert "Dr. Gurke erklärt – Folge 1" komplett neu.
#   ./make_video.sh                       -> Piper-Stimmen (lokal, kostenlos)
#   ENGINE=elevenlabs ./make_video.sh     -> ElevenLabs-Stimmen (API-Key nötig, siehe README)
set -euo pipefail
cd "$(dirname "$0")"
ENGINE="${ENGINE:-piper}"; export ENGINE
pip install -q piper-tts >/dev/null
VOICES="${PIPER_VOICES:-voices}"; export PIPER_VOICES="$VOICES"
if [ "$ENGINE" = piper ]; then
  mkdir -p "$VOICES"
  for v in de/de_DE/thorsten/high/de_DE-thorsten-high de/de_DE/thorsten_emotional/medium/de_DE-thorsten_emotional-medium; do
    n=$(basename "$v")
    if [ ! -f "$VOICES/$n.onnx" ]; then
      curl -sSL -o "$VOICES/$n.onnx" "https://huggingface.co/rhasspy/piper-voices/resolve/main/$v.onnx"
      curl -sSL -o "$VOICES/$n.onnx.json" "https://huggingface.co/rhasspy/piper-voices/resolve/main/$v.onnx.json"
    fi
  done
fi
python3 build_audio.py
N=$(python3 -c "import json;print(int(json.load(open('build/timeline.json'))['duration']*30))")
Q=$(( (N + 3) / 4 )); mkdir -p parts out
for i in 0 1 2 3; do
  a=$(( i * Q )); b=$(( (i + 1) * Q )); [ "$b" -gt "$N" ] && b=$N
  node render.js video "$a" "$b" "parts/p$i.mp4" &
done
wait
printf "file 'p0.mp4'\nfile 'p1.mp4'\nfile 'p2.mp4'\nfile 'p3.mp4'\n" > parts/list.txt
OUTF="out/dr-gurke-folge-1-$ENGINE.mp4"
ffmpeg -y -v error -f concat -safe 0 -i parts/list.txt -i build/audio.wav -map 0:v -map 1:a \
  -c:v copy -c:a aac -b:a 192k -shortest -movflags +faststart "$OUTF"
echo "Fertig: $OUTF"
