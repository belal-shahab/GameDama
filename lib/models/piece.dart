enum PieceType { normal, king }
enum PieceColor { light, dark }

class Piece {
  final PieceColor color;
  PieceType type;
  int row;
  int col;

  Piece({
    required this.color,
    required this.type,
    required this.row,
    required this.col,
  });

  void promoteToKing() {
    type = PieceType.king;
  }

  Piece copyWith({int? row, int? col, PieceType? type}) {
    return Piece(
      color: color,
      type: type ?? this.type,
      row: row ?? this.row,
      col: col ?? this.col,
    );
  }
}