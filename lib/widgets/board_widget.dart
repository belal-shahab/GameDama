import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import 'square_widget.dart';

class BoardWidget extends StatelessWidget {
  const BoardWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;

    // Better mobile responsive calculation
    final availableHeight = screenSize.height - safeArea.top - safeArea.bottom - 350;
    final availableWidth = screenSize.width - 40;
    
    // Calculate board size with better constraints
    final maxBoardSize = availableWidth < availableHeight ? availableWidth : availableHeight;
    final boardSize = maxBoardSize.clamp(200.0, 380.0);
    final squareSize = boardSize / 8;

    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        return Container(
          width: boardSize,
          height: boardSize,
          margin: EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(8, (row) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(8, (col) {
                    final piece = gameProvider.board.getPiece(row, col);
                    return SizedBox(
                      width: squareSize,
                      height: squareSize,
                      child: SquareWidget(
                        row: row,
                        col: col,
                        piece: piece,
                        size: squareSize,
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}