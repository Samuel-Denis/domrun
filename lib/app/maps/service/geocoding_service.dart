import 'dart:convert';
import 'package:get/get.dart';
import 'package:domrun/core/constants/api_constants.dart';
import 'package:domrun/core/services/http_service.dart';

/// Serviço para geocoding usando Mapbox (cidade por coordenadas)
class MapboxGeocodingService extends GetxService {
  final HttpService _httpService = Get.find<HttpService>();

  Future<String?> reverseGeocodeCity({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = ApiConstants.mapboxAccessToken;
      final url =
          'https://api.mapbox.com/geocoding/v5/mapbox.places/$longitude,$latitude.json?types=place&access_token=$token';
      final response = await _httpService.getUrl(
        url,
        includeAuth: false,
      );
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
