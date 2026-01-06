import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/record_controller.dart';
import '../utils/colors.dart';

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
            onPressed: () => auth.logout(),
            icon: Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),

      // 🔽 THIS IS WHERE STEP 4 GOES
      body: Column(
        children: [
          // 1️⃣ Summary cards
          // Padding(
          //   padding: const EdgeInsets.all(8),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //     children: [
          //       _summaryCard('Income', record.totalIncome, Colors.green),
          //       _summaryCard('Expense', record.totalExpense, Colors.red),
          //       _summaryCard('Balance', record.balance, Colors.blue),
          //     ],
          //   ),
          // ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(
                width: Get.width / 2 - 25,
                height: 100,
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
                      width: Get.width / 2 - 25,
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
                          'Total Income',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: Get.width / 2 - 25,
                      height: 50,
                      child: Center(
                        child: Text(
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          'Tk ${record.totalIncome.toStringAsFixed(2)}',

                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: Get.width / 2 - 25,
                height: 100,
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
                          'Total Expense',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(
                      width: Get.width / 2 - 25,
                      height: 50,
                      child: Center(
                        child: Text(
                          'Tk ${record.totalExpense.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Container(
            width: Get.width - 25,
            height: 100,
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
                      'Balance',
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
                  child: Center(
                    child: Text(
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      'Tk ${record.balance.toStringAsFixed(2)}',

                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2️⃣ Add record form
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
                      TextField(
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
                      ),
                      const SizedBox(height: 10),

                      TextField(
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
                      ),
                      const SizedBox(height: 10),

                      TextField(
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
                      ),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              record.addRecord(
                                double.parse(amountCtrl.text),
                                'income',
                                _selectedDate,

                                // categoryCtrl.value,
                              );
                              amountCtrl.clear();
                            },
                            child: const Text('Add Income'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              record.addRecord(
                                double.parse(amountCtrl.text),
                                'expense',
                                _selectedDate,
                                // categoryCtrl.value,
                              );
                              amountCtrl.clear();
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
          Expanded(
            child: Obx(
              () => ListView.builder(
                itemCount: record.records.length,
                itemBuilder: (_, i) {
                  final r = record.records[i];
                  return ListTile(
                    title: Text('${r['category'] ?? "N/A"} (${r['type']})'),
                    subtitle: Text(r['date'].toDate().toString()),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => record.deleteRecord(r.id),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, double value, Color color) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: color)),
            const SizedBox(height: 5),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
