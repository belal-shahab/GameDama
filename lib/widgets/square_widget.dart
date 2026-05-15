import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    final isLastAIMoveTo = gameProvider.isLastAIMove(row, col);
    final isLastAIMoveFrom = gameProvider.isLastAIMoveFrom(row, col);
    final possibleMoves = gameProvider.getPossibleMovesForSquare(row, col);
    final hasPossibleMove = possibleMoves.isNotEmpty;
    final isCapture = hasPossibleMove && possibleMoves.first.captures.isNotEmpty;

    return GestureDetector(
      onTap: () => gameProvider.selectPiece(row, col),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _baseSquareColor(),
          border: isSelected
              ? Border.all(color: GameConstants.selectedSquareColor, width: 3)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isLastAIMoveFrom) _AiHighlight(size: size, isDestination: false),
            if (isLastAIMoveTo) _AiHighlight(size: size, isDestination: true),
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

  Color _baseSquareColor() {
    return (row + col) % 2 == 0
        ? GameConstants.lightSquare
        : GameConstants.darkSquare;
  }
}

/// Glossy ring overlay used to highlight the AI's most recent move.
/// `isDestination = true` produces a brighter, pulsing ring for the landing square.
/// `isDestination = false` produces a softer, dashed-look ring for the origin square.
class _AiHighlight extends StatelessWidget {
  final double size;
  final bool isDestination;

  const _AiHighlight({required this.size, required this.isDestination});

  @override
  Widget build(BuildContext context) {
    final accent = isDestination
        ? const Color(0xFF4DD0E1) // cyan-300
        : const Color(0xFF80DEEA).withOpacity(0.55); // cyan-200 softer
    final stroke = isDestination ? 3.5 : 2.5;
    final inset = size * 0.05;

    Widget ring = Container(
      margin: EdgeInsets.all(inset),
      decoration: BoxDecoration(
        color: isDestination
            ? const Color(0xFF4DD0E1).withOpacity(0.18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(size * 0.18),
        border: Border.all(color: accent, width: stroke),
        boxShadow: isDestination
            ? [
                BoxShadow(
                  color: const Color(0xFF4DD0E1).withOpacity(0.55),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );

    if (isDestination) {
      // Subtle breathing animation so the eye lands on this square first.
      ring = ring
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 0.92, end: 1.0, duration: 850.ms, curve: Curves.easeInOut)
          .fadeIn(duration: 200.ms);
    }

    return IgnorePointer(child: SizedBox(width: size, height: size, child: ring));
  }
}
