#!/usr/bin/env python3
"""Erzeugt Stimmen (Piper), SFX, Mix und timeline.js für das Dr.-Gurke-Video."""
import json, os, re, subprocess, sys
import numpy as np
from piper import PiperVoice, SynthesisConfig

HERE = os.path.dirname(os.path.abspath(__file__))
EP = sys.argv[1] if len(sys.argv) > 1 else os.environ.get('EP', 'folge1')
_spec = __import__('importlib.util').util.spec_from_file_location('ep_script', os.path.join(HERE, EP, 'script.py'))
_mod = __import__('importlib.util').util.module_from_spec(_spec); _spec.loader.exec_module(_mod)
LINES, SCENES = _mod.LINES, _mod.SCENES
EXTRA_CUES = getattr(_mod, 'EXTRA_CUES', [])  # (name, line_id, 'start'|'end', offset, sfx)

VOICES = os.environ.get('PIPER_VOICES', os.path.join(HERE, 'voices'))
OUT = os.path.join(HERE, 'build', EP)
os.makedirs(OUT, exist_ok=True)
SR = 44100
FPS = 30
EMO = {'amused': 0, 'angry': 1, 'disgusted': 2, 'drunk': 3, 'neutral': 4, 'sleepy': 5, 'surprised': 6, 'whisper': 7}
GAP_SAME, GAP_SCENE, START = 0.22, 0.65, 0.35
SENT_PAUSE = 0.16
G_PITCH = 1.24  # Dr. Gurke höher = Cartoon

ENGINE = os.environ.get('ENGINE', 'piper')  # 'piper' (lokal) oder 'elevenlabs' (API)
_PV = {}


def piper_voice(name):
    if name not in _PV:
        _PV[name] = PiperVoice.load(os.path.join(VOICES, name + '.onnx'))
    return _PV[name]


# ---------------- ElevenLabs (optional) ----------------
# Schlüssel: als Network Secret für api.elevenlabs.io (Header xi-api-key) oder als Umgebungsvariable ELEVENLABS_API_KEY.
EL_VOICE_N = os.environ.get('EL_VOICE_N', '2mFWtuyLvvZ3ZVoH5vGT')  # Claas – Warm, Freundlich (Doku-Sprecher)
EL_VOICE_G = os.environ.get('EL_VOICE_G', 'VvmLPzhPQHSqLOL9D1R7')  # Tyrax – Sarcastic (Dr. Gurke)
EL_MODEL = os.environ.get('EL_MODEL', 'eleven_v3')
EL_TAG = {'angry': '[shouting] ', 'amused': '[proudly] ', 'surprised': '[excited] ', 'neutral': ''}


def el_tts(voice, text):
    import hashlib, ssl, urllib.request, urllib.error
    key = hashlib.sha1(f'{voice}|{EL_MODEL}|{text}'.encode()).hexdigest()[:16]
    cdir = os.path.join(OUT, 'el_cache'); os.makedirs(cdir, exist_ok=True)
    cp = os.path.join(cdir, key + '.json')
    if os.path.exists(cp):  # nie doppelt bezahlen
        return json.load(open(cp))
    url = f'https://api.elevenlabs.io/v1/text-to-speech/{voice}/with-timestamps?output_format=mp3_44100_128'
    hdr = {'Content-Type': 'application/json', 'Accept': 'application/json'}
    if os.environ.get('ELEVENLABS_API_KEY'):
        hdr['xi-api-key'] = os.environ['ELEVENLABS_API_KEY']
    else:
        hdr['xi-api-key'] = 'proxy-injected'  # wird vom Session-Proxy durch das Network Secret ersetzt
    bundle = '/root/.ccr/ca-bundle.crt'
    ctxs = ssl.create_default_context(cafile=bundle) if os.path.exists(bundle) else ssl.create_default_context()
    req = urllib.request.Request(url, data=json.dumps({'text': text, 'model_id': EL_MODEL}).encode(), headers=hdr, method='POST')
    try:
        with urllib.request.urlopen(req, timeout=180, context=ctxs) as r:
            data = json.load(r)
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors='replace')[:400]
        sys.exit(f'ElevenLabs-Fehler {e.code}: {body}')
    json.dump(data, open(cp, 'w'))
    return data


def synth_line_el(line):
    import base64
    spoken, toks, spoken_words = parse(line['text'])
    voice = EL_VOICE_N if line['spk'] == 'N' else EL_VOICE_G
    tag = EL_TAG.get(line.get('emo', ''), '') if (line['spk'] == 'G' and EL_MODEL in ('eleven_v3', 'eleven_v4')) else ''
    data = el_tts(voice, tag + spoken)
    p = subprocess.run(['ffmpeg', '-v', 'error', '-i', 'pipe:0', '-f', 'f32le', '-ar', str(SR), '-ac', '1', 'pipe:1'],
                       input=base64.b64decode(data['audio_base64']), capture_output=True, check=True)
    y = np.frombuffer(p.stdout, dtype=np.float32).copy()
    idx = np.where(np.abs(y) > 0.02 * max(1e-6, np.abs(y).max()))[0]
    a0 = max(0, idx[0] - int(0.02 * SR)) if len(idx) else 0
    a1 = min(len(y), idx[-1] + int(0.06 * SR)) if len(idx) else len(y)
    y = y[a0:a1]
    off = a0 / SR
    words_t = None
    al = data.get('alignment') or data.get('normalized_alignment')
    if al and al.get('characters'):
        s = ''.join(al['characters']); st, en = al['character_start_times_seconds'], al['character_end_times_seconds']
        cur, words_t = 0, []
        for w in spoken_words:
            core = re.sub(r'[^\wäöüÄÖÜß-]', '', w)
            i = s.find(core, cur) if core else -1
            if i < 0:
                words_t = None; break
            words_t.append((max(0, st[i] - off), max(0, en[i + len(core) - 1] - off)))
            cur = i + len(core)
    if not words_t:
        tot = len(y) / SR
        w = np.array([len(re.sub(r'[^\w]', '', x)) + 1.0 for x in spoken_words])
        cum = np.concatenate([[0], np.cumsum(w)]) / w.sum()
        words_t = [(0.05 + cum[i] * (tot - 0.1), 0.05 + cum[i + 1] * (tot - 0.1)) for i in range(len(spoken_words))]
    tok_t, wi = [], 0
    for disp, n in toks:
        tok_t.append((disp, words_t[wi][0], words_t[wi + n - 1][1])); wi += n
    rms = np.sqrt(np.mean(y[np.abs(y) > 0.01] ** 2)) if np.any(np.abs(y) > 0.01) else 0.1
    y = y * ((0.13 if line['spk'] == 'N' else 0.14) / max(rms, 1e-4))
    return y, tok_t, spoken


def parse(text):
    """-> spoken text, display tokens [(disp, n_spoken_words)]"""
    toks, spoken = [], []
    for m in re.finditer(r'\{([^|}]*)\|([^}]*)\}|(\S+)', text):
        if m.group(3):
            toks.append((m.group(3), 1)); spoken.append(m.group(3))
        else:
            sw = m.group(2).split()
            toks.append((m.group(1), len(sw))); spoken += sw
    return ' '.join(spoken), toks, spoken


def ffmpeg_proc(x, sr_in, af):
    p = subprocess.run(['ffmpeg', '-v', 'error', '-f', 'f32le', '-ar', str(sr_in), '-ac', '1', '-i', 'pipe:0',
                        '-af', af, '-f', 'f32le', '-ar', str(SR), '-ac', '1', 'pipe:1'],
                       input=x.astype(np.float32).tobytes(), capture_output=True, check=True)
    return np.frombuffer(p.stdout, dtype=np.float32).copy()


def trim_bounds(x, thr=0.02):
    idx = np.where(np.abs(x) > thr * max(1e-6, np.abs(x).max()))[0]
    if len(idx) == 0:
        return 0, len(x)
    pad = int(0.025 * 22050)
    return max(0, idx[0] - pad), min(len(x), idx[-1] + pad)


def phon_weight(p):
    return len(re.sub(r"[ˈˌː.,!?;:\-–…'\"]", '', p)) + 1.5


def synth_line(line):
    spoken, toks, spoken_words = parse(line['text'])
    if line['spk'] == 'N':
        voice, cfg = piper_voice('de_DE-thorsten-high'), SynthesisConfig(length_scale=0.9, noise_scale=0.6, noise_w_scale=0.8)
    else:
        voice, cfg = piper_voice('de_DE-thorsten_emotional-medium'), SynthesisConfig(speaker_id=EMO[line.get('emo', 'angry')], length_scale=0.93,
                                         noise_scale=0.667, noise_w_scale=0.8)
    chunks = list(voice.synthesize(spoken, syn_config=cfg))
    sr0 = chunks[0].sample_rate
    pieces, words_t, cursor = [], [], 0.0
    for ci, c in enumerate(chunks):
        a = c.audio_float_array.astype(np.float32)
        s, e = trim_bounds(a)
        a = a[s:e]
        dur = len(a) / sr0
        pw = [w for w in ''.join(c.phonemes).split(' ') if re.sub(r'[^\w]', '', w)]
        wts = np.array([phon_weight(w) for w in pw]) if pw else np.array([1.0])
        # Sprechbereich (ohne Rand-Padding)
        s0, s1 = cursor + 0.03, cursor + dur - 0.03
        cum = np.concatenate([[0], np.cumsum(wts)]) / wts.sum()
        for i in range(len(pw)):
            words_t.append((s0 + cum[i] * (s1 - s0), s0 + cum[i + 1] * (s1 - s0)))
        pieces.append(a)
        cursor += dur
        if ci < len(chunks) - 1:
            pieces.append(np.zeros(int(SENT_PAUSE * sr0), np.float32))
            cursor += SENT_PAUSE
    raw = np.concatenate(pieces)
    total_in = len(raw) / sr0
    if line['spk'] == 'G':
        af = f'rubberband=pitch={G_PITCH}:formant=preserved,highpass=f=90'
    else:
        af = 'highpass=f=70,equalizer=f=3000:t=q:w=1:g=2'
    y = ffmpeg_proc(raw, sr0, af)
    scale = (len(y) / SR) / total_in
    words_t = [(a * scale, b * scale) for a, b in words_t]
    if len(words_t) != len(spoken_words):
        print(f"  ! {line['id']}: {len(words_t)} Phonemwörter vs {len(spoken_words)} Wörter -> Zeichenverteilung")
        tot = len(y) / SR
        w = np.array([len(re.sub(r'[^\w]', '', x)) + 1.0 for x in spoken_words])
        cum = np.concatenate([[0], np.cumsum(w)]) / w.sum()
        a0, a1 = 0.05, tot - 0.05
        words_t = [(a0 + cum[i] * (a1 - a0), a0 + cum[i + 1] * (a1 - a0)) for i in range(len(spoken_words))]
    # Anzeige-Tokens zeitlich zuordnen
    tok_t, wi = [], 0
    for disp, n in toks:
        tok_t.append((disp, words_t[wi][0], words_t[wi + n - 1][1]))
        wi += n
    # Lautheit angleichen
    rms = np.sqrt(np.mean(y[np.abs(y) > 0.01] ** 2)) if np.any(np.abs(y) > 0.01) else 0.1
    target = 0.13 if line['spk'] == 'N' else 0.14
    y = y * (target / max(rms, 1e-4))
    return y, tok_t, spoken


# ---------------- SFX ----------------
def tt(d):
    return np.arange(int(d * SR)) / SR


def bandnoise(d, lo, hi, seed=0):
    rng = np.random.default_rng(seed)
    n = int(d * SR)
    X = np.fft.rfft(rng.standard_normal(n))
    f = np.fft.rfftfreq(n, 1 / SR)
    X[(f < lo) | (f > hi)] = 0
    y = np.fft.irfft(X, n)
    return y / (np.abs(y).max() + 1e-9)


def sfx(kind):
    if kind == 'pop':
        t = tt(0.16); f = 320 + 1500 * (t / 0.16) ** 0.6
        return 0.55 * np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 22) * np.minimum(1, t * 400)
    if kind == 'boing':
        t = tt(0.55); f = 180 + 260 * np.exp(-t * 5) * (1 + 0.35 * np.sin(2 * np.pi * 14 * t))
        return 0.45 * np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 5.5) * np.minimum(1, t * 300)
    if kind in ('whoosh', 'whoosh_s'):
        d = 0.5 if kind == 'whoosh' else 0.32
        t = tt(d); env = np.sin(np.pi * t / d) ** 2
        return (0.5 if kind == 'whoosh' else 0.32) * bandnoise(d, 400, 4500, 3) * env
    if kind == 'stamp':
        t = tt(0.4)
        return 0.9 * (np.sin(2 * np.pi * 62 * t) * np.exp(-t * 14) + 0.6 * bandnoise(0.4, 80, 2500, 7) * np.exp(-t * 35))
    if kind == 'ding':
        t = tt(0.9)
        y = sum(a * np.sin(2 * np.pi * f * t) for f, a in [(1318, 1), (1976, 0.45), (2637, 0.25), (3951, 0.1)])
        return 0.28 * y * np.exp(-t * 5) * np.minimum(1, t * 500)
    if kind == 'tick':
        t = tt(0.06)
        return 0.5 * (np.sin(2 * np.pi * 1800 * t) + 0.5 * bandnoise(0.06, 2000, 8000, 5)) * np.exp(-t * 90)
    if kind == 'rise':
        t = tt(0.7); f = 200 + 900 * (t / 0.7) ** 2
        return 0.22 * np.sign(np.sin(2 * np.pi * np.cumsum(f) / SR)) * np.minimum(1, t * 8) * np.exp(-np.maximum(0, t - 0.6) * 30) * 0.6
    if kind == 'drum':  # Trommelwirbel
        d = 1.0; t = tt(d)
        roll = (np.sin(2 * np.pi * 28 * t) > 0.6).astype(float)
        return 0.35 * bandnoise(d, 150, 3000, 11) * (0.4 + 0.6 * roll) * np.minimum(1, t * 3) * np.exp(-np.maximum(0, t - 0.85) * 25)
    if kind == 'ff':
        out = []
        for i in range(9):
            t = tt(0.13); f = 500 + 1500 * t / 0.13 + i * 60
            out.append(0.25 * np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 12))
        return np.concatenate(out)
    if kind == 'tada':
        y = np.zeros(int(1.4 * SR))
        for i, f in enumerate([523.25, 659.25, 783.99, 1046.5]):
            a = int(i * 0.09 * SR); t = np.arange(len(y) - a) / SR
            tone = (2 / np.pi) * np.arcsin(np.sin(2 * np.pi * f * t))  # Dreieck
            y[a:] += 0.22 * tone * np.exp(-t * 2.8) * np.minimum(1, t * 300)
        return y
    if kind == 'sniff':
        y = np.zeros(int(0.5 * SR))
        for i in range(3):
            b = bandnoise(0.09, 1200, 6000, 20 + i) * np.sin(np.pi * tt(0.09) / 0.09) * (0.25 + 0.12 * i)
            a = int(i * 0.15 * SR); y[a:a + len(b)] += b
        return y
    if kind == 'swirl':
        d = 1.8; t = tt(d); f = 700 * np.exp(-t * 1.6) + 60
        tone = 0.25 * np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(2 * np.pi * 3 * t) ** 2
        return (0.35 * bandnoise(d, 200, 2500, 31) * np.sin(np.pi * t / d) + tone) * np.minimum(1, t * 4) * np.exp(-np.maximum(0, t - 1.5) * 10)
    if kind == 'drone':
        d = 2.4; t = tt(d)
        y = np.sin(2 * np.pi * 55 * t) + np.sin(2 * np.pi * 58.3 * t) + 0.5 * np.sin(2 * np.pi * 110 * t)
        return 0.22 * y * (0.7 + 0.3 * np.sin(2 * np.pi * 5 * t)) * np.minimum(1, t * 1.5) * np.minimum(1, (d - t) * 2)
    if kind == 'sting':
        d = 1.2; t = tt(d)
        y = sum(np.sign(np.sin(2 * np.pi * f * t)) * 0.3 + np.sin(2 * np.pi * f * t) for f in (311.1, 329.6, 466.2, 155.6))
        return 0.18 * y * np.exp(-t * 3.2) * np.minimum(1, t * 600) + 0.6 * np.sin(2 * np.pi * 50 * t) * np.exp(-t * 10)
    if kind == 'crickets':
        d = 2.2; t = tt(d); y = np.zeros(len(t))
        for g in (0.1, 0.9, 1.6):
            for k in range(3):
                a0 = g + k * 0.07; m = (t >= a0) & (t < a0 + 0.045)
                y[m] += np.sin(2 * np.pi * 4300 * t[m]) * (0.5 + 0.5 * np.sin(2 * np.pi * 220 * t[m]))
        return 0.16 * y
    raise ValueError(kind)


# ---------------- Build ----------------
def main():
    timeline, cursor, prev_scene = [], START, None
    clips = []
    for i, line in enumerate(LINES):
        if prev_scene is not None and line['scene'] != prev_scene:
            cursor += GAP_SCENE - GAP_SAME
        y, tok_t, spoken = synth_line_el(line) if ENGINE == 'elevenlabs' else synth_line(line)
        dur = len(y) / SR
        start = cursor
        toks = [dict(t=d, s=round(start + a, 3), e=round(start + b, 3)) for d, a, b in tok_t]
        entry = dict(id=line['id'], spk=line['spk'], scene=line['scene'], start=round(start, 3),
                     end=round(start + dur, 3), tokens=toks, cues=[])
        for (k, name, kind) in line.get('cues', []):
            entry['cues'].append(dict(name=name, k=k, t=toks[k]['s'], sfx=kind))
        timeline.append(entry)
        clips.append((start, y, line['spk']))
        print(f"{line['id']:>4} {start:6.2f}-{start + dur:6.2f}  {' '.join(f'{k}:{t[0]}' for k, t in enumerate(tok_t))}")
        cursor = start + dur + line.get('gap', GAP_SAME)
        prev_scene = line['scene']
    total = cursor + 1.8
    n = int(total * SR)
    voiceN, voiceG, fx = np.zeros(n), np.zeros(n), np.zeros(n)
    for start, y, spk in clips:
        a = int(start * SR)
        (voiceN if spk == 'N' else voiceG)[a:a + len(y)] += y
    cues = {}
    for e in timeline:
        for c in e['cues']:
            cues[c['name']] = c['t']
            if c['sfx']:
                s = sfx(c['sfx'])
                off = -0.05 if c['sfx'] in ('stamp', 'pop', 'tick', 'ding', 'tada', 'boing') else -0.15
                if c['sfx'] == 'drum':
                    off = 0.0
                a = max(0, int((c['t'] + off) * SR)); fx[a:a + len(s)] += s[:max(0, n - a)]
    # Szenenwechsel
    scenes = {}
    for sc in SCENES:
        ls = [e for e in timeline if e['scene'] == sc]
        scenes[sc] = [ls[0]['start'], ls[-1]['end']]
    bounds = {}
    for i, sc in enumerate(SCENES):
        st = 0.0 if i == 0 else round(scenes[sc][0] - 0.45, 3)
        bounds[sc] = st
        if i > 0:
            s = sfx('whoosh'); a = int((st - 0.05) * SR); fx[a:a + len(s)] += s
    for name, lid, where, offs, kind in EXTRA_CUES:
        ln = next(e for e in timeline if e['id'] == lid)
        cues[name] = round(ln[where] + offs, 3)
        if kind:
            s = sfx(kind); a = int(cues[name] * SR); fx[a:a + len(s)] += s[:max(0, n - a)]
    # Ende der Gurken-Zeilen + Szenengrenzen
    mix = voiceN + voiceG + 0.55 * fx
    peak = np.abs(mix).max()
    mix = np.tanh(mix / max(peak, 1e-6) * 1.4) / np.tanh(1.4) * 0.95
    raw = os.path.join(OUT, 'mix_raw.wav')
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'f32le', '-ar', str(SR), '-ac', '1', '-i', 'pipe:0',
                    '-af', 'loudnorm=I=-14:TP=-1.0:LRA=11', '-ar', str(SR), '-ac', '2', os.path.join(OUT, 'audio.wav')],
                   input=mix.astype(np.float32).tobytes(), check=True)
    # Mundbewegung Dr. Gurke
    hop = SR // FPS
    nf = int(total * FPS) + 1
    env = np.array([np.sqrt(np.mean(voiceG[i * hop:(i + 1) * hop] ** 2)) if i * hop < n else 0 for i in range(nf)])
    ref = np.percentile(env[env > 0.005], 90) if np.any(env > 0.005) else 1
    env = np.clip(env / ref, 0, 1) ** 0.7
    sm, out = 0.0, []
    for v in env:
        sm = v if v > sm else sm * 0.55 + v * 0.45
        out.append(round(float(sm), 3))
    tl = dict(fps=FPS, duration=round(total, 3), lines=timeline, cues=cues, scenes=bounds, sceneOrder=SCENES, mouth=out)
    with open(os.path.join(OUT, 'timeline.js'), 'w') as f:
        f.write('window.TL = ' + json.dumps(tl, ensure_ascii=False) + ';\n')
    with open(os.path.join(OUT, 'timeline.json'), 'w') as f:
        json.dump({k: v for k, v in tl.items() if k != 'mouth'}, f, ensure_ascii=False, indent=1)
    print(f"Dauer: {total:.2f}s  Szenen: {bounds}")


if __name__ == '__main__':
    main()
