"""Gemeinsame Bausteine für Quiz-Folgen (Gameshow-Format, siehe quiz.js)."""
HOST = {
    'Q': dict(model='de_DE-thorsten-high', ref='refs/host.wav', exag=0.75, cfg=0.5, length=1.0, noise=0.5, noise_w=0.6,
              rms=0.15, af='highpass=f=70,equalizer=f=3000:t=q:w=1:g=2'),
}
ZAHL = ['eins', 'zwei', 'drei', 'vier', 'fünf', 'sechs', 'sieben', 'acht', 'neun', 'zehn']


def quiz_lines(intro, questions, outro='Wie viele hattest du? Schreib’s in die Kommentare!', countdown=2.3):
    """questions: Liste von dict(say=..., answer=..., [qextra=dict], [aextra=dict]) – say/answer = gesprochen."""
    words = intro.split()
    gi = next(i for i, w in enumerate(words) if w.lower().startswith('genie'))
    li = next(i for i, w in enumerate(words) if w.lower().startswith('los'))
    lines = [dict(id='intro', spk='Q', scene='quiz', text=intro, gap=0.35,
                  cues=[(0, 'title', 'hit'), (gi, 'genie', 'ding'), (li, 'go', 'whoosh')])]
    extra = []
    for i, q in enumerate(questions, 1):
        if i == 8:
            lines.append(dict(id='h8', spk='Q', scene='quiz', text='Jetzt wird’s schwer.', gap=0.15, cues=[(0, 'hard', 'hit')]))
        if i == 10:
            lines.append(dict(id='h10', spk='Q', scene='quiz', text='Letzte Frage. Nur für Genies.', gap=0.15, cues=[(0, 'last', 'hit')]))
        lines.append(dict(id=f'q{i}', spk='Q', scene='quiz', text=q['say'], gap=countdown, cues=[(0, f'q{i}', 'whoosh_s')], **q.get('qextra', {})))
        lines.append(dict(id=f'a{i}', spk='Q', scene='quiz', text=q['answer'], gap=q.get('agap', 0.4), cues=[(0, f'a{i}', 'ding')], **q.get('aextra', {})))
        extra += [(f'tk{i}_{j}', f'q{i}', 'end', 0.12 + j * 0.72, 'tick') for j in range(3)]
    lines.append(dict(id='o1', spk='Q', scene='quiz', text=outro, gap=2.6, cues=[(0, 'outro', 'tada')]))
    return lines, extra
