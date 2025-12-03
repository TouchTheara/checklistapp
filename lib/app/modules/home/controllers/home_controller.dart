import 'package:get/get.dart';

class HomeController extends GetxController {
  final RxInt _tabIndex = 0.obs;

  int get tabIndex => _tabIndex.value;

  void changeTab(int index) {
    if (index == _tabIndex.value) return;
    _tabIndex.value = index;
  }
}
