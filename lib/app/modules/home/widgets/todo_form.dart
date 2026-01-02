import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/todo.dart';
import '../../../data/repositories/todo_repository.dart';
import '../../../widgets/app_text_field.dart';

class TodoForm extends StatefulWidget {
  const TodoForm({
    super.key,
    this.existing,
  });

  final Todo? existing;

  static const titleFieldKey = Key('todo_title_field');
  static const descriptionFieldKey = Key('todo_description_field');
  static const priorityFieldKey = Key('todo_priority_field');
  static const saveButtonKey = Key('todo_save_button');

  @override
  State<TodoForm> createState() => _TodoFormState();
}

class _TodoFormState extends State<TodoForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TodoPriority _priority;
  final TextEditingController _subtaskController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  DateTime? _dueDate;
  DateTime? _reminderAt;
  late List<SubTask> _subtasks;
  late List<String> _attachments; // existing remote URLs
  late List<String> _localAttachments; // local file paths pending upload
  late List<TaskMember> _members;
  final _memberNameController = TextEditingController();
  final _memberEmailController = TextEditingController();
  bool _isSubmitting = false;
  late final String _todoId;

  @override
  void initState() {
    super.initState();
    _todoId = widget.existing?.id ?? const Uuid().v4();
    _titleController = TextEditingController(text: widget.existing?.title);
    _descriptionController =
        TextEditingController(text: widget.existing?.description);
    _priority = widget.existing?.priority ?? TodoPriority.medium;
    _categoryController.text = widget.existing?.category ?? '';
    _dueDate = widget.existing?.dueDate;
    _reminderAt = widget.existing?.reminderAt;
    _subtasks = widget.existing?.subtasks.toList() ?? [];
    _attachments = widget.existing?.attachments.toList() ?? [];
    _localAttachments = [];
    _members = widget.existing?.members.toList() ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subtaskController.dispose();
    _categoryController.dispose();
    _memberNameController.dispose();
    _memberEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _isSubmitting = true);
    final repository = Get.find<TodoRepository>();
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();
    final category = _categoryController.text.trim().isEmpty
        ? null
        : _categoryController.text.trim();

    var todo = widget.existing == null
        ? Todo(
            id: _todoId,
            title: title,
            description: description,
            priority: _priority,
            category: category,
            dueDate: _dueDate,
            reminderAt: _reminderAt,
            attachments: _attachments,
            subtasks: _subtasks,
            members: _members,
          )
        : widget.existing!.copyWith(
            title: title,
            description: description,
            priority: _priority,
            category: category,
            dueDate: _dueDate,
            reminderAt: _reminderAt,
            attachments: _attachments,
            subtasks: _subtasks,
            members: _members,
          );

    if (widget.existing == null) {
      repository.addTodo(todo);
    } else {
      repository.updateTodo(todo);
    }

    // Upload any local attachments after creating/updating the task
    if (_localAttachments.isNotEmpty) {
      final uploaded = <String>[];
      for (final path in _localAttachments) {
        final url = await repository.uploadAttachment(path, todoId: todo.id);
        if (url != null) uploaded.add(url);
      }
      if (uploaded.isNotEmpty) {
        todo = todo.copyWith(attachments: [...todo.attachments, ...uploaded]);
        repository.updateTodo(todo);
      }
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.of(context).maybePop();
    }
  }

  void _addSubtask() {
    final title = _subtaskController.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _subtasks.add(SubTask(title: title));
      _subtaskController.clear();
    });
  }

  void _toggleSubtask(String id) {
    setState(() {
      _subtasks = _subtasks
          .map((sub) => sub.id == id ? sub.copyWith(isDone: !sub.isDone) : sub)
          .toList();
    });
  }

  void _removeSubtask(String id) {
    setState(() {
      _subtasks.removeWhere((sub) => sub.id == id);
    });
  }

  void _updateSubtaskAssignee(String id, String? memberId) {
    setState(() {
      _subtasks = _subtasks
          .map((sub) => sub.id == id
              ? sub.copyWith(assignedMemberId: memberId)
              : sub)
          .toList();
    });
  }

  void _addMember() {
    final name = _memberNameController.text.trim();
    final email = _memberEmailController.text.trim();
    if (name.isEmpty && email.isEmpty) return;
    final resolvedName = name.isEmpty ? email : name;
    setState(() {
      _members.add(TaskMember(name: resolvedName, email: email));
      _memberNameController.clear();
      _memberEmailController.clear();
    });
  }

  void _removeMember(String id) {
    setState(() {
      _members.removeWhere((m) => m.id == id);
      _subtasks = _subtasks
          .map((s) =>
              s.assignedMemberId == id ? s.copyWith(assignedMemberId: null) : s)
          .toList();
    });
  }

  Future<void> _pickExistingUser() async {
    final selected = await showDialog<TaskMember>(
      context: context,
      builder: (ctx) => _UserPickerDialog(),
    );
    if (selected != null) {
      setState(() {
        _members.add(selected);
      });
    }
  }

  Color _getPriorityColor(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.high:
        return Colors.red.shade400;
      case TodoPriority.medium:
        return Colors.orange.shade400;
      case TodoPriority.low:
        return Colors.green.shade400;
    }
  }

  IconData _getPriorityIcon(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.high:
        return Icons.priority_high;
      case TodoPriority.medium:
        return Icons.remove;
      case TodoPriority.low:
        return Icons.arrow_downward;
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final firstDate = now;
    final lastDate = now.add(const Duration(days: 365 * 2));
    final baseInitial = _reminderAt ?? _dueDate ?? now;
    final initialDate = baseInitial.isBefore(firstDate)
        ? firstDate
        : (baseInitial.isAfter(lastDate) ? lastDate : baseInitial);
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderAt ?? initialDate),
    );
    if (time == null) return;
    final combined = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() => _reminderAt = combined);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _chooseAttachmentSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    await _addAttachment(source);
  }

  Future<void> _addAttachment(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      setState(() => _localAttachments.add(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final categories = Get.find<TodoRepository>()
        .rawTodos
        .map((t) => t.category)
        .whereType<String>()
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              widget.existing == null
                                  ? Icons.add_task
                                  : Icons.edit,
                              color: colorScheme.onPrimaryContainer,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.existing == null
                                  ? 'todo.new.title'.tr
                                  : 'todo.edit.title'.tr,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        fieldKey: TodoForm.titleFieldKey,
                        controller: _titleController,
                        label: 'todo.title'.tr,
                        hintText: 'todo.title.hint'.tr,
                        prefixIcon: const Icon(Icons.title),
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'todo.title.error'.tr;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        fieldKey: TodoForm.descriptionFieldKey,
                        controller: _descriptionController,
                        label: 'todo.desc'.tr,
                        hintText: 'todo.desc.hint'.tr,
                        prefixIcon: const Icon(Icons.description),
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        minLines: 1,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.event_outlined),
                              title: Text(
                                _dueDate == null
                                    ? 'todo.due.none'.tr
                                    : 'todo.due.label'.trParams(
                                        {'date': _formatDate(_dueDate!)},
                                      ),
                              ),
                              onTap: _pickDueDate,
                              trailing: TextButton(
                                onPressed: _pickDueDate,
                                child: Text('todo.due.pick'.tr),
                              ),
                            ),
                          ),
                          if (_dueDate != null)
                            IconButton(
                              tooltip: 'Clear',
                              onPressed: () => setState(() => _dueDate = null),
                              icon: const Icon(Icons.close),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _categoryController,
                        label: 'todo.category.label'.tr,
                        hintText: 'todo.category.hint'.tr,
                        prefixIcon: const Icon(Icons.folder_open),
                        textInputAction: TextInputAction.next,
                      ),
                      if (categories.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: categories
                              .take(6)
                              .map(
                                (c) => ActionChip(
                                  label: Text(c),
                                  avatar:
                                      const Icon(Icons.label_outline, size: 16),
                                  onPressed: () => setState(
                                      () => _categoryController.text = c),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            'Attachments',
                            style: theme.textTheme.titleMedium,
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _chooseAttachmentSource,
                            icon:
                                const Icon(Icons.add_photo_alternate_outlined),
                            label: const Text('Add photo'),
                          ),
                        ],
                      ),
                      if (_attachments.isNotEmpty ||
                          _localAttachments.isNotEmpty)
                        SizedBox(
                          height: 90,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                _attachments.length + _localAttachments.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, index) {
                              final isRemote = index < _attachments.length;
                              final url = isRemote
                                  ? _attachments[index]
                                  : _localAttachments[
                                      index - _attachments.length];
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: isRemote
                                          ? CachedNetworkImage(
                                              imageUrl: url,
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) => Container(
                                                color: colorScheme
                                                    .surfaceContainerHighest,
                                              ),
                                              errorWidget: (_, __, ___) =>
                                                  Container(
                                                color: colorScheme
                                                    .surfaceContainerHighest,
                                                child: Icon(
                                                    Icons.broken_image_outlined,
                                                    color: colorScheme.outline),
                                              ),
                                            )
                                          : Image.file(
                                              File(url),
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isRemote) {
                                            _attachments.removeAt(index);
                                          } else {
                                            _localAttachments.removeAt(
                                                index - _attachments.length);
                                          }
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.alarm),
                        title: Text(_reminderAt == null
                            ? 'todo.reminder.none'.tr
                            : 'todo.reminder.label'
                                .trParams({'date': _formatDate(_reminderAt!)})),
                        trailing: TextButton(
                          onPressed: _pickReminder,
                          child: Text('todo.reminder.set'.tr),
                        ),
                        onTap: _pickReminder,
                      ),
                      if (_reminderAt != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => setState(() => _reminderAt = null),
                            icon: const Icon(Icons.close),
                            label: Text('todo.reminder.clear'.tr),
                          ),
                        ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<TodoPriority>(
                        key: TodoForm.priorityFieldKey,
                        initialValue: _priority,
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          labelText: 'todo.priority'.tr,
                          prefixIcon: Icon(
                            _getPriorityIcon(_priority),
                            color: _getPriorityColor(_priority),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: colorScheme.outline),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: colorScheme.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        items: TodoPriority.values
                            .map(
                              (priority) => DropdownMenuItem(
                                value: priority,
                                child: Row(
                                  children: [
                                    Icon(
                                      _getPriorityIcon(priority),
                                      color: _getPriorityColor(priority),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(priority.label),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _priority = value;
                          });
                        },
                        dropdownColor: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Members',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _memberNameController,
                              decoration: const InputDecoration(
                                hintText: 'Member name (username)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _memberEmailController,
                              decoration: const InputDecoration(
                                hintText: 'Member email',
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _addMember,
                      child: const Icon(Icons.person_add_alt),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Find users',
                      onPressed: _pickExistingUser,
                      icon: const Icon(Icons.search),
                    ),
                  ],
                ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _members
                            .map(
                              (m) => Chip(
                                label: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                onDeleted: () => _removeMember(m.id),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'todo.subtasks'.tr,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        'todo.subtasks'.tr,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _subtaskController,
                              decoration: InputDecoration(
                                hintText: 'todo.subtasks.hint'.tr,
                              ),
                              onSubmitted: (_) => _addSubtask(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: _addSubtask,
                            icon: const Icon(Icons.add),
                            label: Text('todo.subtasks.add'.tr),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_subtasks.isEmpty)
                        Text(
                          'todo.subtasks.empty'.tr,
                          style: theme.textTheme.bodyMedium,
                        )
                      else
                        Column(
                          children: _subtasks
                              .map(
                                (sub) => ListTile(
                                  dense: true,
                                  leading: Checkbox(
                                    value: sub.isDone,
                                    onChanged: (_) => _toggleSubtask(sub.id),
                                  ),
                                  title: Text(
                                    sub.title.isEmpty
                                        ? 'todo.subtasks.untitled'.tr
                                        : sub.title,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  subtitle: _members.isEmpty
                                      ? null
                                      : DropdownButton<String?>(
                                          value: sub.assignedMemberId,
                                          isExpanded: true,
                                          hint: const Text('Assign to member'),
                                          items: [
                                            const DropdownMenuItem(
                                              value: null,
                                              child: Text('Unassigned'),
                                            ),
                                            ..._members.map(
                                              (m) => DropdownMenuItem(
                                                value: m.id,
                                                child: Text(m.name),
                                              ),
                                            ),
                                          ],
                                          onChanged: (val) => _updateSubtaskAssignee(
                                            sub.id,
                                            val,
                                          ),
                                        ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _removeSubtask(sub.id),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('form.cancel'.tr),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            key: TodoForm.saveButtonKey,
                            onPressed: _isSubmitting ? null : _handleSubmit,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.existing == null
                                      ? Icons.add
                                      : Icons.check,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(widget.existing == null
                                    ? 'form.create'.tr
                                    : 'form.save'.tr),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_isSubmitting)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Saving task and uploading attachments...'),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
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
        // simple prefix search on email
        base = FirebaseFirestore.instance
            .collection('users')
            .orderBy('email')
            .startAt([q])
            .endAt(['$q\uf8ff'])
            .limit(50);
      }
      final snap = await base.get();
      _all = snap.docs
          .map(
            (d) => TaskMember(
              id: d.id,
              name: d.data()['name'] as String? ?? '',
              email: d.data()['email'] as String? ?? '',
              userId: d.id,
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

  List<TaskMember> get _filtered {
    return _all;
  }

  @override
  Widget build(BuildContext context) {
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
                            'Could not load users. Check network or rules, or invite manually.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : _filtered.isEmpty
                          ? const Center(
                              child: Text(
                                'No users found. You can still invite by name or email.',
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.separated(
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, index) {
                                final u = _filtered[index];
                                return ListTile(
                                  title: Text(u.name.isEmpty ? u.email : u.name),
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
