import 'package:get/get.dart';

import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/todo_repository.dart';
import '../controllers/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileController>(
      () => ProfileController(
        Get.find<TodoRepository>(),
        Get.find<ProfileRepository>(),
      ),
    );
  }
}
