import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/record_controller.dart';
import '../utils/colors.dart';
import 'date_report_page.dart';
import 'package:intl/intl.dart';

class MonthlyReportPage extends StatefulWidget {
  const MonthlyReportPage({super.key});

  @override
  State<MonthlyReportPage> createState() => _MonthlyReportPageState();
}

class _MonthlyReportPageState extends State<MonthlyReportPage> {
  final record = Get.find<RecordController>();
  List<Map<String, dynamic>> dailyData = [];
  bool loading = true;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    fetchDailyData();
  }

  fetchDailyData({DateTime? from, DateTime? to}) async {
    setState(() {
      loading = true;
    });

    dailyData = await record.getDailySummaryForMonth(
      startDate: from,
      endDate: to,
    );

    setState(() {
      loading = false;
    });
  }

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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: MyColors.appColor))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Summary
                _buildMonthlyStatsHero(),

                // 2. Date Filter
                _buildDateFilter(),

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
    return Obx(() => Container(
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
                startDate == null ? 'Current Month Overview' : 'Custom Range Overview',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Tk ${record.monthlyBalance.value.toStringAsFixed(2)}',
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
                  _heroStatItem('Total In', record.monthlyTotalIncome.value, Icons.trending_up),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _heroStatItem('Total Out', record.monthlyTotalExpense.value, Icons.trending_down),
                ],
              ),
            ],
          ),
        ));
  }

  Widget _heroStatItem(String label, double value, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
            color: Colors.black.withOpacity(0.05),
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
                  const Icon(Icons.calendar_today_rounded, size: 20, color: MyColors.appColor),
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
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final dayLabel = DateFormat('dd').format(date);
    final monthLabel = DateFormat('MMM').format(date);

    return InkWell(
      onTap: () => Get.to(() => DateReportPage(selectedDate: date)),
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
                color: MyColors.appBg.withOpacity(0.5),
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
                    style: const TextStyle(fontSize: 10, color: MyColors.appColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Values
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _dailyValueItem('In', day['income']!, Colors.green),
                  _dailyValueItem('Out', day['expense']!, Colors.red),
                  _dailyValueItem('Balance', day['balance']!, Colors.blue),
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
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black38)),
        Text(
          value.toStringAsFixed(0),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
        ],
      ),
    );
  }

  Widget _miniStat(String label, double value, Color color, {bool isInt = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
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
