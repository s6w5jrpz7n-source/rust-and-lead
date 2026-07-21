# Rust & Lead — Godot 4 Backend (Phase 2)

Reine Logik-Singletons für die Godot-Produktion. **Keine UI, keine Szenen** — nur
Zustandsverwaltung und die Quest-/Progressions-Zustandsmaschine. Basis: `docs/MASTER_GDD.md`
(§2.3 State-Schema, §3 Kampagne, §4 Fraktions-Matrix).

## Dateien
- `scripts/GameState.gd` — globaler Laufzeit-Zustand (Single Source of Truth).
- `scripts/QuestManager.gd` — Quests, Fraktions-Locking, Kapitel-Progression, Reveal.
- `scripts/CombatData.gd` — Kampf-Registries: Schadensarten, Waffen, Gegner-Statblöcke,
  `xp_for_kill()`, `weapon_acid()` (statische Klasse, `class_name`).
- `scripts/CombatTarget.gd` — veränderlicher Kampf-Zustand einer Einheit (Leben,
  Panzerung, Stun/DOT); `from_type(type, {elite, superboss, depth})` inkl.
  Tiefen-Skalierung für Multilevel-Dungeons (GDD §1.6).
- `scripts/CombatEngine.gd` — **Modul 1:** mathematische Kampf-/Mitigations-Engine:
  `calculate()` (Matrix + Flanken-Logik), `apply_status()`, `tick_dot()`, `resolve_hit()`,
  `mitigate_damage()` / `player_damage_taken_mul()` (alles `static`).
- `scripts/TycoonManager.gd` — **Modul 2:** aktive Rustwater-Wirtschaft (Node-Autoload):
  Sekunden-Tick nur bei aktiver Spielzeit, Kostenkurve, Ripple-Booster.
- `scripts/GridInventoryBackend.gd` — **Modul 3:** reines Grid-Inventar (`class_name`,
  instanziierbar): Footprint-Prüfung, Insert/Remove, Auto-Platzierung.
- `scripts/MemoryManager.gd` — **roter Faden** (GDD §7.5.12a/b/§8.3): Erinnerungs-Walzen
  (geordnete 16er-Kette, Drop-Logik 3 %/50 %) & Familien-Bogen (Providence-Cut-Memorials,
  gestufte Gräber, `bury_family`, Codex/Erfolge) — alles über `GameState` (`class_name`, `static`).
- `scripts/WorldManager.gd` — Weltgeografie, Gating & **Biom-Zonierung** (GDD §1.6/§1.7/§1.6.3):
  POI-Registry mit Koordinaten, Sektor-Logik, die drei Tore (Sprengtore, Smog-Linie, Fraktions-
  Feindseligkeit) und die aus dem Prototyp portierten **Biom-Zonen** (Palette/Flora/Gegner-Leitmix,
  ans Sektor-Gating gebunden) — alles als aus `GameState` abgeleitete Abfragen (`class_name`, `static`).

## Weltgeografie & Gating (WorldManager)
Koordinaten: Ursprung SW-Ecke, X = W→O, Y = S→N (0…2000). Alle Gate-Zustände sind aus
`GameState` abgeleitet (kein Doppel-Zustand).

```gdscript
WorldManager.sector_of_pos(Vector2(1000, 1600))   # 3
WorldManager.poi_position("eisernes_herz")        # (1000, 1950)
WorldManager.dungeon_floors("schmelzoefen_vulcan")# 4 (multilevel)

# Gate 1 — Sprengtore (Y=800): erst nach Kapitel 4 offen.
WorldManager.is_blast_gate_open()                 # current_chapter >= 5
WorldManager.can_cross_blast_line(from_y, to_y)   # blockt Nord-Querung, wenn zu

# Gate 2 — Smog-Linie (Y=1500): tödlicher DOT ohne Alchemie-Filter (Labor Stufe 3).
GameState.set_building_level("laboratory", 3)     # schaltet den Filter frei
WorldManager.has_alchemie_filter()                # true
var dmg := WorldManager.smog_dot_damage(player.global_position_2d, delta)  # 0 mit Filter

# Gate 3 — Fraktions-Feindseligkeit (nach Gildenwahl):
QuestManager.choose_guild("rebels")
WorldManager.is_base_hostile("sektor01")          # true  (fremdes HQ -> Geschützturm-Aggro)
WorldManager.is_base_friendly("fort_freedom")     # true  (eigene Gilde)

# Biom-Zonierung (§1.6.3) — geografische Zonen mit eigenem Gegner-Mix, ans Gating gebunden:
WorldManager.biome_at(Vector2(1120, 1080))        # "rostwald" (Sektor 2, Wildnis)
WorldManager.biome_at(Vector2(0, 1600))           # "smog_oedland" (Sektor 3)
WorldManager.pick_enemy_type("kupfer_hochland", true)   # bevorzugt Konstrukte (industriell)
WorldManager.is_biome_unlocked("smog_oedland")    # false ohne Alchemie-Filter (erbt Sektor-3-Gate)
```

## Modul 1 — Kampf-Backend (CombatEngine)
`CombatData`, `CombatTarget` und `CombatEngine` sind `class_name`-Klassen (statisch bzw.
per `.new()`), **kein Autoload nötig**. Wechselwirkungs-Matrix & Werte entsprechen exakt
dem verifizierten Web-Prototyp (Master-GDD §6.2/§6.3).

```gdscript
var now := Time.get_ticks_msec()
# Gegner aus dem Roster (optional Elite/Superboss/Tiefe):
var guard := CombatTarget.from_type("konstrukt")            # MECHANICAL, armor 15
var titan := CombatTarget.from_type("goliath", {"superboss": true, "depth": 2})

# Treffer eines galvanischen Volt-Karabiners auf den Automaten:
var hit := CombatEngine.resolve_hit(CombatData.GALVANIC, guard, 40, 0, now)
# hit == { damage: 100, effect: "SHORT_CIRCUIT_STUN"(40%), immune: false, killed: false }

# Front-Immunität: frontal 0 Kinetik, bis Säure die Panzerung auf 0 ätzt; Flanke umgeht sie.
CombatEngine.calculate(CombatData.KINETIC, titan, 40).damage            # 0 (frontal, armor>0)
CombatEngine.calculate(CombatData.KINETIC, titan, 40, 10, false).damage # Flanke: max(1, 40-armor)

# DOT/Stun pro Frame verarbeiten:
if not guard.is_stunned(now):
    pass  # Bewegung/Angriff erlaubt
CombatEngine.tick_dot(guard, now, get_process_delta_time())

# Eingehender Schaden am Spieler (exakte Mitigations-Formel 100/(100+armor*9)):
var taken := CombatEngine.mitigate_damage(raw_damage, player_armor)
```

## Modul 2 — Aktive Wirtschaft (TycoonManager, Autoload)
Sekunden-Tick **nur bei aktiver Spielzeit** (kein Offline-Ertrag, kein Zeitstempel):
```gdscript
TycoonManager.income_per_sec()               # Σ level*income_per (ganzzahlig)
TycoonManager.upgrade_cost("forge")          # base_cost * (level+1), evtl. -10% (Forge-Boost)
TycoonManager.try_upgrade("forge")           # prüft Gold & Max, bucht ganzzahlig ab
TycoonManager.activate_boost("saloon", 60.0) # 60 aktive Sek: +15% Schmiede-Einkommen (Ripple)
TycoonManager.sell_value(200)                # +20% mit aktivem Destille-Boost
```

## Modul 3 — Grid-Inventar (GridInventoryBackend, instanziierbar)
```gdscript
var grid := GridInventoryBackend.new(10, 8)                   # 10x8 Zellen
var f := GridInventoryBackend.footprint("armor")             # Vector2i(2,2)
grid.can_fit_item(0, 0, f.x, f.y)                            # true
grid.insert_item(101, 0, 0, f.x, f.y)                       # belegt (0,0)-(1,1) mit uid 101
grid.find_first_empty_space(3, 1)                           # erster Platz für schwere Waffe
grid.place_first(102, 3, 1)                                 # Loot-Drop automatisch platzieren
grid.remove_item(101)                                       # Zellen der uid wieder frei
```

## Godot-Projekt & Tests
Die **Projekt-Wurzel ist dieser `godot/`-Ordner** (`project.godot`), also `res:// == godot/`.
Autoloads sind dort bereits registriert (Reihenfolge zählt); die `class_name`-Klassen
(CombatEngine, CombatData, CombatTarget, WorldManager, GridInventoryBackend) brauchen
**keinen** Autoload-Eintrag.

| Reihenfolge | Name | Pfad |
| :-- | :-- | :-- |
| 1 | `GameState` | `res://scripts/GameState.gd` |
| 2 | `QuestManager` | `res://scripts/QuestManager.gd` |
| 3 | `TycoonManager` | `res://scripts/TycoonManager.gd` |

**Headless-Tests** (abhängigkeitsfrei, kein GUT-Addon) — **zwei Pässe** bei einem kalten
Checkout ohne `.godot/`-Cache: erst importieren (baut den `class_name`-Global-Cache), dann
ausführen. Ohne den ersten Pass melden die `class_name`-Klassen (`CombatEngine`, `WorldManager`
…) beim allerersten Lauf „Identifier … not declared".

```sh
godot --headless --path godot --editor --quit   # Pass 1: Import + Klassen-Cache
godot --headless --path godot                    # Pass 2: führt TestRunner aus, Exit 0/1
```
`tests/TestRunner.gd` prüft alle Module deterministisch gegen die GDD-Werte
(Schadens-Matrix & Mitigation, Status/DOT, Quest-Fluss & Reveal, Gilden-Lock,
Tycoon-Tick/Kosten/Ripple, Grid-Platzierung, Welt-Gates, **Biom-Zonierung**,
**Erinnerungs-Walzen & Familien-Bogen**) und beendet mit Exit-Code 0 (alles grün) bzw. 1.

> **Verifiziert:** Godot **4.3.stable**, headless — **133/133 Checks grün, Exit 0**
> (inkl. 22 Biom-Zonierungs- und 29 roter-Faden-Tests). Der schwere 3D-Asset-Import unter `assets/models`
> verlangsamt Pass 1; für reine Logik-Tests kann man Scripts/Tests/`project.godot` in ein
> asset-freies Verzeichnis kopieren und dort testen.

**Statische Prüfung ohne Godot-Runtime** (`gdtoolkit` von PyPI — nützlich, wenn kein
Godot-Binary verfügbar ist, z. B. in CI/Sandbox):

```sh
pip install gdtoolkit
gdparse scripts/*.gd tests/*.gd     # Syntax/Parse-Check (Exit 0 = ok)
gdlint  scripts/*.gd tests/*.gd     # Stil/Struktur (die breiten Daten-Tabellen
                                    # lösen bewusst `max-line-length` aus)
```
`gdparse` fängt Syntaxfehler vor dem Editor ab; die Laufzeit-Verifikation bleibt der
Headless-Test oben.

## Quest-Zustandsmaschine
```
available ──accept_quest()──▶ active ──complete_quest()──▶ done
```
- **Kill-Quests** (Rebellen, Eiserne Gilde, Kopfgelder): Bei Annahme wird
  `GameState.kills` als `quest_base[id]` eingefroren. Fortschritt = `kills − quest_base[id]`.
  Das Kampfsystem ruft bei jedem Tod `GameState.add_kill()` auf.
- **Collect-Quests** (Schmuggler, `q_scrap`): prüfen `GameState.inventory`; bei Abgabe
  werden die Items **atomar abgezogen** (schlägt der Abzug fehl, bricht die Abgabe ab).

### Schutz vor Doppel-Eingaben & Korruption
- `accept_quest` nur aus `available` → keine erneute `quest_base`-Neusetzung.
- `complete_quest` nur aus `active` **und** nur bei serverseitig geprüfter Erfüllung →
  keine doppelte Belohnung, kein Abschluss ohne Zielerreichung.
- `choose_guild` ist eine Einmal-Entscheidung (Kapitel-5-Gate, `chosen_guild == null`).
- `trigger_chapter_4_reveal` ist idempotent (kein Doppel-Reveal).

## Fraktions-Locking (Kapitel-5-Gate)
```gdscript
QuestManager.choose_guild("rebels")   # nur bei current_chapter == 5 && chosen_guild == null
# danach:
QuestManager.can_access_guild("rebels")   # true
QuestManager.can_access_guild("corp")     # false  -> fremde Gilden gesperrt
QuestManager.accept_quest("q_corp5")      # false  -> "guild_locked"
```

## Kapitel-4-Reveal (Zugüberfall)
```gdscript
QuestManager.trigger_chapter_4_reveal()   # reveal_playing = true, is_revealed = true
# ... Cutscene (REVEAL_LINES) spielt ...
QuestManager.finish_reveal()              # reveal_playing = false, Kapitel -> 5
```

## Minimalbeispiel
```gdscript
# Kapitel 5 erreicht, Reveal geschehen:
QuestManager.choose_guild("rebels")
QuestManager.accept_quest("q_rebels5")     # Kill-Quest: 12 Konzern-Schergen
# Kampfsystem meldet Kills:
for i in 12: GameState.add_kill()
QuestManager.check_quest_progress("q_rebels5")  # {current=12, target=12, complete=true}
QuestManager.complete_quest("q_rebels5")   # +250 Gold, +125 XP, +1 Dampfkern, Kapitel -> 8
```

## Enthaltene Quests (Master-GDD §4.2 / §4.3)
Hub: `q_bounty`, `q_scrap`, `q_rats` · Rebellen: `q_rebels5/8/12` ·
Eiserne Gilde: `q_corp5/8/12` · Schmuggler: `q_smug5/8/12`.
