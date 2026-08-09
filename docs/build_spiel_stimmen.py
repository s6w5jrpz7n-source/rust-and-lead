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
    # Ausgesucht nach Gehoer aus `--faecher`, nicht nach Beschreibung. Christoph
    # kann keine Sprechstile — das kostet weniger, als es klingt: Von den 40
    # Zeilen des Helden haetten nur rund zwoelf einen bekommen, weil "trocken",
    # "ruhig" und "langsam" in Azure gar keine Entsprechung haben. Die STIMME
    # hoert man auf allen vierzig.
    "held":    {"azure": "de-DE-ChristophNeural",
                "name": "Der Namenlose",
                "hint": "trocken, nie theatralisch"},
    "mabel":   {"azure": "de-DE-KatjaNeural",
                "name": "Mamma „Rusty“ Mabel",
                "hint": "Frau ~50, rau, warm, Whiskey-tief"},
    "silas":   {"azure": "de-DE-BerndNeural",
                "name": "Silas „Kupferauge“ Finch",
                "hint": "alter Schmied, bedächtig"},
    "gideon":  {"azure": "de-DE-KillianNeural",
                "name": "Gideon Cross",
                "hint": "hart, direkt, keine Höflichkeit"},
    # Christoph ist an den Helden gegangen; der Doc bekommt Ralf.
    "doc":     {"azure": "de-DE-RalfNeural",
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
    """Alle Sprechzeilen eines Blocks, je als `(text, regie)`.

    Nur Literale mit typografischem Anfuehrungszeichen — das ist die Konvention
    des Projekts fuer GESPROCHENEN Text und trennt ihn zuverlaessig von
    Schluesselnamen, Pfaden und Meldungen daneben.

    ## Die Regie steht als Kommentar hinter der Zeile

        "„Und es hat mich noch nicht gesehen.“",   # fluestert

    Das ist der einzige Platz, an dem sie richtig steht, und zwar aus einem
    zwingenden Grund: Sie darf NICHT in den Text. Die Kennung wird ueber den
    Text gerechnet — eine Regieanweisung darin wuerde die Kennung aendern, also
    jede bereits gerenderte Datei unauffindbar machen, und obendrein
    mitgesprochen werden.

    Ein Kommentar dahinter aendert am Text nichts, steht aber im Blick dessen,
    der die Zeile schreibt. Eine Tabelle in einer anderen Datei waere nach dem
    zweiten Umschreiben nicht mehr synchron, und niemand haette es gemerkt: Ein
    Satz, der mit der falschen Haltung gesprochen wird, klingt nicht kaputt.
    Er klingt bloss nach nichts.

    `# stumm` heisst: nicht rendern. Gebraucht fuer Zeilen, die gar keine Rede
    sind — die Pause nach "Wie heisse ich eigentlich" etwa. Ein Sprachdienst
    macht daraus eine halbe Sekunde Nichts, und die Tafel stuende dann kuerzer
    als die Stille, die gemeint war.
    """
    raus = []
    for zeile in block.split("\n"):
        texte = re.findall(r'"(„[^"]*)"', zeile)
        if not texte:
            continue
        # Der Kommentar gilt fuer die Zeile. Gesucht wird er hinter dem LETZTEN
        # Anfuehrungszeichen — ein `#` im Text selbst ist damit keins.
        regie = ""
        schluss = zeile.rfind('"')
        if schluss >= 0 and "#" in zeile[schluss:]:
            regie = zeile[schluss:].split("#", 1)[1].strip()
        for t in texte:
            raus.append((t, regie))
    return raus


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
        for t, regie in _strings_aus(block):
            zeilen.append(("held", t, "_wach_zeilen", regie))

    # 2. Alle uebrigen `_play_speech(HELD_NAME, "held", [ ... ])`.
    for m in re.finditer(r'_play_speech\(HELD_NAME, "held", \[', src):
        block = _block_nach(src, m.end() - 1)
        # Aus welcher Funktion? Nur fuer die Regie und fuers Lesen des JSON.
        vorher = src[:m.start()]
        f = re.findall(r"\nfunc (\w+)\(", vorher)
        quelle = f[-1] if f else "?"
        for t, regie in _strings_aus(block):
            zeilen.append(("held", t, quelle, regie))


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
        for t, regie in _strings_aus(zeile):
            if sprecher:
                zeilen.append((sprecher, t, f"DialogData.{sprecher}.{anlass or '?'}", regie))


def main() -> int:
    zeilen = []
    aus_overworld(zeilen)
    aus_dialogdata(zeilen)

    # Doppelte zusammenlegen: Derselbe Satz an zwei Stellen ist EINE Aufnahme.
    # (Und er MUSS eine sein — die Kennung kommt aus dem Text, es gibt gar
    # keine zweite Datei dafuer.)
    gesehen = {}
    raus = []
    stumm = 0
    format_zeilen = 0
    for rolle, text, quelle, regie in zeilen:
        # `# stumm` heisst: gar nicht rendern (siehe `_strings_aus`).
        # Formatzeichenketten koennen nicht vorab gesprochen werden: Was in
        # `„%s“` steht, entsteht erst zur Laufzeit (eine geborgene Erinnerung
        # etwa). Vorab gerendert waere das eine Aufnahme des Wortes
        # "Prozent s" — und gefunden wuerde sie ohnehin nie, weil das Spiel die
        # Kennung ueber den EINGESETZTEN Text rechnet.
        if re.search(r"%[sdfx]", text):
            format_zeilen += 1
            continue
        # `startswith` und nicht `==`: Eine Anweisung darf sich begruenden
        # duerfen ("stumm — die Pause IST die Zeile"), sonst schreibt sie
        # niemand hin. Der genaue Vergleich hat den ersten Fall stillschweigend
        # durchgelassen, und aufgefallen ist es nur an einer Zahl, die sich
        # nicht bewegt hat.
        if regie.strip().lower().startswith("stumm"):
            stumm += 1
            continue
        k = kennung(text)
        if k in gesehen:
            gesehen[k]["quellen"].append(quelle)
            # Die genauere Regie gewinnt: Steht derselbe Satz einmal mit und
            # einmal ohne Anweisung da, ist die MIT gemeint.
            if regie and not gesehen[k]["regie"]:
                gesehen[k]["regie"] = regie
            continue
        eintrag = {
            "id": k,
            "rolle": rolle,
            "text": text,
            "quellen": [quelle],
            # Die Zeile schlaegt die Szene: Ein Kommentar hinter der Zeile ist
            # eine Aussage ueber SIE, der Vorgabewert nur ueber ihre Umgebung.
            "regie": regie or REGIE_JE_QUELLE.get(quelle, ""),
        }
        gesehen[k] = eintrag
        raus.append(eintrag)

    # Regie, die keine Regel trifft, wirkt NICHT — und das sieht man ihr nicht
    # an. Wer `# verzweifelt` hinschreibt, bekommt dieselbe Ausgabe wie ohne
    # jede Anweisung und haelt die Vertonung fuer flach, statt das Wort zu
    # suchen. Also beim Bauen nachsehen, solange es noch billig ist.
    try:
        import azure_tts
        bekannt = set()
        for keys, _ in azure_tts.REGIE_RULES:
            bekannt |= set(keys)
        unbekannt = set()
        for e in raus:
            for wort in e["regie"].replace(",", " ").split():
                if wort and wort not in bekannt:
                    unbekannt.add(wort)
        if unbekannt:
            print("⚠  Regie ohne Wirkung (kein Eintrag in REGIE_RULES): "
                  + ", ".join(sorted(unbekannt)))
    except ImportError:
        pass

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
    mit_regie = sum(1 for e in raus if e["regie"])
    print(f"{len(raus)} Zeilen · {zeichen:,} Zeichen · {OUT}")
    print(f"   davon mit Regie: {mit_regie} · ohne: {len(raus) - mit_regie}"
          + (f" · stumm: {stumm}" if stumm else "")
          + (f" · Formatzeichenketten: {format_zeilen}" if format_zeilen else ""))
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
