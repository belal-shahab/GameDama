import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/piece.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import 'piece_widget.dart';

class SquareWidget extends StatelessWidget {
  final int row;
  final int col;
  final Piece? piece;
  final double size;

  const SquareWidget({
    Key? key,
    required this.row,
    required this.col,
    required this.piece,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final isSelected = gameProvider.isSquareSelected(row, col);
    final isLastAIMove = gameProvider.isLastAIMove(row, col);
    final possibleMoves = gameProvider.getPossibleMovesForSquare(row, col);
    final hasPossibleMove = possibleMoves.isNotEmpty;
    final isCapture = hasPossibleMove && possibleMoves.first.captures.isNotEmpty;

    return GestureDetector(
      onTap: () => gameProvider.selectPiece(row, col),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _getSquareColor(),
          border: _getBorder(isSelected, isLastAIMove),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (hasPossibleMove)
              Container(
                width: size * 0.4,
                height: size * 0.4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCapture
                      ? GameConstants.captureHighlightColor
                      : GameConstants.possibleMoveColor,
                  border: Border.all(
                    color: isCapture
                        ? GameConstants.captureHighlightColor.withOpacity(0.8)
                        : GameConstants.possibleMoveColor.withOpacity(0.8),
                    width: 2,
                  ),
                ),
              ),
            if (piece != null)
              PieceWidget(piece: piece!, size: size),
          ],
        ),
      ),
    );
  }

  Color _getSquareColor() {
    return (row + col) % 2 == 0
        ? GameConstants.lightSquare
        : GameConstants.darkSquare;
  }

  Border? _getBorder(bool isSelected, bool isLastAIMove) {
    if (isSelected) {
      return Border.all(
        color: GameConstants.selectedSquareColor,
        width: 3,
      );
    } else if (isLastAIMove) {
      return Border.all(
        color: GameConstants.primaryColor,
        width: 2,
      );
    }
    return null;
  }
}