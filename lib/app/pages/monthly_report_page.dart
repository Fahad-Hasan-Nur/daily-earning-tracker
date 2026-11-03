import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/record_controller.dart';
import '../data/models/category_model.dart';
import '../data/models/record_model.dart';
import '../utils/colors.dart';
import '../widgets/loan_widgets.dart';
import 'date_report_page.dart';
import 'package:intl/intl.dart';

class MonthlyReportPage extends StatefulWidget {
  final DateTime? initialMonth;

  const MonthlyReportPage({super.key, this.initialMonth});

  @override
  State<MonthlyReportPage> createState() => _MonthlyReportPageState();
}

class _MonthlyReportPageState extends State<MonthlyReportPage> {
  final record = Get.find<RecordController>();
  List<Map<String, dynamic>> dailyData = [];
  List<RecordModel> rangeRecords = [];
  bool loading = true;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    final initialMonth = widget.initialMonth;
    if (initialMonth != null) {
      startDate = DateTime(initialMonth.year, initialMonth.month, 1);
      endDate = DateTime(
        initialMonth.year,
        initialMonth.month + 1,
        0,
        23,
        59,
        59,
      );
      fetchDailyData(from: startDate, to: endDate);
    } else {
      fetchDailyData();
    }
  }

  fetchDailyData({DateTime? from, DateTime? to}) async {
    setState(() {
      loading = true;
    });

    final DateTime rangeStart;
    final DateTime rangeEnd;
    if (from != null && to != null) {
      rangeStart = DateTime(from.year, from.month, from.day);
      rangeEnd = DateTime(to.year, to.month, to.day, 23, 59, 59);
    } else {
      final now = DateTime.now();
      rangeStart = DateTime(now.year, now.month, 1);
      rangeEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    }

    dailyData = await record.getDailySummaryForMonth(
      startDate: from,
      endDate: to,
    );
    rangeRecords = await record.getRecordsByDateRange(rangeStart, rangeEnd);

    if (!mounted) return;
    setState(() {
      loading = false;
    });
  }

  double _rangeTotal(String type) => rangeRecords
      .where((r) => r.type == type)
      .fold(0.0, (total, r) => total + r.amount);

  int get totalDays => dailyData.length;

  double get averageIncome {
    if (dailyData.isEmpty) return 0.0;
    double total = dailyData.fold(
      0.0,
      (sum, item) => sum + (item['income'] ?? 0.0),
    );
    return total / dailyData.length;
  }

  double get averageExpense {
    if (dailyData.isEmpty) return 0.0;
    double total = dailyData.fold(
      0.0,
      (sum, item) => sum + (item['expense'] ?? 0.0),
    );
    return total / dailyData.length;
  }

  double get averageInvestment {
    if (dailyData.isEmpty) return 0.0;
    double total = dailyData.fold(
      0.0,
      (sum, item) => sum + (item['investment'] ?? 0.0),
    );
    return total / dailyData.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.appBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: MyColors.appColor,
        title: const Text(
          'Analytics & Reports',
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
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: MyColors.appColor),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Summary
                _buildMonthlyStatsHero(),

                // 2. Date Filter
                _buildDateFilter(),

                // 2.5. Category Breakdown
                _buildCategorySummary(),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    "Daily Breakdown",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: MyColors.appColor,
                    ),
                  ),
                ),

                // 3. Daily List
                Expanded(
                  child: dailyData.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: dailyData.length,
                          itemBuilder: (context, index) {
                            return _buildDailyTile(dailyData[index]);
                          },
                        ),
                ),

                // 4. Secondary Stats
                _buildSecondaryStats(),
              ],
            ),
    );
  }

  Widget _buildMonthlyStatsHero() {
    // Worked out from this page's own records. The controller's monthly totals
    // belong to the dashboard and always describe the current month.
    final investment = _rangeTotal('investment');

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
            color: MyColors.appColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            widget.initialMonth != null
                ? '${DateFormat('MMMM yyyy').format(startDate!)} Overview'
                : startDate == null
                ? 'Current Month Overview'
                : 'Custom Range Overview',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Tk ${RecordModel.cashBalance(rangeRecords).toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Investment Balance: Tk ${investment.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          LoanSummaryLine(
            given: _rangeTotal(RecordModel.typeLoan),
            repaid: _rangeTotal(RecordModel.typeLoanRepayment),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _heroStatItem(
                'Total In',
                _rangeTotal('income'),
                Icons.trending_up,
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              _heroStatItem(
                'Total Out',
                _rangeTotal('expense'),
                Icons.trending_down,
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              _heroStatItem('Invested', investment, Icons.savings_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStatItem(String label, double value, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tk ${value.toStringAsFixed(0)}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: MyColors.appColor,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );

                if (picked != null) {
                  startDate = picked.start;
                  endDate = picked.end;
                  fetchDailyData(from: startDate, to: endDate);
                }
              },
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 20,
                    color: MyColors.appColor,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Date Range",
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                      Text(
                        startDate == null
                            ? "Select dates..."
                            : "${DateFormat('dd/MM').format(startDate!)} - ${DateFormat('dd/MM/yy').format(endDate!)}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (startDate != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.grey),
              onPressed: () {
                setState(() {
                  startDate = null;
                  endDate = null;
                });
                fetchDailyData();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDailyTile(Map<String, dynamic> day) {
    final parts = day['date'].split('-');
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final dayLabel = DateFormat('dd').format(date);
    final monthLabel = DateFormat('MMM').format(date);

    return InkWell(
      onTap: () async {
        await Get.to(() => DateReportPage(selectedDate: date));
        // That day may have changed while it was open.
        if (mounted) fetchDailyData(from: startDate, to: endDate);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            // Date Circle
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: MyColors.appBg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: MyColors.appColor,
                    ),
                  ),
                  Text(
                    monthLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      color: MyColors.appColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Values
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _dailyValueItem('In', day['income']!, Colors.green),
                      _dailyValueItem('Out', day['expense']!, Colors.red),
                      _dailyValueItem(
                        'Invest',
                        day['investment']!,
                        Colors.orange,
                      ),
                      _dailyValueItem('Balance', day['balance']!, Colors.blue),
                    ],
                  ),
                  LoanSummaryLine(
                    given: day['loan']!,
                    repaid: day['loanRepaid']!,
                    color: Colors.black54,
                    fontSize: 11,
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black12),
          ],
        ),
      ),
    );
  }

  Widget _dailyValueItem(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.black38),
        ),
        Text(
          value.toStringAsFixed(0),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySummary() {
    final categoryTotals = record.getCategoryTotals(rangeRecords);

    if (categoryTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            'Category Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: MyColors.appColor,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categoryTotals.entries.map((entry) {
                final categoryId = entry.key;
                final total = entry.value;
                final category = record.categories.firstWhere(
                  (cat) => cat.id == categoryId,
                  orElse: () =>
                      const CategoryModel(id: 'other', name: 'Other category'),
                );

                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: MyColors.appColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tk ${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSecondaryStats() {
    return Container(
      margin: const EdgeInsets.all(1),
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _miniStat('Days', totalDays.toDouble(), Colors.purple, isInt: true),
          _miniStat('Avg In', averageIncome, Colors.teal),
          _miniStat('Avg Out', averageExpense, Colors.orange),
          _miniStat('Avg Invest', averageInvestment, Colors.indigo),
        ],
      ),
    );
  }

  Widget _miniStat(
    String label,
    double value,
    Color color, {
    bool isInt = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Text(
          isInt ? value.toInt().toString() : value.toStringAsFixed(0),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.query_stats_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "No data found for this range",
            style: TextStyle(color: Colors.black38, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
