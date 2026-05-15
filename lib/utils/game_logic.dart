import '../models/piece.dart';
import '../models/board.dart';
import '../models/game_state.dart';

class GameLogic {
  static List<Move> getAllPossibleMoves(Board board, PieceColor player) {
    List<Move> allMoves = [];
    List<Move> captureMoves = [];

    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        Piece? piece = board.getPiece(row, col);
        if (piece != null && piece.color == player) {
          List<Move> pieceMoves = getPossibleMovesForPiece(board, piece);
          for (Move move in pieceMoves) {
            if (move.captures.isNotEmpty) {
              captureMoves.add(move);
            } else {
              allMoves.add(move);
            }
          }
        }
      }
    }

    // Capturing is mandatory - return only capture moves if available
    if (captureMoves.isNotEmpty) {
      // Find the maximum number of captures
      int maxCaptures = 0;
      for (Move move in captureMoves) {
        if (move.captures.length > maxCaptures) {
          maxCaptures = move.captures.length;
        } 
      }
      // Return only moves with maximum captures
      return captureMoves.where((move) => move.captures.length == maxCaptures).toList();
    }

    return allMoves;
  }

  static List<Move> getPossibleMovesForPiece(Board board, Piece piece) {
    if (piece.type == PieceType.normal) {
      return getNormalPieceMoves(board, piece);
    } else {
      return getKingMoves(board, piece);
    }
  }

  static List<Move> getNormalPieceMoves(Board board, Piece piece) {
    List<Move> moves = [];
    List<Move> captureMoves = [];

    // Turkish Dama - Men can ONLY move forward, left, right (NO backward, NO diagonal)
    int forward = piece.color == PieceColor.light ? -1 : 1;
    List<List<int>> directions = [
      [forward, 0], // forward
      [0, -1],      // left
      [0, 1],       // right
    ];

    // Check captures first - men can capture in forward, left, right directions only
    for (var dir in directions) {
      List<Move> captures = checkNormalCaptureInDirection(board, piece, piece.row, piece.col, dir, [], [], null);
      captureMoves.addAll(captures);
    }

    if (captureMoves.isNotEmpty) {
      // Find maximum capture length
      int maxCaptures = 0;
      for (Move move in captureMoves) {
        if (move.captures.length > maxCaptures) {
          maxCaptures = move.captures.length;
        }
      }
      return captureMoves.where((move) => move.captures.length == maxCaptures).toList();
    }

    // Normal moves - one square in forward, left, right directions only
    for (var dir in directions) {
      int newRow = piece.row + dir[0];
      int newCol = piece.col + dir[1];

      if (isValidSquare(newRow, newCol) && board.getPiece(newRow, newCol) == null) {
        moves.add(Move(
          fromRow: piece.row,
          fromCol: piece.col,
          toRow: newRow,
          toCol: newCol,
        ));
      }
    }

    return moves;
  }

  static List<Move> checkNormalCaptureInDirection(Board board, Piece originalPiece, int currentRow, int currentCol, List<int> direction, List<Position> capturedSoFar, List<Position> pathSoFar, List<int>? lastDirection) {
    List<Move> allCaptures = [];

    // No-reverse rule: if previous capture was in the same line, can't immediately reverse.
    if (lastDirection != null &&
        direction[0] == -lastDirection[0] &&
        direction[1] == -lastDirection[1]) {
      return allCaptures;
    }

    int enemyRow = currentRow + direction[0];
    int enemyCol = currentCol + direction[1];
    int landRow = currentRow + 2 * direction[0];
    int landCol = currentCol + 2 * direction[1];

    if (!isValidSquare(enemyRow, enemyCol) || !isValidSquare(landRow, landCol)) {
      return allCaptures;
    }

    Piece? enemyPiece = board.getPiece(enemyRow, enemyCol);
    Piece? landPiece = board.getPiece(landRow, landCol);

    // Check if this enemy was already captured in this chain
    bool alreadyCaptured = capturedSoFar.any((pos) => pos.row == enemyRow && pos.col == enemyCol);

    if (enemyPiece != null &&
        enemyPiece.color != originalPiece.color &&
        landPiece == null &&
        !alreadyCaptured) {

      // Create new captured list
      List<Position> newCaptured = List.from(capturedSoFar);
      newCaptured.add(Position(enemyRow, enemyCol));

      List<Position> newPath = List.from(pathSoFar);
      newPath.add(Position(landRow, landCol));

      // Create temporary board for recursive check
      Board tempBoard = Board();
      for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) {
          tempBoard.squares[i][j] = board.squares[i][j];
        }
      }

      // Remove captured pieces from temp board
      for (Position pos in newCaptured) {
        tempBoard.removePiece(pos.row, pos.col);
      }

      // Check for additional captures from landing position (carry direction for no-reverse rule)
      List<Move> furtherCaptures = checkNormalCaptureChain(tempBoard, originalPiece, landRow, landCol, newCaptured, newPath, direction);

      if (furtherCaptures.isEmpty) {
        // No more captures, this is a complete capture chain
        allCaptures.add(Move(
          fromRow: originalPiece.row,
          fromCol: originalPiece.col,
          toRow: landRow,
          toCol: landCol,
          captures: newCaptured,
          path: newPath,
        ));
      } else {
        // Add all further capture chains
        allCaptures.addAll(furtherCaptures);
      }
    }

    return allCaptures;
  }

  static List<Move> checkNormalCaptureChain(Board board, Piece originalPiece, int currentRow, int currentCol, List<Position> capturedSoFar, List<Position> pathSoFar, List<int>? lastDirection) {
    List<Move> allCaptures = [];

    // Turkish Dama - Men can capture in forward, left, right directions only
    int forward = originalPiece.color == PieceColor.light ? -1 : 1;
    List<List<int>> directions = [
      [forward, 0], // forward
      [0, -1],      // left
      [0, 1],       // right
    ];

    for (var dir in directions) {
      List<Move> captures = checkNormalCaptureInDirection(board, originalPiece, currentRow, currentCol, dir, capturedSoFar, pathSoFar, lastDirection);
      allCaptures.addAll(captures);
    }

    return allCaptures;
  }

  static List<Move> getKingMoves(Board board, Piece piece) {
    List<Move> moves = [];
    List<Move> captureMoves = [];

    // Turkish Dama - Kings move orthogonally (like rooks) - forward, backward, left, right
    List<List<int>> directions = [
      [-1, 0], // up
      [1, 0],  // down
      [0, -1], // left
      [0, 1],  // right
    ];

    // Check captures with chain
    List<Move> captures = checkKingCaptureChain(board, piece, piece.row, piece.col, [], [], null);
    captureMoves.addAll(captures);

    if (captureMoves.isNotEmpty) {
      // Find maximum capture length
      int maxCaptures = 0;
      for (Move move in captureMoves) {
        if (move.captures.length > maxCaptures) {
          maxCaptures = move.captures.length;
        }
      }
      return captureMoves.where((move) => move.captures.length == maxCaptures).toList();
    }

    // Normal moves if no captures - Kings can move multiple squares orthogonally
    for (var dir in directions) {
      int steps = 1;
      while (true) {
        int newRow = piece.row + steps * dir[0];
        int newCol = piece.col + steps * dir[1];

        if (!isValidSquare(newRow, newCol)) break;

        Piece? targetPiece = board.getPiece(newRow, newCol);
        if (targetPiece == null) {
          moves.add(Move(
            fromRow: piece.row,
            fromCol: piece.col,
            toRow: newRow,
            toCol: newCol,
          ));
          steps++;
        } else {
          break;
        }
      }
    }

    return moves;
  }

  static List<Move> checkKingCaptureChain(Board board, Piece originalPiece, int currentRow, int currentCol, List<Position> capturedSoFar, List<Position> pathSoFar, List<int>? lastDirection) {
    List<Move> allCaptures = [];

    List<List<int>> directions = [
      [-1, 0], // up
      [1, 0],  // down
      [0, -1], // left
      [0, 1],  // right
    ];

    for (var dir in directions) {
      // No-reverse rule: a king cannot immediately reverse direction on the same line.
      if (lastDirection != null &&
          dir[0] == -lastDirection[0] &&
          dir[1] == -lastDirection[1]) {
        continue;
      }

      int steps = 1;
      Piece? enemyFound = null;
      int enemyRow = -1;
      int enemyCol = -1;

      // Find enemy piece in this direction
      while (true) {
        int checkRow = currentRow + steps * dir[0];
        int checkCol = currentCol + steps * dir[1];

        if (!isValidSquare(checkRow, checkCol)) break;

        Piece? checkPiece = board.getPiece(checkRow, checkCol);

        if (checkPiece != null) {
          bool alreadyCaptured = capturedSoFar.any((pos) => pos.row == checkRow && pos.col == checkCol);

          if (!alreadyCaptured && checkPiece.color != originalPiece.color && enemyFound == null) {
            enemyFound = checkPiece;
            enemyRow = checkRow;
            enemyCol = checkCol;
          } else {
            break; // Can't jump over own piece or multiple enemies
          }
        }

        if (enemyFound != null) {
          // Found enemy, now check landing positions
          int landSteps = steps + 1;
          while (true) {
            int landRow = currentRow + landSteps * dir[0];
            int landCol = currentCol + landSteps * dir[1];

            if (!isValidSquare(landRow, landCol)) break;

            if (board.getPiece(landRow, landCol) == null) {
              // Valid landing position
              List<Position> newCaptured = List.from(capturedSoFar);
              newCaptured.add(Position(enemyRow, enemyCol));

              List<Position> newPath = List.from(pathSoFar);
              newPath.add(Position(landRow, landCol));

              // Create temporary board
              Board tempBoard = Board();
              for (int i = 0; i < 8; i++) {
                for (int j = 0; j < 8; j++) {
                  tempBoard.squares[i][j] = board.squares[i][j];
                }
              }

              // Remove captured pieces
              for (Position pos in newCaptured) {
                tempBoard.removePiece(pos.row, pos.col);
              }

              // Check for additional captures (carry direction for no-reverse rule)
              List<Move> furtherCaptures = checkKingCaptureChain(tempBoard, originalPiece, landRow, landCol, newCaptured, newPath, dir);

              if (furtherCaptures.isEmpty) {
                allCaptures.add(Move(
                  fromRow: originalPiece.row,
                  fromCol: originalPiece.col,
                  toRow: landRow,
                  toCol: landCol,
                  captures: newCaptured,
                  path: newPath,
                ));
              } else {
                allCaptures.addAll(furtherCaptures);
              }

              landSteps++;
            } else {
              break;
            }
          }
          break;
        }

        steps++;
      }
    }

    return allCaptures;
  }

  static bool isValidSquare(int row, int col) {
    return row >= 0 && row < 8 && col >= 0 && col < 8;
  }

  static bool isGameOver(Board board, PieceColor nextPlayer) {
    // Check if player has any pieces left
    bool hasPieces = false;
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        Piece? piece = board.getPiece(row, col);
        if (piece != null && piece.color == nextPlayer) {
          hasPieces = true;
          break;
        }
      }
      if (hasPieces) break;
    }

    if (!hasPieces) return true;

    // Check if player has any legal moves
    return getAllPossibleMoves(board, nextPlayer).isEmpty;
  }
}