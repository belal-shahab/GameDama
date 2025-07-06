import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/game_provider.dart';
import '../widgets/board_widget.dart';
import '../utils/constants.dart';
import '../models/piece.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              Provider.of<GameProvider>(context, listen: false).startNewGame();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<GameProvider>(
          builder: (context, gameProvider, _) {
            return Column(
              children: [
                _buildTurnIndicator(gameProvider),
                SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: BoardWidget(),
                  ),
                ),
                SizedBox(height: 20),
                _buildGameStatus(gameProvider),
                SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTurnIndicator(GameProvider gameProvider) {
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
            Icons.circle,
            color: gameProvider.gameState.currentPlayer == PieceColor.light
                ? GameConstants.darkPieceColor
                : GameConstants.lightPieceColor,
            size: 24,
          ),
          SizedBox(width: 10),
          Text(
            gameProvider.gameState.currentPlayer == PieceColor.light
                ? 'Light\'s Turn'
                : 'Dark\'s Turn',
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

  Widget _buildGameStatus(GameProvider gameProvider) {
    if (gameProvider.gameState.gameOver) {
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
              '${gameProvider.gameState.winner == PieceColor.light ? 'Light' : 'Dark'} Wins!',
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
}