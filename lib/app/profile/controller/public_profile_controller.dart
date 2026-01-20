import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:nur_app/app/profile/models/public_user_profile.dart';
import 'package:nur_app/app/profile/service/public_profile_service.dart';
import 'package:nur_app/core/constants/api_constants.dart';

/// Controller para perfil público de outro usuário
class PublicProfileController extends GetxController {
  final PublicProfileService _service;

  PublicProfileController(this._service);

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
    try {
      final token = ApiConstants.mapboxAccessToken;
      final url =
          'https://api.mapbox.com/geocoding/v5/mapbox.places/$longitude,$latitude.json?types=place&access_token=$token';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final features = data['features'] as List? ?? [];
      if (features.isEmpty) return null;

      final placeFeature = features.firstWhere(
        (feature) {
          final types = (feature as Map<String, dynamic>)['place_type'] as List?;
          return types?.contains('place') == true;
        },
        orElse: () => features.first as Map<String, dynamic>,
      ) as Map<String, dynamic>;

      return placeFeature['text'] as String?;
    } catch (_) {
      return null;
    }
  }
}
