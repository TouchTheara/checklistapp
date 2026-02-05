import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
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
import '../../../routes/app_routes.dart';
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
                if (tabIndex != 2) // skip showing on archive tab
                  Obx(() {
                    final unread = notifCtrl.unreadCount;
                    return IconButton(
                      tooltip: 'Notifications',
                      onPressed: () => Get.toNamed(Routes.notifications),
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications_none),
                          if (unread > 0)
                            Positioned(
                              right: -6,
                              top: -6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  unread > 9 ? '9+' : unread.toString(),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 11),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
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
      floatingActionButtonLocation: tabIndex == 0
          ? FloatingActionButtonLocation.endDocked
          : FloatingActionButtonLocation.centerDocked,
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
        final labels = [
          'nav.checks'.tr,
          'nav.completed'.tr,
          'nav.archive'.tr,
          'nav.notifications'.tr,
          'nav.profile'.tr,
        ];
        final icons = [
          Icons.fact_check_outlined,
          Icons.done_all_outlined,
          Icons.delete_outline,
          Icons.notifications_none,
          Icons.person_outline,
        ];
        Widget buildIcon(int index, bool isActive) {
          final color = isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant;
          if (index != 3) return Icon(icons[index], color: color);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                isActive ? Icons.notifications : Icons.notifications_none,
                color: color,
              ),
              if (unread > 0)
                Positioned(
                  right: -8,
                  top: -6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unread > 9 ? '9+' : unread.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          );
        }

        final showFab = tabIndex == 0;
        return AnimatedBottomNavigationBar.builder(
          itemCount: icons.length,
          tabBuilder: (index, isActive) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildIcon(index, isActive),
              const SizedBox(height: 4),
              Text(
                labels[index],
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
          activeIndex: tabIndex,
          gapLocation: showFab ? GapLocation.end : GapLocation.none,
          notchSmoothness: NotchSmoothness.softEdge,
          leftCornerRadius: 24,
          rightCornerRadius: showFab ? 0 : 24,
          height: 72,
          backgroundColor: theme.colorScheme.surface,
          onTap: controller.changeTab,
        );
      }),
    );
  }
}
