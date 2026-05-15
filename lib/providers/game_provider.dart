import 'package:flutter/material.dart';
import 'dart:math';
import '../models/board.dart';
import '../models/game_state.dart';
import '../models/piece.dart';
import '../utils/game_logic.dart';
import '../services/ai_player.dart';

class _Snapshot {
  final List<List<Piece?>> squares;
  final PieceColor currentPlayer;
  final bool gameOver;
  final PieceColor? winner;
  final Move? lastAIMove;

  _Snapshot({
    required this.squares,
    required this.currentPlayer,
    required this.gameOver,
    required this.winner,
    required this.lastAIMove,
  });
}

class GameProvider extends ChangeNotifier {
  late Board _board;
  late GameState _gameState;
  late AIPlayer _aiPlayer;
  int _gameGen = 0;
  bool _animating = false;
  final List<_Snapshot> _undoStack = [];
  final List<_Snapshot> _redoStack = [];

  Board get board => _board;
  GameState get gameState => _gameState;
  bool get animating => _animating;
  bool get canUndo => _undoStack.isNotEmpty && !_animating && !_gameState.aiThinking;
  bool get canRedo => _redoStack.isNotEmpty && !_animating && !_gameState.aiThinking;

  GameProvider() {
    startNewGame();
  }

  void startNewGame({GameMode gameMode = GameMode.humanVsHuman}) {
    _gameGen++;
    _animating = false;
    _undoStack.clear();
    _redoStack.clear();
    _board = Board();
    _aiPlayer = AIPlayer();

    final firstPlayer = Random().nextBool() ? PieceColor.light : PieceColor.dark;
    _gameState = GameState(
      currentPlayer: firstPlayer,
      gameMode: gameMode,
    );
    _updatePossibleMoves();
    notifyListeners();

    if (_gameState.isAITurn) {
      _makeAIMove();
    }
  }

  void selectPiece(int row, int col) {
    if (_gameState.isAITurn || _gameState.aiThinking || _animating) return;

    Piece? piece = _board.getPiece(row, col);

    if (piece != null && piece.color == _gameState.currentPlayer) {
      _gameState.selectedPiece = Position(row, col);
      _updatePossibleMovesForSelectedPiece();
      notifyListeners();
    } else if (_gameState.selectedPiece != null) {
      Move? validMove = _findValidMove(row, col);
      if (validMove != null) {
        // Player is about to commit a move — clear AI's last-move highlight.
        _gameState.lastAIMove = null;
        _executeMove(validMove).then((_) => _checkForAITurn());
      } else {
        _gameState.selectedPiece = null;
        _refreshAutoCircles();
        notifyListeners();
      }
    }
  }

  // True until the current human player has played their first move of the game.
  // For HVAI: the human is light, so we check whether any snapshot in the undo stack
  // belongs to a state where it was light's turn (i.e. the human had been about to move).
  // For HVH: simply "no moves yet".
  bool get _isFirstHumanMove {
    if (_gameState.gameMode == GameMode.humanVsHuman) {
      return _undoStack.isEmpty;
    }
    return !_undoStack.any((s) => s.currentPlayer == PieceColor.light);
  }

  void _updatePossibleMoves() {
    // Default: hide all circles (player must tap a piece to see its moves).
    // But: (a) on player's very first move of the game, show ALL possible moves so the
    // player sees the options. (b) when a capture is mandatory, auto-show RED capture
    // destinations so player knows they MUST take.
    _refreshAutoCircles();
  }

  void _refreshAutoCircles() {
    if (_gameState.isAITurn || _gameState.selectedPiece != null) {
      _gameState.possibleMoves = [];
      return;
    }
    final all = GameLogic.getAllPossibleMoves(_board, _gameState.currentPlayer);
    if (all.isEmpty) {
      _gameState.possibleMoves = [];
      return;
    }
    final bool mustCapture = all.first.captures.isNotEmpty;
    if (mustCapture || _isFirstHumanMove) {
      _gameState.possibleMoves = all;
    } else {
      _gameState.possibleMoves = [];
    }
  }

  void _updatePossibleMovesForSelectedPiece() {
    if (_gameState.selectedPiece != null) {
      Piece? piece = _board.getPiece(
          _gameState.selectedPiece!.row,
          _gameState.selectedPiece!.col
      );

      if (piece != null) {
        List<Move> allPlayerMoves = GameLogic.getAllPossibleMoves(_board, _gameState.currentPlayer);
        _gameState.possibleMoves = allPlayerMoves
            .where((move) =>
        move.fromRow == _gameState.selectedPiece!.row &&
            move.fromCol == _gameState.selectedPiece!.col)
            .toList();
      }
    } else {
      _gameState.possibleMoves = [];
    }
  }

  Move? _findValidMove(int toRow, int toCol) {
    for (Move move in _gameState.possibleMoves) {
      if (move.toRow == toRow && move.toCol == toCol) {
        return move;
      }
    }
    return null;
  }

  Future<void> _executeMove(Move move) async {
    // Snapshot pre-move state for undo
    _undoStack.add(_snapshot());
    _redoStack.clear();

    _gameState.selectedPiece = null;
    _gameState.possibleMoves = [];
    // NOTE: do NOT clear lastAIMove here. _makeAIMove sets it just before calling
    // this method, and the highlight needs to survive until the player commits their
    // next move (which clears it in selectPiece).

    if (move.captures.isEmpty || move.path.isEmpty) {
      // Non-capture move: instant
      _board.movePiece(move.fromRow, move.fromCol, move.toRow, move.toCol);
      _finalizeMove();
      notifyListeners();
      return;
    }

    // Multi-step capture animation: hop through each landing position
    _animating = true;
    int currentRow = move.fromRow;
    int currentCol = move.fromCol;
    final int gen = _gameGen;

    for (int i = 0; i < move.path.length; i++) {
      if (gen != _gameGen) {
        _animating = false;
        return;
      }
      // Remove captured piece for this hop
      Position cap = move.captures[i];
      _board.removePiece(cap.row, cap.col);
      // Move piece to next landing
      Position land = move.path[i];
      _board.movePiece(currentRow, currentCol, land.row, land.col);
      currentRow = land.row;
      currentCol = land.col;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 280));
    }

    if (gen != _gameGen) {
      _animating = false;
      return;
    }
    _animating = false;
    _finalizeMove();
    notifyListeners();
  }

  void _finalizeMove() {
    _gameState.currentPlayer = _gameState.currentPlayer == PieceColor.light
        ? PieceColor.dark
        : PieceColor.light;

    if (GameLogic.isGameOver(_board, _gameState.currentPlayer)) {
      _gameState.gameOver = true;
      _gameState.winner = _gameState.currentPlayer == PieceColor.light
          ? PieceColor.dark
          : PieceColor.light;
    }

    _updatePossibleMoves();
  }

  void _checkForAITurn() {
    if (_gameState.isAITurn && !_gameState.gameOver) {
      _makeAIMove();
    }
  }

  Future<void> _makeAIMove() async {
    final int gen = _gameGen;
    _gameState.aiThinking = true;
    notifyListeners();

    try {
      Move? aiMove = await _aiPlayer.getBestMove(_board, PieceColor.dark);

      if (gen != _gameGen) return;

      if (aiMove != null && !_gameState.gameOver) {
        // Brief pause so player sees the board before AI moves
        await Future.delayed(const Duration(milliseconds: 400));
        if (gen != _gameGen) return;
        _gameState.lastAIMove = aiMove;
        await _executeMove(aiMove);
      }
    } catch (e) {
      print('AI move error: $e');
    }

    if (gen != _gameGen) return;
    _gameState.aiThinking = false;
    notifyListeners();
  }

  _Snapshot _snapshot() {
    return _Snapshot(
      squares: _deepCopySquares(),
      currentPlayer: _gameState.currentPlayer,
      gameOver: _gameState.gameOver,
      winner: _gameState.winner,
      lastAIMove: _gameState.lastAIMove,
    );
  }

  void _restore(_Snapshot s) {
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        Piece? p = s.squares[r][c];
        _board.squares[r][c] = p == null
            ? null
            : Piece(color: p.color, type: p.type, row: r, col: c);
      }
    }
    _gameState.currentPlayer = s.currentPlayer;
    _gameState.gameOver = s.gameOver;
    _gameState.winner = s.winner;
    _gameState.lastAIMove = s.lastAIMove;
    _gameState.selectedPiece = null;
  }

  List<List<Piece?>> _deepCopySquares() {
    List<List<Piece?>> out = List.generate(8, (_) => List.filled(8, null));
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        Piece? p = _board.squares[r][c];
        if (p != null) {
          out[r][c] = Piece(color: p.color, type: p.type, row: p.row, col: p.col);
        }
      }
    }
    return out;
  }

  void undo() {
    if (!canUndo) return;
    _gameGen++;
    _gameState.aiThinking = false;

    // HVAI: pop both AI's move and player's previous move so player gets their turn back
    int popCount = (_gameState.gameMode == GameMode.humanVsAI && _undoStack.length >= 2) ? 2 : 1;
    for (int i = 0; i < popCount; i++) {
      _redoStack.add(_snapshot());
      _restore(_undoStack.removeLast());
    }
    _updatePossibleMoves();
    notifyListeners();

    // Edge case: landed on AI's turn (e.g. AI started game). AI is deterministic, replays same move.
    if (_gameState.isAITurn && !_gameState.gameOver) {
      _makeAIMove();
    }
  }

  void redo() {
    if (!canRedo) return;
    _gameGen++;
    _gameState.aiThinking = false;

    int popCount = (_gameState.gameMode == GameMode.humanVsAI && _redoStack.length >= 2) ? 2 : 1;
    for (int i = 0; i < popCount; i++) {
      _undoStack.add(_snapshot());
      _restore(_redoStack.removeLast());
    }
    _updatePossibleMoves();
    notifyListeners();

    // If after redo it's AI's turn (HVH ending on dark, or HVAI somehow), trigger AI
    if (_gameState.isAITurn && !_gameState.gameOver) {
      _makeAIMove();
    }
  }

  List<Move> getPossibleMovesForSquare(int row, int col) {
    return _gameState.possibleMoves
        .where((move) => move.toRow == row && move.toCol == col)
        .toList();
  }

  bool isSquareSelected(int row, int col) {
    return _gameState.selectedPiece != null &&
        _gameState.selectedPiece!.row == row &&
        _gameState.selectedPiece!.col == col;
  }

  bool isLastAIMove(int row, int col) {
    return _gameState.lastAIMove != null &&
        _gameState.lastAIMove!.toRow == row &&
        _gameState.lastAIMove!.toCol == col;
  }

  bool isLastAIMoveFrom(int row, int col) {
    return _gameState.lastAIMove != null &&
        _gameState.lastAIMove!.fromRow == row &&
        _gameState.lastAIMove!.fromCol == col;
  }

  int getPieceCount(PieceColor color) {
    int count = 0;
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        Piece? piece = _board.getPiece(row, col);
        if (piece != null && piece.color == color) {
          count++;
        }
      }
    }
    return count;
  }
}
