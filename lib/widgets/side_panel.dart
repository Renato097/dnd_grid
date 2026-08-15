import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/map_state.dart';
import 'aoe_palette.dart';
import 'tile_palette.dart';
import 'token_palette.dart';

class SidePanel extends StatelessWidget {
  /// Se fornito, mostra un'intestazione con pulsante di chiusura (usato
  /// quando il pannello è mostrato come card flottante sopra la mappa).
  final VoidCallback? onClose;

  /// Se fornito, l'intestazione diventa trascinabile e questo callback
  /// riceve il delta di trascinamento per spostare il pannello.
  final ValueChanged<Offset>? onDragHeader;

  const SidePanel({super.key, this.onClose, this.onDragHeader});

  @override
  Widget build(BuildContext context) {
    final map = context.watch<MapState>();

    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onClose != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate:
                  onDragHeader == null ? null : (details) => onDragHeader!(details.delta),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                child: Row(
                  children: [
                    const Icon(Icons.drag_indicator, size: 18, color: Colors.white54),
                    const SizedBox(width: 6),
                    const Icon(Icons.dashboard_customize, size: 18),
                    const SizedBox(width: 8),
                    const Text('Strumenti',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Chiudi pannello',
                      onPressed: onClose,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
          if (onClose != null) const Divider(height: 1, color: Colors.white24),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Impostazioni griglia',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  _GridSizeControls(map: map),
                  const SizedBox(height: 10),
                  Text('Dimensione cella: ${map.cellSize.round()} px'),
                  Slider(
                    min: 12,
                    max: 160,
                    value: map.cellSize,
                    onChanged: (v) => map.setCellSize(v),
                  ),
                  Text('Scala: 1 casella = ${map.metersPerCell.toStringAsFixed(1)} m'),
                  Slider(
                    min: 0.5,
                    max: 5,
                    divisions: 45,
                    value: map.metersPerCell,
                    onChanged: (v) => map.setMetersPerCell(v),
                  ),
                  const Divider(height: 32, color: Colors.white24),
                  const TilePalette(),
                  const Divider(height: 32, color: Colors.white24),
                  const TokenPalette(),
                  const Divider(height: 32, color: Colors.white24),
                  const AoePalette(),
                  const Divider(height: 32, color: Colors.white24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.layers_clear),
                        label: const Text('Pulisci terreno'),
                        onPressed: map.clearTiles,
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Pulisci tutto'),
                        onPressed: map.clearAll,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridSizeControls extends StatefulWidget {
  final MapState map;
  const _GridSizeControls({required this.map});

  @override
  State<_GridSizeControls> createState() => _GridSizeControlsState();
}

class _GridSizeControlsState extends State<_GridSizeControls> {
  late TextEditingController _rowsCtrl;
  late TextEditingController _colsCtrl;

  @override
  void initState() {
    super.initState();
    _rowsCtrl = TextEditingController(text: widget.map.rows.toString());
    _colsCtrl = TextEditingController(text: widget.map.cols.toString());
  }

  @override
  void didUpdateWidget(covariant _GridSizeControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Tiene i campi sincronizzati se la griglia cambia dimensione da sola
    // (es. auto-adattamento allo schermo al primo avvio).
    final rowsText = widget.map.rows.toString();
    final colsText = widget.map.cols.toString();
    if (_rowsCtrl.text != rowsText) _rowsCtrl.text = rowsText;
    if (_colsCtrl.text != colsText) _colsCtrl.text = colsText;
  }

  @override
  void dispose() {
    _rowsCtrl.dispose();
    _colsCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final r = int.tryParse(_rowsCtrl.text) ?? widget.map.rows;
    final c = int.tryParse(_colsCtrl.text) ?? widget.map.cols;
    widget.map.resizeGrid(r, c);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _rowsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Righe'),
            onSubmitted: (_) => _apply(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _colsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Colonne'),
            onSubmitted: (_) => _apply(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(icon: const Icon(Icons.check), onPressed: _apply),
      ],
    );
  }
}