import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/app_controller.dart';
import '../../../widgets/app_text_field.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../routes/app_routes.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _authController = Get.put(AuthController(Get.find<AppController>()));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('auth.welcome'.tr),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'auth.login'.tr),
            Tab(text: 'auth.register'.tr),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LoginForm(authController: _authController),
          _RegisterForm(authController: _authController),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: OutlinedButton.icon(
            onPressed: () => Get.toNamed(Routes.terms),
            icon: const Icon(Icons.article_outlined),
            label: Text('terms.privacy'.tr),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(color: theme.colorScheme.primary),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm({required this.authController});

  final AuthController authController;

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await widget.authController.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    if (!ok) {
      Get.snackbar(
        'auth.failed'.tr,
        'auth.login.error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    Get.offAllNamed(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _emailController,
              label: 'form.email'.tr,
              hintText: 'form.email.hint'.tr,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.alternate_email),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'form.email.error'.tr;
                }
                if (!value.contains('@')) return 'form.email.invalid'.tr;
                return null;
              },
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _passwordController,
              label: 'form.password'.tr,
              hintText: 'form.password.hint'.tr,
              prefixIcon: const Icon(Icons.lock_outline),
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'form.password.error'.tr;
                }
                if (value.length < 6) return 'form.password.length'.tr;
                return null;
              },
            ),
            const SizedBox(height: 20),
            Obx(
              () => ElevatedButton(
                onPressed:
                    widget.authController.isLoading.value ? null : _submit,
                child: widget.authController.isLoading.value
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('auth.login'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterForm extends StatefulWidget {
  const _RegisterForm({required this.authController});

  final AuthController authController;

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await widget.authController.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    if (!ok) {
      Get.snackbar('auth.failed'.tr, 'auth.register.error'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    Get.offAllNamed(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _nameController,
              label: 'form.name'.tr,
              hintText: 'form.name.hint'.tr,
              prefixIcon: const Icon(Icons.badge_outlined),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'form.name.error'.tr;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _emailController,
              label: 'form.email'.tr,
              hintText: 'form.email.hint'.tr,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.alternate_email),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'form.email.error'.tr;
                }
                if (!value.contains('@')) return 'form.email.invalid'.tr;
                return null;
              },
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _passwordController,
              label: 'form.password'.tr,
              hintText: 'form.password.hint'.tr,
              prefixIcon: const Icon(Icons.lock_outline),
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'form.password.error'.tr;
                }
                if (value.length < 6) return 'form.password.length'.tr;
                return null;
              },
            ),
            const SizedBox(height: 20),
            Obx(
              () => ElevatedButton(
                onPressed:
                    widget.authController.isLoading.value ? null : _submit,
                child: widget.authController.isLoading.value
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('auth.register'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
