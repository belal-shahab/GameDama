import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/game_provider.dart';
import '../widgets/board_widget.dart';
import '../utils/constants.dart';
import '../models/piece.dart';
import '../models/game_state.dart';
import '../services/ai_player.dart';

class GameScreen extends StatelessWidget {
  final GameMode gameMode;
  final AIDifficulty aiDifficulty;

  const GameScreen({
    Key? key,
    this.gameMode = GameMode.humanVsHuman,
    this.aiDifficulty = AIDifficulty.medium,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GameProvider>(context, listen: false)
          .startNewGame(gameMode: gameMode, aiDifficulty: aiDifficulty);
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
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.home),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              Provider.of<GameProvider>(context, listen: false)
                  .startNewGame(gameMode: gameMode, aiDifficulty: aiDifficulty);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<GameProvider>(
          builder: (context, gameProvider, _) {
            return Column(
              children: [
                _buildGameInfo(gameProvider),
                if (aiDifficulty == AIDifficulty.mlAI) 
                  _buildMLAIStats(gameProvider),
                SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: BoardWidget(),
                  ),
                ),
                SizedBox(height: 20),
                _buildGameStatus(gameProvider),
                _buildGameControls(context, gameProvider),
                SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGameControls(BuildContext context, GameProvider gameProvider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Return to Main Button
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.home, color: Colors.white),
            label: Text(
              'Main Menu',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: GameConstants.accentColor,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
          
          // New Game Button
          ElevatedButton.icon(
            onPressed: () {
              gameProvider.startNewGame(
                gameMode: gameMode,
                aiDifficulty: aiDifficulty,
              );
            },
            icon: Icon(Icons.refresh, color: Colors.white),
            label: Text(
              'New Game',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: GameConstants.primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameInfo(GameProvider gameProvider) {
    return Column(
      children: [
        _buildTurnIndicator(gameProvider),
        if (gameProvider.gameState.aiThinking) ...[
          SizedBox(height: 10),
          _buildAIThinkingIndicator(),
        ],
      ],
    );
  }

  Widget _buildTurnIndicator(GameProvider gameProvider) {
    String playerText;
    if (gameMode == GameMode.humanVsAI) {
      playerText = gameProvider.gameState.currentPlayer == PieceColor.light
          ? 'Your Turn'
          : 'AI Turn';
    } else {
      playerText = gameProvider.gameState.currentPlayer == PieceColor.light
          ? 'Light\'s Turn'
          : 'Dark\'s Turn';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      decoration: BoxDecoration(
        color: gameProvider.gameState.currentPlayer == PieceColor.light
            ? GameConstants.lightPieceColor
            : GameConstants.darkPieceColor,
        borderRadius: BorderRadius.circular(25),
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
            size: 24,
          ),
          SizedBox(width: 10),
          Text(
            playerText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: gameProvider.gameState.currentPlayer == PieceColor.light
                  ? GameConstants.darkPieceColor
                  : GameConstants.lightPieceColor,
            ),
          ),
        ],
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).shimmer(
      duration: 2.seconds,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildAIThinkingIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: GameConstants.primaryColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 10),
          Text(
            'AI is thinking...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).fadeIn(duration: 300.ms);
  }

  Widget _buildGameStatus(GameProvider gameProvider) {
    if (gameProvider.gameState.gameOver) {
      String winnerText;
      if (gameMode == GameMode.humanVsAI) {
        winnerText = gameProvider.gameState.winner == PieceColor.light
            ? 'You Win!'
            : 'AI Wins!';
      } else {
        winnerText = '${gameProvider.gameState.winner == PieceColor.light ? 'Light' : 'Dark'} Wins!';
      }

      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: GameConstants.accentColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(
              'Game Over!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              winnerText,
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ).animate()
          .scale()
          .shake();
    }

    return SizedBox.shrink();
  }

  Widget _buildMLAIStats(GameProvider gameProvider) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purple.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            '🤖 ML AI Stats',
            style: TextStyle(
              color: Colors.purple.shade300,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Games', '${gameProvider.aiPlayer?.gamesPlayed ?? 0}'),
              _buildStatItem('Win Rate', '${((gameProvider.aiPlayer?.winRate ?? 0) * 100).toStringAsFixed(1)}%'),
              _buildStatItem('Patterns', '${gameProvider.aiPlayer?.patternsLearned ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}