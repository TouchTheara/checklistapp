import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/todo.dart';
import '../../home/widgets/todo_list.dart';
import '../../home/widgets/todo_form.dart';
import '../controllers/search_controller.dart';

class SearchView extends GetView<AppSearchController> {
  const SearchView({super.key});

  void _openTodoForm(BuildContext context, {Todo? existing}) {
    // Reuse the form from home module
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TodoForm(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      'search.tab.active'.tr,
      'search.tab.completed'.tr,
      'search.tab.archive'.tr
    ];
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'search.tasks'.tr,
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: controller.updateQuery,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Column(
              children: [
                TabBar(
                  onTap: controller.changeTab,
                  tabs: tabs.map((t) => Tab(text: t)).toList(),
                ),
                Obx(
                  () => controller.isSearching.value
                      ? const LinearProgressIndicator(minHeight: 2)
                      : const SizedBox(height: 2),
                ),
              ],
            ),
          ),
        ),
        body: Obx(
          () => TabBarView(
            children: [
              _buildActive(context),
              _buildDone(context),
              _buildBin(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActive(BuildContext context) {
    final items = controller.activeResults;
    return TodoListView(
      todos: items,
      onToggle: controller.toggleCompleted,
      onDelete: controller.deleteTodo,
      onEdit: (todo) => _openTodoForm(context, existing: todo),
      emptyTitle: 'empty.title',
      emptyDescription: 'empty.desc',
      emptyIcon: Icons.search,
    );
  }

  Widget _buildDone(BuildContext context) {
    final items = controller.doneResults;
    return TodoListView(
      todos: items,
      onToggle: controller.toggleCompleted,
      onDelete: controller.deleteTodo,
      onEdit: (todo) => _openTodoForm(context, existing: todo),
      emptyTitle: 'done.empty.title',
      emptyDescription: 'done.empty.desc',
      emptyIcon: Icons.search,
    );
  }

  Widget _buildBin(BuildContext context) {
    final items = controller.binResults;
    if (items.isEmpty) return const _SearchEmptyState();
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final todo = items[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        todo.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'search.restore'.tr,
                      icon: const Icon(Icons.restore),
                      onPressed: () => controller.restoreTodo(todo.id),
                    ),
                    IconButton(
                      tooltip: 'search.deleteForever'.tr,
                      icon: const Icon(Icons.delete_forever),
                      onPressed: () => controller.deleteForever(todo.id),
                    ),
                  ],
                ),
                if (todo.description != null &&
                    todo.description!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      todo.description!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            'search.empty.title'.tr,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'search.empty.desc'.tr,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
