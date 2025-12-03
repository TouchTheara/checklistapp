import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/data/repositories/profile_repository.dart';
import 'app/data/repositories/todo_repository.dart';
import 'app/modules/home/bindings/home_binding.dart';
import 'app/modules/home/views/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Get.putAsync<TodoRepository>(() => TodoRepository().init());
  await Get.putAsync<ProfileRepository>(() => ProfileRepository().init());
  runApp(const ChecklistApp());
}

class ChecklistApp extends StatelessWidget {
  const ChecklistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Checklist',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialBinding: HomeBinding(),
      home: const HomeView(),
    );
  }
}
