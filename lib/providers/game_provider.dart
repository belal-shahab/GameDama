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
  
  // Game statistics
  double _lastMoveScore = 0.0;
  int _humanCapturedPieces = 0;
  int _aiCapturedPieces = 0;
  int _humanStartingPieces = 16;
  int _aiStartingPieces = 16;

  Board get board => _board;
  GameState get gameState => _gameState;
  AIPlayer? get aiPlayer => _aiPlayer;

  GameProvider() {
    startNewGame();
  }

  void startNewGame({GameMode gameMode = GameMode.humanVsHuman, AIDifficulty aiDifficulty = AIDifficulty.medium}) {
    _board = Board();
    _gameHistory = []; // Reset game history
    
    // Reset statistics
    _lastMoveScore = 0.0;
    _humanCapturedPieces = 0;
    _aiCapturedPieces = 0;
    _humanStartingPieces = 16;
    _aiStartingPieces = 16;
    
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
    // Calculate move score before executing
    _lastMoveScore = _calculateMoveScore(move);
    
    // Print move details for clarity
    String currentPlayerName = _gameState.currentPlayer == PieceColor.light ? 'Human' : 'AI';
    print('$currentPlayerName move scored: ${_lastMoveScore.toInt()} points');
    
    // Track captures
    if (move.captures.isNotEmpty) {
      if (_gameState.currentPlayer == PieceColor.light) {
        _humanCapturedPieces += move.captures.length;
        print('Human captured ${move.captures.length} pieces');
      } else {
        _aiCapturedPieces += move.captures.length;
        print('AI captured ${move.captures.length} pieces');
      }
    }

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

  double _calculateMoveScore(Move move) {
    double score = 0.0;
    String scoreBreakdown = '';
    
    // Capture bonus
    if (move.captures.isNotEmpty) {
      double captureScore = move.captures.length * 50.0;
      score += captureScore;
      scoreBreakdown += 'Capture(${move.captures.length}): +${captureScore.toInt()} ';
      
      // Check if capturing kings
      for (Position capture in move.captures) {
        Piece? capturedPiece = _board.getPiece(capture.row, capture.col);
        if (capturedPiece?.type == PieceType.king) {
          score += 100.0; // Extra bonus for capturing kings
          scoreBreakdown += 'King captured: +100 ';
        }
      }
    }
    
    // Position improvement
    Piece? movingPiece = _board.getPiece(move.fromRow, move.fromCol);
    if (movingPiece != null) {
      // Advancement bonus
      if (movingPiece.type == PieceType.normal) {
        double advancementScore = 0.0;
        if (movingPiece.color == PieceColor.dark) {
          advancementScore = (move.toRow - move.fromRow) * 5.0;
        } else {
          advancementScore = (move.fromRow - move.toRow) * 5.0;
        }
        if (advancementScore > 0) {
          score += advancementScore;
          scoreBreakdown += 'Advance: +${advancementScore.toInt()} ';
        }
      }
      
      // Center control bonus
      if (move.toCol >= 2 && move.toCol <= 5 && move.toRow >= 2 && move.toRow <= 5) {
        score += 10.0;
        scoreBreakdown += 'Center: +10 ';
      }
      
      // King promotion check
      if (movingPiece.type == PieceType.normal) {
        if ((movingPiece.color == PieceColor.light && move.toRow == 0) ||
            (movingPiece.color == PieceColor.dark && move.toRow == 7)) {
          score += 200.0; // King promotion bonus
          scoreBreakdown += 'PROMOTION: +200 ';
        }
      }
    }
    
    // Print score breakdown for debugging
    if (scoreBreakdown.isNotEmpty) {
      print('Score breakdown: $scoreBreakdown= ${score.toInt()} total');
    }
    
    return score;
  }

  // Getters for statistics
  double get lastMoveScore => _lastMoveScore;
  int get humanCapturedPieces => _humanCapturedPieces;
  int get aiCapturedPieces => _aiCapturedPieces;
  int get humanRemainingPieces => _humanStartingPieces - _aiCapturedPieces;
  int get aiRemainingPieces => _aiStartingPieces - _humanCapturedPieces;

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