import 'package:daily_income_tracker/app/pages/date_report_page.dart';
import 'package:daily_income_tracker/app/pages/monthly_report_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/record_controller.dart';
import '../utils/colors.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final amountCtrl = TextEditingController();
  final categoryCtrl = TextEditingController();
  final dateCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  final _formKey = GlobalKey<FormState>();
  String _transactionType = 'income'; // 'income' or 'expense'

  @override
  void initState() {
    super.initState();
    dateCtrl.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
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
        dateCtrl.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final record = Get.put(RecordController());

    return Scaffold(
      backgroundColor: MyColors.appBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: MyColors.appColor,
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => Get.to(const MonthlyReportPage()),
            icon: const Icon(Icons.analytics_outlined, color: Colors.white),
          ),
          IconButton(
            onPressed: () => auth.logout(),
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Dashboard Summary Card
            _buildBalanceCard(record),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                "Add Transaction",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: MyColors.appColor,
                ),
              ),
            ),

            // 2. Transaction Input Form
            _buildTransactionForm(record),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Transactions",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: MyColors.appColor,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM yyyy').format(DateTime.now()),
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),

            // 3. Today's Summary
            _buildDailyMiniSummary(record),

            // 4. Record List
            _buildRecordList(record),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(RecordController record) {
    return Obx(
      () => Container(
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
            const Text(
              'Total Balance',
              style: TextStyle(color: Colors.white70, fontSize: 16),
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
                _balanceItem(
                  'Income',
                  record.monthlyTotalIncome.value,
                  Icons.arrow_downward,
                ),
                Container(width: 1, height: 40, color: Colors.white24),
                _balanceItem(
                  'Expense',
                  record.monthlyTotalExpense.value,
                  Icons.arrow_upward,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceItem(String label, double value, IconData icon) {
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

  Widget _buildTransactionForm(RecordController record) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Type Toggle
            Container(
              decoration: BoxDecoration(
                color: MyColors.appBg.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _typeButton('income', 'Income'),
                  _typeButton('expense', 'Expense'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Amount', Icons.attach_money),
              validator: (val) => val!.isEmpty || double.tryParse(val) == null
                  ? "Invalid"
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: categoryCtrl,
              decoration: _inputDecoration(
                'Detail / Category',
                Icons.label_outline,
              ),
              validator: (val) => val!.isEmpty ? "Enter detail" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: dateCtrl,
              readOnly: true,
              onTap: _pickDate,
              decoration: _inputDecoration('Date', Icons.calendar_today),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    record.addRecord(
                      double.parse(amountCtrl.text),
                      _transactionType,
                      _selectedDate,
                      categoryCtrl.text,
                    );
                    amountCtrl.clear();
                    categoryCtrl.clear();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColors.appColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Transaction',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeButton(String type, String label) {
    bool isSelected = _transactionType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _transactionType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? MyColors.appColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : MyColors.appColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: MyColors.appColor, size: 20),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
    );
  }

  Widget _buildDailyMiniSummary(RecordController record) {
    return Obx(
      () => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _miniSummaryItem('In', record.totalIncome.value, Colors.green),
            _miniSummaryItem('Out', record.totalExpense.value, Colors.red),
            _miniSummaryItem('Today', record.balance.value, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _miniSummaryItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(0),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordList(RecordController record) {
    return Obx(
      () => ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: record.records.length,
        itemBuilder: (context, index) {
          final r = record.records[index];
          final isIncome = r.type == 'income';
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isIncome ? Colors.green : Colors.red).withOpacity(
                    0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIncome ? Icons.add_rounded : Icons.remove_rounded,
                  color: isIncome ? Colors.green : Colors.red,
                ),
              ),
              title: Text(
                r.category,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                DateFormat('hh:mm a').format(r.date),
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'} Tk ${r.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isIncome ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.grey,
                    ),
                    onPressed: () => record.deleteRecord(r.id),
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
