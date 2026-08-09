#!/usr/bin/env python3
# ============================================================================
#  RUST & LEAD — das Hoerbuch als Vorlage-PDF
# ----------------------------------------------------------------------------
#      python3 docs/build_hoerbuch_pdf.py
#      -> docs/RUST_AND_LEAD_Hoerbuch.pdf
#
#  Setzt docs/HOERBUCH.md so, wie man es VORLIEST — nicht so, wie man es
#  ueberfliegt. Das ist ein Unterschied mit Folgen, und jede einzelne Zahl hier
#  kommt daher:
#
#   * **Ein schmaler Satzspiegel.** Rund 62 Zeichen je Zeile. Wer laut liest,
#     springt am Zeilenende mit den Augen zurueck; je laenger die Zeile, desto
#     oefter landet man in der falschen. Eine A4-Seite mit vollem Satzspiegel
#     hat 95 Zeichen und ist zum Vorlesen unbrauchbar.
#
#   * **Viel Durchschuss.** Zeilenabstand 1,62. Aus demselben Grund.
#
#   * **Keine Silbentrennung, kein Blocksatz.** Blocksatz reisst Loecher in die
#     Zeile, und Loecher liest man als Pausen. Flattersatz sieht schlechter aus
#     und liest sich besser.
#
#   * **Absaetze mit Abstand statt Einzug.** Ein Einzug ist eine typografische
#     Feinheit fuer stilles Lesen. Beim Vorlesen zaehlt, dass man die Stelle
#     wiederfindet, an der man abgesetzt hat.
#
#   * **Jedes Kapitel faengt oben an.** Eine neue Aufnahme beginnt an einem
#     Kapitel, nicht in der Mitte einer Seite.
#
#   * **Kursives bleibt kursiv.** Es ist im Hoerbuch keine Betonung, sondern
#     eine Regieanweisung: innerer Monolog, leiser und naeher am Mikrofon.
#     Wer das beim Setzen verliert, verliert die Anweisung.
# ============================================================================

import pathlib
import re
import sys

from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (BaseDocTemplate, Frame, NextPageTemplate,
                                PageBreak, PageTemplate, Paragraph, Spacer)

HERE = pathlib.Path(__file__).resolve().parent
QUELLE = HERE / "HOERBUCH.md"
ZIEL = HERE / "RUST_AND_LEAD_Hoerbuch.pdf"

# Liberation Serif: metrisch wie Times, aber mit vollstaendigen deutschen
# Anfuehrungszeichen und Gedankenstrichen. Die eingebauten Schriften von
# ReportLab koennen „ und “ nicht und setzen schwarze Kaesten dafuer.
SCHRIFTEN = {
    "Buch": "/usr/share/fonts/truetype/liberation/LiberationSerif-Regular.ttf",
    "Buch-Fett": "/usr/share/fonts/truetype/liberation/LiberationSerif-Bold.ttf",
    "Buch-Kursiv": "/usr/share/fonts/truetype/liberation/LiberationSerif-Italic.ttf",
    "Buch-Halb": "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
}

# Nachgemessen mit `pdfmetrics.stringWidth` an einem echten Satz aus dem Text,
# nicht ueberschlagen: 13,5 pt auf 132 mm Satzbreite ergeben 66 Zeichen je
# Zeile. Der erste Entwurf behauptete im Kopf dieser Datei 62 und lieferte 83 —
# eine A4-Seite verfuehrt dazu, sie auch auszunutzen.
RAND_INNEN = 39 * mm
RAND_AUSSEN = 39 * mm
RAND_OBEN = 28 * mm
RAND_UNTEN = 26 * mm
TEXT_PT = 13.5


def schriften_laden() -> None:
    for name, pfad in SCHRIFTEN.items():
        if not pathlib.Path(pfad).exists():
            print(f"✗ Schrift fehlt: {pfad}")
            sys.exit(1)
        pdfmetrics.registerFont(TTFont(name, pfad))
    pdfmetrics.registerFontFamily(
        "Buch", normal="Buch", bold="Buch-Fett", italic="Buch-Kursiv",
        boldItalic="Buch-Fett")


def stile() -> dict:
    return {
        "titel": ParagraphStyle(
            "titel", fontName="Buch-Fett", fontSize=30, leading=36,
            spaceAfter=6, alignment=1),
        "untertitel": ParagraphStyle(
            "untertitel", fontName="Buch-Kursiv", fontSize=13, leading=19,
            spaceAfter=4, alignment=1),
        "vorspann": ParagraphStyle(
            "vorspann", fontName="Buch", fontSize=10.5, leading=16,
            spaceAfter=9, alignment=0),
        "teil": ParagraphStyle(
            "teil", fontName="Buch-Fett", fontSize=20, leading=26,
            spaceBefore=0, spaceAfter=8, alignment=1),
        "kapitel": ParagraphStyle(
            "kapitel", fontName="Buch-Fett", fontSize=15, leading=21,
            spaceBefore=0, spaceAfter=13),
        # Der eigentliche Lesetext. 12,5/20,2 sind rund 1,62 Durchschuss.
        "text": ParagraphStyle(
            "text", fontName="Buch", fontSize=TEXT_PT, leading=TEXT_PT * 1.62,
            spaceAfter=10.5, alignment=0),
        "mitte": ParagraphStyle(
            "mitte", fontName="Buch-Kursiv", fontSize=12, leading=19,
            spaceBefore=14, spaceAfter=14, alignment=1),
        "marke": ParagraphStyle(
            "marke", fontName="Buch-Halb", fontSize=8.5, leading=12,
            alignment=1),
    }


def anfuehrung_richten(text: str) -> str:
    """Gerade Schlusszeichen in typografische verwandeln: „… " wird „… “.

    Das Manuskript oeffnet durchgehend mit „ und schliesst mit einem geraden
    Zoll-Zeichen — 91-mal, kein einziges Mal richtig. Im Editor sieht man das
    kaum; auf einer gesetzten Seite steht neben einem gezeichneten Anfuehrungs-
    zeichen ein Strich, und das faellt sofort auf.

    Gerichtet wird beim SETZEN und nicht in der Quelle: Der Text ist das
    Manuskript des Autors, und ein Werkzeug, das darin stillschweigend Zeichen
    tauscht, ist eine schlechte Angewohnheit. Wer es dauerhaft will, laesst
    dieselbe Regel einmal ueber die Datei laufen.
    """
    raus = []
    offen = False
    for z in text:
        if z == "„":
            offen = True
            raus.append(z)
        elif z == '"' and offen:
            offen = False
            raus.append("\u201c")
        else:
            raus.append(z)
    return "".join(raus)


def inline(text: str, umbruch_bei_strich: bool = False) -> str:
    """Markdown-Auszeichnung in ReportLabs Satzmarkierung.

    Der Umbruch wird ZULETZT eingesetzt. Andersherum — erst `—` durch `<br/>`
    ersetzen, dann maskieren — maskiert die Maskierung den Umbruch mit, und auf
    der Titelseite steht dann woertlich "<br/>". Genau so war es.
    """
    text = anfuehrung_richten(text)
    text = text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    text = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", text)
    text = re.sub(r"\*(.+?)\*", r"<i>\1</i>", text)
    if umbruch_bei_strich:
        text = text.replace(" — ", "<br/>")
    return text


def lesen():
    """Das Markdown in eine Folge von `(art, text)` zerlegen."""
    zeilen = QUELLE.read_text(encoding="utf-8").split("\n")
    stuecke = []
    vorspann = []
    absatz = []

    def absatz_schliessen():
        if absatz:
            stuecke.append(("text", " ".join(absatz).strip()))
            absatz.clear()

    for zeile in zeilen:
        roh = zeile.rstrip()
        if roh.startswith("> "):
            vorspann.append(roh[2:].strip())
            continue
        if roh.strip() in ("", ">"):
            absatz_schliessen()
            continue
        if roh.startswith("---"):
            absatz_schliessen()
            continue
        if roh.startswith("## "):
            absatz_schliessen()
            stuecke.append(("kapitel", roh[3:].strip()))
            continue
        if roh.startswith("# "):
            absatz_schliessen()
            titel = roh[2:].strip()
            stuecke.append(("titel" if not stuecke else "teil", titel))
            continue
        absatz.append(roh.strip())
    absatz_schliessen()
    return stuecke, [v for v in vorspann if v]


class Buch(BaseDocTemplate):
    """Seitenzahl unten, laufender Kolumnentitel oben.

    Der Kolumnentitel nennt das KAPITEL und nicht den Buchtitel: Wer eine
    Aufnahme unterbricht und spaeter zurueckkommt, sucht nach dem Kapitel.
    Dass das Buch „Rust & Lead" heisst, weiss er.
    """

    def __init__(self, pfad, **kw):
        super().__init__(pfad, pagesize=A4,
                         leftMargin=RAND_INNEN, rightMargin=RAND_AUSSEN,
                         topMargin=RAND_OBEN, bottomMargin=RAND_UNTEN, **kw)
        rahmen = Frame(self.leftMargin, self.bottomMargin,
                       self.width, self.height, id="text",
                       leftPadding=0, rightPadding=0,
                       topPadding=0, bottomPadding=0)
        self.addPageTemplates([
            PageTemplate(id="titel", frames=[rahmen]),
            PageTemplate(id="buch", frames=[rahmen], onPage=self._beschriften),
        ])
        self.kapitel = ""

    def _beschriften(self, leinwand, doc):
        leinwand.saveState()
        leinwand.setFont("Buch-Halb", 8)
        leinwand.setFillGray(0.45)
        if self.kapitel:
            leinwand.drawString(self.leftMargin, A4[1] - RAND_OBEN + 9,
                                self.kapitel)
        leinwand.drawRightString(A4[0] - RAND_AUSSEN, A4[1] - RAND_OBEN + 9,
                                 "RUST & LEAD — Hörbuch")
        leinwand.setFont("Buch", 9.5)
        leinwand.setFillGray(0.3)
        leinwand.drawCentredString(A4[0] / 2.0, RAND_UNTEN - 13,
                                   str(doc.page))
        leinwand.restoreState()

    def afterFlowable(self, flowable):
        # Der Kolumnentitel folgt dem zuletzt gesetzten Kapitel.
        if getattr(flowable, "_kapitel", None):
            self.kapitel = flowable._kapitel


def main() -> int:
    if not QUELLE.exists():
        print(f"✗ {QUELLE} fehlt.")
        return 1
    schriften_laden()
    s = stile()
    stuecke, vorspann = lesen()

    doc = Buch(str(ZIEL), title="Rust & Lead — Das Hörbuch",
               author="Rust & Lead", subject="Hörbuch-Lesefassung")
    fluss = []

    # ── Titelseite ──────────────────────────────────────────────────────────
    buchtitel = stuecke[0][1] if stuecke and stuecke[0][0] == "titel" else "Rust & Lead"
    fluss.append(Spacer(1, 52 * mm))
    fluss.append(Paragraph(inline(buchtitel, True), s["titel"]))
    fluss.append(Spacer(1, 10 * mm))
    fluss.append(Paragraph("Lesefassung für eine Stimme", s["untertitel"]))
    fluss.append(Spacer(1, 26 * mm))
    for v in vorspann:
        fluss.append(Paragraph(inline(v), s["vorspann"]))
    # Ab hier die Buchseiten mit Kolumnentitel und Seitenzahl. Ohne dieses
    # Umschalten bleibt die Titelvorlage fuer das ganze Buch stehen — 27 Seiten
    # ohne eine einzige Seitenzahl, und auf dem Bildschirm faellt das nicht auf,
    # weil man dort nicht blaettert.
    fluss.append(NextPageTemplate("buch"))
    fluss.append(PageBreak())

    kapitel_nr = 0
    erster = True
    for art, text in stuecke:
        if art == "titel":
            continue
        if art == "teil":
            fluss.append(PageBreak() if not erster else Spacer(1, 0))
            fluss.append(Spacer(1, 62 * mm))
            fluss.append(Paragraph(inline(text, True), s["teil"]))
            fluss.append(PageBreak())
            erster = False
            continue
        if art == "kapitel":
            kapitel_nr += 1
            # Der Kolumnentitel wird beim SEITENANFANG gezeichnet, die
            # Ueberschrift erst danach gesetzt — auf der Seite, die Kapitel 16
            # eroeffnet, stand deshalb "15 · Der Mann aus Wachs" darueber.
            #
            # Also die Marke VOR den Seitenumbruch legen: Ein Zwischenstueck
            # ohne Hoehe, das `afterFlowable` noch auf der alten Seite ausloest.
            # Wenn die neue Seite anfaengt, kennt sie ihr Kapitel bereits.
            marke = Spacer(1, 0.01)
            marke._kapitel = re.sub(r"\s+", " ", text)
            fluss.append(marke)
            # Jedes Kapitel oben auf einer neuen Seite: Eine Aufnahme faengt an
            # einem Kapitel an, nicht in der Mitte einer Seite.
            if kapitel_nr > 1:
                fluss.append(PageBreak())
            fluss.append(Paragraph(inline(text), s["kapitel"]))
            erster = False
            continue
        # Ein alleinstehender kursiver Einschub („— Ende des ersten Teils —")
        # ist eine Zaesur und keine Erzaehlung.
        if text.startswith("*") and text.endswith("*") and len(text) < 60:
            fluss.append(Paragraph(inline(text), s["mitte"]))
            continue
        fluss.append(Paragraph(inline(text), s["text"]))

    doc.build(fluss)
    print(f"✓ {ZIEL}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
