#!/usr/bin/env bash
# Rendert nur das Video einer Folge (Audio muss schon in build/<folge>/ liegen): ./render_ep.sh quiz2 [Worker]
set -euo pipefail
cd "$(dirname "$0")"
EP=$1; NW=${2:-4}
N=$(python3 -c "import json;print(int(json.load(open('build/$EP/timeline.json'))['duration']*30))")
Q=$(( (N + NW - 1) / NW )); mkdir -p "parts/$EP" out; : > "parts/$EP/list.txt"
for i in $(seq 0 $((NW - 1))); do
  a=$(( i * Q )); b=$(( (i + 1) * Q )); [ "$b" -gt "$N" ] && b=$N
  node render.js "$EP" video "$a" "$b" "parts/$EP/p$i.mp4" &
  echo "file 'p$i.mp4'" >> "parts/$EP/list.txt"
done
wait
ENGINE=$(python3 -c "import importlib.util as u;s=u.spec_from_file_location('m','$EP/script.py');m=u.module_from_spec(s);s.loader.exec_module(m);print(getattr(m,'ENGINE','piper'))")
ffmpeg -y -v error -f concat -safe 0 -i "parts/$EP/list.txt" -i "build/$EP/audio.wav" -map 0:v -map 1:a \
  -c:v copy -c:a aac -b:a 192k -shortest -movflags +faststart "out/$EP-$ENGINE.mp4"
echo "out/$EP-$ENGINE.mp4"
