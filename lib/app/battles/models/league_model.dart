/// Modelo de dados para uma liga
class LeagueModel {
  final String name;
  final int minTrophies;
  final int maxTrophies;
  final double xpMultiplier;

  LeagueModel({
    required this.name,
    required this.minTrophies,
    required this.maxTrophies,
    required this.xpMultiplier,
  });

  /// Retorna a liga baseada no número de troféus
  static LeagueModel getLeagueByTrophies(int trophies) {
    if (trophies >= 3000) {
      return LeagueModel(
        name: 'Mestre',
        minTrophies: 3000,
        maxTrophies: 999999,
        xpMultiplier: 2.2,
      );
    } else if (trophies >= 2667) {
      return LeagueModel(
        name: 'Cristal I',
        minTrophies: 2667,
        maxTrophies: 2999,
        xpMultiplier: 1.8,
      );
    } else if (trophies >= 2334) {
      return LeagueModel(
        name: 'Cristal II',
        minTrophies: 2334,
        maxTrophies: 2666,
        xpMultiplier: 1.8,
      );
    } else if (trophies >= 2000) {
      return LeagueModel(
        name: 'Cristal III',
        minTrophies: 2000,
        maxTrophies: 2333,
        xpMultiplier: 1.8,
      );
    } else if (trophies >= 1667) {
      return LeagueModel(
        name: 'Ouro I',
        minTrophies: 1667,
        maxTrophies: 1999,
        xpMultiplier: 1.5,
      );
    } else if (trophies >= 1334) {
      return LeagueModel(
        name: 'Ouro II',
        minTrophies: 1334,
        maxTrophies: 1666,
        xpMultiplier: 1.5,
      );
    } else if (trophies >= 1000) {
      return LeagueModel(
        name: 'Ouro III',
        minTrophies: 1000,
        maxTrophies: 1333,
        xpMultiplier: 1.5,
      );
    } else if (trophies >= 834) {
      return LeagueModel(
        name: 'Prata I',
        minTrophies: 834,
        maxTrophies: 999,
        xpMultiplier: 1.2,
      );
    } else if (trophies >= 667) {
      return LeagueModel(
        name: 'Prata II',
        minTrophies: 667,
        maxTrophies: 833,
        xpMultiplier: 1.2,
      );
    } else if (trophies >= 500) {
      return LeagueModel(
        name: 'Prata III',
        minTrophies: 500,
        maxTrophies: 666,
        xpMultiplier: 1.2,
      );
    } else if (trophies >= 334) {
      return LeagueModel(
        name: 'Bronze I',
        minTrophies: 334,
        maxTrophies: 499,
        xpMultiplier: 1.0,
      );
    } else if (trophies >= 167) {
      return LeagueModel(
        name: 'Bronze II',
        minTrophies: 167,
        maxTrophies: 333,
        xpMultiplier: 1.0,
      );
    } else {
      return LeagueModel(
        name: 'Bronze III',
        minTrophies: 0,
        maxTrophies: 166,
        xpMultiplier: 1.0,
      );
    }
  }
}
