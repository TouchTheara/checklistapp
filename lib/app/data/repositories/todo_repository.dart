import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/todo.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class TodoRepository extends GetxService {
  TodoRepository({StorageService? storageService, List<Todo>? seed})
      : _storageService = storageService ?? StorageService(),
        _todos = RxList<Todo>(seed ?? _defaultSeed);

  final StorageService _storageService;
  final RxList<Todo> _todos;
  final Rx<SortOption> _sortOption = SortOption.priorityHighFirst.obs;
  final _firestore = FirebaseFirestore.instance;
  static const _bucket = 'safelist-5b99d.firebasestorage.app';
  final FirebaseStorage _storage =
      FirebaseStorage.instanceFor(app: Firebase.app(), bucket: _bucket);
  final NotificationService? _notificationService =
      Get.isRegistered<NotificationService>()
          ? Get.find<NotificationService>()
          : null;
  String? _userId;

  RxList<Todo> get rawTodos => _todos;

  static final _defaultSeed = <Todo>[];

  Future<TodoRepository> init() async {
    await loadForUser(null);
    return this;
  }

  Future<void> loadForUser(String? userId) async {
    // Clear in-memory list when switching accounts to avoid showing old data.
    if (_userId != null && _userId != userId) {
      _todos.clear();
    }
    _userId = userId;
    _storageService.setUser(userId);
    final hasData = await _storageService.hasSavedData();
    List<Todo> loaded = [];
    try {
      if (userId != null) {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('todos')
            .get();
        loaded = snapshot.docs.map((doc) => Todo.fromJson(doc.data())).toList();
      }
    } catch (_) {
      // ignore network errors, fallback to local
    }
    if (loaded.isEmpty && hasData) {
      loaded = await _storageService.loadTodos();
    }
    if (loaded.isEmpty) {
      loaded = _defaultSeed;
      await _saveTodos();
    }
    _todos.assignAll(_normalized(loaded));

    final savedSortOption = await _storageService.loadSortOption();
    if (savedSortOption != null) {
      _sortOption.value = savedSortOption;
    }
    _todos.refresh();
  }

  Future<void> reloadFromSource() async {
    await loadForUser(_userId);
  }

  SortOption get sortOption => _sortOption.value;
  bool get hasBinItems => _todos.any((todo) => todo.isDeleted);
  StorageService get storageService => _storageService;

  int get totalCount => _activeTodos.length;
  int get completedCount =>
      _activeTodos.where((item) => item.isCompleted).length;
  double get completionRate =>
      totalCount == 0 ? 0 : completedCount / totalCount;

  Map<TodoPriority, int> get priorityBreakdown => {
        for (final priority in TodoPriority.values)
          priority:
              _activeTodos.where((todo) => todo.priority == priority).length,
      };

  List<Todo> get orderedActive {
    final sorted = [..._activeTodos];
    sorted.sort((a, b) => a.order.compareTo(b.order));
    return sorted;
  }

  List<Todo> get sortedActive {
    final sorted = [..._activeTodos];
    sorted.sort((a, b) {
      switch (_sortOption.value) {
        case SortOption.priorityHighFirst:
          final priorityCompare =
              b.priority.weight.compareTo(a.priority.weight);
          if (priorityCompare != 0) return priorityCompare;
          return a.createdAt.compareTo(b.createdAt);
        case SortOption.priorityLowFirst:
          final priorityCompare =
              a.priority.weight.compareTo(b.priority.weight);
          if (priorityCompare != 0) return priorityCompare;
          return a.createdAt.compareTo(b.createdAt);
        case SortOption.alphabetical:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case SortOption.recentlyAdded:
          return b.createdAt.compareTo(a.createdAt);
        case SortOption.dueDateSoon:
          final maxDate = DateTime.utc(9999, 12, 31);
          final aDate = a.dueDate ?? maxDate;
          final bDate = b.dueDate ?? maxDate;
          final compare = aDate.compareTo(bDate);
          if (compare != 0) return compare;
          return a.createdAt.compareTo(b.createdAt);
        case SortOption.manual:
          return a.order.compareTo(b.order);
      }
    });
    return sorted;
  }

  List<Todo> get sortedDone {
    final done = _activeTodos.where((todo) => todo.isCompleted).toList();
    done.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return done;
  }

  List<Todo> get sortedBin {
    final sorted = _todos.where((todo) => todo.isDeleted).toList();
    sorted.sort((a, b) {
      final aDate = a.deletedAt ?? a.createdAt;
      final bDate = b.deletedAt ?? b.createdAt;
      return bDate.compareTo(aDate);
    });
    return sorted;
  }

  void addTodo(Todo todo) {
    final nextOrder = _todos.isEmpty
        ? 0
        : (_todos.map((t) => t.order).reduce((a, b) => a > b ? a : b) + 1);
    _todos.add(todo.copyWith(
      isDeleted: false,
      deletedAt: null,
      order: todo.order == 0 ? nextOrder : todo.order,
    ));
    _saveTodos();
    _notificationService?.scheduleReminder(todo);
  }

  void updateTodo(Todo todo) {
    final index = _todos.indexWhere((item) => item.id == todo.id);
    if (index == -1) return;
    final current = _todos[index];
    final previousMembers = current.members;
    final newMembers = todo.members
        .where(
          (m) => previousMembers.every((prev) => prev.id != m.id),
        )
        .toList();
    _todos[index] = todo.copyWith(
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
      isDeleted: current.isDeleted,
      deletedAt: current.deletedAt,
      isCompleted: current.isCompleted,
    );
    _todos.refresh();
    _saveTodos();
    _notificationService?.scheduleReminder(todo);
    for (final member in newMembers) {
      if (member.userId != null) {
        _notificationService?.notifyInvite(
          inviterName: 'A teammate',
          member: member,
          todo: todo,
        );
      }
    }
  }

  void deleteTodo(String id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) return;
    final current = _todos[index];
    _todos[index] = current.copyWith(
      isDeleted: true,
      deletedAt: DateTime.now(),
    );
    _todos.refresh();
    _saveTodos();
  }

  void restoreTodo(String id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) return;
    final current = _todos[index];
    _todos[index] = current.copyWith(isDeleted: false, deletedAt: null);
    _todos.refresh();
    _saveTodos();
  }

  void emptyBin() {
    _todos.removeWhere((todo) => todo.isDeleted);
    _todos.refresh();
    _saveTodos();
  }

  void deleteForever(String id) {
    _todos.removeWhere((todo) => todo.id == id);
    _todos.refresh();
    _saveTodos();
  }

  void toggleCompleted(String id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) return;
    final current = _todos[index];
    if (current.isDeleted) return;
    final toggled = !current.isCompleted;
    final updatedSubtasks = current.subtasks
        .map((s) => s.copyWith(isDone: toggled))
        .toList();
    _todos[index] = current.copyWith(
      isCompleted: toggled,
      subtasks: updatedSubtasks,
      updatedAt: DateTime.now(),
    );
    _todos.refresh();
    _saveTodos();
  }

  void addSubtask(String todoId, SubTask subtask) {
    final index = _todos.indexWhere((todo) => todo.id == todoId);
    if (index == -1) return;
    final current = _todos[index];
    final updatedSubtasks = [...current.subtasks, subtask];
    _todos[index] = current.copyWith(
      subtasks: updatedSubtasks,
      updatedAt: DateTime.now(),
      isCompleted: updatedSubtasks.every((s) => s.isDone),
    );
    _todos.refresh();
    _saveTodos();
  }

  void toggleSubtask(String todoId, String subtaskId) {
    final index = _todos.indexWhere((todo) => todo.id == todoId);
    if (index == -1) return;
    final current = _todos[index];
    final before = current.subtasks
        .firstWhere((s) => s.id == subtaskId, orElse: () => SubTask(title: ''));
    final wasDone = before.isDone;
    final updatedSubtasks = current.subtasks
        .map(
          (s) => s.id == subtaskId ? s.copyWith(isDone: !s.isDone) : s,
        )
        .toList();
    final nowDone = updatedSubtasks
            .firstWhere((s) => s.id == subtaskId, orElse: () => before)
            .isDone ==
        true;
    final allDone =
        updatedSubtasks.isNotEmpty && updatedSubtasks.every((s) => s.isDone);
    _todos[index] = current.copyWith(
      subtasks: updatedSubtasks,
      isCompleted: allDone,
      updatedAt: DateTime.now(),
    );
    _todos.refresh();
    _saveTodos();
    if (!wasDone && nowDone) {
      _notificationService
          ?.notifySubtaskCompleted(todo: _todos[index], subtask: before);
      if (allDone) {
        _notificationService?.notifyTaskCompleted(_todos[index]);
      }
    }
  }

  void assignSubtask(String todoId, String subtaskId, String? memberId) {
    final index = _todos.indexWhere((todo) => todo.id == todoId);
    if (index == -1) return;
    final current = _todos[index];
    final updatedSubtasks = current.subtasks
        .map(
          (s) => s.id == subtaskId
              ? s.copyWith(assignedMemberId: memberId)
              : s,
        )
        .toList();
    _todos[index] = current.copyWith(
      subtasks: updatedSubtasks,
      updatedAt: DateTime.now(),
    );
    _todos.refresh();
    _saveTodos();
    if (memberId != null) {
      final member = _findMember(current.members, memberId);
      if (member?.userId != null) {
        _notificationService?.notifyAssignment(
          member: member!,
          todo: _todos[index],
        );
      }
    }
  }

  void removeMember(String todoId, String memberId) {
    final index = _todos.indexWhere((todo) => todo.id == todoId);
    if (index == -1) return;
    final current = _todos[index];
    final filteredMembers =
        current.members.where((m) => m.id != memberId).toList();
    final updatedSubtasks = current.subtasks
        .map(
          (s) => s.assignedMemberId == memberId
              ? s.copyWith(assignedMemberId: null)
              : s,
        )
        .toList();
    _todos[index] = current.copyWith(
      members: filteredMembers,
      subtasks: updatedSubtasks,
      updatedAt: DateTime.now(),
    );
    _todos.refresh();
    _saveTodos();
  }

  void updateMemberStatus(
      String todoId, String userId, InviteStatus status) {
    final index = _todos.indexWhere((todo) => todo.id == todoId);
    if (index == -1) return;
    final current = _todos[index];
    final updatedMembers = current.members
        .map((m) =>
            m.userId == userId ? m.copyWith(status: status) : m)
        .toList();
    _todos[index] =
        current.copyWith(members: updatedMembers, updatedAt: DateTime.now());
    _todos.refresh();
    _saveTodos();
  }

  TaskMember? _findMember(List<TaskMember> members, String memberId) {
    for (final m in members) {
      if (m.id == memberId) return m;
    }
    return null;
  }

  void changeSort(SortOption option) {
    if (_sortOption.value == option) return;
    _sortOption.value = option;
    _todos.refresh();
    _saveSortOption();
  }

  void moveTodo(int oldIndex, int newIndex) {
    if (_sortOption.value != SortOption.manual) return;
    final active = orderedActive;
    final item = active.removeAt(oldIndex);
    active.insert(newIndex, item);
    for (var i = 0; i < active.length; i++) {
      active[i] = active[i].copyWith(order: i);
      final idx = _todos.indexWhere((t) => t.id == active[i].id);
      if (idx != -1) _todos[idx] = active[i];
    }
    _todos.refresh();
    _saveTodos();
  }

  List<Todo> _normalized(List<Todo> todos) {
    return todos.asMap().entries.map(
      (entry) {
        final todo = entry.value;
        final normalizedOrder = todo.order == 0 ? entry.key : todo.order;
        return todo.copyWith(
          isCompleted: todo.isCompleted ||
              (todo.subtasks.isNotEmpty &&
                  todo.subtasks.every((sub) => sub.isDone)),
          order: normalizedOrder,
        );
      },
    ).toList();
  }

  List<Todo> get _activeTodos =>
      _todos.where((todo) => !todo.isDeleted).toList();

  Future<void> _saveTodos() async {
    await _storageService.saveTodos(_todos.toList());
    await _syncToFirestore();
  }

  Future<void> _saveSortOption() async {
    await _storageService.saveSortOption(_sortOption.value);
  }

  Future<void> clearForLogout() async {
    _userId = null;
    _todos.clear();
    await _storageService.clearAll();
  }

  Future<void> _syncToFirestore() async {
    if (_userId == null) return;
    try {
      final batch = _firestore.batch();
      final col =
          _firestore.collection('users').doc(_userId).collection('todos');
      for (final todo in _todos) {
        final ref = col.doc(todo.id);
        batch.set(ref, todo.toJson(), SetOptions(merge: true));
      }
      await batch.commit();
    } catch (_) {
      // ignore sync failures in offline/test
    }
  }

  Future<String?> uploadAttachment(String filePath,
      {required String todoId}) async {
    if (_userId == null) return null;
    try {
      final exists = await File(filePath).exists();
      if (!exists) {
        debugPrint('Upload attachment failed: file missing at $filePath');
        return null;
      }
      final file = File(filePath);
      debugPrint('Upload attachment:  $file');
      final fileName = file.uri.pathSegments.last;
      final ref = _storage.ref().child(
          'users/$_userId/todos/$todoId/attachments/${DateTime.now().millisecondsSinceEpoch}_$fileName');
      debugPrint('Upload ref:  $ref');

      final snapshot = await ref.putFile(file);
      if (snapshot.state == TaskState.success) {
        const retries = 5;
        for (var i = 0; i < retries; i++) {
          try {
            return await snapshot.ref.getDownloadURL();
          } on FirebaseException catch (e) {
            if (e.code == 'object-not-found') {
              await Future.delayed(Duration(milliseconds: 400 * (i + 1)));
              continue;
            } else {
              debugPrint(
                  'Download URL failed (${e.code}) for ${snapshot.ref.fullPath} in ${snapshot.ref.bucket}: ${e.message}');
              return null;
            }
          }
        }
        debugPrint(
            'Download URL failed after retries for ${snapshot.ref.fullPath} in ${snapshot.ref.bucket}');
        return null;
      }
      debugPrint('Upload not successful. State: ${snapshot.state}');
      return null;
    } on FirebaseException catch (e) {
      debugPrint('Upload attachment failed (${e.code}): ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Upload attachment failed: $e');
      return null;
    }
  }
}
