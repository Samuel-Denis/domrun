import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:nur_app/app/profile/models/achievement_definition.dart';

/// Dados estáticos de todas as conquistas disponíveis no app
/// Baseado no arquivo cq.json - compilado junto com o app
class AchievementsData {
  // Cache para evitar múltiplas leituras do JSON
  static List<AchievementDefinition>? _cachedAchievements;

  /// Retorna todas as definições de conquistas
  /// Carrega do arquivo JSON estático cq.json
  static Future<List<AchievementDefinition>> getAllAchievements() async {
    // Retorna do cache se já foi carregado
    if (_cachedAchievements != null) {
      return _cachedAchievements!;
    }

    final List<AchievementDefinition> all = [];

    try {
      // Carrega o JSON do asset
      final String jsonString = await rootBundle.loadString(
        'assets/data/cq.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString) as List<dynamic>;

      // Itera sobre as categorias
      for (final categoryData in jsonData) {
        final Map<String, dynamic> categoryMap =
            categoryData as Map<String, dynamic>;
        final List<dynamic> conquistas =
            categoryMap['conquistas'] as List<dynamic>;

        // Converte cada conquista
        for (final conquistaJson in conquistas) {
          final Map<String, dynamic> conquistaMap =
              conquistaJson as Map<String, dynamic>;

          // Cria a definição usando fromJson
          final achievement = AchievementDefinition.fromJson(conquistaMap);
          all.add(achievement);
        }
      }

      // Armazena no cache
      _cachedAchievements = all;
      return all;
    } catch (e) {
      print('Erro ao carregar conquistas do JSON: $e');
      // Retorna lista vazia em caso de erro
      return [];
    }
  }

  /// Retorna conquistas agrupadas por categoria
  /// Retorna um Map onde a chave é a categoria e o valor é a lista de conquistas
  static Future<Map<String, List<AchievementDefinition>>>
  getAchievementsByCategory() async {
    final all = await getAllAchievements();
    final Map<String, List<AchievementDefinition>> grouped = {};

    for (final achievement in all) {
      if (!grouped.containsKey(achievement.category)) {
        grouped[achievement.category] = [];
      }
      grouped[achievement.category]!.add(achievement);
    }

    return grouped;
  }

  /// Retorna conquistas por categoria
  static Future<List<AchievementDefinition>> getByCategory(
    String category,
  ) async {
    final all = await getAllAchievements();
    return all
        .where((achievement) => achievement.category == category)
        .toList();
  }

  /// Retorna uma conquista por ID
  static Future<AchievementDefinition?> getById(String id) async {
    try {
      final all = await getAllAchievements();
      return all.firstWhere((achievement) => achievement.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Limpa o cache (útil para testes ou quando o JSON for atualizado)
  static void clearCache() {
    _cachedAchievements = null;
  }
}
