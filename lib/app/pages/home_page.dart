import 'package:daily_income_tracker/app/pages/monthly_report_page.dart';
import 'package:daily_income_tracker/app/pages/yearly_report_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/record_controller.dart';
import '../data/models/category_model.dart';
import '../data/models/record_model.dart';
import '../utils/colors.dart';
import '../widgets/loan_widgets.dart';
import 'loans_page.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final amountCtrl = TextEditingController();
  final newCategoryCtrl = TextEditingController();
  final categoryDetailCtrl = TextEditingController();
  final borrowerCtrl = TextEditingController();
  final dateCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  final _formKey = GlobalKey<FormState>();
  String _transactionType =
      'income'; // 'income', 'expense', 'investment', 'loan'
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    dateCtrl.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    newCategoryCtrl.dispose();
    categoryDetailCtrl.dispose();
    borrowerCtrl.dispose();
    dateCtrl.dispose();
    // This page only goes away on sign-out. The controller's data and listeners
    // belong to that user, so whoever signs in next needs a fresh one.
    Get.delete<RecordController>();
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
        dateCtrl.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      });
    }
  }

  Future<void> _showAddCategoryDialog(RecordController record) async {
    newCategoryCtrl.clear();

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
            _buildYearlyReportCard(record),

            // 1. Dashboard Summary Card
            _buildBalanceCard(record),

            // Loans Given
            _buildLoansCard(record),

            // 2. Yearly Report Card
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

            // 4. Category Summary
            _buildCategorySummary(record),

            // 4. Today's Summary
            _buildDailyMiniSummary(record),

            // 5. Record List
            _buildRecordList(record),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(RecordController record) {
    return Obx(
      () => GestureDetector(
        onTap: () => Get.to(const MonthlyReportPage()),
        child: Container(
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
              const Text(
                'Cash Balance',
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
              const SizedBox(height: 8),
              Text(
                'Investment Balance: Tk ${record.monthlyTotalInvestment.value.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              LoanSummaryLine(
                given: record.monthlyTotalLoanGiven.value,
                repaid: record.monthlyTotalLoanRepaid.value,
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
                  Container(width: 1, height: 40, color: Colors.white24),
                  _balanceItem(
                    'Investment',
                    record.monthlyTotalInvestment.value,
                    Icons.savings_rounded,
                  ),
                ],
              ),
            ],
          ),
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

  Widget _buildYearlyReportCard(RecordController record) {
    return Obx(
      () => GestureDetector(
        onTap: () => Get.to(const YearlyReportPage()),
        child: Container(
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
                color: Colors.green.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Yearly Cash Balance',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Tk ${record.yearlyBalance.value.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Investment Balance: Tk ${record.yearlyTotalInvestment.value.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              LoanSummaryLine(
                given: record.yearlyTotalLoanGiven.value,
                repaid: record.yearlyTotalLoanRepaid.value,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _balanceItem(
                    'Income',
                    record.yearlyTotalIncome.value,
                    Icons.arrow_downward,
                  ),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _balanceItem(
                    'Expense',
                    record.yearlyTotalExpense.value,
                    Icons.arrow_upward,
                  ),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _balanceItem(
                    'Investment',
                    record.yearlyTotalInvestment.value,
                    Icons.savings_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoansCard(RecordController record) {
    return Obx(() {
      final openLoans = record.openLoanCount;
      return GestureDetector(
        onTap: () => Get.to(() => const LoansPage()),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.all(16),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: MyColors.appColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.handshake_rounded,
                  color: MyColors.appColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Loans Given',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tk ${record.totalLoanOutstanding.toStringAsFixed(2)} outstanding',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      switch (openLoans) {
                        0 => 'No open loans',
                        1 => '1 open loan',
                        _ => '$openLoans open loans',
                      },
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.black26),
            ],
          ),
        ),
      );
    });
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
            color: Colors.black.withValues(alpha: 0.05),
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
                color: MyColors.appBg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _typeButton('income', 'Income'),
                  _typeButton('expense', 'Expense'),
                  _typeButton('investment', 'Investment'),
                  _typeButton(RecordModel.typeLoan, 'Loan'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Amount', Icons.attach_money),
              validator: (val) {
                final amount = double.tryParse(val ?? '');
                if (amount == null) return "Invalid";
                final isBadLoan =
                    _transactionType == RecordModel.typeLoan &&
                    (!amount.isFinite || amount <= 0);
                return isBadLoan ? "Enter an amount above 0" : null;
              },
            ),
            const SizedBox(height: 12),
            if (_transactionType == RecordModel.typeLoan)
              TextFormField(
                controller: borrowerCtrl,
                decoration: _inputDecoration('Given to', Icons.person_outline),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Enter a name' : null,
              )
            else ...[
              Obx(() {
                _selectedCategoryId ??= record.categories.first.id;
                final selectedCat = record.categories.firstWhere(
                  (cat) => cat.id == _selectedCategoryId,
                  orElse: CategoryModel.other,
                );
                if (categoryDetailCtrl.text.isEmpty) {
                  categoryDetailCtrl.text = selectedCat.name;
                }
                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: _inputDecoration(
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
                          categoryDetailCtrl.text = newSelectedCat.name;
                        },
                        validator: (val) => val == null || val.isEmpty
                            ? 'Choose category'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _showAddCategoryDialog(record),
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
                controller: categoryDetailCtrl,
                decoration: _inputDecoration(
                  'Category Detail',
                  Icons.edit_note,
                ),
                validator: (val) =>
                    val!.isEmpty ? 'Enter category detail' : null,
              ),
            ],
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
                    if (_transactionType == RecordModel.typeLoan) {
                      record.addLoan(
                        double.parse(amountCtrl.text),
                        borrowerCtrl.text.trim(),
                        _selectedDate,
                      );
                      amountCtrl.clear();
                      borrowerCtrl.clear();
                      return;
                    }
                    final selectedCategory = record.categories.firstWhere(
                      (cat) => cat.id == _selectedCategoryId,
                      orElse: CategoryModel.other,
                    );
                    final categoryDetail = categoryDetailCtrl.text.trim();
                    record.addRecord(
                      double.parse(amountCtrl.text),
                      _transactionType,
                      _selectedDate,
                      selectedCategory.id,
                      categoryDetail.isEmpty
                          ? selectedCategory.name
                          : categoryDetail,
                    );
                    amountCtrl.clear();
                    categoryDetailCtrl.clear();
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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? MyColors.appColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          // Keeps "Investment" on one line on narrow phones.
          child: FittedBox(
            fit: BoxFit.scaleDown,
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

  Widget _buildCategorySummary(RecordController record) {
    return Obx(() {
      final categoryTotals = record.getCategoryTotals(record.records);
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
                    orElse: CategoryModel.other,
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
    });
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
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniSummaryItem('In', record.totalIncome.value, Colors.green),
                _miniSummaryItem('Out', record.totalExpense.value, Colors.red),
                _miniSummaryItem(
                  'Invest',
                  record.totalInvestment.value,
                  Colors.orange,
                ),
                _miniSummaryItem('Today', record.balance.value, Colors.blue),
              ],
            ),
            LoanSummaryLine(
              given: record.totalLoanGiven.value,
              repaid: record.totalLoanRepaid.value,
              color: Colors.black54,
              fontSize: 12,
              topPadding: 10,
            ),
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

  ({Color color, IconData icon, String sign}) _typeVisuals(String type) {
    switch (type) {
      case 'income':
        return (color: Colors.green, icon: Icons.add_rounded, sign: '+');
      case 'investment':
        return (color: Colors.blue, icon: Icons.savings_rounded, sign: '-');
      case RecordModel.typeLoan:
        return (
          color: Colors.deepOrange,
          icon: Icons.call_made_rounded,
          sign: '-',
        );
      case RecordModel.typeLoanRepayment:
        return (
          color: Colors.teal,
          icon: Icons.call_received_rounded,
          sign: '+',
        );
      default:
        return (color: Colors.red, icon: Icons.remove_rounded, sign: '-');
    }
  }

  Widget _buildRecordList(RecordController record) {
    return Obx(
      () => ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: record.records.length,
        itemBuilder: (context, index) {
          final r = record.records[index];
          final visuals = _typeVisuals(r.type);
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
                  color: visuals.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(visuals.icon, color: visuals.color),
              ),
              title: Text(
                r.displayTitle,
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
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.grey,
                    ),
                    onPressed: () => r.isLoanEntry
                        ? confirmDeleteEntry(r)
                        : record.deleteRecord(r.id),
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
