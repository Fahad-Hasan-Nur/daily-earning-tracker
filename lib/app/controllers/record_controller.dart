import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecordController extends GetxController {
  final db = FirebaseFirestore.instance;
  RxList records = [].obs;
  var balance = 0.0.obs;
  var totalIncome = 0.0.obs;
  var totalExpense = 0.0.obs;
  RxList monthlyRecords = [].obs;
  var monthlyBalance = 0.0.obs;
  var monthlyTotalIncome = 0.0.obs;
  var monthlyTotalExpense = 0.0.obs;

  @override
  void onInit() {
    initiateDailyData();
    initiateMonthlyData();
    super.onInit();
  }

  initiateMonthlyData() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final now = DateTime.now();
    final startOfMonth = DateTime(
      now.year,
      now.month,
      1,
    ); // first day of month, 00:00:00
    final endOfMonth = DateTime(
      now.year,
      now.month + 1,
      0,
      23,
      59,
      59,
    ); // last day of month, 23:59:59

    db
        .collection('records')
        .where('userId', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .snapshots()
        .listen((snapshot) {
          monthlyRecords.value = snapshot.docs;
          getMonthlyTotalIncome();
          getMonthlyTotalExpense();
          getMonthlyBalance();
        });
  }

  initiateDailyData() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Get start and end of today
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day); // 00:00:00
    final endOfDay = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
    ); // 23:59:59

    db
        .collection('records')
        .where('userId', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .listen((snapshot) {
          records.value = snapshot.docs;
          getTotalIncome();
          getTotalExpense();
          getBalance();
        });
  }

  Future addRecord(
    double amount,
    String type,
    DateTime date,
    String cat,
  ) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      await db.collection('records').add({
        'userId': uid,
        'amount': amount,
        'category': cat,
        'type': type,
        'date': Timestamp.fromDate(date),
      });
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future updateRecord(String id, double amount, String category) async {
    await db.collection('records').doc(id).update({
      'amount': amount,
      'category': category,
    });
  }

  Future deleteRecord(String id) async {
    await db.collection('records').doc(id).delete();
  }

  getTotalIncome() {
    totalIncome.value = records
        .where((e) => e['type'] == 'income')
        .fold(0, (a, b) => a + b['amount']);
  }

  getTotalExpense() {
    totalExpense.value = records
        .where((e) => e['type'] == 'expense')
        .fold(0, (a, b) => a + b['amount']);
  }

  getBalance() {
    balance.value = totalIncome.value - totalExpense.value;
  }

  getMonthlyTotalIncome() {
    monthlyTotalIncome.value = monthlyRecords
        .where((e) => e['type'] == 'income')
        .fold(0, (a, b) => a + b['amount']);
  }

  getMonthlyTotalExpense() {
    monthlyTotalExpense.value = monthlyRecords
        .where((e) => e['type'] == 'expense')
        .fold(0, (a, b) => a + b['amount']);
  }

  getMonthlyBalance() {
    monthlyBalance.value = monthlyTotalIncome.value - monthlyTotalExpense.value;
  }

  // Get daily summary for current month
  Future<List<Map<String, dynamic>>> getDailySummaryForMonth() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final snapshot = await db
        .collection('records')
        .where('userId', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .orderBy('date')
        .get();

    // Create a map to hold daily summaries
    Map<String, Map<String, double>> dailySummary = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final Timestamp ts = data['date'];
      final date = ts.toDate();
      final key = "${date.year}-${date.month}-${date.day}";

      if (!dailySummary.containsKey(key)) {
        dailySummary[key] = {'income': 0, 'expense': 0, 'balance': 0};
      }

      if (data['type'] == 'income') {
        dailySummary[key]!['income'] =
            dailySummary[key]!['income']! + (data['amount'] as num).toDouble();
      } else {
        dailySummary[key]!['expense'] =
            dailySummary[key]!['expense']! + (data['amount'] as num).toDouble();
      }

      dailySummary[key]!['balance'] =
          dailySummary[key]!['income']! - dailySummary[key]!['expense']!;
    }

    // Convert to list sorted by date
    List<Map<String, dynamic>> result = dailySummary.entries
        .map(
          (e) => {
            'date': e.key,
            'income': e.value['income'],
            'expense': e.value['expense'],
            'balance': e.value['balance'],
          },
        )
        .toList();

    result.sort((a, b) => a['date'].compareTo(b['date']));

    return result;
  }
}
