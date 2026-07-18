# Assets — Rust & Lead (Godot 4)

3D-Assets für die Godot-Produktion. Zielformat: **glTF/GLB** (Godots natives 3D-Format;
FBX/OBJ werden importiert, glTF ist bevorzugt). PBR-Materialien (§1 Master-GDD).

## Ordnerstruktur (Vorschlag)
```
assets/
├── models/
│   ├── characters/    # Spieler-Chassis, NPCs
│   ├── enemies/       # Grenzgänger, Fauna, Konzern-Konstrukte, Goliath, Bosse
│   ├── environment/   # Boden-/Level-Module, Gebäude, Raffinerie, Wände
│   └── props/         # Palisaden, Kisten, Wracks, Dekor
├── textures/          # PBR-Maps (Albedo/Normal/Roughness/Metallic), falls extern
└── materials/         # wiederverwendbare .tres-Materialien
```

## Import-Hinweise
- Godot importiert glTF automatisch; große Modelle ggf. auf einheitlichen Maßstab bringen
  (1 Godot-Unit = 1 Meter, passend zur 2000×2000-m-Welt).
- Kollision/NavMesh werden pro Modell im Import-Dock oder per Szene ergänzt (nicht im Mesh).
- Herkunft/Lizenz jeder Datei in `CREDITS.md` vermerken (auch bei CC0 gute Praxis).

## Lizenz
Assets hier sind **CC0** (Public Domain), sofern in `CREDITS.md` nicht anders vermerkt.
