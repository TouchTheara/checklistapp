import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/todo.dart';
import '../controllers/home_controller.dart';

class BinView extends GetView<HomeController> {
  const BinView({super.key});

  Future<void> _confirmEmpty(BuildContext context) async {
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
      Get.snackbar('Bin emptied', 'All discarded items were permanently deleted',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bin'),
        actions: [
          Obx(
            () => TextButton.icon(
              onPressed: controller.hasBinItems
                  ? () => _confirmEmpty(context)
                  : null,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Empty bin'),
            ),
          ),
        ],
      ),
      body: const BinBody(),
    );
  }
}

class BinBody extends GetView<HomeController> {
  const BinBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final deleted = controller.binTodos;
      if (deleted.isEmpty) {
        return const _BinEmptyState();
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, index) {
          final todo = deleted[index];
          return _BinItemCard(
            todo: todo,
            onRestore: () => controller.restoreTodo(todo.id),
            onDeleteForever: () => controller.deleteForever(todo.id),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: deleted.length,
      );
    });
  }
}

class _BinItemCard extends StatelessWidget {
  const _BinItemCard({
    required this.todo,
    required this.onRestore,
    required this.onDeleteForever,
  });

  final Todo todo;
  final VoidCallback onRestore;
  final VoidCallback onDeleteForever;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Restore',
                  icon: const Icon(Icons.restore),
                  onPressed: onRestore,
                ),
                IconButton(
                  tooltip: 'Delete forever',
                  icon: const Icon(Icons.delete_forever),
                  onPressed: onDeleteForever,
                ),
              ],
            ),
            if (todo.description != null &&
                todo.description!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  todo.description!,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Moved to bin ${_formatTimestamp(todo.deletedAt ?? todo.createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    return '${difference.inDays}d ago';
  }
}

class _BinEmptyState extends StatelessWidget {
  const _BinEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.delete_outline,
            size: 72,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Bin is empty',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Deleted items stay here temporarily until you empty the bin.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

