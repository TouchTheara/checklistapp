import 'package:get/get.dart';

import '../../../data/repositories/todo_repository.dart';
import '../controllers/done_controller.dart';

class DoneBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DoneController>(
      () => DoneController(Get.find<TodoRepository>()),
    );
  }
}
