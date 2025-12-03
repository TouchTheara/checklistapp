import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/app_controller.dart';
import '../../../data/models/profile.dart';
import '../../../widgets/app_text_field.dart';
import '../controllers/profile_controller.dart';
import '../../support/views/support_view.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appController = Get.find<AppController>();
    return Obx(() {
      final profile = controller.profile;
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
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      size: 32,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.email,
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
              onTap: () => Get.to(() => const SupportView()),
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
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
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

Future<void> _openEditProfile(BuildContext context) async {
  final controller = Get.find<ProfileController>();
  final updated = await showModalBottomSheet<Profile>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ProfileEditSheet(
      initialProfile: controller.profile,
      notificationsEnabled: controller.notificationsEnabled,
    ),
  );

  if (updated != null) {
    await controller.saveProfile(
      name: updated.name,
      email: updated.email,
    );
    Get.snackbar(
      'Profile updated',
      'Your details were saved.',
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
                            notificationsEnabled:
                                widget.notificationsEnabled,
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
