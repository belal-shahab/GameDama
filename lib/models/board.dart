import 'piece.dart';

class Board {
  late List<List<Piece?>> squares;

  Board() {
    initializeBoard();
  }

  void initializeBoard() {
    squares = List.generate(8, (_) => List.filled(8, null));

    // Turkish Dama setup - Black pieces on rows 1 and 2
    for (int row = 1; row < 3; row++) {
      for (int col = 0; col < 8; col++) {
        squares[row][col] = Piece(
          color: PieceColor.dark,
          type: PieceType.normal,
          row: row,
          col: col,
        );
      }
    }

    // White pieces on rows 5 and 6
    for (int row = 5; row < 7; row++) {
      for (int col = 0; col < 8; col++) {
        squares[row][col] = Piece(
          color: PieceColor.light,
          type: PieceType.normal,
          row: row,
          col: col,
        );
      }
    }
  }

  Piece? getPiece(int row, int col) {
    if (row < 0 || row >= 8 || col < 0 || col >= 8) return null;
    return squares[row][col];
  }

  void setPiece(int row, int col, Piece? piece) {
    if (row >= 0 && row < 8 && col >= 0 && col < 8) {
      squares[row][col] = piece;
    }
  }

  void movePiece(int fromRow, int fromCol, int toRow, int toCol) {
    Piece? piece = getPiece(fromRow, fromCol);
    if (piece != null) {
      piece.row = toRow;
      piece.col = toCol;
      setPiece(toRow, toCol, piece);
      setPiece(fromRow, fromCol, null);

      // Check for promotion - Turkish Dama promotion
      if (piece.type == PieceType.normal) {
        if ((piece.color == PieceColor.light && toRow == 0) ||
            (piece.color == PieceColor.dark && toRow == 7)) {
          piece.promoteToKing();
        }
      }
    }
  }

  void removePiece(int row, int col) {
    setPiece(row, col, null);
  }
}