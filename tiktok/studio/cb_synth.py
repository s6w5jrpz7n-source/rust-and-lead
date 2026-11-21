#!/usr/bin/env python3
"""Chatterbox-Multilingual-Synthese mit Whisper-Kontrolle. Läuft im eigenen venv (Python 3.11, torch CPU).
Aufruf: python cb_synth.py job.json  ->  schreibt pro Zeile WAV + JSON (Wörter mit Zeiten, Transkript, Score)."""
import json, os, re, sys, shutil, hashlib, difflib
import torch, torchaudio as ta

job = json.load(open(sys.argv[1]))
outdir = job['outdir']
os.makedirs(outdir, exist_ok=True)
torch.set_num_threads(os.cpu_count() or 4)
model = whisper = None


def norm(s):
    return re.sub(r'[^a-zäöüß0-9 ]', '', s.lower().replace('-', ' '))


results = {}
for it in job['items']:
    key = hashlib.sha1(json.dumps([it['text'], it['ref'], it['exag'], it['cfg'], it.get('seed', 0)]).encode()).hexdigest()[:16]
    js_p, wav_p = os.path.join(outdir, key + '.json'), os.path.join(outdir, key + '.wav')
    if os.path.exists(js_p) and os.path.exists(wav_p):
        results[it['id']] = json.load(open(js_p))
        print(f"{it['id']}: (Cache) {results[it['id']]['score']:.2f}", flush=True)
        continue
    best = None
    for attempt in range(3):
        if model is None:
            from chatterbox.mtl_tts import ChatterboxMultilingualTTS
            model = ChatterboxMultilingualTTS.from_pretrained(device='cpu')
        if whisper is None:
            from faster_whisper import WhisperModel
            whisper = WhisperModel('small', device='cpu', compute_type='int8')
        seed = it.get('seed', 0) + attempt * 101
        torch.manual_seed(seed)
        wav = model.generate(it['text'], language_id='de', audio_prompt_path=it['ref'],
                             exaggeration=it['exag'], cfg_weight=it['cfg'])
        tmp = os.path.join(outdir, f'{key}_try{attempt}.wav')
        ta.save(tmp, wav, model.sr)
        segs, _ = whisper.transcribe(tmp, language='de', word_timestamps=True)
        words = [dict(w=w.word.strip(), s=round(w.start, 3), e=round(w.end, 3)) for s in segs for w in s.words]
        hyp = ' '.join(w['w'] for w in words)
        score = difflib.SequenceMatcher(None, norm(it['text']), norm(hyp)).ratio()
        if best is None or score > best['score']:
            best = dict(wav=tmp, words=words, hyp=hyp, score=round(score, 3), seed=seed, sr=model.sr)
        if score >= 0.88:
            break
    shutil.copy(best['wav'], wav_p)
    best['wav'] = wav_p
    json.dump(best, open(js_p, 'w'), ensure_ascii=False)
    results[it['id']] = best
    print(f"{it['id']}: {best['score']:.2f} | {best['hyp']}", flush=True)
json.dump(results, open(os.path.join(outdir, 'results.json'), 'w'), ensure_ascii=False)
