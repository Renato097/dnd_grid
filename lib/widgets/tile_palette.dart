import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../state/map_state.dart';

class TilePalette extends StatelessWidget {
  const TilePalette({super.key});

  @override
  Widget build(BuildContext context) {
    final map = context.watch<MapState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Terreno', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TileType.values.map((type) {
            final selected = map.selectedTileType == type &&
                (map.currentTool == Tool.paint || map.currentTool == Tool.fill);
            return _TileChip(
              type: type,
              selected: selected,
              onTap: () => map.setSelectedTileType(type),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ToolIconButton(
              icon: Icons.brush,
              label: 'Pennello',
              selected: map.currentTool == Tool.paint,
              onTap: () => map.setTool(Tool.paint),
            ),
            _ToolIconButton(
              icon: Icons.auto_fix_off,
              label: 'Gomma',
              selected: map.currentTool == Tool.erase,
              onTap: () => map.setTool(Tool.erase),
            ),
            _ToolIconButton(
              icon: Icons.format_color_fill,
              label: 'Riempi',
              selected: map.currentTool == Tool.fill,
              onTap: () => map.setTool(Tool.fill),
            ),
          ],
        ),
      ],
    );
  }
}

class _TileChip extends StatelessWidget {
  final TileType type;
  final bool selected;
  final VoidCallback onTap;
  const _TileChip({required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: type.color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? Colors.white : Colors.black26,
            width: selected ? 3 : 1,
          ),
        ),
        child: Text(
          type.label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
          ),
        ),
      ),
    );
  }
}

class _ToolIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToolIconButton(
      {required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Text(label),
      ]),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}