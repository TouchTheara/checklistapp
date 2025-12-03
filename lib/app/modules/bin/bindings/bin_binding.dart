import 'package:get/get.dart';

import '../../../data/repositories/todo_repository.dart';
import '../controllers/bin_controller.dart';

class BinBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BinController>(
      () => BinController(Get.find<TodoRepository>()),
    );
  }
}
