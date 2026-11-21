#!/usr/bin/env bash
# Rendert eine Folge von "Dr. Gurke erklärt" komplett neu.
#   ./make_video.sh folge2                     -> Piper-Stimmen (lokal, kostenlos)
#   ENGINE=elevenlabs ./make_video.sh folge2   -> ElevenLabs-Stimmen (API-Key nötig, siehe README)
set -euo pipefail
cd "$(dirname "$0")"
EP="${1:-folge1}"
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
python3 build_audio.py "$EP"
N=$(python3 -c "import json;print(int(json.load(open('build/$EP/timeline.json'))['duration']*30))")
Q=$(( (N + 3) / 4 )); mkdir -p parts out
for i in 0 1 2 3; do
  a=$(( i * Q )); b=$(( (i + 1) * Q )); [ "$b" -gt "$N" ] && b=$N
  node render.js "$EP" video "$a" "$b" "parts/p$i.mp4" &
done
wait
printf "file 'p0.mp4'\nfile 'p1.mp4'\nfile 'p2.mp4'\nfile 'p3.mp4'\n" > parts/list.txt
OUTF="out/dr-gurke-$EP-$ENGINE.mp4"
ffmpeg -y -v error -f concat -safe 0 -i parts/list.txt -i "build/$EP/audio.wav" -map 0:v -map 1:a \
  -c:v copy -c:a aac -b:a 192k -shortest -movflags +faststart "$OUTF"
echo "Fertig: $OUTF"
