import 'package:get/get.dart';
import 'package:domrun/app/profile/controller/public_profile_controller.dart';
import 'package:domrun/app/profile/service/public_profile_service.dart';
import 'package:domrun/app/maps/service/geocoding_service.dart';

/// Binding para perfil público
class PublicProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PublicProfileService>(() => PublicProfileService());
    Get.lazyPut<MapboxGeocodingService>(
      () => MapboxGeocodingService(),
      fenix: true,
    );
    Get.lazyPut<PublicProfileController>(
      () => PublicProfileController(
        Get.find<PublicProfileService>(),
        Get.find<MapboxGeocodingService>(),
      ),
    );
  }
}
