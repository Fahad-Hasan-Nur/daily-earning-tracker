import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/record_controller.dart';
import '../data/models/record_model.dart';

/// Explains the part of a balance that came from loans. Shows nothing when a
/// period has no loan activity, so the summaries look the same without loans.
class LoanSummaryLine extends StatelessWidget {
  final double given;
  final double repaid;
  final Color color;
  final double fontSize;
  final double topPadding;
  final TextAlign textAlign;

  const LoanSummaryLine({
    super.key,
    required this.given,
    required this.repaid,
    this.color = Colors.white70,
    this.fontSize = 13,
    this.topPadding = 4,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final parts = [
      if (given > 0) 'Tk ${given.toStringAsFixed(2)} given',
      if (repaid > 0) 'Tk ${repaid.toStringAsFixed(2)} repaid',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Text(
        'Loans: ${parts.join(' · ')}',
        textAlign: textAlign,
        style: TextStyle(color: color, fontSize: fontSize),
      ),
    );
  }
}

/// Asks before deleting a record, spelling out what happens to any loan it
/// belongs to.
void confirmDeleteEntry(RecordModel entry, {VoidCallback? onDeleted}) {
  final record = Get.find<RecordController>();

  Get.defaultDialog(
    title: 'Delete Record?',
    middleText: record.deleteWarning(entry),
    textConfirm: 'Delete',
    textCancel: 'Cancel',
    confirmTextColor: Colors.white,
    buttonColor: Colors.red,
    onConfirm: () async {
      Get.back();
      await record.deleteEntry(entry);
      onDeleted?.call();
    },
  );
}
