import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/todo.dart';
import '../../bin/controllers/bin_controller.dart';
import '../../bin/views/bin_view.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../../done/views/done_view.dart';
import '../../profile/views/profile_view.dart';
import '../controllers/home_controller.dart';
import '../widgets/todo_form.dart';

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
      final tabIndex = controller.tabIndex;
      final titles = <String>[
        'tab.dashboard'.tr,
        'tab.completed'.tr,
        'tab.archive'.tr,
        'tab.profile'.tr,
      ];
      return Scaffold(
        appBar: AppBar(
          title: Text(titles[tabIndex]),
          actions: [
            if (tabIndex == 0) const _SortMenu(),
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
        floatingActionButton: tabIndex == 0
            ? FloatingActionButton.extended(
                key: addTodoFabKey,
                onPressed: () => _openTodoForm(context),
                icon: const Icon(Icons.add),
                label: Text('action.addTask'.tr),
              )
            : null,
        body: IndexedStack(
          index: tabIndex,
          children: [
            DashboardView(onOpenForm: _openTodoForm),
            DoneView(onOpenForm: _openTodoForm),
            const BinBody(),
            const ProfileView(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tabIndex,
          onDestinationSelected: controller.changeTab,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.fact_check_outlined),
              selectedIcon: const Icon(Icons.fact_check),
              label: 'nav.checks'.tr,
            ),
            NavigationDestination(
              icon: const Icon(Icons.done_all_outlined),
              selectedIcon: const Icon(Icons.done_all),
              label: 'nav.completed'.tr,
            ),
            NavigationDestination(
              icon: const Icon(Icons.delete_outline),
              selectedIcon: const Icon(Icons.delete),
              label: 'nav.archive'.tr,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: 'nav.profile'.tr,
            ),
          ],
        ),
      );
    });
  }
}

class _SortMenu extends GetView<DashboardController> {
  const _SortMenu();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => PopupMenuButton<SortOption>(
        tooltip: 'action.sort'.tr,
        icon: const Icon(Icons.sort),
        initialValue: controller.sortOption,
        onSelected: controller.changeSort,
        itemBuilder: (_) {
          return SortOption.values
              .map(
                (option) => PopupMenuItem<SortOption>(
                  value: option,
                  child: Text(option.label),
                ),
              )
              .toList();
        },
      ),
    );
  }
}
