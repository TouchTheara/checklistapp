import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/todo.dart';
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
      return Column(
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
              todos: todos,
              onToggle: controller.toggleCompleted,
              onDelete: controller.deleteTodo,
              onEdit: (todo) => onOpenForm(context, existing: todo),
              isDashboard: true,
            ),
          ),
        ],
      );
    });
  }
}
