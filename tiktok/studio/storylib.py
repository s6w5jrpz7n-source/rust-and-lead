"""Erzähl-Folgen (Philosophie, Geschichte): Zeilen mit Inline-Cues.
Ein Token '^name' oder '^name:sfx' setzt einen Cue auf das folgende Wort."""
import re

NARR = {
    # ruhiger Erzähler (Philosophie)
    'P': dict(model='de_DE-thorsten-high', ref='refs/notar.wav', exag=0.5, cfg=0.45, length=1.0, noise=0.5, noise_w=0.6,
              rms=0.14, af='highpass=f=70,equalizer=f=3000:t=q:w=1:g=1.5'),
    # Geschichten-Erzähler (Historie)
    'H': dict(model='de_DE-thorsten-high', ref='refs/host.wav', exag=0.55, cfg=0.45, length=1.0, noise=0.5, noise_w=0.6,
              rms=0.15, af='highpass=f=70,equalizer=f=3000:t=q:w=1:g=2'),
}


def L(id, text, spk, gap=0.28, scene='s'):
    toks, cues, pending = [], [], []
    for m in re.finditer(r'\{[^}]*\}|\S+', text):
        tok = m.group(0)
        if tok.startswith('^'):
            name, _, sfx = tok[1:].partition(':')
            pending.append((name, sfx or None))
            continue
        for name, sfx in pending:
            cues.append((len(toks), name, sfx))
        pending = []
        toks.append(tok)
    assert not pending, f'{id}: Cue ohne folgendes Wort'
    return dict(id=id, spk=spk, scene=scene, text=' '.join(toks), gap=gap, cues=cues)
