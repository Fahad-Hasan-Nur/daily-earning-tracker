import 'package:daily_income_tracker/app/pages/date_report_page.dart';
import 'package:daily_income_tracker/app/pages/monthly_report_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/record_controller.dart';
import '../utils/colors.dart';
import 'package:intl/intl.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final amountCtrl = TextEditingController();

  final categoryCtrl = TextEditingController();
  final dateCtrl = TextEditingController();

  final categories = [
    'Food',
    'Rent',
    'Transport',
    'Shopping',
    'Salary',
    'Other',
  ];
  DateTime _selectedDate = DateTime.now();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final record = Get.put(RecordController());
    Future<void> _pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );

      if (picked != null) {
        setState(() {
          _selectedDate = picked;
          dateCtrl.text = _selectedDate.toLocal().toString().split(' ')[0];
        });
      }
    }

    return Scaffold(
      backgroundColor: MyColors.appBg,
      appBar: AppBar(
        backgroundColor: MyColors.appColor,
        title: Text('Dashboard', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: () => Get.to(MonthlyReportPage()),
            icon: Icon(Icons.calendar_month, color: Colors.white),
          ),

          IconButton(
            onPressed: () => auth.logout(),
            icon: Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),

      // 🔽 THIS IS WHERE STEP 4 GOES
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SizedBox(height: 10),
              Obx(
                () => Container(
                  // width: Get.width,
                  height: 100,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 2,
                        offset: Offset(4, 4),
                      ),
                    ],
                  ),

                  child: Column(
                    children: [
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: MyColors.appColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            DateFormat('MMMM').format(DateTime.now()) +
                                ' Balance: ${record.monthlyBalance.value.toStringAsFixed(2)}',

                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(
                        width: Get.width - 25,
                        height: 50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Center(
                              child: Text(
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                'Income: ${record.monthlyTotalIncome.value.toStringAsFixed(2)}',

                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Container(
                              width: 3,
                              height: 50,
                              decoration: BoxDecoration(
                                color: MyColors.appColor,
                              ),
                            ),
                            Center(
                              child: Text(
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                'Expense: ${record.monthlyTotalExpense.value.toStringAsFixed(2)}',

                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text(
                DateFormat('dd MMMM yyyy').format(DateTime.now()),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        record.totalIncome.value,
                        Colors.green,
                      ),
                      _summaryCard(
                        'Expense',
                        record.totalExpense.value,
                        Colors.red,
                      ),
                      _summaryCard(
                        'Balance',
                        record.balance.value,
                        Colors.blue,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                // decoration: BoxDecoration(
                //   color: MyColors.appColor,
                //   borderRadius: BorderRadius.circular(10),
                // ),
                margin: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    Text(
                      "Add Transaction",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(8),

                      child: Column(
                        children: [
                          TextFormField(
                            controller: amountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Amount',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 20,
                              ),

                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (String? value) {
                              if (value!.isEmpty) {
                                return "Please enter amount";
                              } else if (double.tryParse(value) == null) {
                                return "Please enter valid amount";
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 10),

                          TextFormField(
                            controller: categoryCtrl,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              hintText: 'Detail',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 20,
                              ),

                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (String? value) {
                              if (value!.isEmpty) {
                                return "Please enter detail";
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 10),

                          TextFormField(
                            controller: dateCtrl,
                            readOnly: true,
                            onTap: _pickDate,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              hintText: 'Date',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 20,
                              ),

                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (String? value) {
                              if (value!.isEmpty) {
                                return "Please enter date";
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    record.addRecord(
                                      double.parse(amountCtrl.text),
                                      'income',
                                      _selectedDate,

                                      categoryCtrl.text,
                                    );
                                    amountCtrl.clear();
                                    categoryCtrl.clear();
                                    dateCtrl.clear();
                                  }
                                },
                                child: const Text('Add Income'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    record.addRecord(
                                      double.parse(amountCtrl.text),
                                      'expense',
                                      _selectedDate,

                                      categoryCtrl.text,
                                    );
                                    amountCtrl.clear();
                                    categoryCtrl.clear();
                                    dateCtrl.clear();
                                  }
                                },
                                child: const Text('Add Expense'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // 3️⃣ Scrollable Record List (use Expanded to fill remaining space)
              SizedBox(
                height: 500,
                child: Obx(
                  () => ListView.builder(
                    // physics: const NeverScrollableScrollPhysics(),
                    itemCount: record.records.length,
                    itemBuilder: (_, i) {
                      final r = record.records[i];
                      final isIncome = r.get('type') == 'income';
                      final amount = (r.get('amount') as num).toDouble();
                      final category = r.get('category') ?? 'N/A';
                      final date = (r.get('date') as Timestamp).toDate();

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        color: isIncome ? Colors.green[50] : Colors.red[50],
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: isIncome
                                ? Colors.green
                                : Colors.red,
                            child: Icon(
                              isIncome
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            '$category',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            '${date.toLocal().toString().split(' ')[0]}',
                            style: TextStyle(fontSize: 14),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                isIncome
                                    ? '+ Tk ${amount.toStringAsFixed(2)}'
                                    : '- Tk ${amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isIncome
                                      ? Colors.green[800]
                                      : Colors.red[800],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.grey,
                                ),
                                onPressed: () => record.deleteRecord(r.id),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
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
