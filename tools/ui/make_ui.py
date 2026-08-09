#!/usr/bin/env python3
"""Erzeugt die fehlenden HUD-Grafiken: Symbole und 9-Patch-Rahmen.

Warum als SKRIPT und nicht als abgelegte Bilder: Ein Symbolsatz, der von Hand gemalt ist,
laesst sich nicht nachjustieren. Hier steht die Form als Rechnung — wer die Strichstaerke
aendert, aendert sie fuer alle zehn Symbole auf einmal, und sie bleiben eine Familie.

Die Symbole sind WEISS auf transparent. Die Farbe setzt das Spiel: Dasselbe Symbol wird gelb
bei Knappheit und rot bei leer, und dafuer darf es keine eigene Farbe mitbringen.

Aufruf: python3 tools/ui/make_ui.py
"""
import math
import pathlib
from PIL import Image, ImageDraw

AUS = pathlib.Path(__file__).resolve().parents[2] / "godot" / "assets" / "ui"
# Vierfach gerechnet und dann verkleinert: PIL kennt kein Antialiasing beim Zeichnen, also
# zeichnen wir gross und lassen das Verkleinern die Kanten glaetten.
UEBER = 4
S = 64
W = (255, 255, 255, 255)


def leinwand(px=S):
    im = Image.new("RGBA", (px * UEBER, px * UEBER), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def fertig(im, name, px=S):
    im = im.resize((px, px), Image.LANCZOS)
    im.save(AUS / (name + ".png"))
    return name


def _p(pts, px=S):
    """Punkte in Einheiten 0..1 auf die vergroesserte Leinwand."""
    return [(x * px * UEBER, y * px * UEBER) for x, y in pts]


def _strich(px=S):
    return max(1, int(px * UEBER * 0.075))


# ── Die Symbole ───────────────────────────────────────────────────────────────

def icon_hp():
    im, d = leinwand()
    # Ein Herz aus zwei Kreisen und einem Dreieck — schlicht, aber auf 24 px noch erkennbar.
    r = 0.21
    d.ellipse(_p([(0.5 - r * 2, 0.22), (0.5, 0.22 + r * 2)]), fill=W)
    d.ellipse(_p([(0.5, 0.22), (0.5 + r * 2, 0.22 + r * 2)]), fill=W)
    d.polygon(_p([(0.5 - r * 2, 0.46), (0.5 + r * 2, 0.46), (0.5, 0.86)]), fill=W)
    return fertig(im, "icon_hp")


def icon_xp():
    im, d = leinwand()
    # Ein Stern mit fuenf Zacken.
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        r = 0.42 if i % 2 == 0 else 0.17
        pts.append((0.5 + math.cos(a) * r, 0.5 + math.sin(a) * r))
    d.polygon(_p(pts), fill=W)
    return fertig(im, "icon_xp")


def icon_gold():
    im, d = leinwand()
    st = _strich()
    # Eine gepraegte Muenze: voller Ring, innen ein zweiter, dazu vier Kerben am Rand.
    #
    # Der erste Anlauf hatte einen Riegel quer darueber — und las sich prompt als MINUSZEICHEN
    # oder Verbotsschild. Ein Symbol, das man mit „nicht erlaubt" verwechselt, ist an einer
    # Goldanzeige das Gegenteil von hilfreich.
    d.ellipse(_p([(0.08, 0.08), (0.92, 0.92)]), fill=W)
    loch = _p([(0.08 + 0.16, 0.08 + 0.16), (0.92 - 0.16, 0.92 - 0.16)])
    d.ellipse(loch, fill=(0, 0, 0, 0))
    d.ellipse(_p([(0.36, 0.36), (0.64, 0.64)]), fill=W)
    for i in range(4):
        a = math.pi / 4 + i * math.pi / 2
        d.line(_p([(0.5 + math.cos(a) * 0.30, 0.5 + math.sin(a) * 0.30),
                   (0.5 + math.cos(a) * 0.46, 0.5 + math.sin(a) * 0.46)]), fill=W, width=st)
    return fertig(im, "icon_gold")


def icon_ammo():
    im, d = leinwand()
    st = _strich()
    # Eine Patrone braucht drei Teile, damit sie eine ist: Geschoss, Schulter, Huelse mit RAND.
    #
    # Der erste Anlauf hatte nur Spitze und Rechteck und sah aus wie ein Obelisk. Der Rand am
    # Boden ist das Stueck, an dem man eine Patrone erkennt — ohne ihn ist es ein Turm.
    d.polygon(_p([(0.34, 0.36), (0.66, 0.36), (0.50, 0.06)]), fill=W)     # Geschoss
    d.polygon(_p([(0.34, 0.36), (0.66, 0.36), (0.70, 0.46), (0.30, 0.46)]), fill=W)  # Schulter
    d.rectangle(_p([(0.30, 0.46), (0.70, 0.84)]), fill=W)                 # Huelse
    d.rectangle(_p([(0.24, 0.84), (0.76, 0.94)]), fill=W)                 # Rand
    d.line(_p([(0.30, 0.62), (0.70, 0.62)]), fill=(0, 0, 0, 0), width=st) # Rille
    return fertig(im, "icon_ammo")


def icon_potion():
    im, d = leinwand()
    st = _strich()
    # Derselbe Flakon wie am Trankknopf — Hals, Bauch, Korken.
    umriss = [(0.36, 0.14), (0.64, 0.14), (0.64, 0.36), (0.86, 0.58),
              (0.78, 0.86), (0.22, 0.86), (0.14, 0.58), (0.36, 0.36)]
    d.polygon(_p(umriss), outline=W, width=st)
    d.rectangle(_p([(0.30, 0.06), (0.70, 0.17)]), fill=W)
    # Fuellstand als volle Flaeche unten.
    d.polygon(_p([(0.16, 0.60), (0.84, 0.60), (0.78, 0.86), (0.22, 0.86)]), fill=W)
    return fertig(im, "icon_potion")


def icon_time_day():
    im, d = leinwand()
    st = _strich()
    d.ellipse(_p([(0.28, 0.28), (0.72, 0.72)]), fill=W)
    # Strahlen als KEILE vom Rand nach aussen, nicht als Striche.
    #
    # Der erste Anlauf rechnete Anfang und Ende beide aus demselben Radius mal Faktoren — die
    # Striche fingen dadurch teils INNERHALB der Scheibe an und ragten kaum heraus. Im Bild
    # sah die Sonne aus, als haette sie gepunktete Fluesen.
    for i in range(8):
        a = i * math.pi / 4
        quer = a + math.pi / 2
        b = 0.045
        d.polygon(_p([
            (0.5 + math.cos(a) * 0.40 + math.cos(quer) * b,
             0.5 + math.sin(a) * 0.40 + math.sin(quer) * b),
            (0.5 + math.cos(a) * 0.40 - math.cos(quer) * b,
             0.5 + math.sin(a) * 0.40 - math.sin(quer) * b),
            (0.5 + math.cos(a) * 0.48, 0.5 + math.sin(a) * 0.48)]), fill=W)
    return fertig(im, "icon_time_day")


def icon_time_night():
    im, d = leinwand()
    # Sichel: ein Kreis, aus dem ein zweiter herausgeschnitten wird.
    d.ellipse(_p([(0.12, 0.12), (0.88, 0.88)]), fill=W)
    loch = Image.new("RGBA", im.size, (0, 0, 0, 0))
    dl = ImageDraw.Draw(loch)
    dl.ellipse(_p([(0.34, 0.02), (1.10, 0.78)]), fill=(0, 0, 0, 255))
    im = Image.alpha_composite(im, Image.new("RGBA", im.size, (0, 0, 0, 0)))
    px = im.load()
    lp = loch.load()
    for y in range(im.size[1]):
        for x in range(im.size[0]):
            if lp[x, y][3] > 0:
                px[x, y] = (0, 0, 0, 0)
    return fertig(im, "icon_time_night")


def icon_quest():
    im, d = leinwand()
    # Vierstrahliger Stern — im Spiel steht ✦ fuer den Auftrag.
    pts = []
    for i in range(8):
        a = -math.pi / 2 + i * math.pi / 4
        r = 0.46 if i % 2 == 0 else 0.13
        pts.append((0.5 + math.cos(a) * r, 0.5 + math.sin(a) * r))
    d.polygon(_p(pts), fill=W)
    return fertig(im, "icon_quest")


def icon_map():
    im, d = leinwand()
    st = _strich()
    # Gefaltete Karte: drei Bahnen, abwechselnd oben und unten geknickt.
    d.polygon(_p([(0.08, 0.24), (0.36, 0.14), (0.64, 0.28), (0.92, 0.16),
                  (0.92, 0.78), (0.64, 0.90), (0.36, 0.76), (0.08, 0.88)]),
              outline=W, width=st)
    d.line(_p([(0.36, 0.14), (0.36, 0.76)]), fill=W, width=st)
    d.line(_p([(0.64, 0.28), (0.64, 0.90)]), fill=W, width=st)
    return fertig(im, "icon_map")


def icon_backpack():
    im, d = leinwand()
    st = _strich()
    d.rounded_rectangle(_p([(0.16, 0.30), (0.84, 0.92)]),
                        radius=int(S * UEBER * 0.12), outline=W, width=st)
    # Der Deckel und der Traggriff — ohne die ist es eine Kiste.
    d.line(_p([(0.16, 0.52), (0.84, 0.52)]), fill=W, width=st)
    d.arc(_p([(0.32, 0.06), (0.68, 0.44)]), 180, 360, fill=W, width=st)
    return fertig(im, "icon_backpack")


# ── Die Rahmen (9-Patch) ──────────────────────────────────────────────────────

def rahmen(name, px, rand, kern=(0.16, 0.14, 0.13, 0.88), linie=(0.62, 0.52, 0.34)):
    """Ein Rahmen mit gleichmaessigem Rand — Voraussetzung fuers Strecken.

    Der Rand MUSS ringsum gleich breit sein, sonst wandert die Ecke beim Strecken. Deshalb
    wird er hier gerechnet und nicht gemalt.
    """
    gr = px * UEBER
    im = Image.new("RGBA", (gr, gr), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    r_px = rand * UEBER
    fl = tuple(int(c * 255) for c in kern[:3]) + (int(kern[3] * 255),)
    li = tuple(int(c * 255) for c in linie) + (255,)
    d.rounded_rectangle([(0, 0), (gr - 1, gr - 1)], radius=int(r_px * 0.55), fill=fl,
                        outline=li, width=max(2, int(r_px * 0.22)))
    # Eine zweite, schwaechere Linie innen: Das gibt dem Rand Tiefe, ohne dass jemand eine
    # Textur malen muss.
    innen = tuple(int(c * 0.55 * 255) for c in linie) + (200,)
    d.rounded_rectangle([(r_px * 0.55, r_px * 0.55), (gr - 1 - r_px * 0.55, gr - 1 - r_px * 0.55)],
                        radius=int(r_px * 0.35), outline=innen, width=max(1, int(r_px * 0.12)))
    im = im.resize((px, px), Image.LANCZOS)
    im.save(AUS / (name + ".png"))
    return name


SELTENHEIT = {
    "frame_slot": (0.55, 0.52, 0.48),
    "frame_slot_rare": (0.36, 0.62, 1.00),
    "frame_slot_epic": (0.74, 0.44, 0.96),
    "frame_slot_legendary": (1.00, 0.78, 0.26),
}


def main():
    gemacht = []
    for f in [icon_hp, icon_xp, icon_gold, icon_ammo, icon_potion, icon_time_day,
              icon_time_night, icon_quest, icon_map, icon_backpack]:
        gemacht.append(f())
    gemacht.append(rahmen("frame_panel", 96, 24))
    gemacht.append(rahmen("bar_frame", 64, 16))
    for name, farbe in SELTENHEIT.items():
        gemacht.append(rahmen(name, 48, 12, kern=(0.10, 0.09, 0.08, 0.80), linie=farbe))
    print("erzeugt: " + ", ".join(gemacht))


if __name__ == "__main__":
    main()
