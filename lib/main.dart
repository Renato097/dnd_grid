import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'state/map_state.dart';
import 'widgets/battle_grid.dart';
import 'widgets/quick_toolbar.dart';
import 'widgets/side_panel.dart';

void main() {
  runApp(const DndGridApp());
}

class DndGridApp extends StatelessWidget {
  const DndGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MapState(),
      child: MaterialApp(
        title: 'Griglie D&D',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          colorSchemeSeed: const Color(0xFF7C4DFF),
          scaffoldBackgroundColor: const Color(0xFF121214),
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _panelOpen = true;
  bool _fullscreen = false;

  static const double _panelWidth = 340;
  static const Duration _animDuration = Duration(milliseconds: 180);

  // Posizione del pannello (angolo in alto a sinistra). null = non ancora
  // inizializzata: verrà centrata/posizionata al primo layout disponibile.
  Offset? _panelPosition;

  void _togglePanel() => setState(() => _panelOpen = !_panelOpen);

  void _toggleFullscreen() {
    setState(() {
      _fullscreen = !_fullscreen;
      if (_fullscreen) _panelOpen = false;
    });
    // Su Android/iOS nasconde anche le barre di sistema per guadagnare
    // spazio reale sullo schermo; su desktop/web la chiamata è innocua.
    SystemChrome.setEnabledSystemUIMode(
      _fullscreen ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  void _dragPanel(
    Offset delta,
    Size screenSize,
    double panelWidth,
    double panelHeight,
  ) {
    final current = _panelPosition ?? const Offset(12, 84);
    final maxX = (screenSize.width - panelWidth - 8)
        .clamp(8, double.infinity)
        .toDouble();
    final maxY = (screenSize.height - panelHeight - 8)
        .clamp(8, double.infinity)
        .toDouble();
    setState(() {
      _panelPosition = Offset(
        (current.dx + delta.dx).clamp(8, maxX).toDouble(),
        (current.dy + delta.dy).clamp(8, maxY).toDouble(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final panelWidth = screenSize.width - 24 < _panelWidth
        ? screenSize.width - 24
        : _panelWidth;
    final panelHeight = (screenSize.height - 96).clamp(200, screenSize.height);

    // final panelTop = _fullscreen ? 12.0 : 84.0;
    final panelTop = 12.0;
    final panelPosition = _panelPosition ?? Offset(12, panelTop);

    return Scaffold(
      appBar: _fullscreen
          ? null
          : AppBar(
              title: const Text('Griglie di gioco — D&D'),
              actions: [
                IconButton(
                  tooltip: 'Schermo intero',
                  icon: const Icon(Icons.fullscreen),
                  onPressed: _toggleFullscreen,
                ),
              ],
            ),
      body: Stack(
        children: [
          // La mappa occupa sempre tutto lo spazio disponibile: il
          // pannello è un overlay flottante, non riduce l'area di gioco.
          const Positioned.fill(child: BattleGrid()),

          // Angolo in alto a destra: pulsante fullscreen (solo quando attivo,
          // altrimenti sta nell'AppBar) e sotto di esso la barra rapida con
          // pennello/gomma/riempi + dimensione cella, sempre disponibile.
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_fullscreen)
                      _RoundIconButton(
                        icon: Icons.fullscreen_exit,
                        tooltip: 'Esci da schermo intero',
                        onTap: _toggleFullscreen,
                      ),
                    const SizedBox(height: 8),
                    const QuickToolbar(),
                  ],
                ),
              ),
            ),
          ),

          // Pulsante per aprire il pannello, visibile solo quando è chiuso.
          if (!_panelOpen)
            Positioned(
              top: 12,
              left: 12,
              child: SafeArea(
                child: _RoundIconButton(
                  icon: Icons.tune,
                  tooltip: 'Apri strumenti',
                  onTap: _togglePanel,
                ),
              ),
            ),

          // Pannello flottante, trascinabile dalla sua intestazione.
          AnimatedPositioned(
            duration: _animDuration,
            curve: Curves.easeOut,
            left: panelPosition.dx,
            top: panelPosition.dy,
            width: panelWidth,
            height: panelHeight.toDouble(),
            child: IgnorePointer(
              ignoring: !_panelOpen,
              child: AnimatedOpacity(
                duration: _animDuration,
                opacity: _panelOpen ? 1 : 0,
                child: AnimatedScale(
                  duration: _animDuration,
                  scale: _panelOpen ? 1 : 0.95,
                  alignment: Alignment.topLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E22).withOpacity(0.97),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SidePanel(
                      onClose: _togglePanel,
                      onDragHeader: (delta) => _dragPanel(
                        delta,
                        screenSize,
                        panelWidth,
                        panelHeight.toDouble(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E1E22).withOpacity(0.92),
      shape: const CircleBorder(),
      elevation: 4,
      child: IconButton(tooltip: tooltip, icon: Icon(icon), onPressed: onTap),
    );
  }
}
