#!/usr/bin/env python3
# ============================================================================
#  RUST & LEAD — Sprechzeilen DES SPIELS einsammeln
# ----------------------------------------------------------------------------
#  Schreibt docs/spiel_stimmen.json: jede Zeile, die im Spiel auf der
#  Sprechtafel steht, mit Sprecher, Herkunft und einer festen Kennung.
#
#      python3 docs/build_spiel_stimmen.py
#
#  Danach rendert  python3 docs/azure_tts.py --spiel  daraus die Tondateien.
#
#  ── WARUM DIE ZEILEN NICHT IN EINER TABELLE STEHEN ─────────────────────────
#
#  Weil sie dort falsch stuenden. Eine Sprechzeile gehoert an die Stelle, an
#  der die Szene sie braucht — der zweite Satz der Erstbegegnung steht neben
#  der Kamerafahrt, in die er faellt, und nicht in einer CSV in einem anderen
#  Ordner. Wer beides trennt, pflegt danach zwei Wahrheiten und merkt beim
#  Vertonen, dass die eine seit Wochen von der anderen abweicht.
#
#  Also andersherum: Der Quelltext IST die Wahrheit, und dieses Werkzeug liest
#  sie aus. Eine geaenderte Zeile braucht keine Pflege an zweiter Stelle — sie
#  bekommt beim naechsten Lauf eine neue Kennung und damit eine neue Aufnahme.
#
#  ── DIE KENNUNG ────────────────────────────────────────────────────────────
#
#  Sie ist der SHA-256 des Zeilentextes, auf zwoelf Stellen gekuerzt. Das ist
#  die eine Entscheidung, an der hier alles haengt, und sie hat drei Gruende:
#
#   * Sie steht nicht im Quelltext. Kein Durchnummerieren, kein Pflegen von
#     Kennungen, keine Zeile, die beim Verschieben ihre Nummer verliert.
#   * Godot kann sie SELBST ausrechnen: `text.sha256_text().substr(0, 12)`.
#     Das Spiel braucht also keine Zuordnungstabelle zur Laufzeit — es hat den
#     Text ohnehin in der Hand und findet die Datei daraus.
#   * Und sie ist an den Text GEBUNDEN. Wer eine Zeile umschreibt, bekommt
#     eine neue Kennung, und die alte Aufnahme wird nicht mehr gefunden: Die
#     Figur schweigt und der Text steht da. Das ist genau richtig herum — die
#     Alternative waere, dass sie den alten Satz spricht, waehrend der neue
#     auf der Tafel steht, und das faellt niemandem auf.
# ============================================================================

import json
import pathlib
import hashlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
WURZEL = HERE.parent
SCRIPTS = WURZEL / "godot" / "scripts"
OUT = HERE / "spiel_stimmen.json"

# Rolle -> Azure-Stimme. Vier davon kommen aus dem Hoerspiel-Mapping und
# bleiben dieselben, damit eine Figur in beiden Fassungen gleich klingt.
STIMMEN = {
    "held":    {"azure": "de-DE-FlorianMultilingualNeural",
                "name": "Der Namenlose",
                "hint": "Bariton, heiser, nie theatralisch"},
    "mabel":   {"azure": "de-DE-KatjaNeural",
                "name": "Mamma „Rusty“ Mabel",
                "hint": "Frau ~50, rau, warm, Whiskey-tief"},
    "silas":   {"azure": "de-DE-BerndNeural",
                "name": "Silas „Kupferauge“ Finch",
                "hint": "alter Schmied, bedächtig"},
    "gideon":  {"azure": "de-DE-KillianNeural",
                "name": "Gideon Cross",
                "hint": "hart, direkt, keine Höflichkeit"},
    "doc":     {"azure": "de-DE-ChristophNeural",
                "name": "Doc Aris",
                "hint": "hager, präzise, nervös wenn er lügt"},
    "quentin": {"azure": "de-DE-ConradNeural",
                "name": "Quentin",
                "hint": "gemessen, trocken"},
    "slick":   {"azure": "de-DE-KasperNeural",
                "name": "Slick",
                "hint": "glatt, zu freundlich"},
}

# Regie je Herkunft — dieselben Schluesselwoerter, die azure_tts.py kennt.
# Eine Zeile aus dem Erwachen wird anders gesprochen als eine aus dem Saloon,
# und das steht nirgends im Text.
REGIE_JE_QUELLE = {
    "_wach_zeilen": "müde, heiser, leise",
    "_erst_starten": "leise, angespannt",
    "_erst_abdruecken": "ruhig, trocken",
}


def kennung(text: str) -> str:
    """Die Kennung einer Zeile. Muss Zeichen fuer Zeichen dasselbe liefern wie
    `Stimme.kennung()` in GDScript — sonst sucht das Spiel Dateien, die es
    nicht gibt, und niemand sieht warum."""
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:12]


def _strings_aus(block: str) -> list:
    """Alle GDScript-Stringliterale eines Blocks, in der Reihenfolge.

    Nur solche mit einem typografischen Anfuehrungszeichen — das ist die
    Konvention des Projekts fuer GESPROCHENEN Text und trennt ihn zuverlaessig
    von Schluesselnamen, Pfaden und Meldungen daneben.
    """
    return [m.group(1) for m in re.finditer(r'"(„[^"]*)"', block)]


def _block_nach(src: str, start: int) -> str:
    """Von `start` bis zur schliessenden Klammer der Liste."""
    tiefe = 0
    for i in range(start, len(src)):
        if src[i] == "[":
            tiefe += 1
        elif src[i] == "]":
            tiefe -= 1
            if tiefe == 0:
                return src[start:i + 1]
    return ""


def aus_overworld(zeilen: list) -> None:
    src = (SCRIPTS / "OverworldView.gd").read_text(encoding="utf-8")

    # 1. Das Erwachen. Steht als eigene Funktion da, weil der Test seine Dauer
    #    braucht — also auch hier als eigener Fall.
    i = src.find("static func _wach_zeilen")
    if i >= 0:
        block = _block_nach(src, src.index("[", i))
        for t in _strings_aus(block):
            zeilen.append(("held", t, "_wach_zeilen"))

    # 2. Alle uebrigen `_play_speech(HELD_NAME, "held", [ ... ])`.
    for m in re.finditer(r'_play_speech\(HELD_NAME, "held", \[', src):
        block = _block_nach(src, m.end() - 1)
        # Aus welcher Funktion? Nur fuer die Regie und fuers Lesen des JSON.
        vorher = src[:m.start()]
        f = re.findall(r"\nfunc (\w+)\(", vorher)
        quelle = f[-1] if f else "?"
        for t in _strings_aus(block):
            zeilen.append(("held", t, quelle))


def aus_dialogdata(zeilen: list) -> None:
    src = (SCRIPTS / "DialogData.gd").read_text(encoding="utf-8")
    # Sprecher stehen auf einer Einrueckung, Anlaesse auf zweien.
    sprecher = None
    anlass = None
    for zeile in src.split("\n"):
        m = re.match(r'^\t"([a-z_]+)": \{', zeile)
        if m:
            sprecher = m.group(1)
            anlass = None
            continue
        m = re.match(r'^\t\t"([a-z_]+)": \[', zeile)
        if m:
            anlass = m.group(1)
        for t in _strings_aus(zeile):
            if sprecher:
                zeilen.append((sprecher, t, f"DialogData.{sprecher}.{anlass or '?'}"))


def main() -> int:
    zeilen = []
    aus_overworld(zeilen)
    aus_dialogdata(zeilen)

    # Doppelte zusammenlegen: Derselbe Satz an zwei Stellen ist EINE Aufnahme.
    # (Und er MUSS eine sein — die Kennung kommt aus dem Text, es gibt gar
    # keine zweite Datei dafuer.)
    gesehen = {}
    raus = []
    for rolle, text, quelle in zeilen:
        k = kennung(text)
        if k in gesehen:
            gesehen[k]["quellen"].append(quelle)
            continue
        eintrag = {
            "id": k,
            "rolle": rolle,
            "text": text,
            "quellen": [quelle],
            "regie": REGIE_JE_QUELLE.get(quelle, ""),
        }
        gesehen[k] = eintrag
        raus.append(eintrag)

    ohne_stimme = sorted({e["rolle"] for e in raus} - set(STIMMEN))
    if ohne_stimme:
        print("⚠  Diese Sprecher haben keine Stimme in STIMMEN:", ", ".join(ohne_stimme))

    doc = {
        "titel": "Rust & Lead — Sprechzeilen des Spiels",
        "hinweis": "Erzeugt von docs/build_spiel_stimmen.py. Nicht von Hand aendern — "
                   "die Wahrheit steht im Quelltext.",
        "voices": STIMMEN,
        "lines": raus,
    }
    OUT.write_text(json.dumps(doc, ensure_ascii=False, indent=1), encoding="utf-8")

    zeichen = sum(len(e["text"]) for e in raus)
    print(f"{len(raus)} Zeilen · {zeichen:,} Zeichen · {OUT}")
    je_rolle = {}
    for e in raus:
        je_rolle.setdefault(e["rolle"], [0, 0])
        je_rolle[e["rolle"]][0] += 1
        je_rolle[e["rolle"]][1] += len(e["text"])
    for rolle in sorted(je_rolle, key=lambda r: -je_rolle[r][1]):
        n, z = je_rolle[rolle]
        print(f"   {rolle:<9} {n:>4} Zeilen  {z:>6,} Zeichen")
    return 0


if __name__ == "__main__":
    sys.exit(main())
