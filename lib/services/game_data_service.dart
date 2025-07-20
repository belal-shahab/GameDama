import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/game_state.dart';
import '../models/piece.dart';

class GameDataService {
  static const String GAME_RECORDS_KEY = 'game_records';
  static const String PATTERNS_KEY = 'game_patterns';
  static const String MODEL_WEIGHTS_KEY = 'model_weights';

  Future<void> saveGameRecord(GameRecord record) async {
    // In a real app, this would save to local storage or database
    print('Saved game record: AI ${record.aiWon ? 'won' : 'lost'}');
  }

  Future<List<GamePattern>> getGamePatterns() async {
    // Return pre-loaded patterns for now
    return [];
  }

  Future<void> saveGamePatterns(List<GamePattern> patterns) async {
    print('Saved ${patterns.length} game patterns');
  }

  Future<int> getGamesPlayedCount() async {
    return 0; // Will be loaded from storage in real implementation
  }

  Future<double> getWinRate() async {
    return 0.0; // Will be calculated from stored games
  }

  Future<void> saveModelWeights(Map<String, double> weights) async {
    print('Saved ${weights.length} model weights');
  }
}

class GameRecord {
  final List<Move> moves;
  final PieceColor winner;
  final bool aiWon;
  final DateTime timestamp;

  GameRecord({
    required this.moves,
    required this.winner,
    required this.aiWon,
    required this.timestamp,
  });
}

class GamePattern {
  final String patternType;
  int occurrences;
  int successes;
  double successRate;
  double weight;

  GamePattern({
    required this.patternType,
    required this.occurrences,
    required this.successes,
    required this.successRate,
    required this.weight,
  });
}
