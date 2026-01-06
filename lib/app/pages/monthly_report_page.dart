import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/record_controller.dart';
import '../utils/colors.dart';

class MonthlyReportPage extends StatefulWidget {
  const MonthlyReportPage({super.key});

  @override
  State<MonthlyReportPage> createState() => _MonthlyReportPageState();
}

class _MonthlyReportPageState extends State<MonthlyReportPage> {
  final record = Get.find<RecordController>();
  List<Map<String, dynamic>> dailyData = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchDailyData();
  }

  fetchDailyData() async {
    setState(() {
      loading = true;
    });
    dailyData = await record.getDailySummaryForMonth();
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
          : ListView.builder(
              itemCount: dailyData.length,
              itemBuilder: (_, i) {
                final day = dailyData[i];
                final dateParts = day['date'].split('-');
                final formattedDate =
                    "${dateParts[2]}/${dateParts[1]}/${dateParts[0]}";

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: Text(
                      formattedDate,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Income: Tk ${day['income']!.toStringAsFixed(2)}",
                          style: TextStyle(color: Colors.green[700]),
                        ),
                        Text(
                          "Expense: Tk ${day['expense']!.toStringAsFixed(2)}",
                          style: TextStyle(color: Colors.red[700]),
                        ),
                        Text(
                          "Balance: Tk ${day['balance']!.toStringAsFixed(2)}",
                          style: TextStyle(color: Colors.blue[700]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
