import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../controllers/app_controller.dart';
import '../../../data/models/profile.dart';
import '../../../widgets/app_text_field.dart';
import '../controllers/profile_controller.dart';
import '../../../routes/app_routes.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appController = Get.find<AppController>();
    return Obx(() {
      final profile = controller.profile;
      final displayName = appController.userName ?? profile.name;
      final displayEmail = appController.userEmail ?? profile.email;
      final total = controller.totalCount;
      final completed = controller.completedCount;
      final completionRate = controller.completionRate;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _ProfileAvatar(controller: controller),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayEmail,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'profile.edit'.tr,
                    onPressed: () => _openEditProfile(context),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'profile.snapshot'.tr,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _ProfileStat(
                        label: 'profile.total'.tr,
                        value: total.toString(),
                        icon: Icons.fact_check,
                      ),
                      const SizedBox(width: 12),
                      _ProfileStat(
                        label: 'profile.completed'.tr,
                        value: completed.toString(),
                        icon: Icons.done_all,
                      ),
                      const SizedBox(width: 12),
                      _ProfileStat(
                        label: 'profile.completion'.tr,
                        value: '${(completionRate * 100).round()}%',
                        icon: Icons.trending_up,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: Text('profile.darkmode'.tr),
                  subtitle: Text('profile.darkmode.desc'.tr),
                  value: appController.themeMode == ThemeMode.dark,
                  onChanged: (enabled) => appController.changeTheme(
                    enabled ? ThemeMode.dark : ThemeMode.light,
                  ),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_none),
                  title: Text('profile.notifications'.tr),
                  subtitle: Text('profile.notifications.desc'.tr),
                  value: controller.notificationsEnabled,
                  onChanged: (enabled) =>
                      controller.toggleNotifications(enabled),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.help_outline),
              title: Text('profile.help'.tr),
              subtitle: Text('support.faq.desc'.tr),
              onTap: () => Get.toNamed(Routes.support),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text('settings.language'.tr),
              subtitle: Text(
                appController.locale.languageCode == 'km'
                    ? 'settings.language.khmer'.tr
                    : 'settings.language.english'.tr,
              ),
              onTap: () => _showLanguageSheet(context, appController),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.article_outlined),
              title: Text('terms.privacy'.tr),
              subtitle: Text('terms.description'.tr),
              onTap: () => Get.toNamed(Routes.terms),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () async {
                await appController.logout();
                Get.offAllNamed(Routes.auth);
              },
            ),
          ),
        ],
      );
    });
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarPath = controller.avatarPath;
    final hasImage = avatarPath != null && avatarPath.isNotEmpty;
    ImageProvider? provider;
    final path = avatarPath;
    if (path != null && path.isNotEmpty) {
      if (path.startsWith('http')) {
        provider = NetworkImage(path);
      } else {
        provider = FileImage(File(path)) as ImageProvider;
      }
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: provider,
          child: hasImage
              ? null
              : Icon(
                  Icons.person,
                  size: 32,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
        ),
        Positioned(
          bottom: -4,
          right: -4,
          child: IconButton(
            tooltip: 'profile.edit'.tr,
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surface,
              minimumSize: const Size(32, 32),
              padding: const EdgeInsets.all(4),
            ),
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            onPressed: () => _showImageSourceSheet(context),
          ),
        ),
      ],
    );
  }
}

Future<void> _openEditProfile(BuildContext context) async {
  final controller = Get.find<ProfileController>();
  final appController = Get.find<AppController>();
  final initial = controller.profile;
  final updated = await showModalBottomSheet<Profile>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ProfileEditSheet(
      initialProfile: initial.copyWith(
        name: appController.userName ?? initial.name,
        email: appController.userEmail ?? initial.email,
      ),
      notificationsEnabled: controller.notificationsEnabled,
    ),
  );

  if (updated != null) {
    await controller.saveProfile(
      name: updated.name,
      email: updated.email,
    );
    await appController.updateAuthProfile(
      name: updated.name,
      email: updated.email,
    );
    Get.snackbar(
      'profile.edit'.tr,
      'profile.photo.updated'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

void _showLanguageSheet(BuildContext context, AppController appController) {
  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.language),
              title: Text('settings.language.english'.tr),
              onTap: () {
                appController.changeLocale(const Locale('en', 'US'));
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text('settings.language.khmer'.tr),
              onTap: () {
                appController.changeLocale(const Locale('km', 'KH'));
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _showImageSourceSheet(BuildContext context) async {
  // if (!GetPlatform.isAndroid && !GetPlatform.isIOS) {
  //   Get.snackbar(
  //     'profile.edit'.tr,
  //     'profile.photo.unsupported'.tr,
  //     snackPosition: SnackPosition.BOTTOM,
  //   );
  //   return;
  // }

  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('profile.photo.gallery'.tr),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text('profile.photo.camera'.tr),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
          ],
        ),
      );
    },
  );

  if (source == null) return;
  if (!context.mounted) return;
  await _pickProfileImage(context, source);
}

Future<void> _pickProfileImage(BuildContext context, ImageSource source) async {
  final controller = Get.find<ProfileController>();
  final picker = ImagePicker();
  try {
    final result = await picker.pickImage(source: source);
    if (result == null) return;
    await controller.updateAvatar(result.path);
    Get.snackbar(
      'profile.edit'.tr,
      'profile.photo.updated'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  } on PlatformException {
    Get.snackbar(
      'profile.edit'.tr,
      'profile.photo.error'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

class _ProfileEditSheet extends StatefulWidget {
  const _ProfileEditSheet({
    required this.initialProfile,
    required this.notificationsEnabled,
  });

  final Profile initialProfile;
  final bool notificationsEnabled;

  @override
  State<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<_ProfileEditSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProfile.name);
    _emailController = TextEditingController(text: widget.initialProfile.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_outline,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'profile.edit'.tr,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AppTextField(
                  controller: _nameController,
                  label: 'form.name'.tr,
                  hintText: 'form.name.hint'.tr,
                  prefixIcon: const Icon(Icons.badge_outlined),
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'form.name.error'.tr;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _emailController,
                  label: 'form.email'.tr,
                  hintText: 'form.email.hint'.tr,
                  prefixIcon: const Icon(Icons.alternate_email),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'form.email.error'.tr;
                    }
                    if (!value.contains('@')) {
                      return 'form.email.invalid'.tr;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('form.cancel'.tr),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () {
                        if (!(_formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        Navigator.of(context).pop(
                          Profile(
                            name: _nameController.text.trim(),
                            email: _emailController.text.trim(),
                            notificationsEnabled: widget.notificationsEnabled,
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('form.save'.tr),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
