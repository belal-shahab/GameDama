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
    final boardSize = screenSize.width < screenSize.height
        ? screenSize.width * 0.9
        : screenSize.height * 0.7;
    final squareSize = boardSize / 8.150;

    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        return Container(
          width: boardSize,
          height: boardSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: Offset(5, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Column(
              children: List.generate(8, (row) {
                return Row(
                  children: List.generate(8, (col) {
                    final piece = gameProvider.board.getPiece(row, col);
                    return SquareWidget(
                      row: row,
                      col: col,
                      piece: piece,
                      size: squareSize,
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