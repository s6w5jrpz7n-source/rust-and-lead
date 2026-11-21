# OPAS TESTAMENT – animierter Sketch, schwarzer Humor, dreckig
# spk: N = Notar, O = Opa (VHS-Video), U = Uwe (Sohn), S = Sabine (Schwiegertochter), K = Kevin (Enkel, 30)
# Textsyntax: {Anzeige|gesprochen}  |  cues: (Wortindex der Anzeige, Cue-Name, SFX oder None)

ENGINE = 'chatterbox'
SPEAKERS = {
    'N': dict(model='de_DE-thorsten-high', ref='refs/notar.wav', exag=0.35, cfg=0.5, length=1.0, noise=0.5, noise_w=0.6,
              rms=0.13, af='highpass=f=70'),
    'O': dict(model='de_DE-thorsten-high', ref='refs/opa.wav', exag=0.7, cfg=0.45, length=1.0, noise=0.5, noise_w=0.6,
              rms=0.15, af='highpass=f=140,lowpass=f=6000,vibrato=f=0.7:d=0.08'),
    'U': dict(model='de_DE-thorsten-high', ref='refs/uwe.wav', exag=0.6, cfg=0.5, length=1.0, noise=0.5, noise_w=0.6, rms=0.13),
    'S': dict(model='de_DE-thorsten-high', ref='refs/sabine.wav', exag=0.95, cfg=0.4, length=1.0, noise=0.5, noise_w=0.6, rms=0.13),
    'K': dict(model='de_DE-thorsten-high', ref='refs/kevin.wav', exag=0.85, cfg=0.45, length=1.0, noise=0.5, noise_w=0.6, rms=0.13),
}

LINES = [
    dict(id='n1', spk='N', scene='room', text='Testamentseröffnung, Familie Bode. Ihr Vater hat ein Video hinterlassen.', gap=0.9,
         cues=[(0, 'start', None)]),
    dict(id='o1', spk='O', scene='room', text='Wenn ihr das seht, bin ich tot. Endlich. Ihr habt mich lange genug genervt.',
         cues=[(7, 'endlich', None)]),
    dict(id='o2', spk='O', scene='room',
         text='Uwe. Du kriegst meine Werkzeugkiste. Du weißt eh nicht, wie man die aufmacht, du Weichei.',
         cues=[(0, 'uwe', 'whoosh_s'), (4, 'kiste', 'pop')]),
    dict(id='u1', spk='U', scene='room', text='Papa…', cues=[(0, 'uweSad', None)]),
    dict(id='o3', spk='O', scene='room',
         text='Sabine. {20|Zwanzig} Jahre lang dein Kartoffelsalat. Das war versuchter Mord. Du kriegst gar nichts.',
         cues=[(0, 'sabine', 'whoosh_s'), (5, 'salat', 'pop'), (9, 'mord', 'stamp')]),
    dict(id='s1', spk='S', scene='room', text='Wie bitte?!', cues=[(0, 'sabShock', None)]),
    dict(id='o4', spk='O', scene='room',
         text='Kevin. Du bist {30|dreißig} und wohnst immer noch in meinem Keller. Du kriegst mein Auto. Hau endlich ab, du Lappen.',
         cues=[(0, 'kevin', 'whoosh_s'), (14, 'auto', 'pop')]),
    dict(id='k1', spk='K', scene='room', text='Geil, der Golf!', cues=[(0, 'kevYay', None)]),
    dict(id='o5', spk='O', scene='room', text='Der hat keinen TÜV. Und keine Bremsen. Gute Fahrt.',
         cues=[(3, 'tuev', 'pop'), (6, 'bremsen', 'stamp')]),
    dict(id='o6', spk='O', scene='room', text='Mein Erspartes, {300.000 Euro,|dreihunderttausend Euro,} kriegt…', gap=1.0,
         cues=[(0, 'erspart', None), (2, 'money', 'ding')]),
    dict(id='o7', spk='O', scene='room', text='Gerda von nebenan. Die hat mich als Einzige besucht. Und nicht nur besucht.',
         cues=[(0, 'gerda', 'tada'), (9, 'wink', None)]),
    dict(id='s2', spk='S', scene='room', text='Die ist {82!|zweiundachtzig!}', cues=[(2, 'achtzig', None)]),
    dict(id='o8', spk='O', scene='room', text='Und gelenkig.', gap=0.6, cues=[(1, 'gelenkig', 'boing')]),
    dict(id='o9', spk='O', scene='room', text='Ach, Kevin. Die Dose im Keller war kein Proteinpulver. Das war Oma.',
         cues=[(3, 'dose', 'pop'), (11, 'oma', 'stamp')]),
    dict(id='k2', spk='K', scene='room', text='Ich hab das jeden Morgen in meinen Shake gemacht!', cues=[(0, 'kevSick', None)]),
    dict(id='o10', spk='O', scene='room', text='Ich weiß. Tschüss, ihr Wichser.', gap=0.8, cues=[(2, 'finger', None)]),
    dict(id='n2', spk='N', scene='room', text='Der Leichenschmaus ist übrigens nebenan. Es gibt Kartoffelsalat.', gap=2.2,
         cues=[(7, 'salat2', 'sting')]),
]
EXTRA_CUES = [('vhsOn', 'n1', 'end', 0.15, 'vhs'), ('drum', 'o6', 'end', 0.0, 'drum'), ('vhsOff', 'o10', 'end', 0.2, 'vhs')]
SCENES = ['room']
