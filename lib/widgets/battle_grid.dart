import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../state/map_state.dart';
import 'aoe_geometry.dart';

enum _GestureAction {
  none,
  drawing,
  movingToken,
  movingAoE,
  drawingAoE,
  panningView,
}

class BattleGrid extends StatefulWidget {
  const BattleGrid({super.key});

  @override
  State<BattleGrid> createState() => _BattleGridState();
}

class _BattleGridState extends State<BattleGrid> {
  double _scale = 1;
  Offset _panOffset = Offset.zero;
  bool _initializedView = false;

  static const double _minScale = 0.2;
  static const double _maxScale = 4;

  final Map<int, Offset> _pointerPos = {};
  _GestureAction _action = _GestureAction.none;
  String? _activeTokenId;
  String? _activeAoeId;

  Offset? _aoeStartCanvas;
  double _aoeSizeCells = 0;
  double _aoeAngle = 0;

  int? _pinchA;
  int? _pinchB;
  double _pinchStartDistance = 1;
  double _pinchStartScale = 1;
  Offset _pinchStartPan = Offset.zero;
  Offset _pinchAnchorCanvas = Offset.zero;

  // ---- Conversioni di coordinate -----------------------------------------

  Offset _screenToCanvas(Offset s) => (s - _panOffset) / _scale;
  Offset _canvasToScreen(Offset c) => c * _scale + _panOffset;

  CellPos _cellFromCanvas(Offset c, MapState map) =>
      CellPos((c.dy / map.cellSize).floor(), (c.dx / map.cellSize).floor());

  // ---- Hit test -----------------------------------------------------------

  TokenData? _hitTestToken(Offset canvasPoint, MapState map) {
    for (final t in map.tokens.reversed) {
      final left = t.col * map.cellSize;
      final top = t.row * map.cellSize;
      final size = t.sizeCells * map.cellSize;
      if (canvasPoint.dx >= left &&
          canvasPoint.dx <= left + size &&
          canvasPoint.dy >= top &&
          canvasPoint.dy <= top + size) {
        return t;
      }
    }
    return null;
  }

  AoEData? _hitTestAoE(Offset canvasPoint, MapState map) {
    for (final a in map.aoes.reversed) {
      if (AoEGeometry(a, map.cellSize).contains(canvasPoint)) return a;
    }
    return null;
  }

  // ---- Gestione pinch (zoom/pan a due dita) -------------------------------

  void _startPinch() {
    final ids = _pointerPos.keys.toList();
    if (ids.length < 2) return;
    _pinchA = ids[0];
    _pinchB = ids[1];
    final pA = _pointerPos[_pinchA]!;
    final pB = _pointerPos[_pinchB]!;
    _pinchStartDistance = (pA - pB).distance.clamp(1, double.infinity);
    _pinchStartScale = _scale;
    _pinchStartPan = _panOffset;
    final focal = Offset((pA.dx + pB.dx) / 2, (pA.dy + pB.dy) / 2);
    _pinchAnchorCanvas = (focal - _pinchStartPan) / _pinchStartScale;
  }

  // ---- Gestori di eventi puntatore -----------------------------------------

  void _handlePointerDown(PointerDownEvent event, MapState map) {
    _pointerPos[event.pointer] = event.localPosition;

    if (_pointerPos.length == 1) {
      final isMiddleButton = (event.buttons & kMiddleMouseButton) != 0;
      if (isMiddleButton) {
        _action = _GestureAction.panningView;
        return;
      }

      final canvasPoint = _screenToCanvas(event.localPosition);

      // Con lo strumento AoE attivo: le AoE già posizionate restano
      // selezionabili/spostabili; toccare una pedina non la trascina ma
      // avvia una nuova AoE ancorata al suo centro (comodo per gli
      // incantesimi lanciati da un personaggio già sulla griglia).
      if (map.currentTool == Tool.drawAoE) {
        final existingAoe = _hitTestAoE(canvasPoint, map);
        if (existingAoe != null) {
          _action = _GestureAction.movingAoE;
          _activeAoeId = existingAoe.id;
          map.selectAoE(existingAoe.id);
          return;
        }
        final anchorToken = _hitTestToken(canvasPoint, map);
        final origin = anchorToken != null
            ? Offset(
                (anchorToken.col + anchorToken.sizeCells / 2) * map.cellSize,
                (anchorToken.row + anchorToken.sizeCells / 2) * map.cellSize,
              )
            : canvasPoint;
        _action = _GestureAction.drawingAoE;
        _aoeStartCanvas = origin;
        _aoeSizeCells = 0;
        _aoeAngle = 0;
        setState(() {});
        return;
      }

      final token = _hitTestToken(canvasPoint, map);
      if (token != null) {
        _action = _GestureAction.movingToken;
        _activeTokenId = token.id;
        map.selectToken(token.id);
        return;
      }

      final aoe = _hitTestAoE(canvasPoint, map);
      if (aoe != null) {
        _action = _GestureAction.movingAoE;
        _activeAoeId = aoe.id;
        map.selectAoE(aoe.id);
        return;
      }

      switch (map.currentTool) {
        case Tool.paint:
        case Tool.erase:
          _action = _GestureAction.drawing;
          final cell = _cellFromCanvas(canvasPoint, map);
          map.paintCell(cell.row, cell.col);
          break;
        case Tool.fill:
          final cell = _cellFromCanvas(canvasPoint, map);
          map.fillArea(cell.row, cell.col);
          _action = _GestureAction.none;
          break;
        case Tool.placeToken:
          final cell = _cellFromCanvas(canvasPoint, map);
          final newToken = map.addToken(cell.row, cell.col);
          map.selectToken(newToken.id);
          _action = _GestureAction.movingToken;
          _activeTokenId = newToken.id;
          break;
        case Tool.drawAoE:
          break;
      }
    } else if (_pointerPos.length == 2) {
      // Il secondo dito passa sempre in modalità "vista": eventuali disegni
      // in corso vengono chiusi (le pedine mantengono l'ultima posizione).
      if (_action == _GestureAction.movingToken && _activeTokenId != null) {
        map.snapTokenToGrid(_activeTokenId!);
      }
      _aoeStartCanvas = null;
      _activeTokenId = null;
      _activeAoeId = null;
      _action = _GestureAction.panningView;
      _startPinch();
    }
  }

  void _handlePointerMove(PointerMoveEvent event, MapState map) {
    if (!_pointerPos.containsKey(event.pointer)) return;
    _pointerPos[event.pointer] = event.localPosition;

    switch (_action) {
      case _GestureAction.drawing:
        final canvasPoint = _screenToCanvas(event.localPosition);
        final cell = _cellFromCanvas(canvasPoint, map);
        map.paintCell(cell.row, cell.col);
        break;

      case _GestureAction.movingToken:
        if (_activeTokenId != null) {
          map.moveTokenBy(
            _activeTokenId!,
            event.delta.dy / _scale / map.cellSize,
            event.delta.dx / _scale / map.cellSize,
          );
        }
        break;

      case _GestureAction.movingAoE:
        if (_activeAoeId != null) {
          map.moveAoEBy(
            _activeAoeId!,
            event.delta.dy / _scale / map.cellSize,
            event.delta.dx / _scale / map.cellSize,
          );
        }
        break;

      case _GestureAction.drawingAoE:
        if (_aoeStartCanvas != null) {
          final current = _screenToCanvas(event.localPosition);
          final delta = current - _aoeStartCanvas!;
          setState(() {
            _aoeAngle = math.atan2(delta.dy, delta.dx);
            if (map.selectedAoEShape == AoEShape.cube) {
              final half = math.max(delta.dx.abs(), delta.dy.abs());
              _aoeSizeCells = (half * 2) / map.cellSize;
            } else {
              _aoeSizeCells = delta.distance / map.cellSize;
            }
          });
        }
        break;

      case _GestureAction.panningView:
        if (_pointerPos.length >= 2 &&
            _pinchA != null &&
            _pinchB != null &&
            _pointerPos.containsKey(_pinchA) &&
            _pointerPos.containsKey(_pinchB)) {
          final pA = _pointerPos[_pinchA]!;
          final pB = _pointerPos[_pinchB]!;
          final distance = (pA - pB).distance.clamp(1, double.infinity);
          final focal = Offset((pA.dx + pB.dx) / 2, (pA.dy + pB.dy) / 2);
          final newScale = (_pinchStartScale * (distance / _pinchStartDistance))
              .clamp(_minScale, _maxScale);
          setState(() {
            _scale = newScale;
            _panOffset = focal - _pinchAnchorCanvas * newScale;
          });
        } else {
          setState(() => _panOffset += event.delta);
        }
        break;

      case _GestureAction.none:
        break;
    }
  }

  void _handlePointerUp(PointerEvent event, MapState map) {
    _pointerPos.remove(event.pointer);

    if (_pointerPos.isEmpty) {
      if (_action == _GestureAction.movingToken && _activeTokenId != null) {
        map.snapTokenToGrid(_activeTokenId!);
      } else if (_action == _GestureAction.drawingAoE &&
          _aoeStartCanvas != null) {
        if (_aoeSizeCells > 0.3) {
          final created = map.addAoE(
            originRow: _aoeStartCanvas!.dy / map.cellSize,
            originCol: _aoeStartCanvas!.dx / map.cellSize,
            sizeCells: _aoeSizeCells,
            angle: _aoeAngle,
          );
          // Seleziona subito la nuova AoE così i pulsanti modifica/elimina
          // sono immediatamente disponibili senza doverla ritoccare.
          map.selectAoE(created.id);
        }
      }
      _action = _GestureAction.none;
      _activeTokenId = null;
      _activeAoeId = null;
      _aoeStartCanvas = null;
      _aoeSizeCells = 0;
      setState(() {});
    } else if (_pointerPos.length == 1) {
      if (_action != _GestureAction.panningView) {
        _action = _GestureAction.none;
      }
    } else {
      _startPinch();
    }
  }

  void _handlePointerSignal(PointerSignalEvent event, MapState map) {
    if (event is PointerScrollEvent) {
      final zoomFactor = math.exp(-event.scrollDelta.dy * 0.0015);
      final newScale = (_scale * zoomFactor).clamp(_minScale, _maxScale);
      final canvasPoint = (event.localPosition - _panOffset) / _scale;
      setState(() {
        _panOffset = event.localPosition - canvasPoint * newScale;
        _scale = newScale;
      });
    }
  }

  AoEData? _previewAoe(MapState map) {
    if (_action != _GestureAction.drawingAoE || _aoeStartCanvas == null)
      return null;
    return AoEData(
      id: '__preview__',
      shape: map.selectedAoEShape,
      originRow: _aoeStartCanvas!.dy / map.cellSize,
      originCol: _aoeStartCanvas!.dx / map.cellSize,
      sizeCells: _aoeSizeCells,
      angle: _aoeAngle,
      color: map.selectedAoEColor,
      label: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final map = context.watch<MapState>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.biggest;
        if (!_initializedView && viewport.width > 0 && viewport.height > 0) {
          _initializedView = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            map.autoFitToViewport(viewport.width, viewport.height);
            setState(() {
              _panOffset = Offset(
                (viewport.width - map.gridWidth) / 2,
                (viewport.height - map.gridHeight) / 2,
              );
            });
          });
        }

        return Listener(
          onPointerDown: (e) => _handlePointerDown(e, map),
          onPointerMove: (e) => _handlePointerMove(e, map),
          onPointerUp: (e) => _handlePointerUp(e, map),
          onPointerCancel: (e) => _handlePointerUp(e, map),
          onPointerSignal: (e) => _handlePointerSignal(e, map),
          child: Container(
            color: const Color(0xFF171719),
            child: ClipRect(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _WorldPainter(
                        map: map,
                        scale: _scale,
                        pan: _panOffset,
                        previewAoe: _previewAoe(map),
                      ),
                    ),
                  ),
                  ...map.tokens.map((t) => _buildToken(context, t, map)),
                  _buildAoeMeasurementLabel(map),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToken(BuildContext context, TokenData t, MapState map) {
    final topLeft = _canvasToScreen(
      Offset(t.col * map.cellSize, t.row * map.cellSize),
    );
    final size = t.sizeCells * map.cellSize * _scale;
    final isSelected = map.selectedTokenId == t.id;
    final showLabel = map.showTokenLabels || isSelected;

    // Nota: i pulsanti di modifica/eliminazione della pedina selezionata
    // non sono più qui come icone fluttuanti (difficili da toccare), ma
    // nella QuickToolbar sul lato destro dello schermo.
    return Positioned(
      left: topLeft.dx,
      top: topLeft.dy,
      width: size,
      height: size,
      child: IgnorePointer(
        child: Padding(
          padding: EdgeInsets.all(size * 0.06),
          child: Container(
            decoration: BoxDecoration(
              color: t.category.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.black54,
                width: isSelected ? 3 : 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 3,
                  offset: Offset(1, 1),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.contain,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      t.category.icon,
                      color: Colors.white,
                      size: size,
                    ),
                  ),
                ),
                if (showLabel)
                  Positioned(
                    top: size * 0.88,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        t.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Etichetta con la misura in tempo reale mentre si disegna un'AoE:
  /// mostra raggio/lunghezza/lato sia in celle sia in metri (personalizzabili
  /// dalle Impostazioni griglia).
  Widget _buildAoeMeasurementLabel(MapState map) {
    if (_action != _GestureAction.drawingAoE || _pointerPos.isEmpty) {
      return const SizedBox.shrink();
    }
    final pointerScreen = _pointerPos.values.first;
    final cellsText = _aoeSizeCells.toStringAsFixed(1);
    final metersText = (_aoeSizeCells * map.metersPerCell).toStringAsFixed(1);
    final dimensionLabel = switch (map.selectedAoEShape) {
      AoEShape.circle => 'Raggio',
      AoEShape.cube => 'Lato',
      _ => 'Lunghezza',
    };

    return Positioned(
      left: pointerScreen.dx + 18,
      top: pointerScreen.dy + 18,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            '$dimensionLabel: $cellsText caselle ($metersText m)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Disegna terreno (con spazio tra le celle), linee guida e Aree d'Effetto.
class _WorldPainter extends CustomPainter {
  final MapState map;
  final double scale;
  final Offset pan;
  final AoEData? previewAoe;

  _WorldPainter({
    required this.map,
    required this.scale,
    required this.pan,
    this.previewAoe,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(pan.dx, pan.dy);
    canvas.scale(scale);

    final cellSize = map.cellSize;
    // Spazio vuoto tra le celle: proporzionale alla dimensione della cella,
    // così resta leggibile anche con zoom-out marcato o schermi piccoli.
    final gap = cellSize * 0.08;
    final radius = Radius.circular((gap * 0.7).clamp(1, 10));
    final tilePaint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    for (int r = 0; r < map.rows; r++) {
      for (int c = 0; c < map.cols; c++) {
        final tile = map.tileAt(r, c);
        if (tile != TileType.empty) {
          tilePaint.color = tile.color;
          final rect = Rect.fromLTWH(
            c * cellSize + gap / 2,
            r * cellSize + gap / 2,
            cellSize - gap,
            cellSize - gap,
          );
          canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), tilePaint);
        }
      }
    }

    for (int c = 0; c <= map.cols; c++) {
      final x = c * cellSize;
      canvas.drawLine(Offset(x, 0), Offset(x, map.gridHeight), linePaint);
    }
    for (int r = 0; r <= map.rows; r++) {
      final y = r * cellSize;
      canvas.drawLine(Offset(0, y), Offset(map.gridWidth, y), linePaint);
    }

    for (final aoe in map.aoes) {
      _paintAoe(canvas, aoe, cellSize, selected: aoe.id == map.selectedAoeId);
    }
    if (previewAoe != null) {
      _paintAoe(canvas, previewAoe!, cellSize, selected: false, preview: true);
    }

    canvas.restore();
  }

  void _paintAoe(
    Canvas canvas,
    AoEData aoe,
    double cellSize, {
    bool selected = false,
    bool preview = false,
  }) {
    final geometry = AoEGeometry(aoe, cellSize);
    final path = geometry.buildPath();

    final fillPaint = Paint()
      ..color = aoe.color.withOpacity(preview ? 0.22 : 0.38)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final strokePaint = Paint()
      ..color = (selected ? Colors.white : aoe.color).withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (selected ? 2.5 : 1.5) / scale;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _WorldPainter oldDelegate) => true;
}
