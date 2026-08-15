import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/map_state.dart';

/// Barra flottante verticale con le scorciatoie più usate durante il gioco
/// (dopo aver già disegnato la mappa): pennello, gomma, riempi e la
/// dimensione della cella. Resta visibile anche a pannello chiuso o in
/// modalità schermo intero.
class QuickToolbar extends StatelessWidget {
  const QuickToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final map = context.watch<MapState>();

    return Material(
      color: const Color(0xFF1E1E22).withOpacity(0.92),
      borderRadius: BorderRadius.circular(14),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _QuickToolButton(
              icon: Icons.brush,
              tooltip: 'Pennello',
              selected: map.currentTool == Tool.paint,
              onTap: () => map.setTool(Tool.paint),
            ),
            const SizedBox(height: 6),
            _QuickToolButton(
              icon: Icons.auto_fix_off,
              tooltip: 'Gomma',
              selected: map.currentTool == Tool.erase,
              onTap: () => map.setTool(Tool.erase),
            ),
            const SizedBox(height: 6),
            _QuickToolButton(
              icon: Icons.format_color_fill,
              tooltip: 'Riempi',
              selected: map.currentTool == Tool.fill,
              onTap: () => map.setTool(Tool.fill),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Colors.white24),
            const SizedBox(height: 10),
            Tooltip(
              message: 'Dimensione cella: ${map.cellSize.round()} px',
              child: SizedBox(
                height: 140,
                width: 28,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    ),
                    child: Slider(
                      min: 12,
                      max: 160,
                      value: map.cellSize,
                      onChanged: (v) => map.setCellSize(v),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  const _QuickToolButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}
