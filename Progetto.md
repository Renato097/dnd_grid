# Progetto: dnd_grid (Mapper)

App Flutter multipiattaforma (Windows, Linux, Android, Web) per creare
rapidamente griglie di gioco per D&D e giochi da tavolo simili: terreno
dipingibile, pedine con taglie D&D 5e, Aree d'Effetto disegnabili.

---

## 1. Struttura del progetto

```
dnd_grid/
├── pubspec.yaml                     # dipendenze: flutter, provider, cupertino_icons
├── README.md                        # istruzioni di avvio (flutter create + copia file)
├── Progetto.md                      # questo documento
└── lib/
    ├── main.dart                    # entry point, HomePage, pannello flottante, fullscreen
    ├── models/
    │   └── models.dart              # enum e classi dati (nessuna logica di stato)
    ├── state/
    │   └── map_state.dart           # MapState: unico ChangeNotifier con tutto lo stato
    └── widgets/
        ├── battle_grid.dart         # la griglia: gesture, rendering, CustomPainter
        ├── aoe_geometry.dart        # geometria/hit-test delle Aree d'Effetto
        ├── aoe_editor_dialog.dart   # dialog di modifica AoE (dimensione, colore, nome)
        ├── aoe_palette.dart         # selettore forma/colore AoE nel pannello
        ├── token_editor_dialog.dart # dialog di modifica pedina (nome, taglia, categoria...)
        ├── token_palette.dart       # selettore categoria/taglia pedina nel pannello
        ├── tile_palette.dart        # selettore terreno + pennello/gomma/riempi
        ├── side_panel.dart          # pannello strumenti (header fisso + contenuto scrollabile)
        └── quick_toolbar.dart       # barra rapida verticale (pennello/gomma/riempi + slider)
```

### Modelli principali (`models/models.dart`)

- `TileType` — tipi di terreno (erba, acqua, sabbia, pietra, foresta, lava, muro) con colore ed
  etichetta associati.
- `TokenCategory` — categorie di pedine (giocatore, NPC, nemico, porta, scale, pericolo, altro)
  con colore/icona/etichetta.
- `TokenSize` — taglie D&D 5e dalla Media in su (Media 1×1, Grande 2×2, Enorme 3×3,
  Mastodontica 4×4), espresse come lato in celle.
- `AoEShape` — forme di Area d'Effetto (cerchio/sfera, cono, linea, cubo/quadrato).
- `CellPos` — coordinata intera di cella, usata come chiave nella mappa dei tile dipinti.
- `TokenData` — una pedina: id, categoria, nome, descrizione, posizione (row/col, double per
  consentire trascinamento fluido), taglia in celle.
- `AoEData` — un'Area d'Effetto: id, forma, origine (row/col fractional), dimensione in celle,
  angolo (direzione per cono/linea), colore, etichetta.

### Stato (`state/map_state.dart`)

Un solo `ChangeNotifier` (`MapState`) contiene tutto: dimensioni griglia, tile dipinti, lista
pedine, lista AoE, strumento attivo, selezioni correnti. Non ci sono più "strumenti di
spostamento" dedicati (spostare vista / spostare pedina): il movimento è sempre disponibile
tramite gesture, indipendentemente dallo strumento di disegno attivo (vedi sezione 3).

Metodi chiave: `paintCell`, `fillArea` (flood fill iterativo), `resizeGrid`,
`autoFitToViewport` (auto-dimensionamento al primo avvio), `addToken`/`moveTokenBy`/
`snapTokenToGrid`/`updateTokenInfo`, `addAoE`/`moveAoEBy`/`updateAoE`.

---

## 2. Cronologia delle richieste e decisioni prese

### Versione 1 — Scaffold iniziale
Richiesta: app Flutter multipiattaforma con griglia ridimensionabile, tile dipingibili,
pedine con tag e descrizione, utilizzabile bene sia con mouse/tastiera sia touch.

Decisioni:
- `provider` per lo state management (più semplice di Riverpod/Bloc per questa scala).
- Griglia disegnata con `CustomPainter` (non `GridView`) per poter gestire migliaia di celle
  con overlay di pedine senza migliaia di widget.
- `InteractiveViewer` per pan/zoom iniziale, con modalità esplicite (Pennello/Gomma/Sposta
  pedina/Sposta vista) per evitare conflitti tra gesture di disegno e di navigazione.

### Versione 2 — Pannello flottante, fullscreen, riempimento, nomi pedine
Richiesta: pannello laterale flottante e richiudibile, modalità fullscreen, strumento
riempimento (secchiello), nomi pedine sempre visibili.

Decisioni:
- Pannello trasformato da sidebar fissa a card flottante sopra la mappa (overlay in uno
  `Stack`), con animazione di apertura/chiusura.
- Modalità fullscreen: nasconde `AppBar` e pannello; su Android/iOS nasconde anche le barre di
  sistema (`SystemChrome.setEnabledSystemUIMode`).
- Riempimento implementato come flood fill iterativo a 4 direzioni (senza ricorsione, per
  evitare stack overflow su griglie grandi).
- Etichette nome pedina come overlay sotto l'icona, attivabili globalmente o mostrate
  comunque per la pedina selezionata.

### Versione 3 — Gesture unificate, pannello trascinabile, taglie 5e, Aree d'Effetto
Richiesta: rimuovere i tasti "sposta vista"/"sposta pedina" a favore di gesture libere;
pannello trascinabile dall'intestazione; taglie pedine D&D 5e; nuovo tipo di oggetto Area
d'Effetto (cerchio, cono, linea, cubo) semi-trasparente e ridimensionabile.

Questa è stata la riscrittura più profonda. Decisioni tecniche:
- **Abbandonato `InteractiveViewer`**: non permette di far coesistere in modo pulito "un dito
  disegna/sposta" e "due dita spostano/zoomano la vista" perché i suoi riconoscitori di
  gesture competono con quelli dei widget figli nella stessa arena. Sostituito con un
  `Listener` a basso livello che riceve tutti gli eventi puntatore grezzi (down/move/up/
  cancel/signal) e li gestisce manualmente:
  - 1 dito su una pedina → sposta la pedina.
  - 1 dito su un'AoE già posizionata → sposta/seleziona l'AoE (ha sempre priorità sul
    disegno di una nuova forma).
  - 1 dito con strumento pennello/gomma/riempi/piazza-pedina/disegna-AoE attivo → azione
    corrispondente.
  - 2 dita (o pulsante centrale del mouse) → pan/zoom della vista, con calcolo del punto
    di ancoraggio (focal point) per mantenere fermo sotto le dita il punto toccato.
  - Rotellina del mouse → zoom centrato sul cursore.
- **Trasformazione manuale**: `_scale` e `_panOffset` (invece di `TransformationController`),
  con conversioni esplicite `_screenToCanvas`/`_canvasToScreen`. Tile, pedine e AoE sono
  disegnati/posizionati applicando questa trasformazione a mano, sia nel `CustomPainter`
  (`canvas.translate`/`canvas.scale`) sia nei widget `Positioned` (pedine, pulsanti di
  modifica).
- **Pannello trascinabile**: la sua posizione (`Offset`) è ora stato locale di `HomePage`,
  aggiornata tramite un callback `onDragHeader` esposto da `SidePanel` e collegato a un
  `GestureDetector` sulla sola intestazione (che resta fissa e non scrolla col contenuto).
- **Taglie pedine**: `TokenData.sizeCells` (int, lato del quadrato occupato). Bug iniziale:
  l'icona non cresceva perché il `FittedBox` usava `BoxFit.scaleDown` (che non ingrandisce
  mai) — corretto in `BoxFit.contain`.
- **Aree d'Effetto**: geometria calcolata in `aoe_geometry.dart` (classe `AoEGeometry`) che
  converte i dati "in celle" in coordinate pixel e fornisce sia il `Path` da disegnare sia
  un hit-test approssimato per selezione (distanza dal centro per il cerchio, punto-in-
  triangolo per il cono, distanza da segmento per la linea, bounding box per il cubo).
  Bug iniziale: con lo strumento "disegna AoE" attivo, toccare una forma già esistente
  veniva sempre interpretato come "inizia una nuova forma" invece che "seleziona quella
  esistente" — corretto invertendo l'ordine di controllo (l'AoE esistente ha sempre
  priorità sul disegno di una nuova, indipendentemente dallo strumento attivo).

### Versione 4 — Rifiniture: header fisso, auto-fit griglia, barra rapida, scala in metri
Richiesta: intestazione del pannello non scrollabile; griglia che di default copre lo
schermo (non più fissa 20×20); duplicare pennello/gomma/riempi/slider dimensione cella in
una barra verticale sempre visibile sotto il tasto fullscreen; misura AoE in tempo reale
durante il disegno (celle + metri, scala configurabile, default 1 casella = 1,5 m);
possibilità di eliminare le AoE dopo averle posizionate; possibilità di iniziare un'AoE da
una pedina già posizionata senza spostarla.

Decisioni:
- `SidePanel` ristrutturato in `Column` con header fisso fuori dallo `SingleChildScrollView`
  e contenuto scrollabile in `Expanded`.
- `MapState.autoFitToViewport(width, height)`: calcola righe/colonne in base al viewport
  disponibile al primo frame utile, con un flag `hasAutoSizedGrid` per non sovrascrivere una
  dimensione scelta manualmente in seguito.
- Nuovo widget `QuickToolbar`: barra verticale flottante sempre visibile (pannello aperto o
  chiuso) con Pennello/Gomma/Riempi e uno slider verticale (`RotatedBox` + `Slider`) per la
  dimensione della cella.
- `MapState.metersPerCell` (default 1.5, configurabile dal pannello): usato per convertire
  le dimensioni delle AoE da celle a metri nell'etichetta live e nel dialog di modifica.
- Etichetta di misura live: durante il trascinamento di una nuova AoE, un overlay segue il
  puntatore mostrando raggio/lunghezza/lato sia in caselle sia in metri.
- Priorità di gesture per lo strumento "disegna AoE" ridefinita così: un'AoE esistente sotto
  il dito ha sempre priorità (selezione/spostamento/eliminazione); altrimenti, se il dito
  tocca una pedina già posizionata, la nuova AoE viene ancorata al suo centro invece di
  spostare la pedina; altrimenti si disegna una AoE libera dal punto toccato.

---

## 3. Modello di interazione finale (mouse + touch, senza tasti dedicati)

| Gesto | Effetto |
|---|---|
| 1 dito/click su una pedina | Seleziona e sposta la pedina (mostra pulsante ✏️ per modificarla) |
| 1 dito/click su un'AoE già posizionata | Seleziona e sposta l'AoE (mostra pulsanti ✏️/🗑️) |
| 1 dito/click su cella vuota, strumento Pennello/Gomma | Dipinge/cancella terreno (continuo mentre si trascina) |
| 1 dito/click su cella vuota, strumento Riempi | Flood fill del terreno contiguo |
| 1 dito/click su cella vuota, strumento Piazza pedina | Crea una nuova pedina e la seleziona (trascinabile subito) |
| 1 dito/click su cella vuota, strumento Disegna AoE | Inizia una nuova AoE (raggio/lunghezza cresce trascinando) |
| 1 dito/click su una pedina, strumento Disegna AoE | Inizia una nuova AoE ancorata al centro della pedina (non la sposta) |
| 2 dita (pinch) o rotellina del mouse | Zoom, centrato sul punto medio delle dita / sul cursore |
| 2 dita in movimento o pulsante centrale del mouse | Pan della vista |

Non esistono più strumenti "Sposta vista" o "Sposta pedina": la navigazione e lo spostamento
di pedine/AoE sono sempre disponibili, qualunque sia lo strumento di disegno selezionato.

---

## 4. Problemi noti / semplificazioni consapevoli

- La geometria delle AoE (cono, linea) è un'approssimazione ragionevole delle regole 5e, non
  una riproduzione millimetrica dei manuali (es. il cono è un triangolo isoscele con
  larghezza di base pari alla lunghezza, come da regola generale del DMG).
- L'hit-test delle AoE è approssimato (tolleranze fisse) per restare semplice; non gestisce
  la rotazione del cubo.
- Nessun salvataggio/caricamento persistente delle mappe: è il prossimo passo naturale
  (vedi README, sezione "Prossimi passi suggeriti").
- I file non sono mai stati compilati in questo ambiente (nessun Flutter SDK/rete
  disponibile lato assistente): la verifica avviene tramite lettura/coerenza del codice, poi
  con `flutter pub get` / `flutter run` sul computer dell'utente.
