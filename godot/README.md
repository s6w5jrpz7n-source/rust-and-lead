# Rust & Lead — Godot 4 Backend (Phase 2)

Reine Logik-Singletons für die Godot-Produktion. **Keine UI, keine Szenen** — nur
Zustandsverwaltung und die Quest-/Progressions-Zustandsmaschine. Basis: `docs/MASTER_GDD.md`
(§2.3 State-Schema, §3 Kampagne, §4 Fraktions-Matrix).

## Dateien
- `scripts/GameState.gd` — globaler Laufzeit-Zustand (Single Source of Truth).
- `scripts/QuestManager.gd` — Quests, Fraktions-Locking, Kapitel-Progression, Reveal.

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
