import 'package:get/get.dart';
import 'package:domrun/app/profile/controller/profile_controller.dart';
import 'package:domrun/app/profile/service/profile_service.dart';
import 'package:domrun/app/user/service/user_service.dart';
import 'package:domrun/app/maps/service/geocoding_service.dart';
import 'package:domrun/app/maps/service/mapbox_static_image_service.dart';

/// Binding para a página de perfil
/// Registra o ProfileController como dependência
class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // Registra o ProfileController
    Get.lazyPut<ProfileController>(() => ProfileController());
    Get.lazyPut<UserService>(() => UserService(), fenix: true);
    Get.lazyPut<ProfileService>(() => ProfileService(), fenix: true);
    Get.lazyPut<MapboxGeocodingService>(
      () => MapboxGeocodingService(),
      fenix: true,
    );
    Get.lazyPut<MapboxStaticImageService>(
      () => MapboxStaticImageService(),
      fenix: true,
    );
  }
}
