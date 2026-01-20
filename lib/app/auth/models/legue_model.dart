class LeagueModel {
  final String id;
  final String code;
  final String displayName;
  final int order;
  final bool isChampion;
  final int? minTrophiesToEnter;
  final int? paceTopSecKm;
  final int? paceBaseSecKm;
  final int? smurfCapSecKm;
  final int? weeklyConsistencyMaxBonus;
  final String? shieldName;
  final String? shieldAsset;
  final dynamic rewardJson;
  final dynamic themeJson;
  final DateTime createdAt;
  final DateTime updatedAt;

  LeagueModel({
    required this.id,
    required this.code,
    required this.displayName,
    required this.order,
    required this.isChampion,
    required this.minTrophiesToEnter,
    required this.paceTopSecKm,
    required this.paceBaseSecKm,
    required this.smurfCapSecKm,
    required this.weeklyConsistencyMaxBonus,
    required this.shieldName,
    required this.shieldAsset,
    required this.rewardJson,
    required this.themeJson,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LeagueModel.fromMap(Map<String, dynamic> map) {
    return LeagueModel(
      id: map['id'] as String,
      code: map['code'] as String,
      displayName: map['displayName'] as String,
      order: (map['order'] as num?)?.toInt() ?? 0,
      isChampion: (map['isChampion'] as bool?) ?? false,
      minTrophiesToEnter: (map['minTrophiesToEnter'] as num?)?.toInt(),
      paceTopSecKm: (map['paceTopSecKm'] as num?)?.toInt(),
      paceBaseSecKm: (map['paceBaseSecKm'] as num?)?.toInt(),
      smurfCapSecKm: (map['smurfCapSecKm'] as num?)?.toInt(),
      weeklyConsistencyMaxBonus: (map['weeklyConsistencyMaxBonus'] as num?)
          ?.toInt(),
      shieldName: map['shieldName'] as String?,
      shieldAsset: map['shieldAsset'] as String?,
      rewardJson: map['rewardJson'],
      themeJson: map['themeJson'],
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
