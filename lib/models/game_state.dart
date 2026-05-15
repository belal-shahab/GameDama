import 'piece.dart';

enum GameMode { humanVsHuman, humanVsAI }

class Move {
  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
  final List<Position> captures;
  // Intermediate landing squares for multi-capture animation.
  // Order matches `captures`: path[i] is where piece lands after capturing captures[i].
  // Empty for non-capture moves; for single capture, has one entry equal to (toRow,toCol).
  final List<Position> path;

  Move({
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
    this.captures = const [],
    this.path = const [],
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
  GameMode gameMode;
  bool aiThinking;
  Move? lastAIMove;

  GameState({
    this.currentPlayer = PieceColor.light,
    this.gameOver = false,
    this.winner,
    this.possibleMoves = const [],
    this.selectedPiece,
    this.gameMode = GameMode.humanVsHuman,
    this.aiThinking = false,
    this.lastAIMove,
  });

  bool get isAITurn => gameMode == GameMode.humanVsAI && currentPlayer == PieceColor.dark;
}
