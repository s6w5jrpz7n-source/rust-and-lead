#!/usr/bin/env python3
# ============================================================================
#  RUST & LEAD — Vertonung mit Azure AI Speech
# ----------------------------------------------------------------------------
#  Liest docs/hoerspiel_tts.json und rendert PRO gesprochener Zeile eine Datei.
#  Rollen sind auf konkrete de-DE-Neural-Stimmen gemappt; die Regie-Spalte
#  fliesst als Prosodie (Tempo/Tonhoehe/Lautstaerke) ins SSML ein.
#
#  KEIN FREMDPAKET NOETIG. Das Skript spricht die REST-Schnittstelle direkt an
#  (urllib aus der Standardbibliothek). Frueher stand hier das offizielle SDK —
#  `pip install azure-cognitiveservices-speech` —, und genau daran ist der
#  erste Anlauf gescheitert: Das Paket bringt kompilierte Wheels mit und hinkt
#  neuen Python-Versionen regelmaessig hinterher. Wer eine frische Python-
#  Installation hat, bekommt dort einen Uebersetzungsfehler statt Sprache. Die
#  REST-Schnittstelle kann dasselbe und laeuft ueberall.
#
#  ── SO FAENGST DU AN ───────────────────────────────────────────────────────
#
#   1) Azure-Konto -> Ressource "Speech" anlegen. Der kostenlose Tarif F0
#      reicht bei Weitem: 500.000 Zeichen im Monat, dieses Hoerspiel hat
#      15.429. Du kannst also zwanzigmal alles neu rendern.
#
#   2) Schluessel und Region setzen (Region ist z.B. "westeurope", NICHT die
#      Adresse aus dem Portal):
#         export AZURE_SPEECH_KEY="dein_key"
#         export AZURE_SPEECH_REGION="westeurope"
#      Unter Windows in der PowerShell:
#         $env:AZURE_SPEECH_KEY="dein_key"
#         $env:AZURE_SPEECH_REGION="westeurope"
#
#   3) ZUERST pruefen, nicht gleich rendern:
#         python3 docs/azure_tts.py --pruefen
#      Das kostet nichts, dauert eine Sekunde und sagt dir genau, ob
#      Schluessel und Region stimmen — und ob es jede der zwoelf Stimmen in
#      deiner Region ueberhaupt gibt.
#
#   4) Dann EINE Zeile:
#         python3 docs/azure_tts.py --probe
#      Eine Datei, zum Anhoeren. Wenn die klingt, klingt der Rest auch.
#
#   5) Und dann alles:
#         python3 docs/azure_tts.py
#      Bereits vorhandene Dateien werden UEBERSPRUNGEN. Ein Abbruch nach
#      achtzig Zeilen kostet dich also nicht die achtzig.
#
#  ── WEITERE SCHALTER ───────────────────────────────────────────────────────
#
#   --dry-run       Nur die SSML-Dateien schreiben, kein Azure-Aufruf.
#   --neu           Vorhandene Dateien ueberschreiben statt ueberspringen.
#   --rolle HELD    Nur diese eine Rolle rendern.
#   --mp3           MP3 statt WAV (kleiner, gut zum Durchhoeren).
#   --folge 1       Nur diese Folge.
#
#  ── DER STOLPERSTEIN, DEN MAN NICHT KOMMEN SIEHT ───────────────────────────
#
#  Der kostenlose Tarif erlaubt nur eine Handvoll Anfragen pro Minute. Wer 111
#  Zeilen in einer Schleife ohne Pause abschickt, bekommt ab der zwanzigsten
#  eine Wand aus "429 Too Many Requests" und haelt es fuer einen Fehler im
#  Schluessel. Das Skript wartet deshalb von sich aus zwischen den Anfragen
#  (`PAUSE_SEK`) und legt bei einer 429 noch einmal nach. Der ganze Durchlauf
#  dauert damit ein paar Minuten — er laeuft aber durch.
#
#  ── HELD-DOPPEL-TIMBRE ─────────────────────────────────────────────────────
#
#  Der metallische Unterton ab Folge 2 (fx-Feld) ist ein POST-Effekt. Azure
#  kann ihn nicht erzeugen -> nach dem Rendern in Audacity/ffmpeg einen
#  leichten Ringmodulator/Pitch-Layer auf die HELD-Dateien legen. Das Skript
#  nennt die betroffenen Dateien am Ende beim Namen.
# ============================================================================

import os
import sys
import json
import time
import html
import pathlib
import urllib.request
import urllib.error

# --- Zugangsdaten ------------------------------------------------------------
AZURE_KEY = os.environ.get("AZURE_SPEECH_KEY", "")
AZURE_REGION = os.environ.get("AZURE_SPEECH_REGION", "westeurope")

HERE = pathlib.Path(__file__).resolve().parent
JSON_IN = HERE / "hoerspiel_tts.json"
OUT_DIR = HERE / "hoerspiel_audio"

# Zwischen zwei Anfragen. Siehe oben: Der kostenlose Tarif drosselt hart, und
# eine Drosselung sieht im Log aus wie ein kaputter Schluessel.
PAUSE_SEK = 3.2
# Wie oft eine gedrosselte Anfrage wiederholt wird, bevor aufgegeben wird.
VERSUCHE = 4

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

FORMATE = {
    "wav": ("riff-24khz-16bit-mono-pcm", ".wav"),
    "mp3": ("audio-24khz-96kbitrate-mono-mp3", ".mp3"),
}


def prosody_for(role, regie, delivery="gesprochen"):
    r, p, v = ROLE_PROSODY.get(role, DEFAULT_PROSODY)
    low = (regie or "").lower()
    for keys, (dr, dp, dv) in REGIE_RULES:
        if any(k in low for k in keys):
            r += dr
            p += dp
            v += dv
    if delivery == "gedanke":      # innerer Monolog: intim, leiser, etwas langsamer
        r += -4
        v += -16
        p += -1
    def clamp(x):
        return max(-50, min(50, x))
    return clamp(r), clamp(p), clamp(v)


def build_ssml(voice, text, role, regie, delivery="gesprochen"):
    r, p, v = prosody_for(role, regie, delivery)
    def fmt(n):
        return f"+{n}%" if n >= 0 else f"{n}%"
    return (
        '<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" '
        'xmlns:mstts="https://www.w3.org/2001/mstts" xml:lang="de-DE">'
        f'<voice name="{voice}">'
        f'<prosody rate="{fmt(r)}" pitch="{fmt(p)}" volume="{fmt(v)}">'
        f'{html.escape(text)}'
        '</prosody></voice></speak>'
    )


# ── Netz ─────────────────────────────────────────────────────────────────────

def _host():
    return f"https://{AZURE_REGION}.tts.speech.microsoft.com"


def _deuten(fehler):
    """Eine HTTP-Antwort in einen Satz uebersetzen, mit dem man etwas anfangen kann.

    Ohne das hier steht im Log `HTTP Error 401` — und 401 heisst bei Azure
    dreierlei, von denen nur eins der Schluessel ist.
    """
    code = getattr(fehler, "code", 0)
    return {
        400: "400 — SSML abgelehnt. Meist ein Stimmname, den es in dieser Region nicht gibt "
             "(--pruefen sagt dir welcher).",
        401: "401 — Schluessel abgelehnt. AZURE_SPEECH_KEY falsch, abgelaufen, oder er gehoert "
             "zu einer anderen Region.",
        403: "403 — Verboten. Meist: Kontingent aufgebraucht oder die Ressource ist keine "
             "'Speech'-Ressource.",
        404: "404 — Diese Region kennt den Dienst nicht. AZURE_SPEECH_REGION pruefen "
             "(z.B. 'westeurope', nicht 'West Europe' und nicht die volle Adresse).",
        429: "429 — Gedrosselt. Zu viele Anfragen; der kostenlose Tarif erlaubt nur wenige "
             "pro Minute.",
    }.get(code, f"{code} — {fehler}")


def _post(pfad, daten, headers, versuche=VERSUCHE):
    """POST mit Wiederholung bei Drosselung."""
    warte = PAUSE_SEK
    letzter = None
    for n in range(versuche):
        req = urllib.request.Request(_host() + pfad, data=daten, headers=headers, method="POST")
        try:
            with urllib.request.urlopen(req, timeout=60) as antwort:
                return antwort.read()
        except urllib.error.HTTPError as e:
            letzter = e
            if e.code != 429:
                raise
            # Azure nennt oft selbst, wie lange man warten soll. Wenn nicht: verdoppeln.
            nach = e.headers.get("Retry-After")
            warte = float(nach) if nach and nach.isdigit() else warte * 2
            print(f"      gedrosselt, warte {warte:.0f} s (Versuch {n + 2}/{versuche})")
            time.sleep(warte)
    raise letzter


def stimmen_liste():
    """Alle Stimmen der Region — und zugleich der billigste Test der Zugangsdaten."""
    req = urllib.request.Request(
        _host() + "/cognitiveservices/voices/list",
        headers={"Ocp-Apim-Subscription-Key": AZURE_KEY},
    )
    with urllib.request.urlopen(req, timeout=30) as antwort:
        return json.loads(antwort.read().decode("utf-8"))


def sprich(ssml, format_id):
    return _post(
        "/cognitiveservices/v1",
        ssml.encode("utf-8"),
        {
            "Ocp-Apim-Subscription-Key": AZURE_KEY,
            "Content-Type": "application/ssml+xml",
            "X-Microsoft-OutputFormat": format_id,
            "User-Agent": "rust-and-lead-tts",
        },
    )


# ── Betriebsarten ────────────────────────────────────────────────────────────

def pruefen(doc):
    """Zugangsdaten und Stimmnamen pruefen, ohne eine einzige Silbe zu rendern.

    Das ist der Schritt, der beim ersten Anlauf gefehlt hat: Wer direkt rendert
    und einen Fehler bekommt, weiss nicht, ob es am Schluessel liegt, an der
    Region, am Kontingent oder an einem Stimmnamen — und probiert dann an der
    falschen Stelle herum.
    """
    print(f"Region : {AZURE_REGION}")
    print(f"Key    : {'gesetzt (' + AZURE_KEY[:4] + '…' + str(len(AZURE_KEY)) + ' Zeichen)' if AZURE_KEY else 'FEHLT'}")
    if not AZURE_KEY:
        print("\n⚠  AZURE_SPEECH_KEY ist nicht gesetzt. Siehe Kopf dieser Datei, Schritt 2.")
        return 1
    try:
        alle = stimmen_liste()
    except urllib.error.HTTPError as e:
        print("\n✗ " + _deuten(e))
        return 1
    except urllib.error.URLError as e:
        print(f"\n✗ Keine Verbindung zu {_host()}")
        print(f"   Grund: {e.reason}")
        print("   Drei Moeglichkeiten, in dieser Reihenfolge pruefen:")
        print("    1. Regionsname falsch — es heisst 'westeurope', nicht 'West Europe' und")
        print("       nicht die volle Adresse aus dem Portal.")
        print("    2. Ein Proxy oder eine Firewall dazwischen (typisch im Firmennetz).")
        print("    3. Gar kein Netz.")
        return 1
    namen = {v["ShortName"] for v in alle}
    de = sorted(n for n in namen if n.startswith("de-DE-"))
    print(f"\n✓ Zugang steht. {len(alle)} Stimmen insgesamt, davon {len(de)} deutsche.\n")
    fehlt = []
    for rolle, v in doc["voices"].items():
        name = v.get("azure", "")
        ok = name in namen
        print(f"  {'✓' if ok else '✗'} {rolle:<20} {name}")
        if not ok:
            fehlt.append((rolle, name))
    if fehlt:
        print("\n⚠  Diese Stimmen gibt es in dieser Region nicht. Ersatz aus der Liste:")
        for n in de:
            print("     ", n)
        return 1
    zeilen = [e for e in doc["events"] if e.get("spoken")]
    zeichen = sum(len(e["text"]) for e in zeilen)
    print(f"\nAlles bereit: {len(zeilen)} Zeilen, {zeichen:,} Zeichen.")
    print(f"Beim kostenlosen Tarif (500.000/Monat) sind das {zeichen / 5000:.1f} % — "
          f"du kannst rund {500000 // max(zeichen, 1)}-mal alles neu rendern.")
    return 0


def main():
    argv = sys.argv[1:]
    dry = "--dry-run" in argv
    neu = "--neu" in argv
    endung = "mp3" if "--mp3" in argv else "wav"
    format_id, suffix = FORMATE[endung]

    def opt(name, umwandeln=str):
        if name in argv:
            i = argv.index(name)
            if i + 1 < len(argv):
                return umwandeln(argv[i + 1])
        return None

    nur_rolle = opt("--rolle")
    nur_folge = opt("--folge", int)

    if not JSON_IN.exists():
        print(f"✗ {JSON_IN} fehlt. Erst  python3 docs/build_hoerspiel_tts.py  laufen lassen.")
        return 1
    doc = json.loads(JSON_IN.read_text(encoding="utf-8"))

    if "--pruefen" in argv:
        return pruefen(doc)

    role_voice = {role: v.get("azure") for role, v in doc["voices"].items()}
    lines = [e for e in doc["events"] if e.get("spoken")]
    if nur_rolle:
        lines = [e for e in lines if e["rolle"] == nur_rolle]
    if nur_folge:
        lines = [e for e in lines if e["folge"] == nur_folge]
    if "--probe" in argv:
        lines = lines[:1]

    if not lines:
        print("Keine Zeilen ausgewaehlt. --rolle / --folge pruefen.")
        return 1

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    zeichen = sum(len(e["text"]) for e in lines)
    print(f"{len(lines)} Zeilen · {zeichen:,} Zeichen · {endung.upper()} · Ausgabe: {OUT_DIR}")
    if not dry and not AZURE_KEY:
        print("\n⚠  Kein Azure-Key gesetzt. Entweder AZURE_SPEECH_KEY setzen (siehe Kopf dieser")
        print("   Datei) oder mit  --dry-run  nur die SSML-Dateien erzeugen.")
        return 1
    if not dry and len(lines) > 8:
        dauer = len(lines) * PAUSE_SEK / 60.0
        print(f"Mit der Drosselpause dauert das rund {dauer:.0f} Minuten. Ein Abbruch ist "
              f"unschaedlich — fertige Dateien werden beim naechsten Mal uebersprungen.")

    timbre_files, gedanke_files = [], []
    fertig = uebersprungen = fehler = 0

    for e in lines:
        role = e["rolle"]
        voice = role_voice.get(role)
        if not voice:
            print(f"  · seq {e['seq']}: keine Stimme für Rolle '{role}' — übersprungen")
            continue
        delivery = e.get("delivery", "gesprochen")
        base = f"f{e['folge']}_{e['seq']:03d}_{role.replace(' ', '')}"
        if delivery == "gedanke":
            base += "_GEDANKE"
        ssml = build_ssml(voice, e["text"], role, e.get("regie", ""), delivery)

        if dry:
            (OUT_DIR / (base + ".ssml.xml")).write_text(ssml, encoding="utf-8")
            fertig += 1
            continue

        ziel = OUT_DIR / (base + suffix)
        if ziel.exists() and not neu:
            uebersprungen += 1
            continue

        try:
            ziel.write_bytes(sprich(ssml, format_id))
        except urllib.error.HTTPError as ex:
            print(f"  ✗ {base}: {_deuten(ex)}")
            fehler += 1
            # Ein falscher Schluessel wird bei Zeile 90 nicht besser als bei Zeile 1.
            if ex.code in (401, 403, 404):
                print("\nAbbruch — das betrifft jede weitere Zeile. Erst  --pruefen  laufen lassen.")
                return 1
            continue
        except urllib.error.URLError as ex:
            print(f"  ✗ {base}: keine Verbindung ({ex.reason})")
            fehler += 1
            continue

        tags = []
        if delivery == "gedanke":
            gedanke_files.append(ziel.name)
            tags.append("Gedanke: Hall/close-mic")
        elif e.get("fx"):
            timbre_files.append(ziel.name)
            tags.append("Doppel-Timbre")
        tag = ("  (Post-FX: " + ", ".join(tags) + ")") if tags else ""
        print(f"  ✓ {ziel.name}{tag}")
        fertig += 1
        time.sleep(PAUSE_SEK)

    if dry:
        print(f"Fertig (SSML): {fertig} Dateien. Kein Azure-Aufruf.")
        return 0

    print(f"\nFertig: {fertig} neu, {uebersprungen} schon da, {fehler} Fehler.")
    if timbre_files:
        print("\nDoppel-Timbre nachträglich auf diese HELD-Dateien legen "
              "(Ringmodulator/Pitch-Layer in Audacity oder ffmpeg):")
        for n in timbre_files:
            print("   ", n)
    if gedanke_files:
        print("\nGedanken-Zeilen: leichten Hall + Nahbesprechungs-EQ in Post legen, "
              "Raum-Atmo weglassen:")
        for n in gedanke_files:
            print("   ", n)
    return 1 if fehler else 0


if __name__ == "__main__":
    sys.exit(main())
