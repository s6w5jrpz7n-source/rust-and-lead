# Was offen ist

> Diese Datei ist die **einzige Liste**. Was hier nicht steht, ist erledigt oder war nie
> vereinbart. Sie wird bei jeder Änderung mitgeführt — genau deshalb gibt es sie: Zugesagtes,
> das nur im Gesprächsverlauf steht, geht verloren.

Stand: nach dem Umbau der Kopfzeile, den Wirten vor ihren Häusern und dem Einbau der gemalten
Sinnbilder.

> **Eine Korrektur an mir selbst:** In der ersten Fassung dieser Liste stand, die Porträts von
> Mabel, Silas und Doc erschienen in keinem Gespräch. Das war falsch — `DialogBox.show_line()`
> lädt seit Langem `portrait_<giver>`, und sie erscheinen. Nachgesehen statt behauptet ist auch
> beim Aufschreiben die Regel.

---

## 1 · Braucht dich — ich komme hier nicht weiter

| Was | Warum ich es nicht kann | Was du tun müsstest |
| :-- | :-- | :-- |
| **7 Sprachzeilen fehlen** — Silas' zwei Grubenstahl-Sätze (der Text hat sich geändert, also auch der Dateiname) und Wandas fünf | Der Azure-Schlüssel ist dein Passwort und gehört nicht in dieses Repository | `python3 docs/azure_tts.py --spiel`, dann `godot --headless --path godot --editor --quit`. Rendert nur die fehlenden, halbe Minute |
| **Wandas Stimme ist geraten** | Ich habe `de-DE-TanjaNeural` gesetzt, ohne sie je gehört zu haben | Einmal anhören. Passt sie nicht: `STIMMEN` in `docs/build_spiel_stimmen.py`, dann `--rolle wanda --neu` |
| **`npc_wanda.glb` fehlt** — Wanda ist im Spiel eine **graue Kapsel** | Ich kann keine Modelle erzeugen | Prompt steht in `docs/PROMPTS_GEBAEUDE.md`-Machart; Maß 1,7 m |
| **Vier Waffenmodelle** (`gatling`, `voltgun`, `saeure`, `brenner`) | dito | `docs/ASSETS_OFFEN.md`, Priorität 1 |
| **Zwei Gegner** (`klaeffer` 0,8 m, `goliath` 4,0 m) und **`bolzen`** (Blechhund) | dito | `docs/PROMPTS_GEGNER.md` |
| **`chest_boss.glb`** — die Beutekammer sieht aus wie eine gewöhnliche Truhe | dito | `docs/ASSETS_OFFEN.md`, ganz unten |
| **Zwei gelieferte Modelle ohne Rolle** (`figur_ohne_namen`, `figur_mit_animationen`) | Das ist eine Design-Entscheidung, keine technische | Sag, was sie sein sollen — beide sind 1,8 m und animiert |

---

## 2 · Von mir, noch nicht gemacht

| Was | Wo es klemmt |
| :-- | :-- |
| **Fünf Sinnbilder liegen weiter ungenutzt**: `icon_hp`, `icon_xp`, `icon_ammo`, `icon_map`, `icon_backpack`. Gold, Uhr, Auftrag und Trank benutzen ihres jetzt | Bei Leben und Erfahrung habe ich es bewusst gelassen — du wolltest **weniger** in der Kopfzeile, und die Balken sagen es schon. Karte und Rucksack haben ihren Knopf bereits (Minikarte und Porträt) |
| **Statusmarken** (⚡ Kurzschluss, ☣ Ätzung, ‼ Panzerung durch, ☢ Strahlung) sind Schriftzeichen | ein Bild liest sich schneller als ein Zeichen; Dateien dafür gibt es noch nicht |
| **Praxis und Waffenlager sind Hütten mit Schild**, keine eigenen Modelle | passt fürs Erste, siehe oben unter „braucht dich" |

---

## 3 · Auf Eis, auf deinen Wunsch

* **Hörspiel** — „Das Hörspiel machen wir erst mal nicht weiter. Einfach nur Vertonung des
  Spiels." Die Werkzeuge (`build_hoerspiel_*.py`) bleiben liegen, sie kosten nichts.
* **Hörbuch-PDF** — fertig, liegt als `docs/RUST_AND_LEAD_Hoerbuch.pdf`.

---

## 4 · Erledigt, damit klar ist, was nicht mehr offen ist

Stollen (Schießen, Ausgang, Animationen, Grubenlampen) · Fähigkeitspunkte beim Aufstieg, auch
rückwirkend für alte Spielstände · Mabels Auftrag nur noch einmal am Tag · Gegner erwachen und
schießen nur noch so weit, wie man sieht · weniger Gegner, langsamerer Nachschub · ✕ in Rucksack
und Läden · Wandas Waffenlager samt Menü · Stufenanforderung je Fundstück · Tag/Nacht doppelt so
lang, zwei Drittel hell · Kopfzeile aufgeräumt, Lebensbalken dünn · Wirte vor ihren Häusern,
Praxis und Waffenlager gebaut · APK-Anleitung (`docs/ANDROID_EXPORT.md`)
