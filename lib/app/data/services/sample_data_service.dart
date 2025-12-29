import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../models/todo.dart';

class SampleDataService extends GetxService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> seedForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;
    // Seed profile doc if missing
    final userDoc = _firestore.collection('users').doc(uid);
    final userSnapshot = await userDoc.get();
    if (!userSnapshot.exists) {
      final name = user.displayName ?? 'SafeList user';
      final handle = _buildHandle(name, uid);
      await userDoc.set({
        'name': name,
        'handle': handle,
        'email': user.email ?? '',
        'notificationsEnabled': true,
      });
    }
    final col = _firestore.collection('users').doc(uid).collection('todos');

    final exists = await col.limit(1).get();
    if (exists.docs.isNotEmpty) return;

    final now = DateTime.now();
    final tasks = [
      Todo.create(
        title: 'Site safety walk',
        description: 'Inspect scaffolding and PPE compliance',
        priority: TodoPriority.high,
        dueDate: now.add(const Duration(days: 1)),
      ),
      Todo.create(
        title: 'Quality punch list',
        description: 'Close open punch items with subs',
        priority: TodoPriority.medium,
      ),
    ];

    final batch = _firestore.batch();
    for (final t in tasks) {
      batch.set(col.doc(t.id), t.toJson());
    }
    await batch.commit();
  }

  String _buildHandle(String name, String uid) {
    final base =
        name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final cleaned =
        base.replaceAll(RegExp('_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    final suffix = uid.length >= 6 ? uid.substring(0, 6) : uid;
    if (cleaned.isEmpty) return 'user_$suffix';
    return '${cleaned}_$suffix';
  }
}
