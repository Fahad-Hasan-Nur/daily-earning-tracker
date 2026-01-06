import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecordController extends GetxController {
  final _db = FirebaseFirestore.instance;
  RxList records = [].obs;

  @override
  void onInit() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _db
        .collection('records')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
          records.value = snapshot.docs;
        });
    super.onInit();
  }

  Future addRecord(double amount, String type, DateTime date) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      await _db.collection('records').add({
        'userId': uid,
        'amount': amount,
        'category': 'General',
        'type': type,
        'date': Timestamp.fromDate(date),
      });
    } catch (e) {
      print(e.toString());
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future updateRecord(String id, double amount, String category) async {
    await _db.collection('records').doc(id).update({
      'amount': amount,
      'category': category,
    });
  }

  Future deleteRecord(String id) async {
    await _db.collection('records').doc(id).delete();
  }

  double get totalIncome => records
      .where((e) => e['type'] == 'income')
      .fold(0, (a, b) => a + b['amount']);

  double get totalExpense => records
      .where((e) => e['type'] == 'expense')
      .fold(0, (a, b) => a + b['amount']);

  double get balance => totalIncome - totalExpense;
}
