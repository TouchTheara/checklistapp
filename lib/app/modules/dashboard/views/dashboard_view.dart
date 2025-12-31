import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/todo.dart';
import '../../../routes/app_routes.dart';
import '../../home/widgets/dashboard_card.dart';
import '../../home/widgets/todo_list.dart';
import '../controllers/dashboard_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({
    super.key,
    required this.onOpenForm,
  });

  final void Function(BuildContext context, {Todo? existing}) onOpenForm;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final todos = controller.todos;
      final canReorder = controller.sortOption == SortOption.manual &&
          !controller.urgentOnly &&
          controller.categories.isNotEmpty;
      if (todos.isEmpty) {
        return CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _FilterHeader(
                child: _FilterBar(controller: controller),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _HomeEmptyState(),
              ),
            ),
          ],
        );
      }
      return CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterHeader(
              child: _FilterBar(controller: controller),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.only(left: 12, right: 12, bottom: 4, top: 0),
              child: DashboardCard(
                total: controller.totalCount,
                completed: controller.completedCount,
                rate: controller.completionRate,
                priorityBreakdown: controller.priorityBreakdown,
              ),
            ),
          ),
          if (canReorder)
            SliverReorderableList(
              itemCount: todos.length,
              onReorder: controller.reorder,
              itemBuilder: (_, index) {
                final todo = todos[index];
                return TodoCard(
                  key: ValueKey('todo_${todo.id}'),
                  todo: todo,
                  onToggle: () => controller.toggleCompleted(todo.id),
                  onDelete: () => controller.deleteTodo(todo.id),
                  onEdit: () => onOpenForm(context, existing: todo),
                  onOpenDetail: () => Get.toNamed(
                    Routes.todoDetail,
                    arguments: todo.id,
                  ),
                  isDashboard: true,
                );
              },
            )
          else
            SliverList.separated(
              itemCount: todos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final todo = todos[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TodoCard(
                    key: ValueKey('todo_${todo.id}'),
                    todo: todo,
                    onToggle: () => controller.toggleCompleted(todo.id),
                    onDelete: () => controller.deleteTodo(todo.id),
                    onEdit: () => onOpenForm(context, existing: todo),
                    onOpenDetail: () => Get.toNamed(
                      Routes.todoDetail,
                      arguments: todo.id,
                    ),
                    isDashboard: true,
                  ),
                );
              },
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      );
    });
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'search.tasks'.tr,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              isDense: true,
              filled: true,
            ),
            onChanged: controller.updateSearch,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openSmartAdd(context),
                  icon: const Icon(Icons.auto_awesome),
                  label: Text('smart.add'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'smart.voice.tooltip'.tr,
                onPressed: () => _openSmartAdd(context, voiceMode: true),
                icon: const Icon(Icons.mic_none),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: Text('filter.urgent'.tr),
                  avatar: const Icon(Icons.priority_high, size: 18),
                  selected: controller.urgentOnly,
                  onSelected: (_) => controller.toggleUrgentOnly(),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<TodoPriority?>(
                  tooltip: 'filter.priority'.tr,
                  onSelected: controller.updatePriorityFilter,
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: null,
                      child: Text('filter.priority.any'.tr),
                    ),
                    ...TodoPriority.values.map(
                      (p) => PopupMenuItem(
                        value: p,
                        child: Text(p.label),
                      ),
                    ),
                  ],
                  child: Chip(
                    label: Text('filter.priority'.tr),
                    avatar: const Icon(Icons.filter_alt, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String?>(
                  tooltip: 'filter.category'.tr,
                  onSelected: controller.updateCategoryFilter,
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: '',
                      child: Text('filter.category.any'.tr),
                    ),
                    ...controller.categories.map(
                      (c) => PopupMenuItem(
                        value: c,
                        child: Text(c),
                      ),
                    ),
                  ],
                  child: Chip(
                    label: Text('filter.category'.tr),
                    avatar: const Icon(Icons.folder_open, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<SortOption>(
                  tooltip: 'filter.sort'.tr,
                  onSelected: controller.changeSort,
                  initialValue: controller.sortOption,
                  itemBuilder: (_) => SortOption.values
                      .map(
                        (opt) => PopupMenuItem(
                          value: opt,
                          child: Text(opt.label),
                        ),
                      )
                      .toList(),
                  child: Chip(
                    label: Text('filter.sort'.tr),
                    avatar: const Icon(Icons.sort, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSmartAdd(BuildContext context,
      {bool voiceMode = false}) async {
    final controller = Get.find<DashboardController>();
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(voiceMode ? 'smart.voice.title'.tr : 'smart.add'.tr),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
            hintText: voiceMode
                ? 'smart.voice.hint'.tr
                : 'smart.add.hint'.tr,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('form.cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(textController.text.trim()),
            child: Text('form.save'.tr),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      controller.addSmartTask(result);
      Get.snackbar(
        'smart.added.title'.tr,
        'smart.added.desc'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

class _HomeEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withOpacity(0.08),
            ),
            child: Icon(
              Icons.fact_check_outlined,
              size: 72,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'empty.title'.tr,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'empty.desc'.tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _FilterHeader extends SliverPersistentHeaderDelegate {
  _FilterHeader({required this.child});

  final Widget child;

  @override
  double get minExtent => 170;

  @override
  double get maxExtent => 180;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: overlapsContent ? 1 : 0,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _FilterHeader oldDelegate) {
    return oldDelegate.child != child;
  }
}
