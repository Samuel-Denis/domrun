import 'package:get/get.dart';
import 'package:domrun/app/profile/models/public_user_profile.dart';
import 'package:domrun/app/profile/service/public_profile_service.dart';
import 'package:domrun/app/maps/service/geocoding_service.dart';

/// Controller para perfil público de outro usuário
class PublicProfileController extends GetxController {
  final PublicProfileService _service;
  final MapboxGeocodingService _geocodingService;

  PublicProfileController(this._service, this._geocodingService);

  final Rxn<PublicUserProfile> user = Rxn<PublicUserProfile>();
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();
  final Map<String, String> _cityCache = {};

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    final userId = args is Map ? args['userId'] as String? : null;
    if (userId != null && userId.isNotEmpty) {
      loadUser(userId);
    } else {
      error.value = 'ID do usuário não informado';
    }
  }

  Future<void> loadUser(String userId) async {
    try {
      isLoading.value = true;
      error.value = null;
      user.value = await _service.getUserById(userId);
      await _fillRunCities();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fillRunCities() async {
    final currentUser = user.value;
    if (currentUser == null) return;
    if (currentUser.runs.isEmpty) return;

    final updatedRuns = <PublicRun>[];
    for (final run in currentUser.runs) {
      if ((run.location ?? '').trim().isNotEmpty) {
        updatedRuns.add(run);
        continue;
      }

      if (run.path.isEmpty) {
        updatedRuns.add(run);
        continue;
      }

      final point = run.path.first;
      final cacheKey =
          '${point.latitude.toStringAsFixed(3)},${point.longitude.toStringAsFixed(3)}';
      if (_cityCache.containsKey(cacheKey)) {
        updatedRuns.add(run.copyWith(location: _cityCache[cacheKey]));
        continue;
      }

      final city = await _reverseGeocodeCity(
        latitude: point.latitude,
        longitude: point.longitude,
      );
      if (city != null && city.isNotEmpty) {
        _cityCache[cacheKey] = city;
        updatedRuns.add(run.copyWith(location: city));
      } else {
        updatedRuns.add(run);
      }
    }

    user.value = currentUser.copyWith(runs: updatedRuns);
  }

  Future<String?> _reverseGeocodeCity({
    required double latitude,
    required double longitude,
  }) async {
    return _geocodingService.reverseGeocodeCity(
      latitude: latitude,
      longitude: longitude,
    );
  }
}
