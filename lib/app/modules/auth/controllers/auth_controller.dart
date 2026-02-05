import 'package:get/get.dart';

import '../../../controllers/app_controller.dart';

class AuthController extends GetxController {
  AuthController(this._appController);

  final AppController _appController;
  final RxBool isLoading = false.obs;

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    final ok = await _appController.login(email, password);
    isLoading.value = false;
    return ok;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    final ok = await _appController.register(
      name: name,
      email: email,
      password: password,
    );
    isLoading.value = false;
    return ok;
  }

  Future<bool> loginWithGoogle() async {
    isLoading.value = true;
    final ok = await _appController.loginWithGoogle();
    isLoading.value = false;
    return ok;
  }
}
