import 'piece.dart';

class Move {
  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
  final List<Position> captures;

  Move({
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
    this.captures = const [],
  });
}

class Position {
  final int row;
  final int col;

  Position(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is Position && other.row == row && other.col == col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}

class GameState {
  PieceColor currentPlayer;
  bool gameOver;
  PieceColor? winner;
  List<Move> possibleMoves;
  Position? selectedPiece;

  GameState({
    this.currentPlayer = PieceColor.light,
    this.gameOver = false,
    this.winner,
    this.possibleMoves = const [],
    this.selectedPiece,
  });
}