import 'dart:math';
import '../models/board.dart';
import '../models/piece.dart';
import '../models/game_state.dart';
import '../utils/game_logic.dart';
import 'ml_ai_player.dart';

enum AIDifficulty { easy, medium, hard, expert, master, mlAI }

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
          _maxDepth = 2;        // 2 moves ahead - fast
          _randomFactor = 0.3;  // 30% random moves
          break;
        case AIDifficulty.medium:
          _maxDepth = 4;        // 4 moves ahead - good balance
          _randomFactor = 0.1;  // 10% random moves
          break;
        case AIDifficulty.hard:
          _maxDepth = 6;        // 6 moves ahead - strong but fast
          _randomFactor = 0.0;  // No random moves
          break;
        case AIDifficulty.expert:
          _maxDepth = 8;        // 8 moves ahead - very strong
          _randomFactor = 0.0;  // Perfect play
          break;
        case AIDifficulty.master:
          _maxDepth = 10;       // 10 moves ahead - maximum practical depth
          _randomFactor = 0.0;  // Computer perfection
          break;
        case AIDifficulty.mlAI:
          break;
      }
    }
  }

  double _evaluateBoard(Board board, PieceColor aiColor) {
    double score = 0.0;

    // Quick evaluation - count pieces and basic positioning
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        Piece? piece = board.getPiece(row, col);
        if (piece != null) {
          double pieceValue = piece.type == PieceType.king ? 5.0 : 1.0;
          
          // Simple position bonus
          if (piece.type == PieceType.normal) {
            if (piece.color == PieceColor.dark) {
              pieceValue += row * 0.1; // Advancement bonus
            } else {
              pieceValue += (7 - row) * 0.1;
            }
            
            // SAFETY CHECK: Don't advance pieces that can be easily captured
            if (_isPieceInDanger(board, row, col, piece.color)) {
              pieceValue -= 2.0; // Penalty for dangerous positions
            }
          }
          
          // King safety is CRITICAL
          if (piece.type == PieceType.king) {
            if (_isPieceInDanger(board, row, col, piece.color)) {
              pieceValue -= 10.0; // HUGE penalty for king in danger
            }
          }
          
          if (piece.color == aiColor) {
            score += pieceValue;
          } else {
            score -= pieceValue;
          }
        }
      }
    }

    // Quick mobility check - only for shallow depths
    if (_maxDepth <= 6) {
      List<Move> aiMoves = GameLogic.getAllPossibleMoves(board, aiColor);
      score += aiMoves.length * 0.1;
    }

    return score;
  }

  // NEW METHOD: Check if piece is in danger
  bool _isPieceInDanger(Board board, int row, int col, PieceColor pieceColor) {
    PieceColor enemyColor = pieceColor == PieceColor.dark ? PieceColor.light : PieceColor.dark;
    
    // Check if any enemy piece can capture this piece
    List<Move> enemyMoves = GameLogic.getAllPossibleMoves(board, enemyColor);
    
    for (Move move in enemyMoves) {
      for (Position capture in move.captures) {
        if (capture.row == row && capture.col == col) {
          return true; // This piece can be captured!
        }
      }
    }
    
    return false;
  }

  Future<Move?> getBestMove(Board board, PieceColor aiColor) async {
    // Use ML AI if selected
    if (difficulty == AIDifficulty.mlAI && _mlPlayer != null) {
      return await _mlPlayer!.getBestMove(board, aiColor);
    }

    // ADAPTIVE DEPTH: Reduce depth in complex positions
    int adaptiveDepth = _maxDepth;
    List<Move> possibleMoves = GameLogic.getAllPossibleMoves(board, aiColor);
    
    // If too many moves available, reduce depth to prevent "analysis paralysis"
    if (possibleMoves.length > 12) {
      adaptiveDepth = max(4, _maxDepth - 2);
    }
    
    // If it's early game (many pieces), use less depth
    int totalPieces = _countTotalPieces(board);
    if (totalPieces > 20) {
      adaptiveDepth = max(4, _maxDepth - 1);
    }

    // Optimized thinking time
    int thinkingTime = 300 + (adaptiveDepth * 100) + Random().nextInt(200);
    await Future.delayed(Duration(milliseconds: thinkingTime));
    
    if (possibleMoves.isEmpty) return null;

    // For easy difficulty, sometimes make random moves
    if (_randomFactor > 0 && Random().nextDouble() < _randomFactor) {
      return possibleMoves[Random().nextInt(possibleMoves.length)];
    }

    // SMART MOVE FILTERING: Prioritize safe moves
    List<Move> safeMoves = [];
    List<Move> riskyMoves = [];
    
    for (Move move in possibleMoves) {
      Board tempBoard = _copyBoard(board);
      _executeMove(tempBoard, move);
      
      // Check if the moved piece will be in danger
      bool willBeInDanger = _isPieceInDanger(tempBoard, move.toRow, move.toCol, aiColor);
      
      if (willBeInDanger && move.captures.isEmpty) {
        riskyMoves.add(move); // Risky non-capture moves
      } else {
        safeMoves.add(move); // Safe moves or capture moves
      }
    }

    // Prefer safe moves unless forced to make risky ones
    List<Move> movesToConsider = safeMoves.isNotEmpty ? safeMoves : possibleMoves;

    // Prioritize capture moves to reduce search space
    List<Move> captureMoves = movesToConsider.where((m) => m.captures.isNotEmpty).toList();
    if (captureMoves.isNotEmpty) {
      movesToConsider = captureMoves;
    }

    // Use iterative deepening for better performance
    Move? bestMove = movesToConsider.first;
    double bestScore = double.negativeInfinity;
    
    try {
      for (int depth = 1; depth <= adaptiveDepth; depth++) {
        for (Move move in movesToConsider) {
          Board tempBoard = _copyBoard(board);
          _executeMove(tempBoard, move);
          
          double score = _minimax(
            tempBoard, 
            depth - 1, 
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
        
        // Early exit for obvious moves
        if (depth >= 4 && captureMoves.isNotEmpty && captureMoves.length == 1) {
          break;
        }
      }
      
      // Print AI's move analysis
      String moveDescription = '';
      if (bestMove != null) {
        if (bestMove!.captures.isNotEmpty) {
          moveDescription = 'AI captures ${bestMove!.captures.length} pieces';
        } else {
          moveDescription = 'AI makes safe positional move';
        }
      }
      print('🤖 $moveDescription (depth: $adaptiveDepth, eval: ${bestScore.toInt()})');
      
    } catch (e) {
      print('AI search interrupted, using best move found so far');
    }

    return bestMove;
  }

  int _countTotalPieces(Board board) {
    int count = 0;
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        if (board.getPiece(row, col) != null) count++;
      }
    }
    return count;
  }

  Move? _findBestMoveAtDepth(Board board, List<Move> moves, PieceColor aiColor, int depth) {
    Move? bestMove;
    double bestScore = double.negativeInfinity;
    int nodesEvaluated = 0;
    const int maxNodes = 50000; // Limit to prevent crashes

    for (Move move in moves) {
      if (nodesEvaluated > maxNodes) break; // Safety limit
      
      Board tempBoard = _copyBoard(board);
      _executeMove(tempBoard, move);
      
      double score = _minimax(
        tempBoard, 
        depth - 1, 
        false, 
        aiColor,
        double.negativeInfinity,
        double.infinity
      );

      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
      
      nodesEvaluated++;
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
        return -1000.0 - depth.toDouble();
      } else {
        return 1000.0 + depth.toDouble();
      }
    }

    List<Move> moves = GameLogic.getAllPossibleMoves(board, currentPlayer);
    if (moves.isEmpty) {
      return isMaximizing ? -1000.0 - depth.toDouble() : 1000.0 + depth.toDouble();
    }

    // Move ordering optimization - prioritize captures
    moves.sort((a, b) => b.captures.length.compareTo(a.captures.length));
    
    // Limit moves in deep search to prevent explosion
    if (depth > 4 && moves.length > 8) {
      moves = moves.take(8).toList();
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
