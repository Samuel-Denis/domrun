/// Modelo de definição de conquista
/// Representa a estrutura de uma conquista conforme definida no cq.json
/// Usado para definir todas as conquistas disponíveis no app

class AchievementDefinition {
  final String id;
  final String name;
  final String description;
  final String medal; // bronze, silver, gold, legendary
  final int xpReward;
  final String
  goalType; // territory_count, area_count, distance_accumulated, etc.
  final dynamic goalValue; // Pode ser int, double, String (depende do goalType)
  final String category; // explorer, athlete, strategist, legendary

  AchievementDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.medal,
    required this.xpReward,
    required this.goalType,
    required this.goalValue,
    required this.category,
  });

  /// Cria a definição a partir de JSON
  factory AchievementDefinition.fromJson(Map<String, dynamic> json) {
    return AchievementDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      medal: json['medal'] as String,
      xpReward: json['xp_reward'] as int,
      goalType: json['goal_type'] as String,
      goalValue: json['goal_value'],
      category: json['category'] as String,
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'medal': medal,
      'xp_reward': xpReward,
      'goal_type': goalType,
      'goal_value': goalValue,
      'category': category,
    };
  }
}
