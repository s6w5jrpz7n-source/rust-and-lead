#!/usr/bin/env python3
# Erzeugt aus docs/hoerspiel_tts.json eine ElevenLabs-fertige Fassung:
#   - hoerspiel_eleven.json / .csv : Rolle, Stimme (auszufüllen), Tags, Text (plain & v3-getaggt)
#   - eleven_studio.md             : zum Reinkopieren ins ElevenLabs Studio (Sprecher + Tags)
# ElevenLabs nutzt KEIN SSML: Emotion kommt über Audio-Tags im Text (Modell v3) bzw.
# über die Stimm-Regler. Bei Modell v2 die [Tags] weglassen (v2 spricht sie sonst mit!).
import json, csv, pathlib

HERE   = pathlib.Path(__file__).resolve().parent
SRC    = HERE / "hoerspiel_tts.json"
J_OUT  = HERE / "hoerspiel_eleven.json"
C_OUT  = HERE / "hoerspiel_eleven.csv"
MD_OUT = HERE / "eleven_studio.md"

# Rolle -> ElevenLabs-Stimmvorschlag (Typ). voice_id trägst DU aus deiner Voice Library ein.
# Tipp: in der Library nach deutschen Stimmen filtern; das Multilingual-/v3-Modell spricht Deutsch.
EL_VOICES = {
    "ERZÄHLER":          'ruhiger, tiefer Erzähler (z. B. „George"/„Adam"-Typ)',
    "HELD":              'junger, ausdrucksstarker Bariton (z. B. „Antoni"/„Josh"-Typ)',
    "MABEL":             'reife, warme, tiefe Frauenstimme',
    "SILAS":             'alter, rauer Mann (z. B. „Arnold"-Typ)',
    "DOC ARIS":          'präziser, mittlerer Männerton (z. B. „Daniel"-Typ)',
    "KOLBEN-JACK":       'großer, lauter Mann (kräftig, z. B. „Arnold"-Typ)',
    "GIDEON":            'fester, harter Männerton (z. B. „Clyde"/„Josh"-Typ)',
    "VANE":              'glatter, warmer, ruhiger älterer Mann (z. B. „Charlie"/„George"-Typ)',
    "PATROUILLENFÜHRER": 'kühler, sachlicher Beamtenton',
    "TESS":              'schnelle, aufgeweckte Frauenstimme (z. B. „Domi"/„Elli"-Typ)',
    "PIP":               'junge, helle Stimme (Kind-Ersatz) — nur Nebenstory',
    "SIEDLER":           'alter, müder Mann',
}

# regie/delivery/rolle -> ElevenLabs-Audio-Tags (Modell v3). Bewusst sparsam (max ~2).
def tags_for(role, regie, delivery):
    low = (regie or "").lower()
    tags = []
    def add(t):
        if t not in tags:
            tags.append(t)
    if delivery == "gedanke":
        add("[thoughtful]"); add("[whispers]")
    if any(k in low for k in ("leise", "flüstert", "flüsternd", "still", "kaum hörbar")):
        add("[whispers]")
    if any(k in low for k in ("brüllt", "laut", "schreit")):
        add("[shouting]")
    if any(k in low for k in ("angst", "zittert", "nervös", "kriecht rein")):
        add("[nervously]")
    if any(k in low for k in ("keuchend", "heiser")):
        add("[breathless]")
    if any(k in low for k in ("kalt", "hart")):
        add("[cold]")
    if any(k in low for k in ("trauer", "traurig", "weint", "brüchig", "brechen")):
        add("[sad]")
    if role == "VANE" and "[shouting]" not in tags:
        add("[softly]")
    if any(k in low for k in ("ruhig", "sehr ruhig")) and "[shouting]" not in tags:
        add("[calm]")
    # Widersprüche entschärfen und begrenzen
    if "[shouting]" in tags:
        tags = [t for t in tags if t not in ("[whispers]", "[softly]", "[calm]")]
    return tags[:2]

doc = json.loads(SRC.read_text(encoding="utf-8"))
lines = [e for e in doc["events"] if e.get("spoken")]

out_events = []
for e in lines:
    tags = tags_for(e["rolle"], e.get("regie", ""), e.get("delivery", "gesprochen"))
    tagged = (" ".join(tags) + " " + e["text"]).strip() if tags else e["text"]
    out_events.append({
        "seq": e["seq"], "folge": e["folge"], "szene": e["szene"],
        "rolle": e["rolle"], "stimmen_typ": EL_VOICES.get(e["rolle"], ""),
        "voice_id": "",                      # <- aus deiner ElevenLabs Voice Library eintragen
        "delivery": e.get("delivery", "gesprochen"),
        "tags": tags, "text": e["text"], "text_v3": tagged,
    })

J_OUT.write_text(json.dumps({
    "titel": "RUST & LEAD — ElevenLabs-Fassung (Rebellen-Kanon)",
    "hinweis": "text_v3 = mit Audio-Tags (Modell v3). Bei Modell v2 die Tags weglassen -> Feld 'text'. "
               "voice_id pro Rolle aus deiner Voice Library eintragen.",
    "voices": EL_VOICES, "events": out_events,
}, ensure_ascii=False, indent=2), encoding="utf-8")

with C_OUT.open("w", encoding="utf-8", newline="") as f:
    w = csv.writer(f)
    w.writerow(["seq", "folge", "szene", "rolle", "voice_id", "delivery", "tags", "text", "text_v3"])
    for e in out_events:
        w.writerow([e["seq"], e["folge"], e["szene"], e["rolle"], e["voice_id"],
                    e["delivery"], " ".join(e["tags"]), e["text"], e["text_v3"]])

# --- Studio-Skript zum Reinkopieren ------------------------------------------
md = []
md.append("# RUST & LEAD — ElevenLabs-Studio-Fassung\n")
md.append("> Zum Reinkopieren ins **ElevenLabs Studio**. Jede Zeile: `ROLLE: [tags] Text`.\n"
          "> Die `[Tags]` funktionieren nur mit **Modell v3** — bei v2 die eckigen Klammern entfernen "
          "(sonst werden sie mitgesprochen). Der metallische Doppel-Timbre des Helden ab Folge 2 ist ein "
          "Post-Effekt (Ringmodulator).\n")
md.append("\n## Stimmen zuweisen\n")
md.append("| Rolle | Stimm-Typ (in der Voice Library wählen) |\n| :-- | :-- |")
for r, t in EL_VOICES.items():
    md.append(f"| {r} | {t} |")
md.append("")

cur_folge, cur_szene = None, None
by_seq = {e["seq"]: e for e in out_events}
for ev in doc["events"]:
    if ev["folge"] != cur_folge:
        cur_folge = ev["folge"]; cur_szene = None
        md.append(f"\n\n# FOLGE {cur_folge}\n")
    if ev["typ"] != "line":
        continue
    if ev["szene"] != cur_szene:
        cur_szene = ev["szene"]
        md.append(f"\n### Szene {cur_szene}\n")
    e = by_seq[ev["seq"]]
    md.append(f"**{e['rolle']}:** {e['text_v3']}\n")

MD_OUT.write_text("\n".join(md) + "\n", encoding="utf-8")

from collections import Counter
tagged_n = sum(1 for e in out_events if e["tags"])
print(f"{len(out_events)} Zeilen · {tagged_n} mit Audio-Tags")
print("Tag-Häufigkeit:", dict(Counter(t for e in out_events for t in e["tags"])))
print("Dateien:", J_OUT.name, C_OUT.name, MD_OUT.name)
