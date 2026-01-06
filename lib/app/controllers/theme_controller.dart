import 'package:get/get.dart';

class ThemeController extends GetxController {
  RxBool isDark = false.obs;
  void toggle() => isDark.value = !isDark.value;
}
