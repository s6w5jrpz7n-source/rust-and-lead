# Das Spiel im Browser

Der Web-Export laeuft, und er laeuft auch als Artefakt-Seite. Das ist nicht
selbstverstaendlich, denn eine solche Seite nimmt hoechstens **15 MB je Binaerdatei** — und
Godots Web-Export besteht aus genau zwei Dateien, die darueber liegen:

| Datei | Groesse | |
| :-- | --: | :-- |
| `index.wasm` | 33,7 MB | die Engine |
| `index.pck` | 24,3 MB | das Spiel |

Beide werden deshalb in Stuecke zu 12 MB zersaegt und **im Browser wieder zusammengesetzt**.

## So geht es

```bash
godot --headless --path godot --export-release "Web" bauen/web/index.html
python3 web/zerlegen.py bauen/web bauen/artefakt
cp web/spiel.html bauen/artefakt/
```

Danach `bauen/artefakt/` veroeffentlichen: `spiel.html` als Seite, der Rest als Beidateien.

## Die drei Stellen, an denen es klemmt

**1. `fetch` wird abgefangen.** Godots Lader holt `index.wasm` und `index.pck` per `fetch`.
Beide liegen nicht als Datei vor, sie stehen fertig im Speicher. `spiel.html` ersetzt deshalb
`window.fetch` und bedient genau diese zwei Namen aus dem Speicher.

**2. Der Inhaltstyp muss stimmen.** `WebAssembly.instantiateStreaming` nimmt nur
`application/wasm` an und wirft sonst — auch wenn die Bytes vollkommen richtig sind. Die
gefaelschte Antwort traegt den Typ deshalb ausdruecklich.

**3. Die Teile heissen `.wasm`, auch die des Pakets.** Die Seite liefert nur bestimmte
Endungen aus; `.bin` gehoert nicht dazu, `.wasm` schon, und es ist die einzige binaersichere
darunter. Gelesen werden sie ohnehin als rohe Bytes.

## Ohne Threads

Exportiert wird mit `variant/thread_support=false`. Die Thread-Fassung braucht
`SharedArrayBuffer` und damit die Kopfzeilen `Cross-Origin-Opener-Policy` und
`Cross-Origin-Embedder-Policy` — die kann eine Artefakt-Seite nicht setzen. Fuer ein
2D-Abenteuer kostet das nichts.

## Bedienung

Klicken heisst benutzen, **Halten (0,45 s)** heisst ansehen — dieselbe Geste, die am Telefon
den Rechtsklick ersetzt, und sie war schon im Spiel, bevor es den Web-Export gab.
