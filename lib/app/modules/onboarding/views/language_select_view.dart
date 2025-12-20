import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/app_controller.dart';
import '../../../i18n/app_translations.dart';
import '../../../routes/app_routes.dart';

class LanguageSelectView extends StatelessWidget {
  const LanguageSelectView({super.key});

  @override
  Widget build(BuildContext context) {
    final appController = Get.find<AppController>();
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.language, size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'language.select.title'.tr,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'language.select.desc'.tr,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _LangButton(
                label: 'English',
                onTap: () => _choose(appController, AppTranslations.en),
              ),
              const SizedBox(height: 12),
              _LangButton(
                label: 'Khmer / ខ្មែរ',
                onTap: () => _choose(appController, AppTranslations.km),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _choose(AppController appController, Locale locale) async {
    await appController.changeLocale(locale);
    Get.offAllNamed(Routes.onboarding);
  }
}

class _LangButton extends StatelessWidget {
  const _LangButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          foregroundColor: theme.colorScheme.onSurface,
        ),
        child: Text(label),
      ),
    );
  }
}
