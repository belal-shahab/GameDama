import 'dart:math';
import 'dart:isolate';
import '../models/board.dart';
import '../models/piece.dart';
import '../models/game_state.dart';
import '../utils/game_logic.dart';

class _TTEntry {
  final double score;
  final int depth;
  final int flag; // 0=exact, 1=lowerbound, 2=upperbound
  _TTEntry(this.score, this.depth, this.flag);
}

// Serializable board data for isolate
class _BoardData {
  final List<List<int?>> squares; // null=empty, encoded: color*10 + type
  final int aiColorIndex; // 0=light, 1=dark

  _BoardData(this.squares, this.aiColorIndex);
}

class _MoveResult {
  final int fromRow, fromCol, toRow, toCol;
  final List<List<int>> captures; // [row, col] pairs

  _MoveResult(this.fromRow, this.fromCol, this.toRow, this.toCol, this.captures);
}

class AIPlayer {
  static const int _timeLimitMs = 2000;

  Future<Move?> getBestMove(Board board, PieceColor aiColor) async {
    List<Move> possibleMoves = GameLogic.getAllPossibleMoves(board, aiColor);
    if (possibleMoves.isEmpty) return null;
    if (possibleMoves.length == 1) return possibleMoves.first;

    // Serialize board for isolate
    _BoardData boardData = _serializeBoard(board, aiColor);

    // Run AI search in separate isolate — no UI freeze
    _MoveResult? result = await Isolate.run(() => _searchInIsolate(boardData));

    if (result == null) return possibleMoves.first;

    // Find matching move from possible moves
    for (Move move in possibleMoves) {
      if (move.fromRow == result.fromRow && move.fromCol == result.fromCol &&
          move.toRow == result.toRow && move.toCol == result.toCol) {
        return move;
      }
    }

    return possibleMoves.first;
  }

  static _BoardData _serializeBoard(Board board, PieceColor aiColor) {
    List<List<int?>> squares = List.generate(8, (row) {
      return List.generate(8, (col) {
        Piece? piece = board.getPiece(row, col);
        if (piece == null) return null;
        int colorVal = piece.color == PieceColor.dark ? 1 : 0;
        int typeVal = piece.type == PieceType.king ? 1 : 0;
        return colorVal * 10 + typeVal;
      });
    });
    return _BoardData(squares, aiColor == PieceColor.dark ? 1 : 0);
  }

  static _MoveResult? _searchInIsolate(_BoardData data) {
    // Reconstruct board
    Board board = Board();
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        int? val = data.squares[row][col];
        if (val != null) {
          board.setPiece(row, col, Piece(
            color: val >= 10 ? PieceColor.dark : PieceColor.light,
            type: val % 10 == 1 ? PieceType.king : PieceType.normal,
            row: row,
            col: col,
          ));
        } else {
          board.setPiece(row, col, null);
        }
      }
    }

    PieceColor aiColor = data.aiColorIndex == 1 ? PieceColor.dark : PieceColor.light;

    // Run search
    Map<int, _TTEntry> transpositionTable = {};
    Stopwatch stopwatch = Stopwatch()..start();
    bool timeUp = false;
    Random random = Random();

    List<Move> possibleMoves = GameLogic.getAllPossibleMoves(board, aiColor);
    if (possibleMoves.isEmpty) return null;
    if (possibleMoves.length == 1) {
      Move m = possibleMoves.first;
      return _MoveResult(m.fromRow, m.fromCol, m.toRow, m.toCol,
          m.captures.map((c) => [c.row, c.col]).toList());
    }

    possibleMoves = _orderMovesStatic(possibleMoves);

    Move bestMove = possibleMoves.first;
    double bestScore = double.negativeInfinity;
    Map<int, double> moveScores = {}; // index -> score

    for (int depth = 1; depth <= 30; depth++) {
      if (timeUp) break;

      Map<int, double> currentScores = {};
      double currentBest = double.negativeInfinity;
      int? currentBestIdx;

      for (int i = 0; i < possibleMoves.length; i++) {
        if (stopwatch.elapsedMilliseconds >= _timeLimitMs) {
          timeUp = true;
          break;
        }

        Move move = possibleMoves[i];
        Board tempBoard = _copyBoardStatic(board);
        _executeMoveStatic(tempBoard, move);

        double score = _minimaxStatic(
          tempBoard, depth - 1, false, aiColor,
          double.negativeInfinity, double.infinity,
          transpositionTable, stopwatch, _timeLimitMs,
        );

        if (stopwatch.elapsedMilliseconds >= _timeLimitMs) {
          timeUp = true;
          break;
        }

        currentScores[i] = score;

        if (score > currentBest) {
          currentBest = score;
          currentBestIdx = i;
        }
      }

      if (!timeUp && currentBestIdx != null) {
        bestScore = currentBest;
        bestMove = possibleMoves[currentBestIdx];
        moveScores = Map.from(currentScores);
      }
    }

    // Near-equal randomness
    if (moveScores.isNotEmpty) {
      List<int> topIndices = [];
      for (var entry in moveScores.entries) {
        if (entry.value >= bestScore - 1.0) {
          topIndices.add(entry.key);
        }
      }
      if (topIndices.isNotEmpty) {
        bestMove = possibleMoves[topIndices[random.nextInt(topIndices.length)]];
      }
    }

    return _MoveResult(bestMove.fromRow, bestMove.fromCol, bestMove.toRow, bestMove.toCol,
        bestMove.captures.map((c) => [c.row, c.col]).toList());
  }

  static List<Move> _orderMovesStatic(List<Move> moves) {
    moves.sort((a, b) {
      int capDiff = b.captures.length.compareTo(a.captures.length);
      if (capDiff != 0) return capDiff;
      int aCenter = _centerScoreStatic(a.toRow, a.toCol);
      int bCenter = _centerScoreStatic(b.toRow, b.toCol);
      return bCenter.compareTo(aCenter);
    });
    return moves;
  }

  static int _centerScoreStatic(int row, int col) {
    int rowDist = (row - 3).abs() + (row - 4).abs();
    int colDist = (col - 3).abs() + (col - 4).abs();
    return 14 - rowDist - colDist;
  }

  static double _minimaxStatic(Board board, int depth, bool isMaximizing, PieceColor aiColor,
      double alpha, double beta, Map<int, _TTEntry> tt, Stopwatch sw, int timeLimit) {
    if (sw.elapsedMilliseconds >= timeLimit) return 0.0;

    PieceColor currentPlayer = isMaximizing
        ? aiColor
        : (aiColor == PieceColor.dark ? PieceColor.light : PieceColor.dark);

    int hash = _hashBoardStatic(board, isMaximizing);
    _TTEntry? cached = tt[hash];
    if (cached != null && cached.depth >= depth) {
      if (cached.flag == 0) return cached.score;
      if (cached.flag == 1 && cached.score >= beta) return cached.score;
      if (cached.flag == 2 && cached.score <= alpha) return cached.score;
    }

    if (depth == 0) {
      double score = _evaluateBoardStatic(board, aiColor);
      tt[hash] = _TTEntry(score, depth, 0);
      return score;
    }

    List<Move> moves = GameLogic.getAllPossibleMoves(board, currentPlayer);

    if (moves.isEmpty || GameLogic.isGameOver(board, currentPlayer)) {
      double score = isMaximizing ? -10000.0 - depth : 10000.0 + depth;
      tt[hash] = _TTEntry(score, depth, 0);
      return score;
    }

    moves = _orderMovesStatic(moves);

    if (depth > 4 && moves.length > 10) {
      moves = moves.take(10).toList();
    }

    double origAlpha = alpha;

    if (isMaximizing) {
      double maxEval = double.negativeInfinity;
      for (Move move in moves) {
        if (sw.elapsedMilliseconds >= timeLimit) return 0.0;
        Board tempBoard = _copyBoardStatic(board);
        _executeMoveStatic(tempBoard, move);
        double eval = _minimaxStatic(tempBoard, depth - 1, false, aiColor, alpha, beta, tt, sw, timeLimit);
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break;
      }
      int flag = maxEval <= origAlpha ? 2 : (maxEval >= beta ? 1 : 0);
      tt[hash] = _TTEntry(maxEval, depth, flag);
      return maxEval;
    } else {
      double minEval = double.infinity;
      for (Move move in moves) {
        if (sw.elapsedMilliseconds >= timeLimit) return 0.0;
        Board tempBoard = _copyBoardStatic(board);
        _executeMoveStatic(tempBoard, move);
        double eval = _minimaxStatic(tempBoard, depth - 1, true, aiColor, alpha, beta, tt, sw, timeLimit);
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break;
      }
      int flag = minEval >= beta ? 1 : (minEval <= origAlpha ? 2 : 0);
      tt[hash] = _TTEntry(minEval, depth, flag);
      return minEval;
    }
  }

  static double _evaluateBoardStatic(Board board, PieceColor aiColor) {
    PieceColor enemyColor = aiColor == PieceColor.dark ? PieceColor.light : PieceColor.dark;
    double score = 0.0;
    int aiPieces = 0;
    int enemyPieces = 0;

    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        Piece? piece = board.getPiece(row, col);
        if (piece == null) continue;

        bool isAI = piece.color == aiColor;
        double pieceScore = 0.0;

        pieceScore += piece.type == PieceType.king ? 30.0 : 10.0;

        if (piece.type == PieceType.normal) {
          if (piece.color == PieceColor.dark) {
            pieceScore += row * 0.5;
          } else {
            pieceScore += (7 - row) * 0.5;
          }
        }

        if (col >= 2 && col <= 5 && row >= 2 && row <= 5) {
          pieceScore += 1.5;
        }

        if (piece.type == PieceType.normal) {
          if ((piece.color == PieceColor.dark && row <= 1) ||
              (piece.color == PieceColor.light && row >= 6)) {
            pieceScore += 2.0;
          }
        }

        if (_hasFriendlyNeighborStatic(board, row, col, piece.color)) {
          pieceScore += 1.0;
        }

        if (piece.type == PieceType.king) {
          if (row >= 2 && row <= 5 && col >= 2 && col <= 5) {
            pieceScore += 3.0;
          }
        }

        if (_isUnderThreatStatic(board, row, col, piece)) {
          pieceScore -= piece.type == PieceType.king ? 12.0 : 4.0;
        }

        if (isAI) {
          score += pieceScore;
          aiPieces++;
        } else {
          score -= pieceScore;
          enemyPieces++;
        }
      }
    }

    List<Move> aiMoves = GameLogic.getAllPossibleMoves(board, aiColor);
    List<Move> enemyMoves = GameLogic.getAllPossibleMoves(board, enemyColor);
    score += (aiMoves.length - enemyMoves.length) * 0.5;

    if (enemyPieces == 0) score += 10000.0;
    if (aiPieces == 0) score -= 10000.0;

    return score;
  }

  static bool _hasFriendlyNeighborStatic(Board board, int row, int col, PieceColor color) {
    const dirs = [[-1, 0], [1, 0], [0, -1], [0, 1]];
    for (var dir in dirs) {
      int nr = row + dir[0];
      int nc = col + dir[1];
      if (nr >= 0 && nr < 8 && nc >= 0 && nc < 8) {
        Piece? neighbor = board.getPiece(nr, nc);
        if (neighbor != null && neighbor.color == color) return true;
      }
    }
    return false;
  }

  static bool _isUnderThreatStatic(Board board, int row, int col, Piece piece) {
    PieceColor enemyColor = piece.color == PieceColor.dark ? PieceColor.light : PieceColor.dark;
    const dirs = [[-1, 0], [1, 0], [0, -1], [0, 1]];

    for (var dir in dirs) {
      int attackRow = row - dir[0];
      int attackCol = col - dir[1];
      int landRow = row + dir[0];
      int landCol = col + dir[1];

      if (attackRow < 0 || attackRow >= 8 || attackCol < 0 || attackCol >= 8) continue;
      if (landRow < 0 || landRow >= 8 || landCol < 0 || landCol >= 8) continue;

      Piece? attacker = board.getPiece(attackRow, attackCol);
      Piece? landSquare = board.getPiece(landRow, landCol);

      if (attacker != null && attacker.color == enemyColor && landSquare == null) {
        if (attacker.type == PieceType.normal) {
          int forward = attacker.color == PieceColor.light ? -1 : 1;
          int dr = dir[0];
          if (dr == forward || dir[1] != 0) return true;
        } else {
          return true;
        }
      }

      if (attacker == null) {
        int checkR = attackRow - dir[0];
        int checkC = attackCol - dir[1];
        while (checkR >= 0 && checkR < 8 && checkC >= 0 && checkC < 8) {
          Piece? farPiece = board.getPiece(checkR, checkC);
          if (farPiece != null) {
            if (farPiece.color == enemyColor && farPiece.type == PieceType.king && landSquare == null) {
              return true;
            }
            break;
          }
          checkR -= dir[0];
          checkC -= dir[1];
        }
      }
    }
    return false;
  }

  static int _hashBoardStatic(Board board, bool isMaximizing) {
    int hash = isMaximizing ? 1 : 0;
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        Piece? piece = board.getPiece(row, col);
        if (piece != null) {
          int pieceVal = (piece.color == PieceColor.dark ? 1 : 2) +
              (piece.type == PieceType.king ? 4 : 0);
          hash = hash * 31 + (row * 8 + col) * 7 + pieceVal;
        }
      }
    }
    return hash;
  }

  static Board _copyBoardStatic(Board original) {
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

  static void _executeMoveStatic(Board board, Move move) {
    for (Position capture in move.captures) {
      board.removePiece(capture.row, capture.col);
    }
    board.movePiece(move.fromRow, move.fromCol, move.toRow, move.toCol);
  }
}
