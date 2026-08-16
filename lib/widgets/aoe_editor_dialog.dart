import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../state/map_state.dart';

const List<MapEntry<String, Color>> kAoEColorPresets = [
  MapEntry('Fuoco', Color(0xFFFF5722)),
  MapEntry('Freddo', Color(0xFF4FC3F7)),
  MapEntry('Fulmine', Color(0xFFFFC107)),
  MapEntry('Veleno', Color(0xFF8BC34A)),
  MapEntry('Necrotico', Color(0xFF546E7A)),
  MapEntry('Arcano', Color(0xFF9C27B0)),
];

class AoeEditorDialog extends StatefulWidget {
  final String aoeId;
  const AoeEditorDialog({super.key, required this.aoeId});

  @override
  State<AoeEditorDialog> createState() => _AoeEditorDialogState();
}

class _AoeEditorDialogState extends State<AoeEditorDialog> {
  late TextEditingController _labelController;
  late double _sizeCells;
  late Color _color;
  late AoEShape _shape;

  /// Se l'AoE non esiste più (es. eliminata da un'altra parte
  /// dell'interfaccia mentre il dialog era aperto) evitiamo di lanciare
  /// un'eccezione durante il build: chiudiamo il dialog al frame
  /// successivo invece di mostrare un contenuto rotto.
  bool _missing = false;

  @override
  void initState() {
    super.initState();
    final map = context.read<MapState>();
    AoEData? aoe;
    for (final a in map.aoes) {
      if (a.id == widget.aoeId) {
        aoe = a;
        break;
      }
    }
    if (aoe == null) {
      _missing = true;
      _labelController = TextEditingController();
      _sizeCells = 1;
      _color = const Color(0xFFFF7043);
      _shape = AoEShape.circle;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return;
    }
    _labelController = TextEditingController(text: aoe.label);
    _sizeCells = aoe.sizeCells;
    _color = aoe.color;
    _shape = aoe.shape;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_missing) {
      // Contenuto minimo in attesa della chiusura programmata sopra.
      return const AlertDialog(content: SizedBox(height: 0, width: 0));
    }

    final map = context.read<MapState>();
    final meters = (_sizeCells * map.metersPerCell).toStringAsFixed(1);

    return AlertDialog(
      title: Row(
        children: [
          Icon(_shape.icon, size: 20),
          const SizedBox(width: 8),
          Text('Modifica ${_shape.label.toLowerCase()}'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Nome (es. Palla di fuoco)',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _shape == AoEShape.circle
                  ? 'Raggio: ${_sizeCells.toStringAsFixed(1)} caselle ($meters m)'
                  : _shape == AoEShape.cube
                  ? 'Lato: ${_sizeCells.toStringAsFixed(1)} caselle ($meters m)'
                  : 'Lunghezza: ${_sizeCells.toStringAsFixed(1)} caselle ($meters m)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              min: 0.5,
              max: 40,
              divisions: 79,
              value: _sizeCells,
              onChanged: (v) => setState(() => _sizeCells = v),
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Colore',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kAoEColorPresets.map((entry) {
                final selected = _color.value == entry.value.value;
                return InkWell(
                  onTap: () => setState(() => _color = entry.value),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: entry.value.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? Colors.white : Colors.black26,
                        width: selected ? 3 : 1,
                      ),
                    ),
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      // Nota: AlertDialog dispone `actions` con un OverflowBar, non con una
      // Row/Flex: Spacer/Expanded come figli diretti causano un errore di
      // ParentData incompatibile (visibile come schermo grigio nelle build
      // web release). Per allineare "Elimina" a sinistra e il resto a
      // destra usiamo `actionsAlignment` più un raggruppamento in una Row
      // interna (quella sì è un vero Flex, quindi sicura).
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          label: const Text(
            'Elimina',
            style: TextStyle(color: Colors.redAccent),
          ),
          onPressed: () {
            map.removeAoE(widget.aoeId);
            Navigator.of(context).pop();
          },
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annulla'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                map.updateAoE(
                  widget.aoeId,
                  sizeCells: _sizeCells,
                  color: _color,
                  label: _labelController.text.trim().isEmpty
                      ? null
                      : _labelController.text.trim(),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Salva'),
            ),
          ],
        ),
      ],
    );
  }
}
