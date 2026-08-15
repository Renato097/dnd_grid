import 'package:flutter/material.dart';

/// Tipi di terreno disponibili per "dipingere" la griglia.
enum TileType { empty, grass, water, sand, stone, forest, lava, wall }

extension TileTypeData on TileType {
  Color get color {
    switch (this) {
      case TileType.empty:
        return const Color(0xFF2B2B2E);
      case TileType.grass:
        return const Color(0xFF4CAF50);
      case TileType.water:
        return const Color(0xFF2196F3);
      case TileType.sand:
        return const Color(0xFFE0C068);
      case TileType.stone:
        return const Color(0xFF9E9E9E);
      case TileType.forest:
        return const Color(0xFF1B5E20);
      case TileType.lava:
        return const Color(0xFFD84315);
      case TileType.wall:
        return const Color(0xFF3E2723);
    }
  }

  String get label {
    switch (this) {
      case TileType.empty:
        return 'Vuoto';
      case TileType.grass:
        return 'Erba';
      case TileType.water:
        return 'Acqua';
      case TileType.sand:
        return 'Sabbia';
      case TileType.stone:
        return 'Pietra';
      case TileType.forest:
        return 'Foresta';
      case TileType.lava:
        return 'Lava';
      case TileType.wall:
        return 'Muro';
    }
  }
}

/// Categorie di pedine/segnalini utilizzabili.
enum TokenCategory { player, npc, enemy, door, stairs, hazard, other }

extension TokenCategoryData on TokenCategory {
  Color get color {
    switch (this) {
      case TokenCategory.player:
        return const Color(0xFF2196F3);
      case TokenCategory.npc:
        return const Color(0xFFFFC107);
      case TokenCategory.enemy:
        return const Color(0xFFF44336);
      case TokenCategory.door:
        return const Color(0xFF8D6E63);
      case TokenCategory.stairs:
        return const Color(0xFF9C27B0);
      case TokenCategory.hazard:
        return const Color(0xFFFF9800);
      case TokenCategory.other:
        return const Color(0xFF607D8B);
    }
  }

  IconData get icon {
    switch (this) {
      case TokenCategory.player:
        return Icons.face;
      case TokenCategory.npc:
        return Icons.person;
      case TokenCategory.enemy:
        return Icons.dangerous;
      case TokenCategory.door:
        return Icons.door_front_door;
      case TokenCategory.stairs:
        return Icons.stairs;
      case TokenCategory.hazard:
        return Icons.warning_amber_rounded;
      case TokenCategory.other:
        return Icons.circle_outlined;
    }
  }

  String get label {
    switch (this) {
      case TokenCategory.player:
        return 'Giocatore';
      case TokenCategory.npc:
        return 'NPC';
      case TokenCategory.enemy:
        return 'Nemico';
      case TokenCategory.door:
        return 'Porta';
      case TokenCategory.stairs:
        return 'Scale';
      case TokenCategory.hazard:
        return 'Pericolo';
      case TokenCategory.other:
        return 'Altro';
    }
  }
}

/// Taglie standard di Dungeons & Dragons 5ª edizione, dalla Media in su,
/// espresse come lato (in celle) dell'ingombro quadrato della pedina.
enum TokenSize { medium, large, huge, gargantuan }

extension TokenSizeData on TokenSize {
  int get cells {
    switch (this) {
      case TokenSize.medium:
        return 1;
      case TokenSize.large:
        return 2;
      case TokenSize.huge:
        return 3;
      case TokenSize.gargantuan:
        return 4;
    }
  }

  String get label {
    switch (this) {
      case TokenSize.medium:
        return 'Media';
      case TokenSize.large:
        return 'Grande';
      case TokenSize.huge:
        return 'Enorme';
      case TokenSize.gargantuan:
        return 'Mastodontica';
    }
  }
}

/// Tipologie di Area of Effect più comuni nei manuali di D&D 5e.
enum AoEShape { circle, cone, line, cube }

extension AoEShapeData on AoEShape {
  String get label {
    switch (this) {
      case AoEShape.circle:
        return 'Cerchio/Sfera';
      case AoEShape.cone:
        return 'Cono';
      case AoEShape.line:
        return 'Linea';
      case AoEShape.cube:
        return 'Cubo/Quadrato';
    }
  }

  IconData get icon {
    switch (this) {
      case AoEShape.circle:
        return Icons.circle_outlined;
      case AoEShape.cone:
        return Icons.change_history;
      case AoEShape.line:
        return Icons.timeline;
      case AoEShape.cube:
        return Icons.crop_square;
    }
  }
}

/// Un'Area of Effect disegnata sulla griglia. Le coordinate e le
/// dimensioni sono espresse in "celle" (unità di griglia) e non in pixel,
/// così restano coerenti anche cambiando la dimensione delle celle.
class AoEData {
  final String id;
  AoEShape shape;
  double originRow;
  double originCol;
  /// Raggio (cerchio), lunghezza (cono/linea) o lato (cubo), in celle.
  double sizeCells;
  /// Direzione in radianti, usata da cono e linea.
  double angle;
  Color color;
  String label;

  AoEData({
    required this.id,
    required this.shape,
    required this.originRow,
    required this.originCol,
    required this.sizeCells,
    required this.angle,
    required this.color,
    required this.label,
  });
}

/// Posizione di cella intera, usata come chiave nella mappa dei tile.
@immutable
class CellPos {
  final int row;
  final int col;
  const CellPos(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is CellPos && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);
}

/// Una pedina/segnalino posizionabile sulla griglia.
/// row/col sono double per permettere trascinamento fluido.
class TokenData {
  final String id;
  TokenCategory category;
  String name;
  String description;
  double row;
  double col;
  /// Lato dell'ingombro quadrato della pedina, in celle (vedi [TokenSize]).
  int sizeCells;

  TokenData({
    required this.id,
    required this.category,
    required this.name,
    this.description = '',
    required this.row,
    required this.col,
    this.sizeCells = 1,
  });
}