import 'package:flutter/material.dart';
import 'dart:math';
import '../models/board.dart';
import '../models/game_state.dart';
import '../models/piece.dart';
import '../utils/game_logic.dart';
import '../services/ai_player.dart';

class GameProvider extends ChangeNotifier {
  late Board _board;
  late GameState _gameState;
  late AIPlayer _aiPlayer;
  List<Move> _gameHistory = [];

  Board get board => _board;
  GameState get gameState => _gameState;
  AIPlayer? get aiPlayer => _aiPlayer;

  GameProvider() {
    startNewGame();
  }

  void startNewGame({GameMode gameMode = GameMode.humanVsHuman, AIDifficulty aiDifficulty = AIDifficulty.medium}) {
    _board = Board();
    _gameHistory = []; // Reset game history
    final random = Random();
    final randomPlayer = random.nextBool() ? PieceColor.light : PieceColor.dark;
    _gameState = GameState(
      currentPlayer: randomPlayer,
      gameMode: gameMode,
      aiDifficulty: aiDifficulty,
    );
    _aiPlayer = AIPlayer(difficulty: aiDifficulty);
    _updatePossibleMoves();
    notifyListeners();

    // If AI starts first, trigger AI move
    if (_gameState.isAITurn) {
      _makeAIMove();
    }
  }

  void selectPiece(int row, int col) {
    // Don't allow human moves during AI turn
    if (_gameState.isAITurn || _gameState.aiThinking) return;

    Piece? piece = _board.getPiece(row, col);

    if (piece != null && piece.color == _gameState.currentPlayer) {
      _gameState.selectedPiece = Position(row, col);
      _updatePossibleMovesForSelectedPiece();
    } else if (_gameState.selectedPiece != null) {
      Move? validMove = _findValidMove(row, col);
      if (validMove != null) {
        _executeMove(validMove);
        _checkForAITurn();
      } else {
        _gameState.selectedPiece = null;
        _gameState.possibleMoves = [];
      }
    }

    notifyListeners();
  }

  void _updatePossibleMoves() {
    _gameState.possibleMoves = GameLogic.getAllPossibleMoves(_board, _gameState.currentPlayer);
  }

  void _updatePossibleMovesForSelectedPiece() {
    if (_gameState.selectedPiece != null) {
      Piece? piece = _board.getPiece(
          _gameState.selectedPiece!.row,
          _gameState.selectedPiece!.col
      );

      if (piece != null) {
        // Get all possible moves for the current player
        List<Move> allPlayerMoves = GameLogic.getAllPossibleMoves(_board, _gameState.currentPlayer);

        // Filter moves for the selected piece
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

  void _executeMove(Move move) {
    // Add move to history for ML learning
    _gameHistory.add(move);

    // Execute captures
    for (Position capture in move.captures) {
      _board.removePiece(capture.row, capture.col);
    }

    // Move the piece
    _board.movePiece(move.fromRow, move.fromCol, move.toRow, move.toCol);

    // Switch turns
    _gameState.currentPlayer = _gameState.currentPlayer == PieceColor.light
        ? PieceColor.dark
        : PieceColor.light;

    _gameState.selectedPiece = null;
    _gameState.possibleMoves = [];
    _gameState.lastAIMove = null;

    // Check for game over
    if (GameLogic.isGameOver(_board, _gameState.currentPlayer)) {
      _gameState.gameOver = true;
      _gameState.winner = _gameState.currentPlayer == PieceColor.light
          ? PieceColor.dark
          : PieceColor.light;
      
      // Let ML AI learn from the completed game
      if (_gameState.gameMode == GameMode.humanVsAI && 
          _gameState.aiDifficulty == AIDifficulty.mlAI) {
        _aiPlayer.learnFromGame(_gameHistory, _gameState.winner!, _board);
      }
    }
  }

  void _checkForAITurn() {
    if (_gameState.isAITurn && !_gameState.gameOver) {
      _makeAIMove();
    }
  }

  Future<void> _makeAIMove() async {
    _gameState.aiThinking = true;
    notifyListeners();

    try {
      Move? aiMove = await _aiPlayer.getBestMove(_board, PieceColor.dark);
      
      if (aiMove != null && !_gameState.gameOver) {
        _gameState.lastAIMove = aiMove;
        _executeMove(aiMove);
      }
    } catch (e) {
      print('AI move error: $e');
    }

    _gameState.aiThinking = false;
    notifyListeners();
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