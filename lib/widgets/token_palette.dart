import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../state/map_state.dart';

class TokenPalette extends StatelessWidget {
  const TokenPalette({super.key});

  @override
  Widget build(BuildContext context) {
    final map = context.watch<MapState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pedine e segnalini', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
          'Tocca una categoria poi tocca la griglia per posizionarla. '
          'Per spostare una pedina già piazzata trascinala liberamente.',
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TokenCategory.values.map((cat) {
            final selected = map.selectedTokenCategory == cat &&
                map.currentTool == Tool.placeToken;
            return ChoiceChip(
              avatar: Icon(cat.icon, size: 16, color: Colors.white),
              label: Text(cat.label),
              selectedColor: cat.color,
              backgroundColor: cat.color.withOpacity(0.35),
              labelStyle: const TextStyle(color: Colors.white),
              selected: selected,
              onSelected: (_) => map.setSelectedTokenCategory(cat),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        const Text('Taglia nuove pedine (D&D 5e)', style: TextStyle(fontSize: 12, color: Colors.white70)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TokenSize.values.map((size) {
            return ChoiceChip(
              label: Text(size.label),
              selected: map.selectedTokenSize == size,
              onSelected: (_) => map.setSelectedTokenSize(size),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              avatar: Icon(
                map.showTokenLabels ? Icons.label : Icons.label_outline,
                size: 16,
              ),
              label: const Text('Mostra nomi'),
              selected: map.showTokenLabels,
              onSelected: (_) => map.toggleTokenLabels(),
            ),
            if (map.selectedTokenId != null)
              ActionChip(
                avatar: const Icon(Icons.delete, size: 16),
                label: const Text('Elimina selezionata'),
                onPressed: () => map.removeToken(map.selectedTokenId!),
              ),
          ],
        ),
      ],
    );
  }
}