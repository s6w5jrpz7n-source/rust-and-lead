#!/usr/bin/env python3
# ============================================================================
#  RUST & LEAD — Hörspiel-Vertonung mit Azure AI Speech
# ----------------------------------------------------------------------------
#  Liest docs/hoerspiel_tts.json und rendert PRO gesprochener Zeile eine WAV.
#  Rollen sind bereits auf konkrete de-DE-Neural-Stimmen gemappt; die Regie-
#  Spalte fließt als Prosodie (Tempo/Tonhöhe/Lautstärke) in das SSML ein.
#
#  SO BENUTZT DU ES:
#   1) Azure-Konto anlegen -> Ressource "Speech" (Free-Tier F0 reicht:
#      ~500.000 Zeichen/Monat; dieses Hörspiel hat nur ~15.400).
#   2) Key + Region unten eintragen  ODER  als Umgebungsvariablen setzen:
#         export AZURE_SPEECH_KEY="dein_key"
#         export AZURE_SPEECH_REGION="westeurope"
#   3) SDK installieren:   pip install azure-cognitiveservices-speech
#   4) Starten:            python3 docs/azure_tts.py
#      -> WAVs landen in docs/hoerspiel_audio/  (z.B. f1_007_HELD.wav)
#
#  Nur SSML ansehen/woanders nutzen (kein Azure-Aufruf, kein SDK nötig):
#         python3 docs/azure_tts.py --dry-run
#      -> schreibt .ssml.xml je Zeile statt Audio.
#
#  HINWEIS Held-Doppel-Timbre: Der metallische Unterton ab Folge 2 (fx-Feld)
#  ist ein POST-Effekt. Azure kann ihn nicht erzeugen -> nach dem Rendern in
#  Audacity/ffmpeg einen leichten Ringmodulator/Pitch-Layer auf die HELD-WAVs
#  legen. Das Skript markiert die betroffenen Dateien im Log.
# ============================================================================

import os, sys, json, pathlib, html

# --- Zugangsdaten (hier eintragen ODER per Umgebungsvariable) ----------------
AZURE_KEY    = os.environ.get("AZURE_SPEECH_KEY", "HIER_DEINEN_KEY_EINTRAGEN")
AZURE_REGION = os.environ.get("AZURE_SPEECH_REGION", "westeurope")

DRY_RUN = "--dry-run" in sys.argv

HERE    = pathlib.Path(__file__).resolve().parent
JSON_IN = HERE / "hoerspiel_tts.json"
OUT_DIR = HERE / "hoerspiel_audio"

# --- Prosodie je Rolle: (rate %, pitch %, volume %) --------------------------
# Grundhaltung der Figur. Relativ zur Standardstimme; wird von Regie-Keywords
# (siehe unten) pro Zeile noch fein nachjustiert.
ROLE_PROSODY = {
    "ERZÄHLER":          (-6,   0,   0),   # gemessen, ruhig
    "HELD":              ( 0,  -4,   0),   # Bariton
    "MABEL":             (-4,  -6,   0),   # warm, tief
    "SILAS":             (-8,  -4,   0),   # alt, bedächtig
    "DOC ARIS":          ( 0,   0,   0),
    "KOLBEN-JACK":       (+6,  -4,  +8),   # laut
    "GIDEON":            ( 0,  -2,  +2),   # fest
    "VANE":              (-10, -2,  -4),   # langsam, leise, kontrolliert
    "PATROUILLENFÜHRER": (-2,   0,   0),   # kalt
    "TESS":              (+12, +2,   0),   # schnell
    "PIP":               (+4, +18,   0),   # hell/kindlich
    "SIEDLER":           (-6,  -2,   0),
}
DEFAULT_PROSODY = (0, 0, 0)

# --- Regie-Keywords -> Prosodie-Zuschlag (rate, pitch, volume) ---------------
REGIE_RULES = [
    (("leise", "flüstert", "flüsternd", "still", "kaum hörbar"), (-4,  0, -14)),
    (("brüllt", "laut", "schreit"),                              (+6, +2, +14)),
    (("ruhig", "sehr ruhig", "trocken"),                         (-4,  0,   0)),
    (("schnell", "rattert"),                                     (+8,  0,   0)),
    (("langsam",),                                               (-6,  0,   0)),
    (("hart", "kalt"),                                           ( 0, -2,  +2)),
    (("keuchend", "müde", "heiser"),                             (-4, -2,  -4)),
]

def prosody_for(role, regie):
    r, p, v = ROLE_PROSODY.get(role, DEFAULT_PROSODY)
    low = (regie or "").lower()
    for keys, (dr, dp, dv) in REGIE_RULES:
        if any(k in low for k in keys):
            r += dr; p += dp; v += dv
    clamp = lambda x: max(-50, min(50, x))
    return clamp(r), clamp(p), clamp(v)

def build_ssml(voice, text, role, regie):
    r, p, v = prosody_for(role, regie)
    fmt = lambda n: (f"+{n}%" if n >= 0 else f"{n}%")
    return (
        '<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" '
        'xmlns:mstts="https://www.w3.org/2001/mstts" xml:lang="de-DE">'
        f'<voice name="{voice}">'
        f'<prosody rate="{fmt(r)}" pitch="{fmt(p)}" volume="{fmt(v)}">'
        f'{html.escape(text)}'
        '</prosody></voice></speak>'
    )

def main():
    doc = json.loads(JSON_IN.read_text(encoding="utf-8"))
    role_voice = {role: v.get("azure") for role, v in doc["voices"].items()}
    lines = [e for e in doc["events"] if e.get("spoken")]
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    total_chars = sum(len(e["text"]) for e in lines)
    print(f"{len(lines)} Zeilen · {total_chars:,} Zeichen · Ausgabe: {OUT_DIR}")
    if not DRY_RUN and AZURE_KEY == "HIER_DEINEN_KEY_EINTRAGEN":
        print("\n⚠  Kein Azure-Key gesetzt. Entweder oben eintragen / AZURE_SPEECH_KEY setzen,")
        print("   oder mit  --dry-run  nur die SSML-Dateien erzeugen.")
        sys.exit(1)

    synth = None
    if not DRY_RUN:
        try:
            import azure.cognitiveservices.speech as speechsdk
        except ImportError:
            print("\n⚠  SDK fehlt:  pip install azure-cognitiveservices-speech")
            sys.exit(1)
        cfg = speechsdk.SpeechConfig(subscription=AZURE_KEY, region=AZURE_REGION)
        cfg.set_speech_synthesis_output_format(
            speechsdk.SpeechSynthesisOutputFormat.Riff24Khz16BitMonoPcm)
        speechsdk_ref = speechsdk

    fx_files = []
    for e in lines:
        role = e["rolle"]
        voice = role_voice.get(role)
        if not voice:
            print(f"  · seq {e['seq']}: keine Stimme für Rolle '{role}' — übersprungen")
            continue
        base = f"f{e['folge']}_{e['seq']:03d}_{role.replace(' ', '')}"
        ssml = build_ssml(voice, e["text"], role, e.get("regie", ""))

        if DRY_RUN:
            (OUT_DIR / (base + ".ssml.xml")).write_text(ssml, encoding="utf-8")
            continue

        wav = OUT_DIR / (base + ".wav")
        audio_cfg = speechsdk_ref.audio.AudioOutputConfig(filename=str(wav))
        s = speechsdk_ref.SpeechSynthesizer(speech_config=cfg, audio_config=audio_cfg)
        res = s.speak_ssml_async(ssml).get()
        if res.reason == speechsdk_ref.ResultReason.SynthesizingAudioCompleted:
            tag = "  (Post-FX: Doppel-Timbre)" if e.get("fx") else ""
            if e.get("fx"):
                fx_files.append(wav.name)
            print(f"  ✓ {wav.name}{tag}")
        else:
            det = getattr(res, "cancellation_details", None)
            print(f"  ✗ {base}: {res.reason} {getattr(det,'error_details','')}")

    if DRY_RUN:
        print("Fertig (SSML). Kein Azure-Aufruf.")
    else:
        print("Fertig.")
        if fx_files:
            print("\nDoppel-Timbre nachträglich auf diese HELD-Dateien legen "
                  "(Ringmodulator/Pitch-Layer in Audacity oder ffmpeg):")
            for n in fx_files:
                print("   ", n)

if __name__ == "__main__":
    main()
