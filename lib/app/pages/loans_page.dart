import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/record_controller.dart';
import '../data/models/loan_model.dart';
import '../data/models/record_model.dart';
import '../utils/colors.dart';
import '../widgets/loan_widgets.dart';

class LoansPage extends StatelessWidget {
  const LoansPage({super.key});

  @override
  Widget build(BuildContext context) {
    final record = Get.find<RecordController>();

    return Scaffold(
      backgroundColor: MyColors.appBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: MyColors.appColor,
        title: const Text(
          'Loans',
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
      body: Obx(() {
        final error = record.loansError.value;
        if (record.loansLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: MyColors.appColor),
          );
        }
        if (error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(error, textAlign: TextAlign.center),
            ),
          );
        }

        final loans = record.loans.toList();
        return ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            _LoanSummary(loans: loans),
            if (loans.isEmpty)
              const _EmptyLoans()
            else
              for (final loan in loans)
                _LoanCard(key: ValueKey(loan.id), loan: loan),
          ],
        );
      }),
    );
  }
}

class _LoanSummary extends StatelessWidget {
  final List<LoanModel> loans;

  const _LoanSummary({required this.loans});

  @override
  Widget build(BuildContext context) {
    final given = loans.fold(0.0, (total, loan) => total + loan.amount);
    final repaid = loans.fold(0.0, (total, loan) => total + loan.repaid);
    final outstanding = loans.fold(
      0.0,
      (total, loan) => total + loan.outstanding,
    );

    return Container(
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
            'Outstanding',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Tk ${outstanding.toStringAsFixed(2)}',
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
              _summaryItem('Given', given, Icons.call_made_rounded),
              Container(width: 1, height: 40, color: Colors.white24),
              _summaryItem('Repaid', repaid, Icons.call_received_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double value, IconData icon) {
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
}

class _EmptyLoans extends StatelessWidget {
  const _EmptyLoans();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
      child: Column(
        children: [
          Icon(Icons.handshake_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No loans yet',
            style: TextStyle(color: Colors.black54, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose Loan when you add a transaction on the dashboard.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black38),
          ),
        ],
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final LoanModel loan;

  const _LoanCard({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  // Hidden from screen readers: the amounts below say the same.
                  child: ExcludeSemantics(
                    child: LinearProgressIndicator(
                      value: loan.progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey[200],
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _amount('Given', loan.amount, Colors.black87),
                    _amount('Repaid', loan.repaid, Colors.green),
                    _amount('Left', loan.outstanding, Colors.deepOrange),
                  ],
                ),
                if (!loan.isSettled) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Get.dialog(_RepaymentDialog(loan: loan)),
                      icon: const Icon(Icons.payments_outlined, size: 18),
                      label: const Text('Receive Payment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyColors.appColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (loan.repayments.isNotEmpty)
            Semantics(container: true, child: _buildHistory()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loan.borrower,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Given ${DateFormat('dd MMM yyyy').format(loan.date)}',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
        _StatusChip(status: loan.status),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
          onSelected: (value) {
            if (value == 'edit') Get.dialog(_EditLoanDialog(loan: loan));
            if (value == 'delete') confirmDeleteEntry(loan.record);
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _amount(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          'Tk ${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildHistory() {
    final count = loan.repayments.length;
    // Its own Material, so the card's white background can't hide the ripple.
    return Material(
      type: MaterialType.transparency,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.only(right: 12),
        childrenPadding: EdgeInsets.zero,
        iconColor: MyColors.appColor,
        collapsedIconColor: Colors.black38,
        title: Text(
          count == 1 ? '1 payment received' : '$count payments received',
          style: const TextStyle(
            color: MyColors.appColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [for (final r in loan.repayments) _buildRepaymentRow(r)],
      ),
    );
  }

  Widget _buildRepaymentRow(RecordModel repayment) {
    return Row(
      children: [
        Expanded(
          child: Text(
            DateFormat('dd MMM yyyy').format(repayment.date),
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ),
        Text(
          '+ Tk ${repayment.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
          tooltip: 'Delete payment',
          onPressed: () => confirmDeleteEntry(repayment),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final LoanStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      LoanStatus.unpaid => ('Unpaid', Colors.red),
      LoanStatus.partiallyPaid => ('Partially paid', Colors.orange.shade800),
      LoanStatus.paid => ('Paid', Colors.green.shade700),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _RepaymentDialog extends StatefulWidget {
  final LoanModel loan;

  const _RepaymentDialog({required this.loan});

  @override
  State<_RepaymentDialog> createState() => _RepaymentDialogState();
}

class _RepaymentDialogState extends State<_RepaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  DateTime _date = DateTime.now();

  LoanModel get _loan => widget.loan;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final loanDay = DateTime(_loan.date.year, _loan.date.month, _loan.date.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(loanDay) ? loanDay : _date,
      firstDate: loanDay,
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountCtrl.text);
    Get.back();
    Get.find<RecordController>().addLoanRepayment(_loan, amount, _date);
  }

  @override
  Widget build(BuildContext context) {
    final outstanding = _loan.outstanding.toStringAsFixed(2);

    return AlertDialog(
      title: Text('Payment from ${_loan.borrower}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Outstanding: Tk $outstanding',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountCtrl,
                autofocus: true,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount received',
                  prefixText: 'Tk ',
                ),
                validator: (value) =>
                    _loan.repaymentError(double.tryParse(value ?? '')),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _amountCtrl.text = outstanding,
                  child: const Text('Pay in full'),
                ),
              ),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date received',
                    prefixIcon: Icon(Icons.calendar_today, size: 20),
                  ),
                  child: Text(DateFormat('yyyy-MM-dd').format(_date)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save Payment')),
      ],
    );
  }
}

class _EditLoanDialog extends StatefulWidget {
  final LoanModel loan;

  const _EditLoanDialog({required this.loan});

  @override
  State<_EditLoanDialog> createState() => _EditLoanDialogState();
}

class _EditLoanDialogState extends State<_EditLoanDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _borrowerCtrl = TextEditingController(text: widget.loan.borrower);
  late final _amountCtrl = TextEditingController(
    text: widget.loan.amount.toStringAsFixed(2),
  );

  @override
  void dispose() {
    _borrowerCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountCtrl.text);
    final borrower = _borrowerCtrl.text.trim();
    Get.back();
    Get.find<RecordController>().updateLoan(widget.loan, amount, borrower);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Loan'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _borrowerCtrl,
                decoration: const InputDecoration(labelText: 'Given to'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount given',
                  prefixText: 'Tk ',
                ),
                validator: (value) =>
                    widget.loan.amountEditError(double.tryParse(value ?? '')),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
