import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:nur_app/core/services/http_service.dart';

/// Serviço para buscar imagens estáticas do Mapbox
class MapboxStaticImageService extends GetxService {
  final HttpService _httpService = Get.find<HttpService>();

  Future<Uint8List?> fetchImageBytes(String url) async {
    final response = await _httpService.getUrl(
      url,
      includeAuth: false,
    );
    if (response.statusCode != 200) return null;
    return response.bodyBytes;
  }
}
