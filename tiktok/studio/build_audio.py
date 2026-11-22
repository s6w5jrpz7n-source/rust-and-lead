#!/usr/bin/env python3
"""Erzeugt Stimmen (Piper), SFX, Mix und timeline.js für das Dr.-Gurke-Video."""
import difflib, json, os, re, subprocess, sys
import numpy as np
from piper import PiperVoice, SynthesisConfig

HERE = os.path.dirname(os.path.abspath(__file__))
EP = sys.argv[1] if len(sys.argv) > 1 else os.environ.get('EP', 'gurke1')
_spec = __import__('importlib.util').util.spec_from_file_location('ep_script', os.path.join(HERE, EP, 'script.py'))
_mod = __import__('importlib.util').util.module_from_spec(_spec); _spec.loader.exec_module(_mod)
LINES, SCENES = _mod.LINES, _mod.SCENES
EXTRA_CUES = getattr(_mod, 'EXTRA_CUES', [])  # (name, line_id, 'start'|'end', offset, sfx)
MUSIC = getattr(_mod, 'MUSIC', None)  # z. B. dict(bpm=100, gain=0.2)
# Sprecher: Piper-Modell, Tempo, Tonhöhe, Ziel-Lautheit. Eine Folge kann SPEAKERS ergänzen/überschreiben.
SPEAKERS = {
    'N': dict(model='de_DE-thorsten-high', length=0.9, noise=0.6, noise_w=0.8, pitch=None, rms=0.13,
              af='highpass=f=70,equalizer=f=3000:t=q:w=1:g=2'),
    'G': dict(model='de_DE-thorsten_emotional-medium', emo='angry', length=0.93, noise=0.667, noise_w=0.8, pitch=1.24, rms=0.14),
}
SPEAKERS.update(getattr(_mod, 'SPEAKERS', {}))

VOICES = os.environ.get('PIPER_VOICES', os.path.join(HERE, 'voices'))
OUT = os.path.join(HERE, 'build', EP)
os.makedirs(OUT, exist_ok=True)
SR = 44100
FPS = 30
EMO = {'amused': 0, 'angry': 1, 'disgusted': 2, 'drunk': 3, 'neutral': 4, 'sleepy': 5, 'surprised': 6, 'whisper': 7}
GAP_SAME, GAP_SCENE, START = 0.22, 0.65, 0.35
SENT_PAUSE = 0.16
G_PITCH = 1.24  # Dr. Gurke höher = Cartoon

ENGINE = os.environ.get('ENGINE') or getattr(_mod, 'ENGINE', 'piper')  # 'piper', 'chatterbox' (lokal) oder 'elevenlabs' (API)
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
    y = y * (SPEAKERS[line['spk']]['rms'] / max(rms, 1e-4))
    return y, tok_t, spoken


def parse(text):
    """-> spoken text, display tokens [(disp, n_spoken_words)]"""
    toks, spoken = [], []
    for m in re.finditer(r'\{([^|}]*)\|([^}]*)\}|(\S+)', text):
        if m.group(3):
            toks.append((m.group(3), 1)); spoken.append(m.group(3).replace('*', ''))
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
    sp = SPEAKERS[line['spk']]
    sid = EMO[line.get('emo', sp.get('emo', 'neutral'))] if 'emotional' in sp['model'] else None
    voice = piper_voice(sp['model'])
    cfg = SynthesisConfig(speaker_id=sid, length_scale=sp['length'], noise_scale=sp['noise'], noise_w_scale=sp['noise_w'])
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
    chain = [f"rubberband=pitch={sp['pitch']}:formant=preserved"] if sp.get('pitch') else []
    chain.append(sp.get('af', 'highpass=f=90' if sp.get('pitch') else 'highpass=f=70'))
    af = ','.join(chain)
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
    target = sp['rms']
    y = y * (target / max(rms, 1e-4))
    return y, tok_t, spoken


# ---------------- Chatterbox (lokal, natürlicher) ----------------
# Braucht ein eigenes venv (Python 3.11): uv venv -p 3.11 cbx && uv pip install chatterbox-tts faster-whisper "setuptools<81"
# CBX_PY zeigt auf dessen python. SPEAKERS[x]['ref'] = Referenzstimme (WAV), 'exag' = Ausdruck, 'cfg' = Tempo/Treue.
CB = {}


def _norm(w):
    return re.sub(r'[^a-zäöüß0-9]', '', w.lower())


def run_chatterbox():
    items = []
    for line in LINES:
        spoken, _, _ = parse(line['text'])
        sp = SPEAKERS[line['spk']]
        items.append(dict(id=line['id'], text=spoken, ref=os.path.join(HERE, sp['ref']),
                          exag=line.get('exag', sp.get('exag', 0.5)), cfg=line.get('cfg', sp.get('cfg', 0.5)),
                          seed=line.get('seed', 0)))
    jp = os.path.join(OUT, 'cb_job.json')
    json.dump(dict(outdir=os.path.join(OUT, 'cb_cache'), items=items), open(jp, 'w'), ensure_ascii=False)
    subprocess.run([os.environ.get('CBX_PY', 'python3'), os.path.join(HERE, 'cb_synth.py'), jp], check=True)
    CB.update(json.load(open(os.path.join(OUT, 'cb_cache', 'results.json'))))


def synth_line_cb(line):
    spoken, toks, spoken_words = parse(line['text'])
    r, sp = CB[line['id']], SPEAKERS[line['spk']]
    sr0 = r['sr']
    p = subprocess.run(['ffmpeg', '-v', 'error', '-i', r['wav'], '-f', 'f32le', '-ac', '1', '-ar', str(sr0), 'pipe:1'],
                       capture_output=True, check=True)
    raw = np.frombuffer(p.stdout, dtype=np.float32).copy()
    idx = np.where(np.abs(raw) > 0.02 * max(1e-6, np.abs(raw).max()))[0]
    a0 = max(0, idx[0] - int(0.03 * sr0)) if len(idx) else 0
    a1 = min(len(raw), idx[-1] + int(0.08 * sr0)) if len(idx) else len(raw)
    if r['words']:  # Nachklang/Artefakte nach dem letzten erkannten Wort abschneiden
        a1 = min(a1, int((r['words'][-1]['e'] + 0.3) * sr0))
        a0 = max(a0, int((r['words'][0]['s'] - 0.15) * sr0))
    raw = raw[a0:a1]
    off, dur_raw = a0 / sr0, len(raw) / sr0
    chain = [f"rubberband=pitch={sp['pitch']}:formant=preserved"] if sp.get('pitch') else []
    chain.append(sp.get('af', 'highpass=f=70'))
    y = ffmpeg_proc(raw, sr0, ','.join(chain))
    scale = (len(y) / SR) / dur_raw
    hw = [(_norm(w['w']), w['s'] - off, w['e'] - off) for w in r['words'] if _norm(w['w'])]
    sw = [_norm(w) for w in spoken_words]
    times = [None] * len(sw)
    sm = difflib.SequenceMatcher(None, sw, [h[0] for h in hw], autojunk=False)
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == 'equal':
            for k in range(i2 - i1):
                times[i1 + k] = (hw[j1 + k][1], hw[j1 + k][2])
        elif tag == 'replace':
            s0, s1 = hw[j1][1], hw[j2 - 1][2]
            w = np.array([len(x) + 1.0 for x in sw[i1:i2]]); cum = np.concatenate([[0], np.cumsum(w)]) / w.sum()
            for k in range(i2 - i1):
                times[i1 + k] = (s0 + cum[k] * (s1 - s0), s0 + cum[k + 1] * (s1 - s0))
    i = 0
    while i < len(times):
        if times[i] is None:
            j = i
            while j < len(times) and times[j] is None:
                j += 1
            left = times[i - 1][1] if i > 0 else 0.02
            right = times[j][0] if j < len(times) else dur_raw - 0.05
            w = np.array([len(x) + 1.0 for x in sw[i:j]]); cum = np.concatenate([[0], np.cumsum(w)]) / w.sum()
            for k in range(j - i):
                times[i + k] = (left + cum[k] * (right - left), left + cum[k + 1] * (right - left))
            i = j
        else:
            i += 1
    words_t = [(max(0, a) * scale, max(0, b) * scale) for a, b in times]
    tok_t, wi = [], 0
    for disp, n in toks:
        tok_t.append((disp, words_t[wi][0], words_t[wi + n - 1][1])); wi += n
    rms = np.sqrt(np.mean(y[np.abs(y) > 0.01] ** 2)) if np.any(np.abs(y) > 0.01) else 0.1
    y = y * (sp['rms'] / max(rms, 1e-4))
    if r['score'] < 0.8:
        print(f"  ! {line['id']}: Whisper-Score {r['score']} – bitte anhören: {r['hyp']}")
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
    if kind == 'vhs':
        d = 0.45; t = tt(d)
        return 0.35 * bandnoise(d, 300, 9000, 77) * np.exp(-t * 7) + 0.5 * np.sin(2 * np.pi * 60 * t) * np.exp(-t * 20)
    if kind == 'ring':
        d = 1.1; t = tt(d)
        f = np.where((t * 22).astype(int) % 2 == 0, 2100, 2550)
        bell = np.sin(2 * np.pi * np.cumsum(f) / SR) + 0.4 * np.sin(2 * np.pi * np.cumsum(f * 2.7) / SR)
        return 0.22 * bell * (0.6 + 0.4 * np.sign(np.sin(2 * np.pi * 22 * t))) * np.minimum(1, (d - t) * 8)
    if kind == 'type':
        y = np.zeros(int(1.2 * SR)); rng = np.random.default_rng(42)
        for i in range(15):
            a = int((i * 0.072 + rng.uniform(0, 0.02)) * SR); c = bandnoise(0.025, 1800, 9000, 60 + i) * np.exp(-tt(0.025) * 260) * rng.uniform(0.18, 0.3)
            y[a:a + len(c)] += c
        return y
    if kind == 'glitch':
        d = 0.22; t = tt(d); rng = np.random.default_rng(7)
        nz = np.repeat(rng.uniform(-1, 1, int(len(t) / 40) + 1), 40)[:len(t)]
        nz = np.round(nz * 3) / 3
        sq = np.sign(np.sin(2 * np.pi * np.where(t < 0.1, 880, 220) * t))
        hit = np.sin(2 * np.pi * 52 * t) * np.exp(-t * 9)
        return 0.28 * nz * np.exp(-t * 9) + 0.12 * sq * (t < 0.14) + 0.7 * hit
    if kind == 'hit':
        t = tt(0.45)
        return 0.8 * np.sin(2 * np.pi * (48 + 40 * np.exp(-t * 30)) * t) * np.exp(-t * 8) + 0.25 * bandnoise(0.45, 100, 3000, 3) * np.exp(-t * 40)
    if kind == 'notif':
        y = np.zeros(int(0.7 * SR))
        for i, f in enumerate([1318.5, 1975.5]):
            a = int(i * 0.13 * SR); t = np.arange(len(y) - a) / SR
            y[a:] += 0.25 * np.sin(2 * np.pi * f * t) * np.exp(-t * 7) * np.minimum(1, t * 400)
        return y
    if kind == 'splash':
        d = 0.9; t = tt(d)
        return 0.6 * bandnoise(d, 200, 6000, 41) * np.exp(-t * 5) * np.minimum(1, t * 60) + 0.4 * np.sin(2 * np.pi * (90 + 120 * np.exp(-t * 20)) * t) * np.exp(-t * 12)
    if kind == 'horn':  # Schiffshorn
        d = 1.6; t = tt(d)
        y = sum(np.sign(np.sin(2 * np.pi * f * t)) * a for f, a in [(98, 1), (123.5, 0.7), (196, 0.3)])
        return 0.16 * np.convolve(y, np.ones(18) / 18, 'same') * np.minimum(1, t * 6) * np.minimum(1, (d - t) * 4)
    if kind == 'boom':
        d = 1.8; t = tt(d)
        return 0.9 * np.sin(2 * np.pi * (35 + 70 * np.exp(-t * 6)) * t) * np.exp(-t * 2.5) + 0.5 * bandnoise(d, 40, 1800, 13) * np.exp(-t * 3.5) * np.minimum(1, t * 200)
    if kind == 'glug':
        y = np.zeros(int(0.9 * SR))
        for i in range(4):
            t = tt(0.16); f = 260 + 180 * (t / 0.16)
            c = 0.35 * np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(np.pi * t / 0.16)
            a = int(i * 0.2 * SR); y[a:a + len(c)] += c
        return y
    if kind == 'groan':  # Stahl ächzt
        d = 1.6; t = tt(d); f = 70 + 25 * np.sin(2 * np.pi * 0.8 * t) + 10 * np.sin(2 * np.pi * 7 * t)
        return 0.3 * np.sign(np.sin(2 * np.pi * np.cumsum(f) / SR)) * bandnoise(d, 60, 900, 17) ** 2 * 3 * np.sin(np.pi * t / d)
    if kind == 'bubbles':
        y = np.zeros(int(1.2 * SR)); rng = np.random.default_rng(5)
        for i in range(14):
            t = tt(0.07); f = rng.uniform(500, 1400) * (1 + 2 * t / 0.07)
            c = 0.18 * np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(np.pi * t / 0.07)
            a = int(rng.uniform(0, 1.1) * SR); y[a:a + len(c)] += c[:len(y) - a]
        return y
    if kind == 'smash':  # Tonschale zerbricht
        d = 0.7; t = tt(d); y = 0.5 * bandnoise(d, 800, 9000, 23) * np.exp(-t * 9)
        for i in range(8):
            a = int(i * 0.04 * SR); t2 = t[:len(t) - a]
            y[a:] += 0.15 * np.sin(2 * np.pi * (1800 + 400 * i) * t2) * np.exp(-t2 * 25)
        return y
    if kind == 'crack':  # Knochen/Holz knackt
        d = 0.35; t = tt(d)
        return 0.9 * bandnoise(d, 1500, 9000, 29) * np.exp(-t * 60) + 0.5 * np.sin(2 * np.pi * 140 * t) * np.exp(-t * 30)
    if kind == 'recscratch':  # Plattenkratzer
        d = 0.55; t = tt(d); f = 900 * np.abs(np.sin(2 * np.pi * 2.2 * t)) + 150
        return 0.5 * bandnoise(d, 300, 5000, 33) * np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 3)
    if kind == 'rimshot':  # Ba-dum-tss
        y = np.zeros(int(1.4 * SR))
        for a, fr in [(0.0, 180), (0.16, 140)]:
            t = tt(0.25); c = 0.6 * np.sin(2 * np.pi * fr * t) * np.exp(-t * 20) + 0.4 * bandnoise(0.25, 1500, 6000, 5) * np.exp(-t * 25)
            i = int(a * SR); y[i:i + len(c)] += c
        t = tt(1.0); c = 0.35 * bandnoise(1.0, 5000, 15000, 9) * np.exp(-t * 4)
        i = int(0.34 * SR); y[i:i + len(c)] += c
        return y
    if kind == 'buzz':  # Handy vibriert / Fehler
        y = np.zeros(int(0.7 * SR))
        for a in (0.0, 0.3):
            t = tt(0.22); c = 0.4 * np.sign(np.sin(2 * np.pi * 150 * t)) * np.convolve(np.ones(len(t)), np.ones(1), 'same') * np.minimum(1, (0.22 - t) * 40)
            c = np.convolve(c, np.ones(30) / 30, 'same'); i = int(a * SR); y[i:i + len(c)] += c
        return y
    if kind == 'doorbell':
        y = np.zeros(int(1.6 * SR))
        for a, f in ((0.0, 659.3), (0.45, 523.3)):
            t = tt(1.1); c = 0.3 * (np.sin(2 * np.pi * f * t) + 0.4 * np.sin(2 * np.pi * f * 2.76 * t)) * np.exp(-t * 3.5)
            i = int(a * SR); y[i:i + len(c)] += c
        return y
    if kind == 'jingle':  # fröhliche Firmen-Melodie
        y = np.zeros(int(2.6 * SR))
        for i, (n, d) in enumerate([(72, .2), (76, .2), (79, .2), (84, .4), (81, .2), (84, .6)]):
            f = 440 * 2 ** ((n - 69) / 12); t = tt(0.9); c = 0.22 * (np.sin(2 * np.pi * f * t) + 0.5 * np.sin(4 * np.pi * f * t)) * np.exp(-t * 6)
            a = int(sum(x[1] for x in [(72, .2), (76, .2), (79, .2), (84, .4), (81, .2), (84, .6)][:i]) * SR); y[a:a + len(c)] += c[:len(y) - a]
        return y
    if kind == 'click':
        t = tt(0.05); return 0.5 * bandnoise(0.05, 1500, 8000, 61) * np.exp(-t * 120)
    if kind == 'flicker':
        y = np.zeros(int(1.0 * SR)); rng = np.random.default_rng(4)
        for a in rng.uniform(0, 0.9, 7):
            t = tt(0.04); c = 0.3 * bandnoise(0.04, 2000, 9000, int(a * 100)) * np.exp(-t * 80); i = int(a * SR); y[i:i + len(c)] += c
        t = tt(1.0); y += 0.05 * np.sin(2 * np.pi * 100 * t) * (np.sin(2 * np.pi * 9 * t) > 0)
        return y
    if kind == 'slam':  # Schranktüren fliegen auf
        y = np.zeros(int(1.3 * SR))
        for k, a in enumerate((0.0, 0.07, 0.13, 0.2)):
            t = tt(0.5); c = 0.7 * np.sin(2 * np.pi * (70 + 40 * k) * t) * np.exp(-t * 14) + 0.4 * bandnoise(0.5, 200, 3000, 70 + k) * np.exp(-t * 20)
            i = int(a * SR); y[i:i + len(c)] += c
        return y
    if kind == 'ghost':
        d = 1.6; t = tt(d); f = 420 + 120 * np.sin(2 * np.pi * 0.8 * t) + 15 * np.sin(2 * np.pi * 6 * t)
        return 0.18 * np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(np.pi * t / d) + 0.05 * bandnoise(d, 300, 3000, 71) * np.sin(np.pi * t / d)
    if kind == 'hupe':  # fröhliche Doppelhupe
        y = np.zeros(int(0.6 * SR))
        for a in (0.0, 0.22):
            t = tt(0.16); c = 0.3 * sum(np.sign(np.sin(2 * np.pi * f * t)) for f in (440, 554)) * np.minimum(1, (0.16 - t) * 60) * np.minimum(1, t * 200)
            c = np.convolve(c, np.ones(12) / 12, 'same'); i = int(a * SR); y[i:i + len(c)] += c
        return y
    if kind == 'siren':
        d = 1.6; t = tt(d); f = np.where((t * 2.5).astype(int) % 2 == 0, 740, 560)
        return 0.16 * np.sin(2 * np.pi * np.cumsum(f) / SR) * np.minimum(1, t * 8) * np.minimum(1, (d - t) * 6)
    if kind == 'engine':
        d = 1.2; t = tt(d); f = 55 + 40 * np.minimum(1, t / 0.6)
        return 0.35 * np.convolve(np.sign(np.sin(2 * np.pi * np.cumsum(f) / SR)), np.ones(40) / 40, 'same') * np.minimum(1, t * 10) * np.minimum(1, (d - t) * 5)
    if kind == 'spray':
        d = 1.8; t = tt(d); return 0.3 * bandnoise(d, 1500, 9000, 81) * np.minimum(1, t * 10) * np.minimum(1, (d - t) * 4)
    if kind == 'squish':
        d = 0.5; t = tt(d); return 0.5 * bandnoise(d, 100, 1200, 82) * np.exp(-t * 7) + 0.3 * np.sin(2 * np.pi * (180 - 120 * t) * t) * np.exp(-t * 8)
    if kind == 'spin':  # Räder drehen durch
        d = 1.4; t = tt(d); f = 300 + 80 * np.sin(2 * np.pi * 7 * t)
        return 0.2 * np.sin(2 * np.pi * np.cumsum(f) / SR) * (0.6 + 0.4 * np.sign(np.sin(2 * np.pi * 14 * t))) + 0.25 * bandnoise(d, 300, 3000, 83) * np.abs(np.sin(2 * np.pi * 7 * t))
    if kind == 'sparkle':
        y = np.zeros(int(1.0 * SR))
        for i, f in enumerate([1568, 2093, 2637, 3136]):
            t = tt(0.4); c = 0.15 * np.sin(2 * np.pi * f * t) * np.exp(-t * 9); a = int(i * 0.07 * SR); y[a:a + len(c)] += c
        return y
    if kind == 'pluck':  # Lyra-Akkord
        y = np.zeros(int(1.6 * SR))
        for i, f in enumerate([146.8, 220.0, 293.7, 349.2]):
            c = ks_pluck(f, 1.5); a = int(i * 0.05 * SR); y[a:a + len(c)] += 0.3 * c[:len(y) - a]
        return y
    raise ValueError(kind)


def ks_pluck(f, d, decay=0.996, seed=1):
    """Karplus-Strong-Saite, blockweise vektorisiert."""
    n, N = int(d * SR), max(2, int(SR / f))
    y = np.zeros(n + N + 1)
    y[:N + 1] = np.random.default_rng(seed).uniform(-1, 1, N + 1)
    i = N + 1
    while i < n:
        j = min(n, i + N)
        y[i:j] = decay * 0.5 * (y[i - N:j - N] + y[i - N - 1:j - N - 1])
        i = j
    out = y[:n]
    return out * np.minimum(1, np.arange(n) / 40)


def music_lyra(total, bpm, n):
    """Antik: Lyra-Arpeggien in D-Dorisch, Bordun, Rahmentrommel."""
    beat = 60.0 / bpm; y = np.zeros(n); tN = np.arange(n) / SR
    y += 0.05 * (np.sin(2 * np.pi * 73.4 * tN) + 0.6 * np.sin(2 * np.pi * 110 * tN)) * (0.8 + 0.2 * np.sin(2 * np.pi * 0.2 * tN))
    pats = [[293.7, 349.2, 440, 349.2], [261.6, 329.6, 392, 329.6], [293.7, 349.2, 440, 523.3], [246.9, 293.7, 392, 293.7]]
    cache = {}
    for b in range(int(total / beat * 2) + 1):
        tb = b * beat / 2; f = pats[(b // 8) % 4][b % 4]
        if f not in cache: cache[f] = ks_pluck(f, 1.4, 0.995, int(f))
        c = cache[f] * (0.22 if b % 2 == 0 else 0.15); a = int(tb * SR)
        if a < n: y[a:a + len(c)] += c[:n - a]
        if b % 4 == 0:
            t = tt(0.4); dr = 0.5 * np.sin(2 * np.pi * (70 + 50 * np.exp(-t * 25)) * t) * np.exp(-t * 9)
            if a < n: y[a:a + len(dr)] += dr[:n - a]
    return y


def music_retro(total, bpm, n):
    """50er-Jahre: Swing mit Walking Bass, Besen-Snare, Vibraphon-Akkorden + Plattenknistern."""
    beat = 60.0 / bpm; y = np.zeros(n)
    def add(sig, t0):
        a = int(t0 * SR)
        if 0 <= a < n: y[a:a + len(sig)] += sig[:n - a]
    prog_ = [[261.6, 329.6, 392.0, 440.0], [293.7, 349.2, 440.0, 523.3], [293.7, 349.2, 440.0, 523.3], [246.9, 293.7, 349.2, 440.0]]
    bass = [[65.4, 82.4, 98.0, 110.0], [73.4, 87.3, 110.0, 98.0], [73.4, 87.3, 110.0, 130.8], [98.0, 87.3, 82.4, 73.4]]
    for b in range(int(total / beat) + 1):
        tb = b * beat; bar = (b // 4) % 4; k = b % 4
        t = tt(beat * 0.95); f = bass[bar][k]
        add(0.32 * (np.sin(2 * np.pi * f * t) + 0.3 * np.sin(4 * np.pi * f * t)) * np.exp(-t * 3.5) * np.minimum(1, t * 300), tb)
        if k in (1, 3): add(0.12 * bandnoise(0.18, 2000, 9000, 40 + b % 7) * np.exp(-tt(0.18) * 14), tb)
        add(0.05 * bandnoise(0.05, 7000, 14000, 50) * np.exp(-tt(0.05) * 60), tb)
        add(0.035 * bandnoise(0.05, 7000, 14000, 51) * np.exp(-tt(0.05) * 60), tb + beat * 0.66)
        if k in (0, 2):
            t = tt(beat * 1.6)
            ch = sum(np.sin(2 * np.pi * fr * t) for fr in prog_[bar]) * (1 + 0.3 * np.sin(2 * np.pi * 5.5 * t))
            add(0.05 * ch * np.exp(-t * 2.2) * np.minimum(1, t * 200), tb + (beat * 0.66 if k == 2 else 0))
    rng = np.random.default_rng(3)
    hiss = 0.012 * bandnoise(min(total, 30), 1000, 9000, 77); reps = int(np.ceil(n / len(hiss)))
    y += np.tile(hiss, reps)[:n]
    for i in rng.integers(0, n - 200, int(total * 7)):
        y[i:i + 60] += rng.uniform(0.05, 0.25) * np.exp(-np.arange(60) / 8) * rng.choice([-1, 1])
    return y


def music_organ(total, bpm, n):
    """Trauerhallen-Orgel: langsame Mollakkorde."""
    y = np.zeros(n); bar = 60.0 / bpm * 4
    chords = [[110.0, 130.8, 164.8, 220.0], [87.3, 110.0, 130.8, 174.6], [98.0, 123.5, 146.8, 196.0], [82.4, 103.8, 123.5, 164.8]]
    for k in range(int(total / bar) + 1):
        t = tt(bar + 0.4); a = int(k * bar * SR)
        c = sum(sum(np.sin(2 * np.pi * f * h * t) / h for h in (1, 2, 3, 4)) for f in chords[k % 4])
        c *= 0.035 * np.minimum(1, t / 0.5) * np.minimum(1, (bar + 0.4 - t) / 0.5) * (1 + 0.04 * np.sin(2 * np.pi * 5 * t))
        if a < n: y[a:a + len(c)] += c[:n - a]
    return y


def music_romance(total, bpm, n):
    """Restaurant: sanftes Jazz-Klavier (Maj7-Akkorde)."""
    y = np.zeros(n); beat = 60.0 / bpm
    chords = [[261.6, 329.6, 392.0, 493.9], [220.0, 261.6, 329.6, 392.0], [293.7, 349.2, 440.0, 523.3], [196.0, 246.9, 293.7, 349.2]]
    for b in range(int(total / beat) + 1):
        ch = chords[(b // 4) % 4]; t = tt(beat * 2.2)
        if b % 2 == 0: c = sum(np.sin(2 * np.pi * f * t) + 0.25 * np.sin(4 * np.pi * f * t) for f in ch) * 0.05 * np.exp(-t * 1.8) * np.minimum(1, t * 300)
        else: f = ch[(b // 2) % 4] * 2; c = 0.07 * np.sin(2 * np.pi * f * t) * np.exp(-t * 3) * np.minimum(1, t * 300)
        a = int(b * beat * SR)
        if a < n: y[a:a + len(c)] += c[:n - a]
        bt = tt(0.3); bs = 0.2 * np.sin(2 * np.pi * ch[0] / 2 * bt) * np.exp(-bt * 6)
        if a < n: y[a:a + len(bs)] += bs[:n - a]
    return y


def music_kids(total, bpm, n):
    """Verspielt: Marimba-Melodie, Pizzicato-Bass, Holzblock und Shaker in C-Dur."""
    beat = 60.0 / bpm; y = np.zeros(n)
    def add(sig, t0):
        a = int(t0 * SR)
        if 0 <= a < n: y[a:a + len(sig)] += sig[:n - a]
    mel = [72, 76, 79, 76, 74, 77, 81, 77, 72, 76, 79, 84, 83, 79, 74, 79]
    bass = [48, 55, 50, 57, 53, 55, 48, 43]
    for b in range(int(total / beat * 2) + 1):
        tb = b * beat / 2; f = 440 * 2 ** ((mel[b % 16] - 69) / 12)
        if b % 16 not in (7, 15):
            t = tt(0.4); add(0.11 * (np.sin(2 * np.pi * f * t) + 0.35 * np.sin(2 * np.pi * f * 4 * t) * np.exp(-t * 30)) * np.exp(-t * 9) * np.minimum(1, t * 400), tb)
        if b % 2 == 0:
            fb = 440 * 2 ** ((bass[(b // 2) % 8] - 69) / 12); t = tt(0.3)
            add(0.22 * np.sin(2 * np.pi * fb * t) * np.exp(-t * 10) * np.minimum(1, t * 300), tb)
        if b % 4 == 2: t = tt(0.06); add(0.18 * np.sin(2 * np.pi * 1200 * t) * np.exp(-t * 80), tb)
        add(0.04 * bandnoise(0.06, 5000, 12000, 90 + b % 3) * np.exp(-tt(0.06) * 50), tb)
    return y


def music_drama(total, bpm, n):
    """Dramatisch: Klavier-Arpeggien in d-Moll über Streicherfläche."""
    beat = 60.0 / bpm; y = np.zeros(n); tN = np.arange(n) / SR
    chords = [[146.8, 174.6, 220.0], [116.5, 146.8, 174.6], [174.6, 220.0, 261.6], [130.8, 164.8, 196.0]]
    bar = beat * 4
    for k in range(int(total / bar) + 1):
        ch = chords[k % 4]; a = int(k * bar * SR); t = tt(bar + 0.3)
        pad = sum(np.convolve(np.sign(np.sin(2 * np.pi * f / 2 * t + i)), np.ones(30) / 30, 'same') for i, f in enumerate(ch))
        pad *= 0.05 * np.minimum(1, t / 0.8) * np.minimum(1, (bar + 0.3 - t) / 0.4)
        if a < n: y[a:a + len(pad)] += pad[:n - a]
        for j in range(8):
            f = ch[j % 3] * (2 if j >= 3 else 2) * (2 if j in (3, 7) else 1); t = tt(1.6)
            note = 0.12 * (np.sin(2 * np.pi * f * t) + 0.3 * np.sin(4 * np.pi * f * t) + 0.1 * np.sin(6 * np.pi * f * t)) * np.exp(-t * 3) * np.minimum(1, t * 300)
            b = a + int(j * beat / 2 * SR)
            if b < n: y[b:b + len(note)] += note[:n - b]
    return y


def make_music(total, bpm, n):
    beat = 60.0 / bpm
    y = np.zeros(n)

    def add(sig, t0):
        a = int(t0 * SR)
        if a < n:
            y[a:a + len(sig)] += sig[:n - a]
    t = tt(0.35); kick = np.sin(2 * np.pi * np.cumsum(110 * np.exp(-t * 18) + 45) / SR) * np.exp(-t * 7)
    t = tt(0.18); snare = 0.45 * bandnoise(0.18, 1500, 7000, 91) * np.exp(-t * 22) + 0.3 * np.sin(2 * np.pi * 190 * t) * np.exp(-t * 25)
    t = tt(0.05); hat = 0.22 * bandnoise(0.05, 6000, 14000, 92) * np.exp(-t * 80)
    notes = [55.0, 55.0, 43.65, 49.0]
    for b in range(int(total / beat) + 1):
        tb = b * beat
        if b % 4 in (0, 2): add(kick, tb)
        if b % 4 in (1, 3): add(snare, tb)
        add(hat, tb); add(0.6 * hat, tb + beat / 2)
        if b % 2 == 0:
            f0 = notes[(b // 4) % 4]; t = tt(beat * 1.9)
            add(0.32 * sum(np.sin(2 * np.pi * f0 * k * t) / k for k in range(1, 5)) * np.exp(-t * 1.3) * np.minimum(1, t * 200), tb)
    return y


# ---------------- Build ----------------
def main():
    if ENGINE == 'chatterbox':
        run_chatterbox()
    timeline, cursor, prev_scene = [], START, None
    clips = []
    for i, line in enumerate(LINES):
        if prev_scene is not None and line['scene'] != prev_scene:
            cursor += GAP_SCENE - GAP_SAME
        if ENGINE == 'elevenlabs':
            y, tok_t, spoken = synth_line_el(line)
        elif ENGINE == 'chatterbox':
            y, tok_t, spoken = synth_line_cb(line)
        else:
            y, tok_t, spoken = synth_line(line)
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
    fx = np.zeros(n)
    tracks = {}
    for start, y, spk in clips:
        a = int(start * SR)
        tracks.setdefault(spk, np.zeros(n))[a:a + len(y)] += y
    voiceN = tracks.get('N', np.zeros(n))
    voiceG = sum((v for k, v in tracks.items() if k != 'N'), np.zeros(n))
    cues = {}
    for e in timeline:
        for c in e['cues']:
            cues[c['name']] = c['t']
            if c['sfx']:
                s = sfx(c['sfx'])
                off = -0.05 if c['sfx'] in ('stamp', 'pop', 'tick', 'ding', 'tada', 'boing', 'smash', 'splash', 'boom', 'pluck', 'crack', 'recscratch', 'rimshot', 'click', 'doorbell', 'slam', 'hupe', 'squish', 'sparkle') else -0.15
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
    if MUSIC:
        mus = {'lyra': music_lyra, 'drama': music_drama, 'retro': music_retro, 'organ': music_organ, 'romance': music_romance, 'kids': music_kids}.get(MUSIC.get('style'), make_music)(total, MUSIC.get('bpm', 100), n)
        v = np.abs(voiceN + voiceG)
        k = int(0.08 * SR)
        env = np.convolve(v, np.ones(k) / k, mode='same')
        duck = 1 - 0.6 * np.clip(env / 0.05, 0, 1)
        fade_out = np.clip((total - np.arange(n) / SR) / 1.2, 0, 1)
        if MUSIC.get('stop'):  # Musik bricht an einer Zeile ab (Pointe)
            ts = next(e['start'] for e in timeline if e['id'] == MUSIC['stop']) - 0.25
            mus = mus * np.clip((ts - np.arange(n) / SR) / 0.12, 0, 1)
        mix = mix + MUSIC.get('gain', 0.2) * mus * duck * fade_out
    peak = np.abs(mix).max()
    mix = np.tanh(mix / max(peak, 1e-6) * 1.4) / np.tanh(1.4) * 0.95
    raw = os.path.join(OUT, 'mix_raw.wav')
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'f32le', '-ar', str(SR), '-ac', '1', '-i', 'pipe:0',
                    '-af', 'loudnorm=I=-14:TP=-1.0:LRA=11', '-ar', str(SR), '-ac', '2', os.path.join(OUT, 'audio.wav')],
                   input=mix.astype(np.float32).tobytes(), check=True)
    # Mundbewegung (pro Sprecher; 'mouth' = alle außer Erzähler N)
    hop = SR // FPS
    nf = int(total * FPS) + 1

    def mouth_env(track):
        env = np.array([np.sqrt(np.mean(track[i * hop:(i + 1) * hop] ** 2)) if i * hop < n else 0 for i in range(nf)])
        ref = np.percentile(env[env > 0.005], 90) if np.any(env > 0.005) else 1
        env = np.clip(env / ref, 0, 1) ** 0.7
        sm, out = 0.0, []
        for v in env:
            sm = v if v > sm else sm * 0.55 + v * 0.45
            out.append(round(float(sm), 3))
        return out
    out = mouth_env(voiceG)
    mouths = {k: mouth_env(v) for k, v in tracks.items()}
    tl = dict(fps=FPS, duration=round(total, 3), lines=timeline, cues=cues, scenes=bounds, sceneOrder=SCENES, mouth=out, mouths=mouths)
    tl['data'] = getattr(_mod, 'EXPORT', None)  # frei verwendbare Folgen-Daten für die Szenen (z. B. Quizfragen)
    with open(os.path.join(OUT, 'timeline.js'), 'w') as f:
        f.write('window.TL = ' + json.dumps(tl, ensure_ascii=False) + ';\n')
    with open(os.path.join(OUT, 'timeline.json'), 'w') as f:
        json.dump({k: v for k, v in tl.items() if k != 'mouth'}, f, ensure_ascii=False, indent=1)
    print(f"Dauer: {total:.2f}s  Szenen: {bounds}")


if __name__ == '__main__':
    main()
