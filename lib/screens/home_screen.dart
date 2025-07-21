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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    
    return Scaffold(
      backgroundColor: GameConstants.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenSize.height - MediaQuery.of(context).padding.vertical,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 40),
                  
                  Text(
                    'DAMA',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 56 : 72,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: isSmallScreen ? 6 : 8,
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

                  SizedBox(height: 15),

                  Text(
                    'Classic Checkers Game',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 20,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ).animate()
                      .fadeIn(delay: 800.ms),

                  SizedBox(height: isSmallScreen ? 50 : 80),

                  _buildGameModeButton(
                    context,
                    'Play vs Human',
                    Icons.people,
                    () => _startGame(context, GameMode.humanVsHuman),
                    isSmallScreen,
                  ).animate()
                      .fadeIn(delay: 1.seconds)
                      .slideY(begin: 0.3, end: 0),

                  SizedBox(height: 15),

                  _buildGameModeButton(
                    context,
                    'Play vs AI',
                    Icons.smart_toy,
                    () => _showAIDifficultyDialog(context),
                    isSmallScreen,
                  ).animate()
                      .fadeIn(delay: 1.2.seconds)
                      .slideY(begin: 0.3, end: 0),

                  SizedBox(height: 25),

                  TextButton(
                    onPressed: () {
                      _showRulesDialog(context);
                    },
                    child: Text(
                      'How to Play',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        color: Colors.white70,
                      ),
                    ),
                  ).animate()
                      .fadeIn(delay: 1.4.seconds),
                  
                  SizedBox(height: 40),
                ],
              ),
            ),
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
    bool isSmallScreen,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: isSmallScreen ? 20 : 24),
        label: Text(
          text,
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: GameConstants.primaryColor,
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 20 : 40, 
            vertical: isSmallScreen ? 12 : 16
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 8,
          minimumSize: Size(double.infinity, isSmallScreen ? 50 : 60),
        ),
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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GameConstants.backgroundColor,
        contentPadding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        title: Text(
          'Choose AI Difficulty',
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDifficultyOption(context, '🟢 Easy (2 moves ahead)', AIDifficulty.easy, Colors.green, isSmallScreen),
              SizedBox(height: 8),
              _buildDifficultyOption(context, '🟡 Medium (4 moves ahead)', AIDifficulty.medium, Colors.orange, isSmallScreen),
              SizedBox(height: 8),
              _buildDifficultyOption(context, '🔴 Hard (6 moves ahead)', AIDifficulty.hard, Colors.red, isSmallScreen),
              SizedBox(height: 8),
              _buildDifficultyOption(context, '🔥 Expert (8 moves ahead)', AIDifficulty.expert, Colors.deepOrange, isSmallScreen),
              SizedBox(height: 8),
              _buildDifficultyOption(context, '💀 Master (10 moves ahead)', AIDifficulty.master, Colors.purple.shade900, isSmallScreen),
              SizedBox(height: 8),
              _buildDifficultyOption(context, '🤖 ML AI (Learning)', AIDifficulty.mlAI, Colors.purple, isSmallScreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(BuildContext context, String text, AIDifficulty difficulty, Color color, bool isSmallScreen) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          _startGame(context, GameMode.humanVsAI, difficulty);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _showRulesDialog(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GameConstants.backgroundColor,
        contentPadding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        title: Text(
          'How to Play Turkish Dama',
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _ruleSection('Objective',
                  'Capture all opponent pieces or block them from moving.', isSmallScreen),
              _ruleSection('Movement',
                  '• Normal pieces move one square forward, left, or right (NOT backward)\n'
                      '• NO diagonal moves in Turkish Dama!\n'
                      '• Kings move any distance horizontally or vertically (like rooks)\n'
                      '• Pieces become kings when reaching the opposite end', isSmallScreen),
              _ruleSection('Capturing',
                  '• Men can capture in all 4 directions (including backward)\n'
                      '• Jump over adjacent enemy pieces\n'
                      '• Multiple captures are mandatory\n'
                      '• Must capture the maximum number of pieces\n'
                      '• Kings capture like rooks - any distance', isSmallScreen),
              _ruleSection('Important',
                  '• If you can capture, you MUST capture\n'
                      '• Choose the move that captures the most pieces', isSmallScreen),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it!', 
              style: TextStyle(
                color: GameConstants.primaryColor,
                fontSize: isSmallScreen ? 14 : 16,
              )
            ),
          ),
        ],
      ),
    );
  }

  Widget _ruleSection(String title, String content, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: GameConstants.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
          SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isSmallScreen ? 12 : 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}