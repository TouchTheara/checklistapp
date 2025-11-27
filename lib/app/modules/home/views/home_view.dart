import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/todo.dart';
import '../controllers/home_controller.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/todo_form.dart';
import '../widgets/todo_list.dart';
import 'bin_view.dart';

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

  Future<void> _confirmEmptyBin(BuildContext context) async {
    final shouldEmpty = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Empty bin?'),
            content: const Text(
              'This will permanently delete all items in your bin.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Empty bin'),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldEmpty) {
      controller.emptyBin();
      Get.snackbar(
          'Bin emptied', 'All discarded items were permanently deleted',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tabIndex = controller.tabIndex;
      final hasBinItems = controller.hasBinItems;
      final titles = <String>[
        'Checklist Dashboard',
        'Done',
        'Bin',
      ];
      return Scaffold(
        appBar: AppBar(
          title: Text(titles[tabIndex]),
          actions: [
            if (tabIndex == 0) const _SortMenu(),
            if (tabIndex == 2)
              TextButton.icon(
                onPressed: hasBinItems ? () => _confirmEmptyBin(context) : null,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Empty bin'),
              ),
          ],
        ),
        floatingActionButton: tabIndex == 0
            ? FloatingActionButton.extended(
                key: addTodoFabKey,
                onPressed: () => _openTodoForm(context),
                icon: const Icon(Icons.add),
                label: const Text('Add task'),
              )
            : null,
        body: IndexedStack(
          index: tabIndex,
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DashboardCard(
                    total: controller.totalCount,
                    completed: controller.completedCount,
                    rate: controller.completionRate,
                    priorityBreakdown: controller.priorityBreakdown,
                  ),
                ),
                Expanded(
                  child: TodoListView(
                    todos: controller.todos,
                    onToggle: controller.toggleCompleted,
                    onDelete: controller.deleteTodo,
                    onEdit: (todo) => _openTodoForm(context, existing: todo),
                    isDashboard: true,
                  ),
                ),
              ],
            ),
            TodoListView(
              todos: controller.doneTodos,
              onToggle: controller.toggleCompleted,
              onDelete: controller.deleteTodo,
              onEdit: (todo) => _openTodoForm(context, existing: todo),
              emptyTitle: 'No tasks completed yet',
              emptyDescription:
                  'Mark checklist items as done to review them here.',
              emptyIcon: Icons.celebration_outlined,
              isDashboard: false,
            ),
            const BinBody(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tabIndex,
          onDestinationSelected: controller.changeTab,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check),
              label: 'Checklist',
            ),
            NavigationDestination(
              icon: Icon(Icons.done_all_outlined),
              selectedIcon: Icon(Icons.done_all),
              label: 'Done',
            ),
            NavigationDestination(
              icon: Icon(Icons.delete_outline),
              selectedIcon: Icon(Icons.delete),
              label: 'Bin',
            ),
          ],
        ),
      );
    });
  }
}

class _SortMenu extends GetView<HomeController> {
  const _SortMenu();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => PopupMenuButton<SortOption>(
        tooltip: 'Sort checklist',
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
