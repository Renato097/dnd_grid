import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../state/map_state.dart';
import 'aoe_editor_dialog.dart';

class AoePalette extends StatelessWidget {
  const AoePalette({super.key});

  @override
  Widget build(BuildContext context) {
    final map = context.watch<MapState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Aree d\'effetto', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
          'Scegli una forma poi trascina sulla griglia dal punto di origine: '
          'la dimensione si regola in base a quanto trascini.',
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AoEShape.values.map((shape) {
            final selected =
                map.selectedAoEShape == shape && map.currentTool == Tool.drawAoE;
            return ChoiceChip(
              avatar: Icon(shape.icon, size: 16),
              label: Text(shape.label),
              selected: selected,
              onSelected: (_) => map.setSelectedAoEShape(shape),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        const Text('Colore', style: TextStyle(fontSize: 12, color: Colors.white70)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kAoEColorPresets.map((entry) {
            final selected = map.selectedAoEColor.value == entry.value.value;
            return InkWell(
              onTap: () => map.setSelectedAoEColor(entry.value),
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
        if (map.selectedAoeId != null) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.tune, size: 16),
                label: const Text('Modifica selezionata'),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => AoeEditorDialog(aoeId: map.selectedAoeId!),
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.delete, size: 16),
                label: const Text('Elimina selezionata'),
                onPressed: () => map.removeAoE(map.selectedAoeId!),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
