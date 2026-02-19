import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/record_controller.dart';
import '../utils/colors.dart';
import 'date_report_page.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.appBg,
      appBar: AppBar(
        backgroundColor: MyColors.appColor,
        title: Text('Monthly Daily Report'),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MyColors.appColor,
                          ),
                          onPressed: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );

                            if (picked != null) {
                              startDate = picked.start;
                              endDate = picked.end;

                              fetchDailyData(from: startDate, to: endDate);
                            }
                          },
                          child: Text(
                            startDate == null
                                ? "Select Date Range"
                                : "${startDate!.day}/${startDate!.month}/${startDate!.year} - "
                                      "${endDate!.day}/${endDate!.month}/${endDate!.year}",
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Reset Button
                      if (startDate != null)
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            startDate = null;
                            endDate = null;
                            fetchDailyData(); // reload default month
                          },
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: dailyData.length,
                    itemBuilder: (context, index) {
                      return buildDailyTile(dailyData[index]);
                    },
                  ),
                ),
                Obx(
                  () => Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _summaryCard(
                          'Income',
                          record.monthlyTotalIncome.value,
                          Colors.green,
                        ),
                        _summaryCard(
                          'Expense',
                          record.monthlyTotalExpense.value,
                          Colors.red,
                        ),
                        _summaryCard(
                          'Balance',
                          record.monthlyBalance.value,
                          Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget buildDailyTile(Map<String, dynamic> day) {
    final parts = day['date'].split('-');
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );

    final formattedDate = "${parts[2]}/${parts[1]}/${parts[0]}";

    return GestureDetector(
      onTap: () {
        Get.to(() => DateReportPage(selectedDate: date));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Date (Left side)
            Container(
              width: 65,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: MyColors.appColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    formattedDate,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: MyColors.appColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Details (Right side)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Income
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            color: Colors.green,
                            size: 18,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "${day['income']!.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Expense
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.arrow_upward, color: Colors.red, size: 18),
                          SizedBox(width: 4),
                          Text(
                            "${day['expense']!.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Balance
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: Colors.blue,
                            size: 18,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "${day['balance']!.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String title, double value, Color color) {
    return Container(
      width: (Get.width - 60) / 3,
      height: 60,
      decoration: BoxDecoration(
        // color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
