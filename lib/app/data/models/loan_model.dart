import 'record_model.dart';

enum LoanStatus { unpaid, partiallyPaid, paid }

/// A loan and the repayments made against it.
///
/// What's still owed is always worked out from the repayments rather than
/// stored, so deleting a repayment can never leave the two out of step.
class LoanModel {
  /// Differences smaller than this are floating point noise, not real money.
  static const _tolerance = 0.005;

  final RecordModel record;
  final List<RecordModel> repayments;

  const LoanModel({required this.record, required this.repayments});

  String get id => record.id;
  String get borrower => record.category;
  double get amount => record.amount;
  DateTime get date => record.date;

  double get repaid =>
      repayments.fold(0.0, (total, repayment) => total + repayment.amount);

  double get outstanding {
    final left = amount - repaid;
    return left < _tolerance ? 0 : left;
  }

  bool get isSettled => outstanding == 0;

  LoanStatus get status {
    if (isSettled) return LoanStatus.paid;
    return repaid > 0 ? LoanStatus.partiallyPaid : LoanStatus.unpaid;
  }

  /// The share of the loan paid back so far, from 0 to 1.
  double get progress => amount <= 0 ? 1 : (repaid / amount).clamp(0.0, 1.0);

  /// Why [value] can't be recorded as a repayment, or null if it can.
  String? repaymentError(double? value) {
    if (value == null || !value.isFinite || value <= 0) {
      return 'Enter an amount above 0';
    }
    if (value > outstanding + _tolerance) {
      return 'Only Tk ${outstanding.toStringAsFixed(2)} is outstanding';
    }
    return null;
  }

  /// Why the loan's amount can't be changed to [value], or null if it can.
  String? amountEditError(double? value) {
    if (value == null || !value.isFinite || value <= 0) {
      return 'Enter an amount above 0';
    }
    if (value < repaid - _tolerance) {
      return 'Tk ${repaid.toStringAsFixed(2)} has already been repaid';
    }
    return null;
  }

  /// Snaps a repayment to the exact amount owed when it's effectively the
  /// full balance, so paying in full never leaves a fraction of a taka behind.
  double normalizeRepayment(double value) =>
      (value - outstanding).abs() < _tolerance ? outstanding : value;

  /// Groups loan and repayment records into loans: open loans first, then
  /// newest first within each group.
  static List<LoanModel> fromRecords(Iterable<RecordModel> entries) {
    final loanRecords = <RecordModel>[];
    final repaymentsByLoan = <String, List<RecordModel>>{};

    for (final entry in entries) {
      final loanId = entry.loanId;
      if (entry.isLoan) {
        loanRecords.add(entry);
      } else if (entry.isLoanRepayment && loanId != null) {
        (repaymentsByLoan[loanId] ??= []).add(entry);
      }
    }

    final loans = loanRecords.map((loan) {
      final repayments = repaymentsByLoan[loan.id] ?? <RecordModel>[];
      repayments.sort((a, b) => b.date.compareTo(a.date));
      return LoanModel(record: loan, repayments: repayments);
    }).toList();

    loans.sort((a, b) {
      if (a.isSettled != b.isSettled) return a.isSettled ? 1 : -1;
      return b.date.compareTo(a.date);
    });

    return loans;
  }
}
