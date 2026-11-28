#!/usr/bin/env python3
"""Den Web-Export in Teile zerlegen, die eine Artefakt-Seite ausliefern darf.

Eine Artefakt-Seite nimmt hoechstens 15 MB je Binaerdatei. Godots Web-Export besteht aus
genau zwei Dateien, die darueber liegen:

    index.wasm   33,7 MB   die Engine
    index.pck    24,3 MB   das Spiel

Also werden beide in Stuecke zu 12 MB zersaegt und im Browser wieder zusammengesetzt
(siehe `spiel.html`). Zwoelf statt vierzehn, weil der Abstand zur Grenze billiger ist als
ein fehlgeschlagener Upload von 58 MB.

Die Stuecke heissen `.wasm`, auch die des Pakets, und das ist keine Schlamperei: Die Seite
liefert nur bestimmte Endungen aus, und `.wasm` ist die einzige darunter, die binaer
unveraendert durchkommt. Gelesen werden sie ohnehin als rohe Bytes.

    python3 web/zerlegen.py bauen/web ziel/
"""
import os
import sys

TEIL = 12 * 1024 * 1024
GROSS = ("index.wasm", "index.pck")


def zerlegen(quelle: str, ziel: str) -> None:
    os.makedirs(os.path.join(ziel, "teile"), exist_ok=True)

    # Die kleinen Dateien gehen unveraendert mit.
    for name in ("index.js", "index.audio.worklet.js"):
        with open(os.path.join(quelle, name), "rb") as f:
            roh = f.read()
        with open(os.path.join(ziel, name), "wb") as f:
            f.write(roh)
        print("  %-24s %10d Byte" % (name, len(roh)))

    for name in GROSS:
        with open(os.path.join(quelle, name), "rb") as f:
            roh = f.read()
        kurz = name.split(".")[1]
        teile = [roh[i:i + TEIL] for i in range(0, len(roh), TEIL)]
        for i, stueck in enumerate(teile):
            pfad = os.path.join(ziel, "teile", "%s%02d.wasm" % (kurz, i))
            with open(pfad, "wb") as f:
                f.write(stueck)
        print("  %-24s %10d Byte -> %d Teile" % (name, len(roh), len(teile)))
        print("    In spiel.html eintragen: GROESSE['%s'] = %d" % (name, len(roh)))


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("Aufruf: zerlegen.py <bauen/web> <ziel>")
    zerlegen(sys.argv[1], sys.argv[2])
