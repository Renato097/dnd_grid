# DND GRID

Griglia di gioco digitale per **D&D 5e** e giochi da tavolo simili, scritta in
Flutter. Pensata per essere veloce da usare al tavolo (fisico o virtuale):
dipingi il terreno, piazza pedine con le taglie ufficiali 5e e disegna Aree
d'Effetto (cerchio, cono, linea, cubo) con misura in tempo reale, tutto con
gesture naturali sia da mouse/tastiera sia da touch.

![platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20Android%20%7C%20Web-blue)
![flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)

---

## Funzionalità

- **Terreno dipingibile** — pennello, gomma e riempimento (flood fill) su una
  griglia di celle, con diversi tipi di tile (erba, acqua, sabbia, ...).
- **Pedine** — categorie (giocatore, NPC, nemico, porta, scale, pericolo,
  altro), nome e descrizione personalizzabili, taglie ufficiali D&D 5e da
  Media (1×1) a Mastodontica (4×4).
- **Aree d'Effetto** — cerchio/sfera, cono, linea e cubo/quadrato,
  semi-trasparenti, con etichetta di misura live (caselle **e** metri) mentre
  le disegni, colori a tema per tipo di danno.
- **Vista** — pan e zoom fluidi con gesture a due dita o rotellina del mouse,
  dimensione cella regolabile, scala configurabile (default 1 casella = 1,5 m
  come da regole 5e).
- **Interfaccia pensata per il touch** — pannello strumenti flottante e
  trascinabile, richiudibile, barra rapida sempre visibile con le azioni più
  usate, modalità schermo intero.
- **Multipiattaforma** — stesso codice per Windows, Linux, Android e Web.

## Piattaforme supportate

| Piattaforma | Stato |
|---|---|
| Windows | ✅ |
| Linux | ✅ |
| Android | ✅ |
| Web | ✅ |
| macOS / iOS | non ancora testate |

## Come si usa

Non ci sono strumenti dedicati "sposta vista" o "sposta pedina": la
navigazione e lo spostamento di pedine/AoE sono sempre disponibili,
qualunque sia lo strumento di disegno attivo.

| Gesto | Effetto |
|---|---|
| Tocco/click su una pedina | Seleziona e sposta la pedina |
| Tocco/click su un'AoE già posizionata | Seleziona e sposta l'AoE |
| Tocco/click su cella vuota — Pennello/Gomma | Dipinge/cancella terreno (continuo trascinando) |
| Tocco/click su cella vuota — Riempi | Flood fill del terreno contiguo |
| Tocco/click su cella vuota — Piazza pedina | Crea una nuova pedina e la seleziona |
| Tocco/click su cella vuota — Disegna AoE | Inizia una nuova AoE (dimensione cresce trascinando) |
| Tocco/click su una pedina — Disegna AoE | Ancora la nuova AoE al centro della pedina |
| Due dita (pinch) o rotellina | Zoom |
| Due dita in movimento o pulsante centrale mouse | Pan della vista |

Pedina e AoE selezionate si modificano/eliminano dalla barra rapida verticale
sulla destra dello schermo (icone ✏️ / 🗑️), pensata per essere facilmente
raggiungibile anche col dito.

## Progetto e dettagli Tecnici

Requisiti: [Flutter SDK](https://docs.flutter.dev/get-started/install)
(canale stable) con supporto abilitato per le piattaforme desktop/web che ti
interessano.

```bash
git clone https://github.com/Renato097/dnd_grid.git
cd dnd_grid
flutter pub get
```

Esecuzione in sviluppo:

```bash
flutter run -d windows   # oppure: linux, chrome, <id-dispositivo-android>
```

Build di rilascio:

```bash
flutter build windows
flutter build linux
flutter build apk            # o: flutter build appbundle
flutter build web
```

## Struttura del progetto

```
lib/
├── main.dart                    # entry point, pannello flottante, fullscreen
├── models/
│   └── models.dart               # enum e classi dati (nessuna logica di stato)
├── state/
│   └── map_state.dart            # MapState: unico ChangeNotifier con tutto lo stato
└── widgets/
    ├── battle_grid.dart          # griglia: gesture, rendering, CustomPainter
    ├── aoe_geometry.dart         # geometria/hit-test delle Aree d'Effetto
    ├── aoe_editor_dialog.dart    # dialog di modifica AoE
    ├── aoe_palette.dart          # selettore forma/colore AoE
    ├── token_editor_dialog.dart  # dialog di modifica pedina
    ├── token_palette.dart        # selettore categoria/taglia pedina
    ├── tile_palette.dart         # selettore terreno + pennello/gomma/riempi
    ├── side_panel.dart           # pannello strumenti principale
    └── quick_toolbar.dart        # barra rapida verticale sempre visibile
```

Architettura in breve: un singolo `ChangeNotifier` (`MapState`, via
`provider`) contiene tutto lo stato — griglia, tile dipinti, pedine, AoE,
strumento attivo e selezioni correnti. La griglia è disegnata con
`CustomPainter` invece che con widget per cella, per reggere griglie grandi
senza migliaia di oggetti nell'albero dei widget. Pan/zoom e disegno
coesistono grazie a un gestore di gesture a basso livello basato su
`Listener` (niente `InteractiveViewer`, che genera conflitti tra i
riconoscitori di gesture quando disegno e navigazione devono convivere).

## Dipendenze

Il progetto è volutamente minimale:

- [`provider`](https://pub.dev/packages/provider) — state management
- [`cupertino_icons`](https://pub.dev/packages/cupertino_icons)