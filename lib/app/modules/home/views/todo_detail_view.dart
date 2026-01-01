import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';

import '../../../data/models/todo.dart';
import '../controllers/home_controller.dart';

class TodoDetailView extends GetView<HomeController> {
  const TodoDetailView({super.key, required this.todoId});

  final String todoId;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final todo = controller.todos.firstWhereOrNull((t) => t.id == todoId);
      if (todo == null) {
        return Scaffold(
          body: const Center(child: Text('Task not found')),
        );
      }
      final theme = Theme.of(context);
      final allSubtasksDone =
          todo.subtasks.isNotEmpty && todo.subtasks.every((s) => s.isDone);
      // Consider the task done if it is explicitly marked done OR all subtasks are done.
      final taskDone = todo.isCompleted || allSubtasksDone;
      return Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _addSubtask(context),
          icon: const Icon(Icons.add_task),
          label: Text('todo.subtasks.add'.tr),
        ),
        body: Stack(
          children: [
            // Sticky top controls
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [],
                ),
              ),
            ),
            // Scrollable content
            ListView(
              padding: EdgeInsets.zero,
              children: [
                _HeaderImage(
                  title: todo.title.isEmpty ? 'Untitled task' : todo.title,
                  attachments:
                      todo.attachments.isNotEmpty ? todo.attachments : [],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Chip(
                            avatar: const Icon(Icons.flag_outlined, size: 18),
                            label: Text(todo.priority.label),
                          ),
                          if (todo.dueDate != null)
                            Chip(
                              avatar: const Icon(Icons.event, size: 18),
                              label: Text('Due ${_formatDate(todo.dueDate!)}'),
                            ),
                          if (todo.reminderAt != null)
                            Chip(
                              avatar: const Icon(Icons.alarm, size: 18),
                              label: Text(
                                  'Reminder ${_formatDate(todo.reminderAt!)}'),
                            ),
                          if (todo.category != null &&
                              todo.category!.isNotEmpty)
                            Chip(
                              avatar: const Icon(Icons.folder_open, size: 18),
                              label: Text(todo.category!),
                            ),
                        ],
                      ),
                      if (todo.description != null &&
                          todo.description!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _ExpandableDescription(
                            text: todo.description!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: todo.progress,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'todo.subtasks.progress'.trParams({
                          'done': '${todo.completedSubtasks}',
                          'total': '${todo.totalSubtasks}',
                        }),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sub-tasks',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (todo.subtasks.isEmpty)
                        Text(
                          'todo.subtasks.empty'.tr,
                          style: theme.textTheme.bodyMedium,
                        )
                      else
                        ...todo.subtasks.map(
                          (sub) => Card(
                            child: ListTile(
                              title: Text(
                                  sub.title.isEmpty ? 'Untitled' : sub.title),
                              trailing: Checkbox(
                                value: sub.isDone,
                                shape: const CircleBorder(),
                                onChanged: (_) =>
                                    controller.toggleSubtask(todo.id, sub.id),
                              ),
                              onTap: () =>
                                  controller.toggleSubtask(todo.id, sub.id),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Material(
                      color: Colors.black45,
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Get.back();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        todo.title.isEmpty ? 'Untitled task' : todo.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 4,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: Colors.black45,
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: Icon(
                          taskDone
                              ? Icons.check_circle
                              : Icons.task_alt_outlined,
                          color: Colors.white,
                        ),
                        tooltip: 'Mark all sub-tasks done',
                        onPressed: () {
                          if (todo.subtasks.isEmpty) {
                            controller.toggleCompleted(todo.id);
                          } else {
                            if (allSubtasksDone) {
                              // Uncheck all
                              for (final sub
                                  in todo.subtasks.where((s) => s.isDone)) {
                                controller.toggleSubtask(todo.id, sub.id);
                              }
                            } else if (todo.isCompleted && !allSubtasksDone) {
                              controller.toggleCompleted(todo.id);
                            } else {
                              // Mark all done
                              for (final sub
                                  in todo.subtasks.where((s) => !s.isDone)) {
                                controller.toggleSubtask(todo.id, sub.id);
                              }
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _addSubtask(BuildContext context) async {
    final textController = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('todo.subtasks.add'.tr),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
            hintText: 'todo.subtasks.hint'.tr,
          ),
          autofocus: true,
          textInputAction: TextInputAction.done,
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
    if (title != null && title.isNotEmpty) {
      controller.addSubtask(todoId, SubTask(title: title));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _ExpandableDescription extends StatefulWidget {
  const _ExpandableDescription({
    required this.text,
    this.style,
  });

  final String text;
  final TextStyle? style;

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = widget.text.trim();
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: widget.style,
            maxLines: _expanded ? null : 3,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          if (text.split('\n').length > 1 || text.length > 120)
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'form.less'.tr : 'form.more'.tr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderImage extends StatefulWidget {
  const _HeaderImage({
    required this.title,
    required this.attachments,
  });

  final String title;
  final List<String> attachments;

  @override
  State<_HeaderImage> createState() => _HeaderImageState();
}

class _HeaderImageState extends State<_HeaderImage> {
  late final PageController _pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImages = widget.attachments.isNotEmpty;
    final total = widget.attachments.length;
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImages)
            PageView.builder(
              controller: _pageController,
              itemCount: widget.attachments.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, index) {
                final url = widget.attachments[index];
                return CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                );
              },
            )
          else
            Container(
              color: theme.colorScheme.surfaceContainerHighest,
            ),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black54, Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                  ),
                ),
              ),
            ),
          ),
          if (hasImages)
            Positioned(
              bottom: 12,
              left: 0,
              right: 10,
              child: Align(
                alignment: AlignmentGeometry.bottomRight,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_page + 1}/$total',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
