import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/record_controller.dart';
import '../utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class DateReportPage extends StatefulWidget {
  final DateTime? selectedDate; // <-- ADD THIS

  const DateReportPage({super.key, this.selectedDate});

  @override
  State<DateReportPage> createState() => _DateReportPageState();
}

class _DateReportPageState extends State<DateReportPage> {
  final _dateCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  final RecordController record = Get.find<RecordController>();

  RxList dateRecords = <DocumentSnapshot>[].obs;
  var totalIncome = 0.0.obs;
  var totalExpense = 0.0.obs;
  var balance = 0.0.obs;

  @override
  void initState() {
    super.initState();

    _selectedDate = widget.selectedDate ?? DateTime.now();
    _dateCtrl.text = _selectedDate.toString().split(' ')[0];

    fetchDateRecords(); // fetch automatically
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    super.dispose();
  }

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
        _dateCtrl.text = _selectedDate.toLocal().toString().split(' ')[0];
      });
      fetchDateRecords();
    }
  }

  void fetchDateRecords() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    // make sure you have access
    final startOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final endOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      23,
      59,
      59,
    );

    record.db
        .collection('records')
        .where('userId', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get()
        .then((snapshot) {
          dateRecords.value = snapshot.docs;

          // Calculate totals
          totalIncome.value = dateRecords
              .where((e) => e['type'] == 'income')
              .fold(0.0, (a, b) => a + b['amount']);
          totalExpense.value = dateRecords
              .where((e) => e['type'] == 'expense')
              .fold(0.0, (a, b) => a + b['amount']);
          balance.value = totalIncome.value - totalExpense.value;
        });
  }

  void _showEditDialog(DocumentSnapshot r) {
    final amountCtrl = TextEditingController(text: r['amount'].toString());
    final categoryCtrl = TextEditingController(text: r['category']);
    DateTime selectedDate = (r['date'] as Timestamp).toDate();
    String type = r['type'];

    Get.defaultDialog(
      title: "Edit Record",
      content: Column(
        children: [
          TextField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "Amount"),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: categoryCtrl,
            decoration: const InputDecoration(hintText: "Detail"),
          ),
          const SizedBox(height: 10),
          DropdownButton<String>(
            value: type,
            isExpanded: true,
            items: ['income', 'expense']
                .map(
                  (e) =>
                      DropdownMenuItem(value: e, child: Text(e.toUpperCase())),
                )
                .toList(),
            onChanged: (val) {
              type = val!;
            },
          ),
        ],
      ),
      textConfirm: "Update",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        await record.updateRecord(
          r.id,
          double.parse(amountCtrl.text),
          categoryCtrl.text,
        );

        Get.back();
        fetchDateRecords(); // refresh date list
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Date Report'),
        backgroundColor: MyColors.appColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextFormField(
              controller: _dateCtrl,
              readOnly: true,
              onTap: _pickDate,
              decoration: InputDecoration(
                hintText: 'Select Date',
                filled: true,
                fillColor: Colors.white,
                suffixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),

            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _summaryCard('Income', totalIncome.value, Colors.green),
                  _summaryCard('Expense', totalExpense.value, Colors.red),
                  _summaryCard('Balance', balance.value, Colors.blue),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: Obx(
                () => ListView.builder(
                  itemCount: dateRecords.length,
                  itemBuilder: (_, i) {
                    final r = dateRecords[i];
                    final isIncome = r['type'] == 'income';
                    final amount = (r['amount'] as num).toDouble();
                    final category = r['category'] ?? 'N/A';
                    final date = (r['date'] as Timestamp).toDate();

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: isIncome ? Colors.green[50] : Colors.red[50],
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isIncome ? Colors.green : Colors.red,
                          child: Icon(
                            isIncome
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          category,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${date.toLocal().toString().split(' ')[0]}',
                        ),
                        trailing: SizedBox(
                          width: 120, // fixed width prevents layout overflow
                          child: Column(
                            mainAxisSize: MainAxisSize.min, // 🔥 IMPORTANT
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${isIncome ? '+' : '-'} Tk ${amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isIncome
                                      ? Colors.green[800]
                                      : Colors.red[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: Colors.blue,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _showEditDialog(r),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      Get.defaultDialog(
                                        title: "Delete?",
                                        middleText: "Are you sure?",
                                        onConfirm: () async {
                                          await record.deleteRecord(r.id);
                                          Get.back();
                                          fetchDateRecords();
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
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
    );
  }

  Widget _summaryCard(String title, double value, Color color) {
    return Container(
      width: (Get.width - 40) / 3,
      height: 60,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
