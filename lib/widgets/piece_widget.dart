import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/piece.dart';
import '../utils/constants.dart';

class PieceWidget extends StatelessWidget {
  final Piece piece;
  final double size;

  const PieceWidget({
    Key? key,
    required this.piece,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Responsive piece sizing
    final pieceSize = (size * 0.75).clamp(20.0, 40.0);
    final starSize = (size * 0.4).clamp(12.0, 24.0);

    return Container(
      width: pieceSize,
      height: pieceSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: piece.color == PieceColor.light
            ? GameConstants.lightPieceColor
            : GameConstants.darkPieceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: size * 0.1,
            offset: Offset(size * 0.05, size * 0.05),
          ),
        ],
        gradient: RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: piece.color == PieceColor.light
              ? [
            GameConstants.lightPieceColor.withOpacity(0.9),
            GameConstants.lightPieceColor,
            GameConstants.lightPieceColor.withOpacity(0.7),
          ]
              : [
            GameConstants.darkPieceColor.withOpacity(0.9),
            GameConstants.darkPieceColor,
            GameConstants.darkPieceColor.withOpacity(0.7),
          ],
        ),
      ),
      child: piece.type == PieceType.king
          ? Center(
        child: Icon(
          Icons.star,
          color: piece.color == PieceColor.light
              ? Colors.amber.shade800
              : Colors.amber.shade400,
          size: starSize,
        ).animate()
            .scale(delay: 300.ms, duration: 600.ms)
            .fadeIn(),
      )
          : null,
    ).animate()
        .scale(duration: 300.ms)
        .fadeIn();
  }
}