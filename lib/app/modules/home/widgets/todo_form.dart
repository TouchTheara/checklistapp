import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/todo.dart';
import '../controllers/home_controller.dart';

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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title);
    _descriptionController =
        TextEditingController(text: widget.existing?.description);
    _priority = widget.existing?.priority ?? TodoPriority.medium;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final controller = Get.find<HomeController>();
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    final todo = widget.existing == null
        ? Todo.create(
            title: title,
            description: description,
            priority: _priority,
          )
        : widget.existing!.copyWith(
            title: title,
            description: description,
            priority: _priority,
          );

    if (widget.existing == null) {
      controller.addTodo(todo);
    } else {
      controller.updateTodo(todo);
    }
    Navigator.of(context).maybePop();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
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
                          widget.existing == null ? Icons.add_task : Icons.edit,
                          color: colorScheme.onPrimaryContainer,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.existing == null
                              ? 'New checklist item'
                              : 'Edit item',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: TodoForm.titleFieldKey,
                    controller: _titleController,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter task title',
                      prefixIcon: const Icon(Icons.title),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 128),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: colorScheme.primary, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: colorScheme.error),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: colorScheme.error, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    key: TodoForm.descriptionFieldKey,
                    controller: _descriptionController,
                    style: theme.textTheme.bodyMedium,
                    keyboardType: TextInputType.multiline,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Add a description (optional)',
                      prefixIcon: const Icon(Icons.description),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 128),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: colorScheme.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    textInputAction: TextInputAction.newline,
                    minLines: 1,
                    maxLines: null,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<TodoPriority>(
                    key: TodoForm.priorityFieldKey,
                    initialValue: _priority,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Priority',
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
                          color: colorScheme.outline.withOpacity(0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: colorScheme.primary, width: 2),
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
                  const SizedBox(height: 32),
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
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        key: TodoForm.saveButtonKey,
                        onPressed: _handleSubmit,
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
                              widget.existing == null ? Icons.add : Icons.check,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(widget.existing == null ? 'Create' : 'Save'),
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
    );
  }
}
