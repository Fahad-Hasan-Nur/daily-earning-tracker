import 'package:daily_income_tracker/app/controllers/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/controllers/auth_controller.dart';
import 'app/pages/login_page.dart';
import 'app/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(AuthController());
    Get.put(ThemeController());

    return GetMaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: Get.find<ThemeController>().isDark.value
          ? ThemeMode.dark
          : ThemeMode.light,
      home: Obx(() {
        final auth = Get.find<AuthController>();
        return auth.user.value == null ? LoginPage() : HomePage();
      }),
    );
  }
}
