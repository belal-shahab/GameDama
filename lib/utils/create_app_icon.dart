import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// This is a utility to help create the app icon programmatically
// You can run this to generate the icon, then save it as PNG

class AppIconGenerator {
  static Future<Uint8List> generateDamaIcon() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 512.0;
    
    // Background
    final backgroundPaint = Paint()..color = const Color(0xFF1A1A2E);
    canvas.drawRect(Rect.fromLTWH(0, 0, size, size), backgroundPaint);
    
    // Board background
    final boardPaint = Paint()..color = const Color(0xFF8B4513);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size * 0.1, size * 0.1, size * 0.8, size * 0.8),
        Radius.circular(size * 0.05),
      ),
      boardPaint,
    );
    
    // Chess pattern
    final lightSquarePaint = Paint()..color = const Color(0xFFDEB887);
    final darkSquarePaint = Paint()..color = const Color(0xFF8B4513);
    
    const squareSize = 40.0;
    const startX = (size - 8 * squareSize) / 2;
    const startY = (size - 8 * squareSize) / 2;
    
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        final paint = (row + col) % 2 == 0 ? lightSquarePaint : darkSquarePaint;
        canvas.drawRect(
          Rect.fromLTWH(
            startX + col * squareSize,
            startY + row * squareSize,
            squareSize,
            squareSize,
          ),
          paint,
        );
      }
    }
    
    // Game pieces
    final darkPiecePaint = Paint()..color = const Color(0xFF2C2C2C);
    final lightPiecePaint = Paint()..color = const Color(0xFFF5DEB3);
    
    // Dark pieces on top
    for (int row = 1; row < 3; row++) {
      for (int col = 0; col < 8; col++) {
        canvas.drawCircle(
          Offset(
            startX + col * squareSize + squareSize / 2,
            startY + row * squareSize + squareSize / 2,
          ),
          squareSize * 0.3,
          darkPiecePaint,
        );
      }
    }
    
    // Light pieces on bottom
    for (int row = 5; row < 7; row++) {
      for (int col = 0; col < 8; col++) {
        canvas.drawCircle(
          Offset(
            startX + col * squareSize + squareSize / 2,
            startY + row * squareSize + squareSize / 2,
          ),
          squareSize * 0.3,
          lightPiecePaint,
        );
      }
    }
    
    // Title "DAMA"
    final textStyle = ui.TextStyle(
      color: Colors.white,
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: 4,
    );
    
    final paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(textAlign: TextAlign.center),
    )
      ..pushStyle(textStyle)
      ..addText('DAMA');
    
    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: size));
    
    canvas.drawParagraph(paragraph, Offset(0, size * 0.85));
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }
}
