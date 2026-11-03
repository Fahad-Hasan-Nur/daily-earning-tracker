import 'dart:async';
import 'package:daily_income_tracker/app/data/models/category_model.dart';
import 'package:daily_income_tracker/app/data/models/loan_model.dart';
import 'package:daily_income_tracker/app/data/models/record_model.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecordController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream subscriptions
  StreamSubscription? _dailySub;
  StreamSubscription? _monthlySub;
  StreamSubscription? _loanSub;

  // Use typed lists
  final RxList<RecordModel> records = <RecordModel>[].obs;
  final RxList<RecordModel> monthlyRecords = <RecordModel>[].obs;

  // Every loan ever given, not limited to a date range
  final RxList<LoanModel> loans = <LoanModel>[].obs;
  final RxBool loansLoading = true.obs;
  final RxnString loansError = RxnString();

  double get totalLoanOutstanding =>
      loans.fold(0.0, (total, loan) => total + loan.outstanding);
  int get openLoanCount => loans.where((loan) => !loan.isSettled).length;

  // Category list used for dropdown selection
  final RxList<CategoryModel> categories = <CategoryModel>[
    CategoryModel.other(),
  ].obs;

  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      _db.collection('users').doc(_uid).collection('categories');

  // Rx totals
  final RxDouble balance = 0.0.obs;
  final RxDouble totalIncome = 0.0.obs;
  final RxDouble totalExpense = 0.0.obs;
  final RxDouble totalInvestment = 0.0.obs;
  final RxDouble totalLoanGiven = 0.0.obs;
  final RxDouble totalLoanRepaid = 0.0.obs;

  final RxDouble monthlyBalance = 0.0.obs;
  final RxDouble monthlyTotalIncome = 0.0.obs;
  final RxDouble monthlyTotalExpense = 0.0.obs;
  final RxDouble monthlyTotalInvestment = 0.0.obs;
  final RxDouble monthlyTotalLoanGiven = 0.0.obs;
  final RxDouble monthlyTotalLoanRepaid = 0.0.obs;

  final RxDouble yearlyBalance = 0.0.obs;
  final RxDouble yearlyTotalIncome = 0.0.obs;
  final RxDouble yearlyTotalExpense = 0.0.obs;
  final RxDouble yearlyTotalInvestment = 0.0.obs;
  final RxDouble yearlyTotalLoanGiven = 0.0.obs;
  final RxDouble yearlyTotalLoanRepaid = 0.0.obs;

  String get _uid => _auth.currentUser!.uid;
  FirebaseFirestore get db => _db;

  @override
  void onInit() {
    loadCategories();
    initiateDailyData();
    initiateMonthlyData();
    initiateLoanData();
    calculateYearlyTotals();
    super.onInit();
  }

  @override
  void onClose() {
    _dailySub?.cancel();
    _monthlySub?.cancel();
    _loanSub?.cancel();
    super.onClose();
  }

  // Fetch records for a specific date range
  Future<List<RecordModel>> getRecordsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _db
        .collection('records')
        .where('userId', isEqualTo: _uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    return snapshot.docs.map((doc) => RecordModel.fromFirestore(doc)).toList();
  }

  // Common query logic
  Stream<QuerySnapshot<Map<String, dynamic>>> _getRecordsStream(
    DateTime start,
    DateTime end,
  ) {
    return _db
        .collection('records')
        .where('userId', isEqualTo: _uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots();
  }

  void initiateDailyData() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    _dailySub?.cancel();
    _dailySub = _getRecordsStream(startOfDay, endOfDay).listen((snapshot) {
      records.value = snapshot.docs
          .map((doc) => RecordModel.fromFirestore(doc))
          .toList();
      _calculateDailyTotals();
    });
  }

  void initiateMonthlyData() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    _monthlySub?.cancel();
    _monthlySub = _getRecordsStream(startOfMonth, endOfMonth).listen((
      snapshot,
    ) {
      monthlyRecords.value = snapshot.docs
          .map((doc) => RecordModel.fromFirestore(doc))
          .toList();
      _calculateMonthlyTotals();
    });
  }

  // Loans and their repayments share a categoryId, so both come from one query.
  void initiateLoanData() {
    _loanSub?.cancel();
    _loanSub = _db
        .collection('records')
        .where('userId', isEqualTo: _uid)
        .where('categoryId', isEqualTo: RecordModel.loanCategoryId)
        .snapshots()
        .listen(
          (snapshot) {
            loans.value = LoanModel.fromRecords(
              snapshot.docs.map((doc) => RecordModel.fromFirestore(doc)),
            );
            loansError.value = null;
            loansLoading.value = false;
          },
          onError: (Object e) {
            loansLoading.value = false;
            // Listeners can be cut off by signing out, which isn't a failure.
            if (_auth.currentUser != null) {
              loansError.value = 'Failed to load loans: $e';
            }
          },
        );
  }

  void _calculateDailyTotals() {
    totalIncome.value = _calculateTotal(records, 'income');
    totalExpense.value = _calculateTotal(records, 'expense');
    totalInvestment.value = _calculateTotal(records, 'investment');
    totalLoanGiven.value = _calculateTotal(records, RecordModel.typeLoan);
    totalLoanRepaid.value = _calculateTotal(
      records,
      RecordModel.typeLoanRepayment,
    );
    balance.value = RecordModel.cashBalance(records);
  }

  void _calculateMonthlyTotals() {
    monthlyTotalIncome.value = _calculateTotal(monthlyRecords, 'income');
    monthlyTotalExpense.value = _calculateTotal(monthlyRecords, 'expense');
    monthlyTotalInvestment.value = _calculateTotal(
      monthlyRecords,
      'investment',
    );
    monthlyTotalLoanGiven.value = _calculateTotal(
      monthlyRecords,
      RecordModel.typeLoan,
    );
    monthlyTotalLoanRepaid.value = _calculateTotal(
      monthlyRecords,
      RecordModel.typeLoanRepayment,
    );
    monthlyBalance.value = RecordModel.cashBalance(monthlyRecords);
  }

  double _calculateTotal(List<RecordModel> list, String type) {
    return list
        .where((r) => r.type == type)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  Map<String, double> getCategoryTotals(List<RecordModel> recordsList) {
    final totals = <String, double>{};
    for (var record in recordsList) {
      if (record.isLoanEntry) continue; // Loans have their own summary
      totals[record.categoryId] =
          (totals[record.categoryId] ?? 0) + record.amount;
    }
    return totals;
  }

  void calculateYearlyTotals() async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);

    final snapshot = await _db
        .collection('records')
        .where('userId', isEqualTo: _uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfYear))
        .get();

    final yearlyRecords = snapshot.docs
        .map((doc) => RecordModel.fromFirestore(doc))
        .toList();

    yearlyTotalIncome.value = _calculateTotal(yearlyRecords, 'income');
    yearlyTotalExpense.value = _calculateTotal(yearlyRecords, 'expense');
    yearlyTotalInvestment.value = _calculateTotal(yearlyRecords, 'investment');
    yearlyTotalLoanGiven.value = _calculateTotal(
      yearlyRecords,
      RecordModel.typeLoan,
    );
    yearlyTotalLoanRepaid.value = _calculateTotal(
      yearlyRecords,
      RecordModel.typeLoanRepayment,
    );
    yearlyBalance.value = RecordModel.cashBalance(yearlyRecords);
  }

  Future<void> addRecord(
    double amount,
    String type,
    DateTime date,
    String categoryId,
    String category,
  ) async {
    try {
      await _db.collection('records').add({
        'userId': _uid,
        'amount': amount,
        'categoryId': categoryId,
        'category': category,
        'type': type,
        'date': Timestamp.fromDate(date),
      });
      calculateYearlyTotals(); // Added to ensure yearly total updates
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add record: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> addLoan(double amount, String borrower, DateTime date) {
    return addRecord(
      amount,
      RecordModel.typeLoan,
      date,
      RecordModel.loanCategoryId,
      borrower,
    );
  }

  Future<void> addLoanRepayment(
    LoanModel loan,
    double amount,
    DateTime date,
  ) async {
    try {
      await _db.collection('records').add({
        'userId': _uid,
        'amount': loan.normalizeRepayment(amount),
        'categoryId': RecordModel.loanCategoryId,
        'category': loan.borrower,
        'type': RecordModel.typeLoanRepayment,
        'loanId': loan.id,
        'date': Timestamp.fromDate(date),
      });
      calculateYearlyTotals();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save repayment: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Repayments repeat the borrower's name, so a rename has to reach them too.
  Future<void> updateLoan(
    LoanModel loan,
    double amount,
    String borrower,
  ) async {
    try {
      final recordsRef = _db.collection('records');
      final batch = _db.batch();
      batch.update(recordsRef.doc(loan.id), {
        'amount': amount,
        'category': borrower,
      });
      if (borrower != loan.borrower) {
        for (final repayment in loan.repayments) {
          batch.update(recordsRef.doc(repayment.id), {'category': borrower});
        }
      }
      await batch.commit();
      calculateYearlyTotals();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update loan: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<CategoryModel?> addCategory(String category) async {
    final normalized = category.trim();
    if (normalized.isEmpty) return null;

    final existing = categories.firstWhere(
      (existing) => existing.name.toLowerCase() == normalized.toLowerCase(),
      orElse: () => CategoryModel.other(),
    );

    if (existing.name.toLowerCase() == normalized.toLowerCase() &&
        existing.id != CategoryModel.other().id) {
      return existing;
    }

    try {
      final docRef = await _categoriesRef.add({'name': normalized});
      final categoryModel = CategoryModel(id: docRef.id, name: normalized);
      categories.add(categoryModel);
      return categoryModel;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save category: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  Future<void> loadCategories() async {
    try {
      final snapshot = await _categoriesRef.orderBy('name').get();
      final loaded =
          snapshot.docs
              .map((doc) => CategoryModel.fromFirestore(doc))
              .where((model) => model.name.isNotEmpty)
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );

      categories.value = [
        CategoryModel.other(),
        ...loaded.where((category) => category.id != CategoryModel.other().id),
      ];
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load categories: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> updateRecord(
    String id,
    double amount,
    String categoryId,
    String category,
  ) async {
    try {
      await _db.collection('records').doc(id).update({
        'amount': amount,
        'categoryId': categoryId,
        'category': category,
      });
      calculateYearlyTotals();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update record: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> deleteRecord(String id) async {
    try {
      await _db.collection('records').doc(id).delete();
      calculateYearlyTotals();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete record: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Repayments are looked up fresh so none can outlive their loan, which would
  // leave money in the cash balance with nothing to explain it.
  Future<void> deleteLoan(String loanId) async {
    try {
      final recordsRef = _db.collection('records');
      final repayments = await recordsRef
          .where('userId', isEqualTo: _uid)
          .where('loanId', isEqualTo: loanId)
          .get();

      final batch = _db.batch();
      batch.delete(recordsRef.doc(loanId));
      for (final repayment in repayments.docs) {
        batch.delete(repayment.reference);
      }
      await batch.commit();
      calculateYearlyTotals();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete loan: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> deleteEntry(RecordModel entry) {
    return entry.isLoan ? deleteLoan(entry.id) : deleteRecord(entry.id);
  }

  // Explains what deleting this record will do to the loan it belongs to.
  String deleteWarning(RecordModel entry) {
    const cannotUndo = 'This action cannot be undone.';

    if (entry.isLoanRepayment) {
      return '${entry.category} will owe this '
          'Tk ${entry.amount.toStringAsFixed(2)} again. $cannotUndo';
    }

    if (entry.isLoan) {
      final count = loans
          .where((loan) => loan.id == entry.id)
          .fold(0, (total, loan) => total + loan.repayments.length);
      if (count > 0) {
        final repayments = count == 1 ? '1 repayment' : '$count repayments';
        return 'This also deletes $repayments from ${entry.category}. '
            '$cannotUndo';
      }
    }

    return cannotUndo;
  }

  Future<List<Map<String, dynamic>>> getDailySummaryForMonth({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    DateTime start;
    DateTime end;

    if (startDate != null && endDate != null) {
      start = DateTime(startDate.year, startDate.month, startDate.day);
      end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    } else {
      final now = DateTime.now();
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    }

    final snapshot = await _db
        .collection('records')
        .where('userId', isEqualTo: _uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date')
        .get();

    final fetchedRecords = snapshot.docs
        .map((doc) => RecordModel.fromFirestore(doc))
        .toList();

    final Map<String, Map<String, double>> dailySummary = {};

    for (var record in fetchedRecords) {
      final key =
          "${record.date.year.toString().padLeft(4, '0')}-"
          "${record.date.month.toString().padLeft(2, '0')}-"
          "${record.date.day.toString().padLeft(2, '0')}";

      dailySummary.putIfAbsent(
        key,
        () => {
          'income': 0,
          'expense': 0,
          'investment': 0,
          'loan': 0,
          'loanRepaid': 0,
          'balance': 0,
        },
      );

      if (record.type == 'income') {
        dailySummary[key]!['income'] =
            dailySummary[key]!['income']! + record.amount;
      } else if (record.type == 'expense') {
        dailySummary[key]!['expense'] =
            dailySummary[key]!['expense']! + record.amount;
      } else if (record.isLoan) {
        dailySummary[key]!['loan'] =
            dailySummary[key]!['loan']! + record.amount;
      } else if (record.isLoanRepayment) {
        dailySummary[key]!['loanRepaid'] =
            dailySummary[key]!['loanRepaid']! + record.amount;
      } else {
        dailySummary[key]!['investment'] =
            dailySummary[key]!['investment']! + record.amount;
      }
      dailySummary[key]!['balance'] =
          dailySummary[key]!['balance']! + record.cashEffect;
    }

    final result = dailySummary.entries.map((e) {
      return {
        'date': e.key,
        'income': e.value['income'],
        'expense': e.value['expense'],
        'investment': e.value['investment'],
        'loan': e.value['loan'],
        'loanRepaid': e.value['loanRepaid'],
        'balance': e.value['balance'],
      };
    }).toList();

    result.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

    // Update monthly totals
    monthlyTotalIncome.value = _calculateTotal(fetchedRecords, 'income');
    monthlyTotalExpense.value = _calculateTotal(fetchedRecords, 'expense');
    monthlyTotalInvestment.value = _calculateTotal(
      fetchedRecords,
      'investment',
    );
    monthlyTotalLoanGiven.value = _calculateTotal(
      fetchedRecords,
      RecordModel.typeLoan,
    );
    monthlyTotalLoanRepaid.value = _calculateTotal(
      fetchedRecords,
      RecordModel.typeLoanRepayment,
    );
    monthlyBalance.value = RecordModel.cashBalance(fetchedRecords);

    return result;
  }
}
