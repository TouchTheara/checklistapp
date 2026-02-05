import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/todo.dart';
import '../../home/widgets/todo_list.dart';
import '../controllers/done_controller.dart';

class DoneView extends GetView<DoneController> {
  const DoneView({
    super.key,
    required this.onOpenForm,
  });

  final void Function(BuildContext context, {Todo? existing}) onOpenForm;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final todos = controller.doneTodos;
      return TodoListView(
        todos: todos,
        onToggle: controller.toggleCompleted,
        onDelete: controller.deleteTodo,
        onEdit: (todo) => onOpenForm(context, existing: todo),
        emptyTitle: 'done.empty.title',
        emptyDescription: 'done.empty.desc',
        emptyIcon: Icons.celebration_outlined,
        isDashboard: false,
        refreshController: controller.refreshController,
        onRefresh: controller.refresh,
        onLoading: controller.loadMore,
      );
    });
  }
}
