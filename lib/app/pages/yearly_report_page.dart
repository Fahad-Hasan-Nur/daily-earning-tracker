import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/record_controller.dart';
import '../controllers/auth_controller.dart';
import '../data/models/record_model.dart';
import '../utils/colors.dart';

class YearlyReportPage extends StatefulWidget {
  const YearlyReportPage({super.key});

  @override
  State<YearlyReportPage> createState() => _YearlyReportPageState();
}

class _YearlyReportPageState extends State<YearlyReportPage> {
  late int selectedYear;
  final record = Get.find<RecordController>();
  final auth = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    selectedYear = DateTime.now().year;
  }

  Future<List<RecordModel>> _getYearlyRecords(int year) async {
    try {
      final uid = auth.user.value?.uid;
      if (uid == null) return [];

      final startOfYear = DateTime(year, 1, 1);
      final endOfYear = DateTime(year, 12, 31, 23, 59, 59);

      final snapshot = await FirebaseFirestore.instance
          .collection('records')
          .where('userId', isEqualTo: uid)
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear),
          )
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfYear))
          .get();

      return snapshot.docs
          .map((doc) => RecordModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching yearly records: $e');
      return [];
    }
  }

  Map<int, Map<String, double>> _getMonthlyDataForYear(
    List<RecordModel> records,
  ) {
    final monthlyData = <int, Map<String, double>>{};

    // Initialize all months with zero values
    for (int month = 1; month <= 12; month++) {
      monthlyData[month] = {'income': 0.0, 'expense': 0.0, 'balance': 0.0};
    }

    // Filter records for the selected year and aggregate by month
    for (var rec in records) {
      final month = rec.date.month;
      if (rec.type == 'income') {
        monthlyData[month]!['income'] =
            (monthlyData[month]!['income'] ?? 0.0) + rec.amount;
      } else {
        monthlyData[month]!['expense'] =
            (monthlyData[month]!['expense'] ?? 0.0) + rec.amount;
      }
      monthlyData[month]!['balance'] =
          (monthlyData[month]!['income'] ?? 0.0) -
          (monthlyData[month]!['expense'] ?? 0.0);
    }

    return monthlyData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.appBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: MyColors.appColor,
        title: const Text(
          'Yearly Report',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: FutureBuilder<List<RecordModel>>(
        future: _getYearlyRecords(selectedYear),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: MyColors.appColor),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final yearlyRecords = snapshot.data ?? [];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Year Selector
                _buildYearSelector(),

                // Yearly Summary Card
                _buildYearlySummaryCard(yearlyRecords),

                // Monthly List
                _buildMonthlyList(yearlyRecords),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildYearSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: MyColors.appColor),
            onPressed: selectedYear > 2020
                ? () => setState(() => selectedYear--)
                : null,
          ),
          Text(
            selectedYear.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: MyColors.appColor,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: MyColors.appColor),
            onPressed: selectedYear < DateTime.now().year
                ? () => setState(() => selectedYear++)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildYearlySummaryCard(List<RecordModel> yearlyRecords) {
    final monthlyData = _getMonthlyDataForYear(yearlyRecords);
    double totalIncome = 0;
    double totalExpense = 0;

    for (var month in monthlyData.values) {
      totalIncome += month['income'] ?? 0;
      totalExpense += month['expense'] ?? 0;
    }

    final balance = totalIncome - totalExpense;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [MyColors.appColor, Color(0xFF674ABB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: MyColors.appColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Year $selectedYear Balance',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Tk ${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem('Income', totalIncome, Icons.arrow_downward),
              Container(width: 1, height: 40, color: Colors.white24),
              _summaryItem('Expense', totalExpense, Icons.arrow_upward),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double value, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tk ${value.toStringAsFixed(0)}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyList(List<RecordModel> yearlyRecords) {
    final monthlyData = _getMonthlyDataForYear(yearlyRecords);
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            'Monthly Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: MyColors.appColor,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 12,
          itemBuilder: (context, index) {
            final month = index + 1;
            final data = monthlyData[month]!;
            final income = data['income'] ?? 0.0;
            final expense = data['expense'] ?? 0.0;
            final balance = data['balance'] ?? 0.0;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          months[index],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'In: Tk ${income.toStringAsFixed(0)} ',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Out: Tk ${expense.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Tk ${balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: balance >= 0
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
