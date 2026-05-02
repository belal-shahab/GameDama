import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/game_provider.dart';
import '../widgets/board_widget.dart';
import '../utils/constants.dart';
import '../models/piece.dart';
import '../models/game_state.dart';

class GameScreen extends StatelessWidget {
  final GameMode gameMode;

  const GameScreen({
    Key? key,
    this.gameMode = GameMode.humanVsHuman,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GameProvider>(context, listen: false)
          .startNewGame(gameMode: gameMode);
    });

    return Scaffold(
      backgroundColor: GameConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: GameConstants.backgroundColor,
        elevation: 0,
        title: Text(
          'DAMA',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: isSmallScreen ? 2 : 4,
            fontSize: isSmallScreen ? 20 : 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.home, color: Colors.white, size: isSmallScreen ? 20 : 24),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white, size: isSmallScreen ? 20 : 24),
            onPressed: () {
              Provider.of<GameProvider>(context, listen: false)
                  .startNewGame(gameMode: gameMode);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<GameProvider>(
          builder: (context, gameProvider, _) {
            return Column(
              children: [
                // Fixed height turn indicator — board never moves
                SizedBox(
                  height: isSmallScreen ? 50 : 60,
                  child: Center(
                    child: _buildTurnIndicator(gameProvider, isSmallScreen),
                  ),
                ),

                SizedBox(height: isSmallScreen ? 10 : 20),

                // Board takes center space, fixed position
                Expanded(
                  child: Center(
                    child: BoardWidget(),
                  ),
                ),

                // Game over status — fixed height area at bottom
                SizedBox(
                  height: isSmallScreen ? 80 : 100,
                  child: Center(
                    child: _buildGameStatus(gameProvider, isSmallScreen),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTurnIndicator(GameProvider gameProvider, bool isSmallScreen) {
    String playerText;
    if (gameMode == GameMode.humanVsAI) {
      if (gameProvider.gameState.aiThinking) {
        playerText = 'AI Thinking...';
      } else {
        playerText = gameProvider.gameState.currentPlayer == PieceColor.light
            ? 'Your Turn'
            : 'AI Turn';
      }
    } else {
      playerText = gameProvider.gameState.currentPlayer == PieceColor.light
          ? 'Light\'s Turn'
          : 'Dark\'s Turn';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 20 : 30,
        vertical: isSmallScreen ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: gameProvider.gameState.currentPlayer == PieceColor.light
            ? GameConstants.lightPieceColor
            : GameConstants.darkPieceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            gameMode == GameMode.humanVsAI && gameProvider.gameState.currentPlayer == PieceColor.dark
                ? Icons.smart_toy
                : Icons.circle,
            color: gameProvider.gameState.currentPlayer == PieceColor.light
                ? GameConstants.darkPieceColor
                : GameConstants.lightPieceColor,
            size: isSmallScreen ? 18 : 22,
          ),
          SizedBox(width: 8),
          Text(
            playerText,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: gameProvider.gameState.currentPlayer == PieceColor.light
                  ? GameConstants.darkPieceColor
                  : GameConstants.lightPieceColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameStatus(GameProvider gameProvider, bool isSmallScreen) {
    if (!gameProvider.gameState.gameOver) return SizedBox.shrink();

    String winnerText;
    if (gameMode == GameMode.humanVsAI) {
      winnerText = gameProvider.gameState.winner == PieceColor.light
          ? 'You Win!'
          : 'AI Wins!';
    } else {
      winnerText = '${gameProvider.gameState.winner == PieceColor.light ? 'Light' : 'Dark'} Wins!';
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: GameConstants.accentColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Game Over!',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            winnerText,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ).animate()
        .scale()
        .shake();
  }
}
