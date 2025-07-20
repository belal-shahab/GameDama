import 'dart:math';
import '../models/board.dart';
import '../models/piece.dart';
import '../models/game_state.dart';
import '../utils/game_logic.dart';
import 'ml_ai_player.dart';

enum AIDifficulty { easy, medium, hard, mlAI }

class AIPlayer {
  final AIDifficulty difficulty;
  late int _maxDepth;
  late double _randomFactor;
  MLAIPlayer? _mlPlayer;

  AIPlayer({required this.difficulty}) {
    if (difficulty == AIDifficulty.mlAI) {
      _mlPlayer = MLAIPlayer();
    } else {
      switch (difficulty) {
        case AIDifficulty.easy:
          _maxDepth = 2;
          _randomFactor = 0.3; // 30% random moves
          break;
        case AIDifficulty.medium:
          _maxDepth = 4;
          _randomFactor = 0.1; // 10% random moves
          break;
        case AIDifficulty.hard:
          _maxDepth = 6;
          _randomFactor = 0.0; // No random moves
          break;
        case AIDifficulty.mlAI:
          break;
      }
    }
  }

  Future<Move?> getBestMove(Board board, PieceColor aiColor) async {
    // Use ML AI if selected
    if (difficulty == AIDifficulty.mlAI && _mlPlayer != null) {
      return await _mlPlayer!.getBestMove(board, aiColor);
    }

    // Add delay to simulate thinking
    await Future.delayed(Duration(milliseconds: 500 + Random().nextInt(1000)));

    List<Move> possibleMoves = GameLogic.getAllPossibleMoves(board, aiColor);
    
    if (possibleMoves.isEmpty) return null;

    // For easy difficulty, sometimes make random moves
    if (_randomFactor > 0 && Random().nextDouble() < _randomFactor) {
      return possibleMoves[Random().nextInt(possibleMoves.length)];
    }

    // Use minimax algorithm for intelligent moves
    Move? bestMove;
    double bestScore = double.negativeInfinity;

    for (Move move in possibleMoves) {
      Board tempBoard = _copyBoard(board);
      _executeMove(tempBoard, move);
      
      double score = _minimax(
        tempBoard, 
        _maxDepth - 1, 
        false, 
        aiColor,
        double.negativeInfinity,
        double.infinity
      );

      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    return bestMove;
  }

  Future<void> learnFromGame(List<Move> moves, PieceColor winner, Board finalBoard) async {
    if (difficulty == AIDifficulty.mlAI && _mlPlayer != null) {
      await _mlPlayer!.learnFromGame(moves, winner, finalBoard);
    }
  }

  // Getters for ML AI stats
  int get gamesPlayed => _mlPlayer?.gamesPlayed ?? 0;
  double get winRate => _mlPlayer?.winRate ?? 0.0;
  int get patternsLearned => _mlPlayer?.patternsLearned ?? 0;

  double _minimax(Board board, int depth, bool isMaximizing, PieceColor aiColor, double alpha, double beta) {
    PieceColor currentPlayer = isMaximizing ? aiColor : (aiColor == PieceColor.dark ? PieceColor.light : PieceColor.dark);
    
    // Base cases
    if (depth == 0) {
      return _evaluateBoard(board, aiColor);
    }

    if (GameLogic.isGameOver(board, currentPlayer)) {
      if (isMaximizing) {
        return -1000.0 - depth.toDouble(); // AI loses, prefer later losses
      } else {
        return 1000.0 + depth.toDouble(); // AI wins, prefer earlier wins
      }
    }

    List<Move> moves = GameLogic.getAllPossibleMoves(board, currentPlayer);
    if (moves.isEmpty) {
      return isMaximizing ? -1000.0 - depth.toDouble() : 1000.0 + depth.toDouble();
    }

    if (isMaximizing) {
      double maxEval = double.negativeInfinity;
      for (Move move in moves) {
        Board tempBoard = _copyBoard(board);
        _executeMove(tempBoard, move);
        double eval = _minimax(tempBoard, depth - 1, false, aiColor, alpha, beta);
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break; // Alpha-beta pruning
      }
      return maxEval;
    } else {
      double minEval = double.infinity;
      for (Move move in moves) {
        Board tempBoard = _copyBoard(board);
        _executeMove(tempBoard, move);
        double eval = _minimax(tempBoard, depth - 1, true, aiColor, alpha, beta);
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break; // Alpha-beta pruning
      }
      return minEval;
    }
  }

  double _evaluateBoard(Board board, PieceColor aiColor) {
    double score = 0.0;

    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        Piece? piece = board.getPiece(row, col);
        if (piece != null) {
          double pieceValue = _getPieceValue(piece, row, col);
          
          if (piece.color == aiColor) {
            score += pieceValue;
          } else {
            score -= pieceValue;
          }
        }
      }
    }

    // Add mobility bonus (number of possible moves)
    List<Move> aiMoves = GameLogic.getAllPossibleMoves(board, aiColor);
    PieceColor opponentColor = aiColor == PieceColor.dark ? PieceColor.light : PieceColor.dark;
    List<Move> opponentMoves = GameLogic.getAllPossibleMoves(board, opponentColor);
    
    score += aiMoves.length * 0.1;
    score -= opponentMoves.length * 0.1;

    return score;
  }

  double _getPieceValue(Piece piece, int row, int col) {
    double baseValue = piece.type == PieceType.king ? 5.0 : 1.0;
    
    // Position bonus for normal pieces
    if (piece.type == PieceType.normal) {
      if (piece.color == PieceColor.dark) {
        // Dark pieces get bonus for advancing (higher row numbers)
        baseValue += (row * 0.1);
      } else {
        // Light pieces get bonus for advancing (lower row numbers)
        baseValue += ((7 - row) * 0.1);
      }
      
      // Center control bonus
      if (col >= 2 && col <= 5) {
        baseValue += 0.1;
      }
    }
    
    // King positioning bonus
    if (piece.type == PieceType.king) {
      // Kings are more valuable in the center
      int centerDistance = max((row - 3.5).abs(), (col - 3.5).abs()).round();
      baseValue += (4 - centerDistance) * 0.2;
    }

    return baseValue;
  }

  Board _copyBoard(Board original) {
    Board copy = Board();
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        Piece? piece = original.getPiece(row, col);
        if (piece != null) {
          copy.setPiece(row, col, Piece(
            color: piece.color,
            type: piece.type,
            row: row,
            col: col,
          ));
        } else {
          copy.setPiece(row, col, null);
        }
      }
    }
    return copy;
  }

  void _executeMove(Board board, Move move) {
    // Remove captured pieces
    for (Position capture in move.captures) {
      board.removePiece(capture.row, capture.col);
    }

    // Move the piece
    board.movePiece(move.fromRow, move.fromCol, move.toRow, move.toCol);
  }
}
