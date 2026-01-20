class AchievementModel {
  final String id;
  final String code;
  final String title;
  final String description;
  final String category; // RUN, TERRITORY, SOCIAL, LEAGUE, EVENT, MILESTONE
  final String rarity; // COMMON, RARE, EPIC, LEGENDARY
  final String? iconAsset;
  final bool isHidden;

  final Map<String, dynamic>? criteriaJson;
  final Map<String, dynamic>? rewardJson; // por enquanto ainda tem trophies, ok
  final int? seasonNumber;

  // Estado do usuário
  final String status; // LOCKED, IN_PROGRESS, UNLOCKED, CLAIMED
  final double
  progress; // 0..1 (ou 0..100 dependendo do seu backend — abaixo eu normalizei)
  final String? progressText;
  final double? currentValue;
  final double? targetValue;
  final DateTime? unlockedAt;
  final DateTime? claimedAt;

  const AchievementModel({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.category,
    required this.rarity,
    required this.iconAsset,
    required this.isHidden,
    required this.criteriaJson,
    required this.rewardJson,
    required this.seasonNumber,
    required this.status,
    required this.progress,
    required this.progressText,
    required this.currentValue,
    required this.targetValue,
    required this.unlockedAt,
    required this.claimedAt,
  });

  bool get isClaimable => status == 'UNLOCKED';
  bool get isClaimed => status == 'CLAIMED';

  int get rewardXp {
    final v = rewardJson?['xp'];
    return (v is num) ? v.toInt() : 0;
  }

  // Se seu backend mandar progress como 0..100, isso corrige pra 0..1.
  double get normalizedProgress {
    final p = progress;
    if (p > 1.0) return (p / 100.0).clamp(0.0, 1.0);
    return p.clamp(0.0, 1.0);
  }

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    Map<String, dynamic>? parseMap(dynamic v) {
      if (v is Map<String, dynamic>) return v;
      return null;
    }

    return AchievementModel(
      id: json['id'].toString(),
      code: json['code'].toString(),
      title: json['title'].toString(),
      description: json['description'].toString(),
      category: json['category'].toString(),
      rarity: json['rarity'].toString(),
      iconAsset: json['iconAsset']?.toString(),
      isHidden: json['isHidden'] == true,
      criteriaJson: parseMap(json['criteriaJson']),
      rewardJson: parseMap(json['rewardJson']),
      seasonNumber: (json['seasonNumber'] is num)
          ? (json['seasonNumber'] as num).toInt()
          : null,
      status: (json['status'] ?? 'LOCKED').toString(),
      progress: (json['progress'] is num)
          ? (json['progress'] as num).toDouble()
          : 0.0,
      progressText: json['progressText']?.toString(),
      currentValue: parseDouble(json['currentValue']),
      targetValue: parseDouble(json['targetValue']),
      unlockedAt: parseDt(json['unlockedAt']),
      claimedAt: parseDt(json['claimedAt']),
    );
  }
}
