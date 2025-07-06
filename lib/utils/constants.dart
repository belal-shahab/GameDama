import 'package:flutter/material.dart';

class GameConstants {
  // Board colors
  static const Color darkSquare = Color(0xFF8B4513);
  static const Color lightSquare = Color(0xFFDEB887);

  // Piece colors
  static const Color darkPieceColor = Color(0xFF2C2C2C);
  static const Color lightPieceColor = Color(0xFFF5DEB3);

  // UI colors
  static const Color primaryColor = Color(0xFF1E88E5);
  static const Color accentColor = Color(0xFFFF6B6B);
  static const Color backgroundColor = Color(0xFF1A1A2E);

  // Highlight colors
  static const Color possibleMoveColor = Color(0x8066BB6A);
  static const Color selectedSquareColor = Color(0x80FFD700);
  static const Color captureHighlightColor = Color(0x80FF5252);

  // Board size
  static const int boardSize = 8;

  // Animation durations
  static const Duration moveDuration = Duration(milliseconds: 300);
  static const Duration captureDuration = Duration(milliseconds: 200);
}