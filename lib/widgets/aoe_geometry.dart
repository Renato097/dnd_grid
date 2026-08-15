import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/models.dart';

/// Utility per convertire un'AoE (espressa in celle) in coordinate canvas
/// (pixel, spazio "mondo" prima della trasformazione pan/zoom) e per
/// verificare se un punto ricade al suo interno (hit-test approssimato).
class AoEGeometry {
  final AoEData aoe;
  final double cellSize;
  AoEGeometry(this.aoe, this.cellSize);

  Offset get originPx => Offset(aoe.originCol * cellSize, aoe.originRow * cellSize);
  double get sizePx => aoe.sizeCells * cellSize;

  Offset get direction => Offset(math.cos(aoe.angle), math.sin(aoe.angle));
  Offset get perpendicular => Offset(-math.sin(aoe.angle), math.cos(aoe.angle));

  /// Vertici del cono (apice + due angoli di base), in pixel.
  List<Offset> get conePoints {
    final apex = originPx;
    final base = apex + direction * sizePx;
    final halfWidth = sizePx / 2;
    final p1 = base + perpendicular * halfWidth;
    final p2 = base - perpendicular * halfWidth;
    return [apex, p1, p2];
  }

  /// Estremi della linea, in pixel (la linea ha spessore fisso di 1 cella).
  Offset get lineEnd => originPx + direction * sizePx;

  /// Rettangolo del cubo/quadrato, centrato sull'origine.
  Rect get cubeRect => Rect.fromCenter(center: originPx, width: sizePx, height: sizePx);

  /// Path pronto per essere disegnato sul canvas.
  Path buildPath() {
    switch (aoe.shape) {
      case AoEShape.circle:
        return Path()..addOval(Rect.fromCircle(center: originPx, radius: sizePx));
      case AoEShape.cone:
        final pts = conePoints;
        return Path()
          ..moveTo(pts[0].dx, pts[0].dy)
          ..lineTo(pts[1].dx, pts[1].dy)
          ..lineTo(pts[2].dx, pts[2].dy)
          ..close();
      case AoEShape.line:
        final end = lineEnd;
        final halfW = cellSize / 2;
        final p = perpendicular * halfW;
        return Path()
          ..moveTo(originPx.dx + p.dx, originPx.dy + p.dy)
          ..lineTo(end.dx + p.dx, end.dy + p.dy)
          ..lineTo(end.dx - p.dx, end.dy - p.dy)
          ..lineTo(originPx.dx - p.dx, originPx.dy - p.dy)
          ..close();
      case AoEShape.cube:
        return Path()..addRect(cubeRect);
    }
  }

  /// True se [point] (in pixel, spazio canvas) ricade nella forma.
  bool contains(Offset point) {
    switch (aoe.shape) {
      case AoEShape.circle:
        return (point - originPx).distance <= sizePx;
      case AoEShape.cube:
        return cubeRect.inflate(2).contains(point);
      case AoEShape.cone:
        final pts = conePoints;
        return _pointInTriangle(point, pts[0], pts[1], pts[2]);
      case AoEShape.line:
        return _distanceToSegment(point, originPx, lineEnd) <= (cellSize / 2) + 3;
    }
  }

  static bool _pointInTriangle(Offset p, Offset a, Offset b, Offset c) {
    double sign(Offset p1, Offset p2, Offset p3) =>
        (p1.dx - p3.dx) * (p2.dy - p3.dy) - (p2.dx - p3.dx) * (p1.dy - p3.dy);
    final d1 = sign(p, a, b);
    final d2 = sign(p, b, c);
    final d3 = sign(p, c, a);
    final hasNeg = (d1 < 0) || (d2 < 0) || (d3 < 0);
    final hasPos = (d1 > 0) || (d2 > 0) || (d3 > 0);
    return !(hasNeg && hasPos);
  }

  static double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final lengthSq = ab.dx * ab.dx + ab.dy * ab.dy;
    if (lengthSq == 0) return (p - a).distance;
    var t = ((p - a).dx * ab.dx + (p - a).dy * ab.dy) / lengthSq;
    t = t.clamp(0.0, 1.0);
    final projection = a + ab * t;
    return (p - projection).distance;
  }
}
