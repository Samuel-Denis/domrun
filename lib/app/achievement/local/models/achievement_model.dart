import 'package:flutter/material.dart';

/// Modelo de conquista/achievement
/// Representa uma conquista do usuário
class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String medal;
  final String? icon;
  final AchievementStatus status; // Status da conquista
  final double? progress; // Progresso (0.0 a 1.0) se status for inProgress
  final String? progressText; // Texto de progresso (ex: "50%")

  AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.medal,
    this.icon,
    this.progress,
    this.progressText,
  });

  /// Cria um modelo a partir de JSON
  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      medal: json['medal'] ?? '',
      status: _statusFromString(json['status'] ?? 'locked'),
      progress: json['progress'] != null
          ? (json['progress'] as num).toDouble()
          : null,
      progressText: json['progressText'],
    );
  }

  /// Converte string para IconData
  static IconData _iconFromString(String iconName) {
    // Mapeia nomes de ícones para IconData
    switch (iconName.toLowerCase()) {
      case 'running':
      case 'directions_run':
        return Icons.directions_run;
      case 'map':
      case 'map_outlined':
        return Icons.map_outlined;
      case 'globe':
      case 'public':
        return Icons.public;
      case 'trophy':
      case 'emoji_events':
        return Icons.emoji_events;
      default:
        return Icons.emoji_events;
    }
  }

  /// Converte o modelo para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.toString().split('.').last,
      'progress': progress,
      'progressText': progressText,
    };
  }

  /// Converte IconData para string
  static String _iconToString(IconData icon) {
    // Retorna o nome do ícone baseado no código
    if (icon.codePoint == Icons.directions_run.codePoint) return 'running';
    if (icon.codePoint == Icons.map_outlined.codePoint) return 'map';
    if (icon.codePoint == Icons.public.codePoint) return 'globe';
    if (icon.codePoint == Icons.emoji_events.codePoint) return 'trophy';
    return 'trophy';
  }

  /// Converte string de cor para Color
  static Color _colorFromString(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF7B2CBF); // Cor padrão roxa
    }
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

/// Status da conquista
enum AchievementStatus {
  completed, // Concluída
  inProgress, // Em progresso
  locked, // Bloqueada
}
