import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
              padding: EdgeInsets.only(bottom: 100),
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
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Members',
                            style: theme.textTheme.titleMedium,
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final member = await _promptAddMember(context);
                              if (member != null) {
                                final updated = todo.copyWith(
                                  members: [...todo.members, member],
                                );
                                controller.updateTodo(updated);
                              }
                            },
                            icon: const Icon(Icons.person_add_alt),
                            label: const Text('Invite'),
                          ),
                        ],
                      ),
                      if (todo.members.isEmpty)
                        Text(
                          'No members yet',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: theme.colorScheme.outline),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: todo.members
                              .map(
                                (m) => Chip(
                                  label: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.name,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        m.email,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      if (m.status != InviteStatus.accepted)
                                        Text(
                                          m.status.label,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: m.status ==
                                                    InviteStatus.cancelled
                                                ? theme.colorScheme.error
                                                : theme.colorScheme.primary,
                                          ),
                                        ),
                                    ],
                                  ),
                                  deleteIcon:
                                      const Icon(Icons.person_remove_alt_1),
                                  onDeleted: () =>
                                      controller.removeMember(todo.id, m.id),
                                ),
                              )
                              .toList(),
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
                        ...todo.subtasks.map((sub) {
                          final assignedMember = sub.assignedMemberId == null
                              ? null
                              : (() {
                                  final found = todo.members
                                      .where(
                                          (m) => m.id == sub.assignedMemberId)
                                      .toList();
                                  return found.isNotEmpty ? found.first : null;
                                })();
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Checkbox(
                                    value: sub.isDone,
                                    shape: const CircleBorder(),
                                    onChanged: (_) => controller.toggleSubtask(
                                        todo.id, sub.id),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sub.title.isEmpty
                                              ? 'Untitled'
                                              : sub.title,
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                        Text(
                                          assignedMember == null
                                              ? 'Unassigned'
                                              : 'Assigned to ${assignedMember.name}',
                                          style: theme.textTheme.bodySmall!
                                              .copyWith(
                                                  color:
                                                      theme.colorScheme.outline,
                                                  fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (todo.members.isNotEmpty ||
                                      sub.assignedMemberId != null)
                                    DropdownButtonHideUnderline(
                                      child: SizedBox(
                                        width: 150,
                                        child: DropdownButton<String?>(
                                          isExpanded: true,
                                          value: sub.assignedMemberId != null &&
                                                  todo.members.any((m) =>
                                                      m.id ==
                                                      sub.assignedMemberId)
                                              ? sub.assignedMemberId
                                              : null,
                                          hint: const Text('Assign'),
                                          items: todo.members
                                              .map(
                                                (m) => DropdownMenuItem(
                                                  value: m.id,
                                                  child: Text(
                                                    m.name,
                                                    style: theme
                                                        .textTheme.bodyMedium!
                                                        .copyWith(fontSize: 13),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (val) =>
                                              controller.assignSubtask(
                                            todo.id,
                                            sub.id,
                                            val,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
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

  Future<TaskMember?> _promptAddMember(BuildContext context) async {
    return showDialog<TaskMember>(
      context: context,
      builder: (_) => const _UserPickerDialog(),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _UserPickerDialog extends StatefulWidget {
  const _UserPickerDialog();

  @override
  State<_UserPickerDialog> createState() => _UserPickerDialogState();
}

class _UserPickerDialogState extends State<_UserPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<TaskMember> _all = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers([String query = '']) async {
    try {
      setState(() {
        _loading = true;
        _error = false;
      });
      Query<Map<String, dynamic>> base =
          FirebaseFirestore.instance.collection('users').limit(50);
      final q = query.trim();
      if (q.isNotEmpty) {
        base = FirebaseFirestore.instance
            .collection('users')
            .orderBy('email')
            .startAt([q]).endAt(['$q\uf8ff']).limit(50);
      }
      final snap = await base.get();
      _all = snap.docs
          .map(
            (d) => TaskMember(
              id: d.id,
              name: d.data()['name'] as String? ?? '',
              email: d.data()['email'] as String? ?? '',
              userId: d.id,
              status: InviteStatus.pending,
            ),
          )
          .where((u) => u.name.isNotEmpty || u.email.isNotEmpty)
          .toList();
    } catch (_) {
      _all = [];
      _error = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final users = _all;
    return AlertDialog(
      title: const Text('Select user'),
      content: SizedBox(
        width: double.maxFinite,
        height: 360,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _loadUsers(_searchController.text),
                ),
              ),
              onSubmitted: (v) => _loadUsers(v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error
                      ? const Center(
                          child: Text(
                            'Could not load users. You can still invite manually.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : users.isEmpty
                          ? const Center(
                              child: Text(
                                'No users found. Invite by name or email below.',
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.separated(
                              itemCount: users.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, index) {
                                final u = users[index];
                                return ListTile(
                                  title:
                                      Text(u.name.isEmpty ? u.email : u.name),
                                  subtitle:
                                      u.email.isEmpty ? null : Text(u.email),
                                  onTap: () => Navigator.of(context).pop(u),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
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
