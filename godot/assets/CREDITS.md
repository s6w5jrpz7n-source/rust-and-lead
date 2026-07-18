# Asset-Credits & Lizenzen

Alle 3D-Assets in `assets/` stammen von **[Poly Haven](https://polyhaven.com)** und sind
**CC0 (Public Domain)**. CC0 erfordert keine Namensnennung — dieser Nachweis dient der
Herkunft und Nachvollziehbarkeit. Jedes Paket: glTF + `.bin` + PBR-Texturen
(diff = Albedo, nor_gl = Normal (OpenGL), arm = AO/Roughness/Metallic gepackt), 1k = 1024px.

## Umgebung / Boden & Felsen (`models/environment/`)
| Ordner | Beschreibung | Einsatz | Lizenz |
| :-- | :-- | :-- | :-- |
| `gravelly_sand_1k/` | Kiesiger Sandboden (tileable Plane) | Wüsten-/Sektor-1-Boden | CC0 · Poly Haven |
| `sand_rocks_small_01_1k/` | Kleine Sandsteine (Scatter-Detail) | Boden-Streuung | CC0 · Poly Haven |
| `namaqualand_cliff_02_1k/` | Felsklippe | Sektorgrenzen, Canyon (Rogue's Landing) | CC0 · Poly Haven |
| `namaqualand_boulder_03_1k/` | Findling/Felsbrocken | Deckung, Landschafts-Dekor | CC0 · Poly Haven |

## Deko / Props (`models/props/`)
| Ordner | Beschreibung | Passt zu | Lizenz |
| :-- | :-- | :-- | :-- |
| `ammo_box_1k/` | Munitionskiste | Loot-Kisten, Basen, Kampfzonen | CC0 · Poly Haven |
| `worn_metal_rack_1k/` | Abgenutztes Metallregal | Werkstatt, Händler, Lager | CC0 · Poly Haven |
| `chemistry_set_1k/` | Chemie-/Alchemie-Set | Alchemie-Raffinerie/Labor (§1.7.2) | CC0 · Poly Haven |
| `industrial_wall_lamp_1k/` | Industrie-Wandlampe | Gaslampen-Beleuchtung (Saloon, Rogue's Landing) | CC0 · Poly Haven |
| `tool_cart_1k/` | Werkzeugwagen | Eiserne Schmiede, Werkstatt | CC0 · Poly Haven |

## Hinweise
- Godot importiert glTF automatisch (bin + Texturen liegen daneben, relative Pfade).
- `arm`-Texturen entsprechen der glTF-ORM-Konvention (AO/Roughness/Metallic) — Godot
  ordnet sie beim Import korrekt zu.
- Bei weiterem Wachstum der Asset-Bibliothek **Git LFS** erwägen (aktuell ~53 MB direkt
  versioniert).
