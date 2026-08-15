import 'package:flutter/material.dart';
import '../models/models.dart';

/// Strumento attivo nella toolbar principale. Lo spostamento di vista e
/// il movimento delle pedine/AoE non sono più strumenti dedicati: sono
/// sempre disponibili tramite gesture (vedi BattleGrid).
enum Tool { paint, erase, fill, placeToken, drawAoE }

class MapState extends ChangeNotifier {
  int rows;
  int cols;
  double cellSize;
  /// Metri reali rappresentati da un lato di una cella (personalizzabile).
  double metersPerCell;
  bool hasAutoSizedGrid = false;

  final Map<CellPos, TileType> _tiles = {};
  final List<TokenData> _tokens = [];
  final List<AoEData> _aoes = [];

  Tool currentTool = Tool.paint;
  TileType selectedTileType = TileType.grass;

  TokenCategory selectedTokenCategory = TokenCategory.player;
  TokenSize selectedTokenSize = TokenSize.medium;

  AoEShape selectedAoEShape = AoEShape.circle;
  Color selectedAoEColor = const Color(0xFFFF7043);

  String? selectedTokenId;
  String? selectedAoeId;
  bool showTokenLabels = true;

  int _tokenCounter = 0;
  int _aoeCounter = 0;

  MapState({this.rows = 20, this.cols = 20, this.cellSize = 40, this.metersPerCell = 1.5});

  double get gridWidth => cols * cellSize;
  double get gridHeight => rows * cellSize;

  TileType tileAt(int row, int col) =>
      _tiles[CellPos(row, col)] ?? TileType.empty;

  List<TokenData> get tokens => List.unmodifiable(_tokens);
  List<AoEData> get aoes => List.unmodifiable(_aoes);

  TokenData? get selectedToken {
    for (final t in _tokens) {
      if (t.id == selectedTokenId) return t;
    }
    return null;
  }

  AoEData? get selectedAoE {
    for (final a in _aoes) {
      if (a.id == selectedAoeId) return a;
    }
    return null;
  }

  // ---- Griglia / terreno ---------------------------------------------

  void paintCell(int row, int col) {
    if (row < 0 || col < 0 || row >= rows || col >= cols) return;
    final pos = CellPos(row, col);
    if (currentTool == Tool.paint) {
      if (_tiles[pos] == selectedTileType) return;
      _tiles[pos] = selectedTileType;
      notifyListeners();
    } else if (currentTool == Tool.erase) {
      if (!_tiles.containsKey(pos)) return;
      _tiles.remove(pos);
      notifyListeners();
    }
  }

  /// Riempimento a secchiello: sostituisce tutte le celle contigue dello
  /// stesso tipo del punto di partenza con il tile selezionato
  /// (flood fill iterativo a 4 direzioni, senza ricorsione).
  void fillArea(int startRow, int startCol) {
    if (startRow < 0 || startCol < 0 || startRow >= rows || startCol >= cols) {
      return;
    }
    final target = tileAt(startRow, startCol);
    if (target == selectedTileType) return;

    final visited = <CellPos>{};
    final stack = <CellPos>[CellPos(startRow, startCol)];

    while (stack.isNotEmpty) {
      final pos = stack.removeLast();
      if (visited.contains(pos)) continue;
      if (pos.row < 0 || pos.col < 0 || pos.row >= rows || pos.col >= cols) {
        continue;
      }
      if (tileAt(pos.row, pos.col) != target) continue;

      visited.add(pos);
      if (selectedTileType == TileType.empty) {
        _tiles.remove(pos);
      } else {
        _tiles[pos] = selectedTileType;
      }

      stack.add(CellPos(pos.row - 1, pos.col));
      stack.add(CellPos(pos.row + 1, pos.col));
      stack.add(CellPos(pos.row, pos.col - 1));
      stack.add(CellPos(pos.row, pos.col + 1));
    }
    notifyListeners();
  }

  void toggleTokenLabels() {
    showTokenLabels = !showTokenLabels;
    notifyListeners();
  }

  void resizeGrid(int newRows, int newCols) {
    hasAutoSizedGrid = true;
    rows = newRows.clamp(1, 300);
    cols = newCols.clamp(1, 300);
    _tiles.removeWhere((pos, _) => pos.row >= rows || pos.col >= cols);
    _tokens.removeWhere((t) => t.row >= rows || t.col >= cols);
    notifyListeners();
  }

  void setCellSize(double size) {
    cellSize = size.clamp(12, 160);
    notifyListeners();
  }

  void setMetersPerCell(double meters) {
    metersPerCell = meters.clamp(0.1, 20);
    notifyListeners();
  }

  /// Dimensiona la griglia per coprire lo schermo al primo caricamento
  /// dell'app. Non ha effetto se l'utente ha già impostato una dimensione
  /// (manualmente, tramite [resizeGrid]) o se è già stata eseguita.
  void autoFitToViewport(double viewportWidth, double viewportHeight) {
    if (hasAutoSizedGrid) return;
    hasAutoSizedGrid = true;
    rows = (viewportHeight / cellSize).ceil().clamp(4, 300);
    cols = (viewportWidth / cellSize).ceil().clamp(4, 300);
    notifyListeners();
  }

  void clearTiles() {
    _tiles.clear();
    notifyListeners();
  }

  void clearAll() {
    _tiles.clear();
    _tokens.clear();
    _aoes.clear();
    selectedTokenId = null;
    selectedAoeId = null;
    notifyListeners();
  }

  // ---- Pedine -----------------------------------------------------------

  TokenData addToken(int row, int col, {TokenCategory? category, String? name}) {
    _tokenCounter++;
    final cat = category ?? selectedTokenCategory;
    final sizeCells = selectedTokenSize.cells;
    final token = TokenData(
      id: 'tok_$_tokenCounter',
      category: cat,
      name: name ?? '${cat.label} $_tokenCounter',
      row: row.clamp(0, (rows - sizeCells).clamp(0, rows)).toDouble(),
      col: col.clamp(0, (cols - sizeCells).clamp(0, cols)).toDouble(),
      sizeCells: sizeCells,
    );
    _tokens.add(token);
    notifyListeners();
    return token;
  }

  void removeToken(String id) {
    _tokens.removeWhere((t) => t.id == id);
    if (selectedTokenId == id) selectedTokenId = null;
    notifyListeners();
  }

  void moveTokenBy(String id, double deltaRow, double deltaCol) {
    final token = _find(_tokens, id);
    if (token == null) return;
    final maxRow = (rows - token.sizeCells).clamp(0, rows).toDouble();
    final maxCol = (cols - token.sizeCells).clamp(0, cols).toDouble();
    token.row = (token.row + deltaRow).clamp(0, maxRow);
    token.col = (token.col + deltaCol).clamp(0, maxCol);
    notifyListeners();
  }

  void snapTokenToGrid(String id) {
    final token = _find(_tokens, id);
    if (token == null) return;
    final maxRow = (rows - token.sizeCells).clamp(0, rows).toDouble();
    final maxCol = (cols - token.sizeCells).clamp(0, cols).toDouble();
    token.row = token.row.roundToDouble().clamp(0, maxRow);
    token.col = token.col.roundToDouble().clamp(0, maxCol);
    notifyListeners();
  }

  void updateTokenInfo(
    String id, {
    String? name,
    String? description,
    TokenCategory? category,
    TokenSize? size,
  }) {
    final token = _find(_tokens, id);
    if (token == null) return;
    if (name != null) token.name = name;
    if (description != null) token.description = description;
    if (category != null) token.category = category;
    if (size != null) token.sizeCells = size.cells;
    notifyListeners();
  }

  void selectToken(String? id) {
    selectedTokenId = id;
    if (id != null) selectedAoeId = null;
    notifyListeners();
  }

  void setSelectedTokenSize(TokenSize size) {
    selectedTokenSize = size;
    notifyListeners();
  }

  // ---- Aree d'effetto -----------------------------------------------------

  AoEData addAoE({
    required double originRow,
    required double originCol,
    required double sizeCells,
    required double angle,
  }) {
    _aoeCounter++;
    final aoe = AoEData(
      id: 'aoe_$_aoeCounter',
      shape: selectedAoEShape,
      originRow: originRow,
      originCol: originCol,
      sizeCells: sizeCells,
      angle: angle,
      color: selectedAoEColor,
      label: '${selectedAoEShape.label} $_aoeCounter',
    );
    _aoes.add(aoe);
    notifyListeners();
    return aoe;
  }

  void moveAoEBy(String id, double deltaRow, double deltaCol) {
    final aoe = _find(_aoes, id);
    if (aoe == null) return;
    aoe.originRow += deltaRow;
    aoe.originCol += deltaCol;
    notifyListeners();
  }

  void updateAoE(String id, {double? sizeCells, Color? color, String? label}) {
    final aoe = _find(_aoes, id);
    if (aoe == null) return;
    if (sizeCells != null) aoe.sizeCells = sizeCells.clamp(0.5, 200);
    if (color != null) aoe.color = color;
    if (label != null) aoe.label = label;
    notifyListeners();
  }

  void removeAoE(String id) {
    _aoes.removeWhere((a) => a.id == id);
    if (selectedAoeId == id) selectedAoeId = null;
    notifyListeners();
  }

  void selectAoE(String? id) {
    selectedAoeId = id;
    if (id != null) selectedTokenId = null;
    notifyListeners();
  }

  void setSelectedAoEShape(AoEShape shape) {
    selectedAoEShape = shape;
    currentTool = Tool.drawAoE;
    notifyListeners();
  }

  void setSelectedAoEColor(Color color) {
    selectedAoEColor = color;
    notifyListeners();
  }

  // ---- Strumenti ----------------------------------------------------------

  void setTool(Tool tool) {
    currentTool = tool;
    notifyListeners();
  }

  void setSelectedTileType(TileType type) {
    selectedTileType = type;
    if (currentTool != Tool.fill) currentTool = Tool.paint;
    notifyListeners();
  }

  void setSelectedTokenCategory(TokenCategory category) {
    selectedTokenCategory = category;
    currentTool = Tool.placeToken;
    notifyListeners();
  }

  T? _find<T>(List<T> list, String id) {
    for (final item in list) {
      final dynamic d = item;
      if (d.id == id) return item;
    }
    return null;
  }
}