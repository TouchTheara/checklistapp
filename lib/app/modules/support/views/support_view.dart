import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../modules/profile/controllers/profile_controller.dart';

class SupportView extends StatelessWidget {
  const SupportView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('support.title'.tr),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.article_outlined),
                title: Text('support.faq'.tr),
                subtitle: Text('support.faq.desc'.tr),
                onTap: () {
                  Get.snackbar(
                    'support.faq'.tr,
                    'support.faq.desc'.tr,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.mail_outline),
                title: Text('support.contact'.tr),
                subtitle: Text(controller.supportEmail),
                trailing: const Icon(Icons.copy),
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: controller.supportEmail),
                  );
                  Get.snackbar(
                    'support.copied'.tr,
                    'support.copied.desc'.tr,
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.book_outlined),
                title: Text('support.guide'.tr),
                subtitle: Text('support.guide.desc'.tr),
                onTap: () {
                  Get.snackbar(
                    'support.guide'.tr,
                    'support.guide.desc'.tr,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
