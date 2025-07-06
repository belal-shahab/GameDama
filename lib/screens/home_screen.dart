import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameConstants.backgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'DAMA',
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 8,
                  shadows: [
                    Shadow(
                      color: GameConstants.primaryColor,
                      blurRadius: 20,
                    ),
                  ],
                ),
              ).animate()
                  .fadeIn(duration: 1.seconds)
                  .scale(delay: 500.ms),

              SizedBox(height: 20),

              Text(
                'Classic Checkers Game',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white70,
                ),
              ).animate()
                  .fadeIn(delay: 800.ms),

              SizedBox(height: 80),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => GameScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameConstants.primaryColor,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                ),
                child: Text(
                  'Play Game',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ).animate()
                  .fadeIn(delay: 1.seconds)
                  .slideY(begin: 0.3, end: 0),

              SizedBox(height: 30),

              TextButton(
                onPressed: () {
                  _showRulesDialog(context);
                },
                child: Text(
                  'How to Play',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
              ).animate()
                  .fadeIn(delay: 1.2.seconds),
            ],
          ),
        ),
      ),
    );
  }

  void _showRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GameConstants.backgroundColor,
        title: Text(
          'How to Play Turkish Dama',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _ruleSection('Objective',
                  'Capture all opponent pieces or block them from moving.'),
              _ruleSection('Movement',
                  '• Normal pieces move one square forward, left, or right (NOT backward)\n'
                      '• NO diagonal moves in Turkish Dama!\n'
                      '• Kings move any distance horizontally or vertically (like rooks)\n'
                      '• Pieces become kings when reaching the opposite end'),
              _ruleSection('Capturing',
                  '• Men can capture in all 4 directions (including backward)\n'
                      '• Jump over adjacent enemy pieces\n'
                      '• Multiple captures are mandatory\n'
                      '• Must capture the maximum number of pieces\n'
                      '• Kings capture like rooks - any distance'),
              _ruleSection('Important',
                  '• If you can capture, you MUST capture\n'
                      '• Choose the move that captures the most pieces'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it!', style: TextStyle(color: GameConstants.primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _ruleSection(String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: GameConstants.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}