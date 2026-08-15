# Griglie D&D — scaffold Flutter

App multipiattaforma (Windows, Linux, Android, Web) per creare rapidamente
griglie di gioco per D&D e simili: dipingi il terreno, posiziona pedine
(giocatori, NPC, nemici, porte, scale, pericoli...) e muovile sulla mappa.

## Come avviare il progetto

Questi file contengono solo la cartella `lib/` e il `pubspec.yaml`: sul tuo
computer devi generare l'ossatura di piattaforma con Flutter (richiede
Flutter SDK installato e connessione internet per scaricare le dipendenze).

```bash
# 1. Crea un nuovo progetto Flutter vuoto
flutter create dnd_grid
cd dnd_grid

# 2. Sostituisci pubspec.yaml e la cartella lib/ con quelli forniti
#    (copia i file scaricati sovrascrivendo quelli generati)

# 3. Scarica le dipendenze
flutter pub get

# 4. Abilita le piattaforme desktop/web se non già attive
flutter config --enable-windows-desktop --enable-linux-desktop
flutter create . # rigenera le cartelle windows/, linux/, web/, android/

# 5. Avvia
flutter run -d windows   # oppure -d linux, -d chrome, -d <device-android>
```

## Come si usa l'app

- **Pennello / Gomma** (pannello laterale, sezione "Terreno"): scegli un
  tipo di terreno (erba, acqua, sabbia...) e tocca/trascina sulla griglia
  per dipingere. Con la gomma cancelli le celle.
- **Pedine**: scegli una categoria (Giocatore, NPC, Nemico, Porta, Scale,
  Pericolo, Altro) e tocca la griglia per posizionarla. Tocca una pedina
  per rinominarla, aggiungere una descrizione o cambiarne la categoria.
- **Sposta pedina**: attiva questa modalità per trascinare le pedine già
  posizionate (funziona sia con il mouse sia con il touch).
- **Sposta vista**: attiva questa modalità per scorrere/zoomare la mappa
  (pinch-to-zoom su touch, rotellina/trackpad su desktop).
- **Impostazioni griglia**: righe, colonne e dimensione delle celle sono
  regolabili in ogni momento dal pannello laterale (drawer su mobile).

## Architettura

- `models/models.dart` — enum dei tile e delle categorie di pedine, classe
  `TokenData`.
- `state/map_state.dart` — stato centrale (`ChangeNotifier`) con griglia,
  tile dipinti, pedine, strumento attivo.
- `widgets/battle_grid.dart` — la griglia vera e propria: `CustomPainter`
  per le celle colorate + `InteractiveViewer` per pan/zoom + pedine come
  widget posizionati sopra.
- `widgets/tile_palette.dart`, `token_palette.dart` — selettori di terreno
  e categoria pedina.
- `widgets/token_editor_dialog.dart` — form per nome/descrizione/categoria
  della pedina.
- `widgets/side_panel.dart` — pannello con impostazioni + entrambe le
  palette (sidebar fissa su schermi larghi, drawer su schermi stretti).

## Prossimi passi suggeriti

Questo è uno scaffold solido e funzionante ma volutamente minimale.
Estensioni naturali, se ti interessano, potrei aggiungerle in seguito:

1. **Salvataggio/caricamento mappe** su file JSON locale (via
   `file_picker`/`path_provider`) o `shared_preferences` per bozze rapide.
2. **Immagini personalizzate per le pedine** (foto o icone caricate).
3. **Righello/misuratore di distanza** in caselle (utile per gittate/movimento).
4. **Nebbia di guerra** (celle nascoste ai giocatori, mostrate dal master).
5. **Scorciatoie da tastiera** (numeri per selezionare rapidamente il tile,
   frecce per muovere la pedina selezionata) per un uso più rapido con
   mouse+tastiera.
6. **Esportazione della mappa come immagine PNG.**

Fammi sapere quali di questi vuoi che sviluppi per primi.
