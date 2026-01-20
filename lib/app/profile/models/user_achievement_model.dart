import 'package:nur_app/app/profile/models/achievement_model.dart';

/// Modelo de conquista do usuário (relacionamento)
/// Representa a relação entre usuário e conquista
class UserAchievementModel {
  final String id;
  final String userId;
  final String achievementId;
  final AchievementStatus status;
  final double progress; // 0.0 a 1.0
  final String? progressText;
  final DateTime? unlockedAt;
  final DateTime updatedAt;

  UserAchievementModel({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.status,
    required this.progress,
    this.progressText,
    this.unlockedAt,
    required this.updatedAt,
  });

  /// Cria um modelo a partir de JSON
  factory UserAchievementModel.fromJson(Map<String, dynamic> json) {
    return UserAchievementModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      achievementId: json['achievementId'] as String,
      status: _statusFromString(json['status'] as String),
      progress: (json['progress'] as num).toDouble(),
      progressText: json['progressText'] as String?,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Converte string para AchievementStatus
  static AchievementStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AchievementStatus.completed;
      case 'inprogress':
      case 'in_progress':
        return AchievementStatus.inProgress;
      case 'locked':
      default:
        return AchievementStatus.locked;
    }
  }
}
