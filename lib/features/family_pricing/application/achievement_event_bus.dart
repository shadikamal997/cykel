import 'dart:async';

import '../domain/family_gamification.dart';

/// A simple event bus for achievement notifications
/// This is used to communicate between application and presentation layers
class AchievementEventBus {
  static final AchievementEventBus _instance = AchievementEventBus._internal();
  factory AchievementEventBus() => _instance;
  AchievementEventBus._internal();

  final _controller = StreamController<List<UnlockedAchievement>>.broadcast();

  /// Stream of achievement unlock events
  Stream<List<UnlockedAchievement>> get stream => _controller.stream;

  /// Emit a list of newly unlocked achievements
  void emit(List<UnlockedAchievement> achievements) {
    if (achievements.isNotEmpty) {
      _controller.add(achievements);
    }
  }

  /// Close the event bus
  void dispose() {
    _controller.close();
  }
}

/// Global instance of the achievement event bus
final achievementEventBus = AchievementEventBus();
