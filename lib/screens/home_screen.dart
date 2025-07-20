import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';
import '../models/game_state.dart';
import '../services/ai_player.dart';
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

              _buildGameModeButton(
                context,
                'Play vs Human',
                Icons.people,
                () => _startGame(context, GameMode.humanVsHuman),
              ).animate()
                  .fadeIn(delay: 1.seconds)
                  .slideY(begin: 0.3, end: 0),

              SizedBox(height: 20),

              _buildGameModeButton(
                context,
                'Play vs AI',
                Icons.smart_toy,
                () => _showAIDifficultyDialog(context),
              ).animate()
                  .fadeIn(delay: 1.2.seconds)
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
                  .fadeIn(delay: 1.4.seconds),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameModeButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        text,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: GameConstants.primaryColor,
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 8,
        minimumSize: Size(250, 60),
      ),
    );
  }

  void _startGame(BuildContext context, GameMode gameMode, [AIDifficulty? difficulty]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          gameMode: gameMode,
          aiDifficulty: difficulty ?? AIDifficulty.medium,
        ),
      ),
    ).then((_) {
      // This runs when returning from game screen
      print('Returned to main menu');
    });
  }

  void _showAIDifficultyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GameConstants.backgroundColor,
        title: Text(
          'Choose AI Difficulty',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDifficultyOption(context, 'Easy', AIDifficulty.easy, Colors.green),
            SizedBox(height: 10),
            _buildDifficultyOption(context, 'Medium', AIDifficulty.medium, Colors.orange),
            SizedBox(height: 10),
            _buildDifficultyOption(context, 'Hard', AIDifficulty.hard, Colors.red),
            SizedBox(height: 10),
            _buildDifficultyOption(context, '🤖 ML AI (Learning)', AIDifficulty.mlAI, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(BuildContext context, String text, AIDifficulty difficulty, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          _startGame(context, GameMode.humanVsAI, difficulty);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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