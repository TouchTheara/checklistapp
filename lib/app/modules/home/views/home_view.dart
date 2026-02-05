import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/todo.dart';
import '../../bin/controllers/bin_controller.dart';
import '../../bin/views/bin_view.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../../done/views/done_view.dart';
import '../../profile/views/profile_view.dart';
import '../controllers/home_controller.dart';
import '../widgets/todo_form.dart';
import '../../notifications/controllers/notifications_controller.dart';
import '../../notifications/views/notifications_view.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  static const addTodoFabKey = Key('add_todo_fab');

  void _openTodoForm(BuildContext context, {Todo? existing}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TodoForm(existing: existing),
    );
  }

  Future<void> _confirmEmptyBin(
    BuildContext context,
    BinController binController,
  ) async {
    final shouldEmpty = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('bin.confirm.title'.tr),
            content: Text('bin.confirm.body'.tr),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('bin.confirm.cancel'.tr),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('bin.confirm.ok'.tr),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldEmpty) {
      binController.emptyBin();
      Get.snackbar(
        'bin.emptied.title'.tr,
        'bin.emptied.desc'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final binController = Get.find<BinController>();
    return Obx(() {
      if (controller.isLoading) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      final tabIndex = controller.tabIndex;
      final titles = <String>[
        'tab.dashboard'.tr,
        'tab.completed'.tr,
        'tab.archive'.tr,
        'nav.notifications'.tr,
        'tab.profile'.tr,
      ];
      return _buildScaffold(context, tabIndex, titles, binController);
    });
  }

  Widget _buildScaffold(
    BuildContext context,
    int tabIndex,
    List<String> titles,
    BinController binController,
  ) {
    // Hide app bar on dashboard (0), notifications (3), and profile (4)
    final hideAppBar = tabIndex == 0 || tabIndex == 3 || tabIndex == 4;
    final notifCtrl = Get.find<NotificationsController>();
    return Scaffold(
      appBar: hideAppBar
          ? null
          : AppBar(
              title: Text(titles[tabIndex]),
              actions: [
                if (tabIndex == 2)
                  Obx(
                    () {
                      final hasBinItems = binController.hasBinItems;
                      return TextButton.icon(
                        onPressed: hasBinItems
                            ? () => _confirmEmptyBin(context, binController)
                            : null,
                        icon: const Icon(Icons.delete_sweep_outlined),
                        label: Text('action.emptyArchive'.tr),
                      );
                    },
                  ),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: tabIndex == 0
          ? FloatingActionButton.extended(
              key: addTodoFabKey,
              onPressed: () => _openTodoForm(context),
              icon: const Icon(Icons.add),
              label: Text('action.addTask'.tr),
            )
          : null,
      body: SafeArea(
        child: IndexedStack(
          index: tabIndex,
          children: [
            DashboardView(onOpenForm: _openTodoForm),
            DoneView(onOpenForm: _openTodoForm),
            const BinBody(),
            const NotificationsView(),
            const ProfileView(),
          ],
        ),
      ),
      bottomNavigationBar: Obx(() {
        final unread = notifCtrl.unreadCount;
        final theme = Theme.of(context);
        final badge = unread > 0
            ? {
                3: unread > 9 ? '9+' : unread.toString(),
              }
            : <int, dynamic>{};
        return ConvexAppBar.badge(
          badge,
          initialActiveIndex: tabIndex,
          onTap: controller.changeTab,
          backgroundColor: theme.colorScheme.surface,
          activeColor: theme.colorScheme.primary,
          color: theme.colorScheme.onSurfaceVariant,
          elevation: 8,
          height: 64,
          top: -12,
          curveSize: 80,
          items: [
            TabItem(icon: Icons.fact_check_outlined, title: 'nav.checks'.tr),
            TabItem(icon: Icons.done_all_outlined, title: 'nav.completed'.tr),
            TabItem(icon: Icons.delete_outline, title: 'nav.archive'.tr),
            TabItem(
                icon: Icons.notifications_none, title: 'nav.notifications'.tr),
            TabItem(icon: Icons.person_outline, title: 'nav.profile'.tr),
          ],
        );
      }),
    );
  }
}
