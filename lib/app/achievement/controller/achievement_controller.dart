import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:nur_app/app/achievement/models/achievement_model.dart';
import 'package:nur_app/app/auth/service/auth_service.dart';
import 'package:nur_app/core/constants/api_constants.dart';

class AchievementsController extends GetxController {
  late final AuthService _authService;

  final isLoading = false.obs;
  final isClaiming = <String, bool>{}.obs;
  final errorMessage = RxnString();

  final selectedCategory = 'ALL'.obs;
  final showOnlyUnlocked = false.obs;
  final query = ''.obs;

  final achievements = <AchievementModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _authService = Get.find<AuthService>();
    fetchAchievements();
  }

  Future<void> fetchAchievements() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final token = _authService.getAccessToken();
      final res = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.achievementsEndpoint}',
        ),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }

      final decoded = jsonDecode(res.body);
      final List list = (decoded is Map && decoded['achievements'] is List)
          ? decoded['achievements'] as List
          : <dynamic>[];

      achievements.value = list
          .map((e) => AchievementModel.fromJson(e as Map<String, dynamic>))
          .where(
            (a) => !(a.isHidden && a.status == 'LOCKED'),
          ) // esconde secretas travadas
          .toList();

      _sortDefault();
    } catch (_) {
      errorMessage.value = 'Não foi possível carregar conquistas.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> claimAchievement(AchievementModel a) async {
    if (!a.isClaimable) return;

    isClaiming[a.code] = true;
    try {
      final token = _authService.getAccessToken();
      final res = await http.post(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.achievementsEndpoint}/${a.code}/claim',
        ),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }

      // Atualiza local (CLAIMED)
      final idx = achievements.indexWhere((x) => x.code == a.code);
      if (idx >= 0) {
        final old = achievements[idx];
        achievements[idx] = AchievementModel(
          id: old.id,
          code: old.code,
          title: old.title,
          description: old.description,
          category: old.category,
          rarity: old.rarity,
          iconAsset: old.iconAsset,
          isHidden: old.isHidden,
          criteriaJson: old.criteriaJson,
          rewardJson: old.rewardJson,
          seasonNumber: old.seasonNumber,
          status: 'CLAIMED',
          progress: old.progress,
          progressText: old.progressText,
          currentValue: old.currentValue,
          targetValue: old.targetValue,
          unlockedAt: old.unlockedAt,
          claimedAt: DateTime.now().toUtc(),
        );
      }

      _sortDefault();
      Get.snackbar('Boa!', 'Conquista resgatada.');
    } catch (_) {
      Get.snackbar('Ops', 'Não foi possível resgatar a conquista.');
    } finally {
      isClaiming.remove(a.code);
    }
  }

  void setCategory(String cat) => selectedCategory.value = cat;
  void toggleUnlockedOnly() => showOnlyUnlocked.value = !showOnlyUnlocked.value;
  void setQuery(String v) => query.value = v;

  List<AchievementModel> get filtered {
    final q = query.value.trim().toLowerCase();
    final cat = selectedCategory.value;
    final unlockedOnly = showOnlyUnlocked.value;

    return achievements.where((a) {
      if (cat != 'ALL' && a.category != cat) return false;
      if (unlockedOnly && !(a.status == 'UNLOCKED' || a.status == 'CLAIMED'))
        return false;
      if (q.isNotEmpty) {
        final hay = '${a.title} ${a.description} ${a.code}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  void _sortDefault() {
    int statusRank(String s) {
      switch (s) {
        case 'CLAIMED':
          return 0;
        case 'UNLOCKED':
          return 1;
        case 'IN_PROGRESS':
          return 2;
        case 'LOCKED':
          return 3;
        default:
          return 9;
      }
    }

    int rarityRank(String r) {
      switch (r) {
        case 'COMMON':
          return 0;
        case 'RARE':
          return 1;
        case 'EPIC':
          return 2;
        case 'LEGENDARY':
          return 3;
        default:
          return 9;
      }
    }

    achievements.sort((a, b) {
      final sr = statusRank(a.status).compareTo(statusRank(b.status));
      if (sr != 0) return sr;
      final rr = rarityRank(a.rarity).compareTo(rarityRank(b.rarity));
      if (rr != 0) return rr;
      final pr = b.normalizedProgress.compareTo(a.normalizedProgress);
      if (pr != 0) return pr;
      return a.title.compareTo(b.title);
    });
  }
}
