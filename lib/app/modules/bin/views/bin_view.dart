import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../../data/models/todo.dart';
import '../controllers/bin_controller.dart';

class BinView extends GetView<BinController> {
  const BinView({super.key});

  Future<void> _confirmEmpty(BuildContext context) async {
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
      controller.emptyBin();
      Get.snackbar(
        'bin.emptied.title'.tr,
        'bin.emptied.desc'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('tab.archive'.tr),
        actions: [
          Obx(
            () => TextButton.icon(
              onPressed:
                  controller.hasBinItems ? () => _confirmEmpty(context) : null,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: Text('action.emptyArchive'.tr),
            ),
          ),
        ],
      ),
      body: const BinBody(),
    );
  }
}

class BinBody extends GetView<BinController> {
  const BinBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final deleted = controller.binTodos;
      return deleted.isEmpty
          ? const _BinEmptyState()
          : SmartRefresher(
              controller: controller.refreshController,
              enablePullDown: true,
              onRefresh: () async {
                await controller.refresh();
                controller.refreshController.refreshCompleted();
                controller.refreshController.resetNoData();
              },
              enablePullUp: controller.hasMore,
              onLoading: () {
                controller.loadMore();
                if (controller.hasMore) {
                  controller.refreshController.loadComplete();
                } else {
                  controller.refreshController.loadNoData();
                }
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: deleted.length,
                itemBuilder: (_, index) {
                  final todo = deleted[index];
                  return Padding(
                    padding: EdgeInsets.only(
                        bottom: index == deleted.length - 1 ? 0 : 12),
                    child: _BinItemCard(
                      todo: todo,
                      onRestore: () => controller.restoreTodo(todo.id),
                      onDeleteForever: () => controller.deleteForever(todo.id),
                    ),
                  );
                },
              ));
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
            if (todo.description != null && todo.description!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  todo.description!,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_outline,
            size: 72,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'bin.empty.title'.tr,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'bin.empty.desc'.tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
