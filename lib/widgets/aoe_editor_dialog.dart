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

  @override
  void initState() {
    super.initState();
    final map = context.read<MapState>();
    final aoe = map.aoes.firstWhere((a) => a.id == widget.aoeId);
    _labelController = TextEditingController(text: aoe.label);
    _sizeCells = aoe.sizeCells;
    _color = aoe.color;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final map = context.read<MapState>();
    final aoe = map.aoes.firstWhere((a) => a.id == widget.aoeId);
    final meters = (_sizeCells * map.metersPerCell).toStringAsFixed(1);

    return AlertDialog(
      title: Row(
        children: [
          Icon(aoe.shape.icon, size: 20),
          const SizedBox(width: 8),
          Text('Modifica ${aoe.shape.label.toLowerCase()}'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(labelText: 'Nome (es. Palla di fuoco)'),
            ),
            const SizedBox(height: 16),
            Text(
              aoe.shape == AoEShape.circle
                  ? 'Raggio: ${_sizeCells.toStringAsFixed(1)} caselle ($meters m)'
                  : aoe.shape == AoEShape.cube
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
              child: Text('Colore', style: TextStyle(fontWeight: FontWeight.w600)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: entry.value.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? Colors.white : Colors.black26,
                        width: selected ? 3 : 1,
                      ),
                    ),
                    child: Text(entry.key,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          label: const Text('Elimina', style: TextStyle(color: Colors.redAccent)),
          onPressed: () {
            map.removeAoE(widget.aoeId);
            Navigator.of(context).pop();
          },
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () {
            map.updateAoE(
              widget.aoeId,
              sizeCells: _sizeCells,
              color: _color,
              label: _labelController.text.trim().isEmpty ? null : _labelController.text.trim(),
            );
            Navigator.of(context).pop();
          },
          child: const Text('Salva'),
        ),
      ],
    );
  }
}