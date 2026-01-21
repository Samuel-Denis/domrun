import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../controller/navigation_controller.dart';

class NavSyncMiddleware extends GetMiddleware {
  @override
  Widget Function()? onPageBuildStart(Widget Function()? page) {
    if (Get.isRegistered<NavigationController>()) {
      Get.find<NavigationController>().syncIndexWithCurrentRoute();
    }
    return page;
  }
}
