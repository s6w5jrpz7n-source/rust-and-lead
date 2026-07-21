#!/usr/bin/env python3
# Parst docs/HOERSPIEL.md in eine TTS-fertige Zeilenliste (JSON + CSV).
# Jede Zeile: gesprochener Text getrennt von Regie; Sound-Cues als eigene Events.
import re, json, csv, pathlib

SRC = pathlib.Path("/workspace/rust-and-lead/docs/HOERSPIEL.md")
OUT_JSON = pathlib.Path("/workspace/rust-and-lead/docs/hoerspiel_tts.json")
OUT_CSV = pathlib.Path("/workspace/rust-and-lead/docs/hoerspiel_tts.csv")

# Rolle -> Voice-Hinweis (Platzhalter-IDs auf konkrete TTS-Stimmen mappen).
VOICES = {
    "ERZÄHLER":          {"voice_id": "V_ERZAEHLER", "hint": "de-DE, ruhig, trocken, lakonisch (Leone-Erzähler)"},
    "HELD":              {"voice_id": "V_HELD",      "hint": "de-DE, Bariton; Folge 1 menschlich/heiser, ab Folge 2 zusätzlich metallischer Ring-Mod-Unterton (Doppel-Timbre)"},
    "MABEL":             {"voice_id": "V_MABEL",     "hint": "de-DE, Frau ~50, rau, warm, Whiskey-tief"},
    "SILAS":             {"voice_id": "V_SILAS",     "hint": "de-DE, alter Mann, bedächtig, leises mechanisches Surren (Kupferlinse)"},
    "DOC ARIS":          {"voice_id": "V_DOC",       "hint": "de-DE, hager, präzise, nervös wenn er lügt"},
    "KOLBEN-JACK":       {"voice_id": "V_JACK",      "hint": "de-DE, Riese, laut, Galgenhumor, gegen Sturm"},
    "GIDEON":            {"voice_id": "V_GIDEON",    "hint": "de-DE, hart, direkt, keine Höflichkeit"},
    "VANE":              {"voice_id": "V_VANE",      "hint": "de-DE, warm wie Maschinenöl, Predigergeduld, NIE laut, leichter Messing-Hall"},
    "PATROUILLENFÜHRER": {"voice_id": "V_PATROUILLE","hint": "de-DE, beamtenkalt, liest von Lochkarten ab"},
    "TESS":              {"voice_id": "V_TESS",      "hint": "de-DE, Frau, schnell, aufgeweckt — wird nur einmal langsam"},
    "PIP":               {"voice_id": "V_PIP",       "hint": "de-DE, Kind ~9, hell, furchtlos, Zahnlücke"},
    "SIEDLER":           {"voice_id": "V_SIEDLER",   "hint": "de-DE, alter Siedler, müde, spuckt in den Sand"},
}

CUE_PAT = re.compile(r"^\[(ATMO|MUSIK|GERÄUSCH|BLENDE|HARTER SCHNITT)(?::\s*(.*?))?\]\s*$")
LINE_PAT = re.compile(r"^\*\*([^*(:]+?)(?:\s*\(([^)]*)\))?:\*\*\s*(.*)$")
FOLGE_PAT = re.compile(r"^#\s+FOLGE\s+(\d+)")
SZENE_PAT = re.compile(r"^##\s+SZENE\s+([0-9.]+[a-z]?)\s+—\s+(.*)$")

def clean_spoken(t):
    # Inline-Regie *(...)* entfernen (auch mit eingebettetem GERÄUSCH:)
    t = re.sub(r"\*\([^)]*\)\*", "", t)
    # eingebettete [..]-Cues entfernen
    t = re.sub(r"\[[^\]]*\]", "", t)
    # Betonungs-Marker weg, Text bleibt
    t = t.replace("**", "").replace("*", "")
    # Mehrfach-Leerzeichen glätten
    t = re.sub(r"\s+", " ", t).strip()
    # doppelte Auslassungspunkte (durch entfernte Inline-Regie) zu einem zusammenfassen
    t = re.sub(r"(?:…\s*){2,}", "… ", t)
    t = re.sub(r"\s{2,}", " ", t)
    # Leerzeichen vor Satzzeichen entfernen
    t = re.sub(r"\s+([,.;:!?])", r"\1", t)
    return t.strip()

events = []
folge = 0
szene = ""
szene_titel = ""
seq = 0
in_script = False

for raw in SRC.read_text(encoding="utf-8").splitlines():
    line = raw.rstrip()
    mf = FOLGE_PAT.match(line)
    if mf:
        in_script = True
        folge = int(mf.group(1)); szene = ""; szene_titel = ""
        continue
    if line.startswith("## Anhang") or line.startswith("## Regie-Notiz"):
        in_script = False
        continue
    if not in_script:
        continue
    ms = SZENE_PAT.match(line)
    if ms:
        szene = ms.group(1); szene_titel = ms.group(2).strip()
        continue
    if line.startswith(">") or line.startswith("---") or not line.strip():
        continue
    mc = CUE_PAT.match(line)
    if mc:
        kind = mc.group(1); body = (mc.group(2) or "").strip()
        typ = {"ATMO": "atmo", "MUSIK": "music", "GERÄUSCH": "sfx",
               "BLENDE": "transition", "HARTER SCHNITT": "transition"}[kind]
        seq += 1
        events.append({"seq": seq, "folge": folge, "szene": szene, "typ": typ,
                       "rolle": "", "voice_id": "", "regie": body if body else kind,
                       "text": "", "spoken": False})
        continue
    ml = LINE_PAT.match(line)
    if ml:
        rolle = ml.group(1).strip()
        regie = (ml.group(2) or "").strip()
        text = clean_spoken(ml.group(3))
        if not text:
            continue
        v = VOICES.get(rolle, {"voice_id": "V_" + re.sub(r"[^A-Z]", "", rolle.upper())[:8] or "V_X", "hint": ""})
        fx = ""
        if rolle == "HELD":
            if folge >= 2 or szene == "1.8":
                fx = "doppel-timbre (Ring-Mod-Unterton)"
        seq += 1
        events.append({"seq": seq, "folge": folge, "szene": szene, "typ": "line",
                       "rolle": rolle, "voice_id": v["voice_id"], "regie": regie,
                       "text": text, "spoken": True, "fx": fx})

# JSON mit Meta + Voice-Map
doc = {
    "titel": "RUST & LEAD — Hörspiel (Rebellen-Kanon)",
    "hinweis": "TTS-fertige Zeilenliste, generiert aus docs/HOERSPIEL.md. Filtere spoken==true für reine Sprachausgabe; typ in {atmo,music,sfx,transition} sind nicht gesprochene Timeline-Events für den Mix.",
    "voices": VOICES,
    "events": events,
}
OUT_JSON.write_text(json.dumps(doc, ensure_ascii=False, indent=2), encoding="utf-8")

# CSV (flach)
with OUT_CSV.open("w", encoding="utf-8", newline="") as f:
    w = csv.writer(f)
    w.writerow(["seq", "folge", "szene", "typ", "rolle", "voice_id", "regie", "text"])
    for e in events:
        w.writerow([e["seq"], e["folge"], e["szene"], e["typ"], e["rolle"],
                    e["voice_id"], e["regie"], e["text"]])

lines = [e for e in events if e["spoken"]]
print(f"Events gesamt: {len(events)} | gesprochene Zeilen: {len(lines)}")
from collections import Counter
print("Zeilen je Rolle:", dict(Counter(e["rolle"] for e in lines)))
print("Events je Typ:", dict(Counter(e["typ"] for e in events)))
