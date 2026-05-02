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
    final pieceSize = (size * 0.75).clamp(20.0, 40.0);
    final starSize = (size * 0.4).clamp(12.0, 24.0);

    return Container(
      width: pieceSize,
      height: pieceSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: piece.color == PieceColor.light
              ? [
                  Colors.white,
                  GameConstants.lightPieceColor,
                  GameConstants.lightPieceColor.withValues(alpha: 0.8),
                ]
              : [
                  Colors.grey.shade600,
                  GameConstants.darkPieceColor,
                  GameConstants.darkPieceColor.withValues(alpha: 0.8),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: size * 0.12,
            offset: Offset(size * 0.04, size * 0.06),
          ),
          BoxShadow(
            color: (piece.color == PieceColor.light
                    ? Colors.amber
                    : Colors.blueGrey)
                .withValues(alpha: 0.2),
            blurRadius: size * 0.2,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: piece.color == PieceColor.light
              ? Colors.amber.shade200
              : Colors.grey.shade700,
          width: 1.5,
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
                  .scale(delay: 200.ms, duration: 400.ms, curve: Curves.elasticOut)
                  .fadeIn(duration: 300.ms),
            )
          : null,
    ).animate()
        .scale(
          begin: Offset(0.0, 0.0),
          end: Offset(1.0, 1.0),
          duration: 250.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 200.ms);
  }
}
