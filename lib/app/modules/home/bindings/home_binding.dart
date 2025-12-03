import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../../dashboard/bindings/dashboard_binding.dart';
import '../../done/bindings/done_binding.dart';
import '../../bin/bindings/bin_binding.dart';
import '../../profile/bindings/profile_binding.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    DashboardBinding().dependencies();
    DoneBinding().dependencies();
    BinBinding().dependencies();
    ProfileBinding().dependencies();
    Get.lazyPut<HomeController>(() => HomeController());
  }
}
