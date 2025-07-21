import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class IconGenerator {
  static Future<void> createSimpleIcon() async {
    // Create a simple 512x512 app icon
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 512.0;
    
    // Background gradient
    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size, size));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size, size), backgroundPaint);
    
    // Board background
    final boardPaint = Paint()..color = const Color(0xFF8B4513);
    final boardRect = Rect.fromLTWH(size * 0.15, size * 0.15, size * 0.7, size * 0.7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect, Radius.circular(size * 0.05)),
      boardPaint,
    );
    
    // Simple checkerboard pattern
    final lightSquarePaint = Paint()..color = const Color(0xFFDEB887);
    final darkSquarePaint = Paint()..color = const Color(0xFF8B4513);
    
    const squares = 8;
    final squareSize = (size * 0.7) / squares;
    final startX = size * 0.15;
    final startY = size * 0.15;
    
    for (int row = 0; row < squares; row++) {
      for (int col = 0; col < squares; col++) {
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
    
    // Add some pieces to make it look like a game
    final pieceRadius = squareSize * 0.35;
    
    // Dark pieces on top rows
    for (int row = 1; row < 3; row++) {
      for (int col = 0; col < 8; col++) {
        if (col % 2 == 0) { // Every other piece for cleaner look
          canvas.drawCircle(
            Offset(
              startX + col * squareSize + squareSize / 2,
              startY + row * squareSize + squareSize / 2,
            ),
            pieceRadius,
            darkPiecePaint,
          );
        }
      }
    }
    
    // Light pieces on bottom rows  
    for (int row = 5; row < 7; row++) {
      for (int col = 0; col < 8; col++) {
        if (col % 2 == 1) { // Every other piece for cleaner look
          canvas.drawCircle(
            Offset(
              startX + col * squareSize + squareSize / 2,
              startY + row * squareSize + squareSize / 2,
            ),
            pieceRadius,
            lightPiecePaint,
          );
        }
      }
    }
    
    // Add "DAMA" text at bottom
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'DAMA',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.08,
          fontWeight: FontWeight.bold,
          letterSpacing: size * 0.01,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        size * 0.88,
      ),
    );
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      final file = File('assets/icon/app_icon.png');
      await file.create(recursive: true);
      await file.writeAsBytes(byteData.buffer.asUint8List());
      print('✅ App icon created at: ${file.path}');
    }
  }
}

