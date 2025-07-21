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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    
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
                  .startNewGame(gameMode: gameMode, aiDifficulty: aiDifficulty);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<GameProvider>(
          builder: (context, gameProvider, _) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: isSmallScreen ? 10 : 20),
                  _buildGameInfo(gameProvider, isSmallScreen),
                  _buildGameStats(gameProvider, isSmallScreen),
                  if (aiDifficulty == AIDifficulty.mlAI) 
                    _buildMLAIStats(gameProvider, isSmallScreen),
                  SizedBox(height: isSmallScreen ? 10 : 20),
                  BoardWidget(),
                  SizedBox(height: isSmallScreen ? 10 : 20),
                  _buildGameStatus(gameProvider, isSmallScreen),
                  SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGameInfo(GameProvider gameProvider, bool isSmallScreen) {
    return Column(
      children: [
        _buildTurnIndicator(gameProvider, isSmallScreen),
        if (gameProvider.gameState.aiThinking) ...[
          SizedBox(height: 8),
          _buildAIThinkingIndicator(isSmallScreen),
        ],
      ],
    );
  }

  Widget _buildGameStats(GameProvider gameProvider, bool isSmallScreen) {
    String currentPlayerName = gameMode == GameMode.humanVsAI 
        ? (gameProvider.gameState.currentPlayer == PieceColor.light ? 'You' : 'AI')
        : (gameProvider.gameState.currentPlayer == PieceColor.light ? 'Light' : 'Dark');

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 15 : 20, vertical: isSmallScreen ? 8 : 10),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 15),
      decoration: BoxDecoration(
        color: GameConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GameConstants.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Last Move Score with clear indication
          if (gameProvider.lastMoveScore > 0)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 15, 
                vertical: isSmallScreen ? 6 : 8
              ),
              decoration: BoxDecoration(
                color: GameConstants.accentColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.white,
                    size: isSmallScreen ? 16 : 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    '$currentPlayerName scored: +${gameProvider.lastMoveScore.toInt()} points',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                ],
              ),
            ),
          
          SizedBox(height: isSmallScreen ? 8 : 12),
          
          // Game Statistics with clearer labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPlayerStats(
                gameMode == GameMode.humanVsAI ? 'You' : 'Light',
                gameProvider.humanRemainingPieces,
                gameProvider.humanCapturedPieces,
                Colors.white,
                true,
                isSmallScreen,
              ),
              Container(
                width: 1,
                height: isSmallScreen ? 40 : 50,
                color: GameConstants.primaryColor.withOpacity(0.5),
              ),
              _buildPlayerStats(
                gameMode == GameMode.humanVsAI ? 'AI' : 'Dark',
                gameProvider.aiRemainingPieces,
                gameProvider.aiCapturedPieces,
                Colors.grey.shade300,
                false,
                isSmallScreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerStats(String playerName, int remaining, int captured, Color textColor, bool isHumanSide, bool isSmallScreen) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isHumanSide) Icon(Icons.smart_toy, color: textColor, size: isSmallScreen ? 14 : 16),
            if (isHumanSide) Icon(Icons.person, color: textColor, size: isSmallScreen ? 14 : 16),
            SizedBox(width: 4),
            Text(
              playerName,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        
        // Remaining pieces
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: textColor, size: isSmallScreen ? 12 : 14),
            SizedBox(width: 4),
            Text(
              'Remaining: $remaining',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
          ],
        ),
        SizedBox(height: 3),
        
        // Captured pieces
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close, color: Colors.red.shade300, size: isSmallScreen ? 12 : 14),
            SizedBox(width: 4),
            Text(
              'Captured: $captured',
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontSize: isSmallScreen ? 10 : 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTurnIndicator(GameProvider gameProvider, bool isSmallScreen) {
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
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 20 : 30, 
        vertical: isSmallScreen ? 10 : 15
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
            size: isSmallScreen ? 20 : 24,
          ),
          SizedBox(width: 8),
          Text(
            playerText,
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
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

  Widget _buildAIThinkingIndicator(bool isSmallScreen) {
    String thinkingText = 'AI is thinking...';
    
    // Show move depth for non-ML AI
    if (aiDifficulty != AIDifficulty.mlAI) {
      Map<AIDifficulty, String> depthTexts = {
        AIDifficulty.easy: 'AI thinking (2 moves ahead)...',
        AIDifficulty.medium: 'AI calculating (4 moves ahead)...',
        AIDifficulty.hard: 'AI analyzing (6 moves ahead)...',
        AIDifficulty.expert: 'Expert AI computing (8 moves ahead)...',
        AIDifficulty.master: 'Master AI processing (10 moves ahead)...',
      };
      thinkingText = depthTexts[aiDifficulty] ?? thinkingText;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 15 : 20, 
        vertical: isSmallScreen ? 8 : 10
      ),
      decoration: BoxDecoration(
        color: GameConstants.primaryColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: isSmallScreen ? 14 : 16,
            height: isSmallScreen ? 14 : 16,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 8),
          Text(
            thinkingText,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
        ],
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).fadeIn(duration: 300.ms);
  }

  Widget _buildGameStatus(GameProvider gameProvider, bool isSmallScreen) {
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
        margin: EdgeInsets.symmetric(horizontal: 20),
        padding: EdgeInsets.all(isSmallScreen ? 15 : 20),
        decoration: BoxDecoration(
          color: GameConstants.accentColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(
              'Game Over!',
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              winnerText,
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 20,
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

  Widget _buildMLAIStats(GameProvider gameProvider, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 15 : 20),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 15),
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
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
          SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Games', '${gameProvider.aiPlayer?.gamesPlayed ?? 0}', isSmallScreen),
              _buildStatItem('Win Rate', '${((gameProvider.aiPlayer?.winRate ?? 0) * 100).toStringAsFixed(1)}%', isSmallScreen),
              _buildStatItem('Patterns', '${gameProvider.aiPlayer?.patternsLearned ?? 0}', isSmallScreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isSmallScreen) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 12 : 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: isSmallScreen ? 10 : 12,
          ),
        ),
      ],
    );
  }
}