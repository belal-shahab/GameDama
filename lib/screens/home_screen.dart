import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';
import '../models/game_state.dart';
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
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                  () => _startGame(context, GameMode.humanVsAI),
                  isSmallScreen,
                ).animate()
                    .fadeIn(delay: 1.2.seconds)
                    .slideY(begin: 0.3, end: 0),
              ],
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

  void _startGame(BuildContext context, GameMode gameMode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(gameMode: gameMode),
      ),
    );
  }
}
