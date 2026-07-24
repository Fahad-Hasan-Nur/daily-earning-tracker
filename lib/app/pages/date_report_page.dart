import 'package:daily_income_tracker/app/data/models/record_model.dart';
import 'package:daily_income_tracker/app/data/models/category_model.dart';
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
  final RxDouble totalInvestment = 0.0.obs;
  final RxDouble balance = 0.0.obs;

  final _entryFormKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _categoryDetailCtrl = TextEditingController();
  String _transactionType = 'income';
  String? _selectedCategoryId;

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
    _amountCtrl.dispose();
    _categoryDetailCtrl.dispose();
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

    final results = await record.getRecordsByDateRange(startOfDay, endOfDay);
    dateRecords.value = results;

    totalIncome.value = dateRecords
        .where((e) => e.type == 'income')
        .fold(0.0, (a, b) => a + b.amount);
    totalExpense.value = dateRecords
        .where((e) => e.type == 'expense')
        .fold(0.0, (a, b) => a + b.amount);
    totalInvestment.value = dateRecords
        .where((e) => e.type == 'investment')
        .fold(0.0, (a, b) => a + b.amount);
    balance.value =
        totalIncome.value - totalExpense.value - totalInvestment.value;
  }

  void _showEditDialog(RecordModel r) {
    final amountCtrl = TextEditingController(text: r.amount.toString());
    final categoryCtrl = TextEditingController(text: r.category);
    String type = r.type;

    Get.defaultDialog(
      title: "Edit Record",
      titleStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        color: MyColors.appColor,
      ),
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
              decoration: _dialogInputDecoration(
                "Category Detail",
                Icons.label_outline,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: _dialogInputDecoration("Type", Icons.swap_vert),
              items: ['income', 'expense', 'investment']
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) type = val;
              },
            ),
          ],
        ),
      ),
      textConfirm: "Update",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: MyColors.appColor,
      onConfirm: () async {
        await record.updateRecord(
          r.id,
          double.parse(amountCtrl.text),
          r.categoryId,
          categoryCtrl.text,
        );
        Get.back();
        fetchDateRecords();
      },
    );
  }

  Future<void> _showAddCategoryDialog() async {
    final newCategoryCtrl = TextEditingController();

    await Get.dialog(
      AlertDialog(
        title: const Text('Create Category'),
        content: TextField(
          controller: newCategoryCtrl,
          decoration: const InputDecoration(labelText: 'Category name'),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newCategory = newCategoryCtrl.text.trim();
              if (newCategory.isEmpty) {
                Get.snackbar(
                  'Invalid',
                  'Category name cannot be empty',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              final category = await record.addCategory(newCategory);
              if (category != null) {
                setState(() => _selectedCategoryId = category.id);
              }
              Get.back();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddEntryForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _entryFormKey,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: MyColors.appBg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _entryTypeButton('income', 'Income'),
                  _entryTypeButton('expense', 'Expense'),
                  _entryTypeButton('investment', 'Investment'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: _formInputDecoration('Amount', Icons.attach_money),
              validator: (val) => val!.isEmpty || double.tryParse(val) == null
                  ? "Invalid"
                  : null,
            ),
            const SizedBox(height: 12),
            Obx(() {
              _selectedCategoryId ??= record.categories.first.id;
              final selectedCat = record.categories.firstWhere(
                (cat) => cat.id == _selectedCategoryId,
                orElse: CategoryModel.other,
              );
              if (_categoryDetailCtrl.text.isEmpty) {
                _categoryDetailCtrl.text = selectedCat.name;
              }
              return Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategoryId,
                      decoration: _formInputDecoration(
                        'Category',
                        Icons.label_outline,
                      ),
                      items: record.categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category.id,
                              child: Text(category.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedCategoryId = value);
                        final newSelectedCat = record.categories.firstWhere(
                          (cat) => cat.id == value,
                          orElse: CategoryModel.other,
                        );
                        _categoryDetailCtrl.text = newSelectedCat.name;
                      },
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Choose category' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _showAddCategoryDialog,
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: MyColors.appColor,
                    ),
                    tooltip: 'Create category',
                  ),
                ],
              );
            }),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryDetailCtrl,
              decoration: _formInputDecoration(
                'Category Detail',
                Icons.edit_note,
              ),
              validator: (val) => val!.isEmpty ? 'Enter category detail' : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_entryFormKey.currentState!.validate()) {
                    final selectedCategory = record.categories.firstWhere(
                      (cat) => cat.id == _selectedCategoryId,
                      orElse: CategoryModel.other,
                    );
                    final categoryDetail = _categoryDetailCtrl.text.trim();
                    record.addRecord(
                      double.parse(_amountCtrl.text),
                      _transactionType,
                      _selectedDate,
                      selectedCategory.id,
                      categoryDetail.isEmpty
                          ? selectedCategory.name
                          : categoryDetail,
                    );
                    _amountCtrl.clear();
                    _categoryDetailCtrl.clear();
                    fetchDateRecords();
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

  Widget _entryTypeButton(String type, String label) {
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

  InputDecoration _formInputDecoration(String label, IconData icon) {
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

  Widget _buildCategorySummary() {
    if (dateRecords.isEmpty) {
      return const SizedBox.shrink();
    }

    final categoryTotals = <String, double>{};
    for (var record in dateRecords) {
      categoryTotals[record.categoryId] =
          (categoryTotals[record.categoryId] ?? 0) + record.amount;
    }

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
                final record = Get.find<RecordController>();
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
        title: const Text(
          'Daily Report',
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Summary Card
            _buildDayHeroSummary(),

            // 2. Date Selector Card
            _buildDateSelector(),

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

            // 2.4 Add Entry Form
            _buildAddEntryForm(),

            // 2.5 Category Breakdown
            _buildCategorySummary(),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                "Transactions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: MyColors.appColor,
                ),
              ),
            ),

            // 3. Transactions List
            Obx(
              () => dateRecords.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: dateRecords.length,
                      itemBuilder: (_, i) =>
                          _buildTransactionTile(dateRecords[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayHeroSummary() {
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
              color: MyColors.appColor.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              DateFormat('EEEE, dd MMMM').format(_selectedDate),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Tk ${balance.value.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Investment Balance: Tk ${totalInvestment.value.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _heroStat(
                  'Inflow',
                  totalIncome.value,
                  Icons.arrow_circle_down_rounded,
                ),
                Container(width: 1, height: 30, color: Colors.white24),
                _heroStat(
                  'Outflow',
                  totalExpense.value,
                  Icons.arrow_circle_up_rounded,
                ),
                Container(width: 1, height: 30, color: Colors.white24),
                _heroStat(
                  'Invested',
                  totalInvestment.value,
                  Icons.savings_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroStat(String label, double value, IconData icon) {
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

  Widget _buildDateSelector() {
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
      child: InkWell(
        onTap: _pickDate,
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: MyColors.appColor),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Selected Report Date",
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(_selectedDate),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Spacer(),
            const Icon(
              Icons.edit_calendar_rounded,
              color: Colors.black26,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  ({Color color, IconData icon, String sign}) _typeVisuals(String type) {
    switch (type) {
      case 'income':
        return (color: Colors.green, icon: Icons.add_rounded, sign: '+');
      case 'investment':
        return (color: Colors.blue, icon: Icons.savings_rounded, sign: '-');
      default:
        return (color: Colors.red, icon: Icons.remove_rounded, sign: '-');
    }
  }

  Widget _buildTransactionTile(RecordModel r) {
    final visuals = _typeVisuals(r.type);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: visuals.color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(visuals.icon, color: visuals.color),
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
              '${visuals.sign} Tk ${r.amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: visuals.color,
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
              onSelected: (val) {
                if (val == 'edit') _showEditDialog(r);
                if (val == 'delete') {
                  Get.defaultDialog(
                    title: "Delete Record?",
                    middleText: "This action cannot be undone.",
                    textConfirm: "Delete",
                    textCancel: "Cancel",
                    confirmTextColor: Colors.white,
                    buttonColor: Colors.red,
                    onConfirm: () {
                      record.deleteRecord(r.id);
                      Get.back();
                      fetchDateRecords();
                    },
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text("Edit"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Delete", style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
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
          const Text(
            "No transactions found for this day",
            style: TextStyle(color: Colors.black38, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
