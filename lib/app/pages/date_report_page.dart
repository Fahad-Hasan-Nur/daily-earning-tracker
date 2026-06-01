import 'package:daily_income_tracker/app/data/models/record_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/record_controller.dart';
import '../utils/colors.dart';
import 'package:intl/intl.dart';

class DateReportPage extends StatefulWidget {
  final DateTime? selectedDate;

  const DateReportPage({super.key, this.selectedDate});

  @override
  State<DateReportPage> createState() => _DateReportPageState();
}

class _DateReportPageState extends State<DateReportPage> {
  final _dateCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  final RecordController record = Get.find<RecordController>();

  final RxList<RecordModel> dateRecords = <RecordModel>[].obs;
  final RxDouble totalIncome = 0.0.obs;
  final RxDouble totalExpense = 0.0.obs;
  final RxDouble balance = 0.0.obs;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    _dateCtrl.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    fetchDateRecords();
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
        _dateCtrl.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      });
      fetchDateRecords();
    }
  }

  Future<void> fetchDateRecords() async {
    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    final results = await record.getRecordsByDateRange(startOfDay, endOfDay);
    dateRecords.value = results;

    totalIncome.value = dateRecords.where((e) => e.type == 'income').fold(0.0, (a, b) => a + b.amount);
    totalExpense.value = dateRecords.where((e) => e.type == 'expense').fold(0.0, (a, b) => a + b.amount);
    balance.value = totalIncome.value - totalExpense.value;
  }

  void _showEditDialog(RecordModel r) {
    final amountCtrl = TextEditingController(text: r.amount.toString());
    final categoryCtrl = TextEditingController(text: r.category);
    String type = r.type;

    Get.defaultDialog(
      title: "Edit Record",
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: MyColors.appColor),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            const SizedBox(height: 10),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: _dialogInputDecoration("Amount", Icons.attach_money),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: categoryCtrl,
              decoration: _dialogInputDecoration("Detail", Icons.label_outline),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: type,
              decoration: _dialogInputDecoration("Type", Icons.swap_vert),
              items: ['income', 'expense']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
                  .toList(),
              onChanged: (val) { if (val != null) type = val; },
            ),
          ],
        ),
      ),
      textConfirm: "Update",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: MyColors.appColor,
      onConfirm: () async {
        await record.updateRecord(r.id, double.parse(amountCtrl.text), categoryCtrl.text);
        Get.back();
        fetchDateRecords();
      },
    );
  }

  InputDecoration _dialogInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: MyColors.appColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.appBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: MyColors.appColor,
        title: const Text('Daily Report', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hero Summary Card
          _buildDayHeroSummary(),

          // 2. Date Selector Card
          _buildDateSelector(),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              "Transactions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: MyColors.appColor),
            ),
          ),

          // 3. Transactions List
          Expanded(
            child: Obx(() => dateRecords.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: dateRecords.length,
                  itemBuilder: (_, i) => _buildTransactionTile(dateRecords[i]),
                ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeroSummary() {
    return Obx(() => Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [MyColors.appColor, Color(0xFF674ABB)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: MyColors.appColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Text(DateFormat('EEEE, dd MMMM').format(_selectedDate), style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            'Tk ${balance.value.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _heroStat('Inflow', totalIncome.value, Icons.arrow_circle_down_rounded),
              Container(width: 1, height: 30, color: Colors.white24),
              _heroStat('Outflow', totalExpense.value, Icons.arrow_circle_up_rounded),
            ],
          ),
        ],
      ),
    ));
  }

  Widget _heroStat(String label, double value, IconData icon) {
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
        Text('Tk ${value.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: _pickDate,
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: MyColors.appColor),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Selected Report Date", style: TextStyle(color: Colors.black54, fontSize: 12)),
                Text(DateFormat('dd MMM yyyy').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.edit_calendar_rounded, color: Colors.black26, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(RecordModel r) {
    final isIncome = r.type == 'income';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isIncome ? Colors.green : Colors.red).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(isIncome ? Icons.add_rounded : Icons.remove_rounded, color: isIncome ? Colors.green : Colors.red),
        ),
        title: Text(r.category, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(DateFormat('hh:mm a').format(r.date), style: const TextStyle(color: Colors.black54, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isIncome ? '+' : '-'} Tk ${r.amount.toStringAsFixed(0)}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isIncome ? Colors.green[700] : Colors.red[700]),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
              onSelected: (val) {
                if (val == 'edit') _showEditDialog(r);
                if (val == 'delete') {
                  Get.defaultDialog(
                    title: "Delete Record?", middleText: "This action cannot be undone.",
                    textConfirm: "Delete", textCancel: "Cancel", confirmTextColor: Colors.white,
                    buttonColor: Colors.red, onConfirm: () { record.deleteRecord(r.id); Get.back(); fetchDateRecords(); },
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text("Edit")])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text("Delete", style: TextStyle(color: Colors.red))])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No transactions found for this day", style: TextStyle(color: Colors.black38, fontSize: 16)),
        ],
      ),
    );
  }
}
