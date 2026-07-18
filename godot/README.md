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
- `scripts/DamageEngine.gd` — reiner Schadens-Kalkulator: `calculate()`, `apply_status()`,
  `tick_dot()`, `resolve_hit()`, `player_damage_taken_mul()` (alles `static`).
- `scripts/WorldManager.gd` — Weltgeografie & Gating (GDD §1.6/§1.7): POI-Registry mit
  Koordinaten, Sektor-Logik und die drei Tore (Sprengtore, Smog-Linie, Fraktions-
  Feindseligkeit) als aus `GameState` abgeleitete Abfragen (`class_name`, `static`).

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
```

## Kampf-Backend (Nutzung)
`CombatData`, `CombatTarget` und `DamageEngine` sind `class_name`-Klassen (statisch bzw.
per `.new()`), **kein Autoload nötig**. Wechselwirkungs-Matrix & Werte entsprechen exakt
dem verifizierten Web-Prototyp (Master-GDD §6.2/§6.3).

```gdscript
var now := Time.get_ticks_msec()
# Gegner aus dem Roster (optional Elite/Superboss/Tiefe):
var guard := CombatTarget.from_type("konstrukt")            # MECHANICAL, armor 15
var titan := CombatTarget.from_type("goliath", {"superboss": true, "depth": 2})

# Treffer eines galvanischen Volt-Karabiners auf den Automaten:
var hit := DamageEngine.resolve_hit(CombatData.GALVANIC, guard, 40, 0, now)
# hit == { damage: 100, effect: "SHORT_CIRCUIT_STUN"(40%), immune: false, killed: false }

# DOT/Stun pro Frame verarbeiten:
if not guard.is_stunned(now):
    pass  # Bewegung/Angriff erlaubt
DamageEngine.tick_dot(guard, now, get_process_delta_time())

# Eingehender Schaden am Spieler (Rüstung mindert):
var taken := int(round(raw_damage * DamageEngine.player_damage_taken_mul(player_armor)))
```

## Autoload-Registrierung (Reihenfolge beachten!)
Project Settings ▸ Autoload — **`GameState` zuerst**, dann `QuestManager` (letzterer
liest bei jedem Aufruf `GameState`):

| Reihenfolge | Name | Pfad |
| :-- | :-- | :-- |
| 1 | `GameState` | `res://godot/scripts/GameState.gd` |
| 2 | `QuestManager` | `res://godot/scripts/QuestManager.gd` |

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
