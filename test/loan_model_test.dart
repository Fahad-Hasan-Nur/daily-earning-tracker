import 'package:daily_income_tracker/app/data/models/loan_model.dart';
import 'package:daily_income_tracker/app/data/models/record_model.dart';
import 'package:flutter_test/flutter_test.dart';

RecordModel _record(
  String id,
  String type,
  double amount, {
  String? loanId,
  DateTime? date,
}) {
  return RecordModel(
    id: id,
    userId: 'user',
    amount: amount,
    categoryId: 'category',
    category: 'Rahim',
    type: type,
    date: date ?? DateTime(2026, 11, 3),
    loanId: loanId,
  );
}

RecordModel _loan(String id, double amount, {DateTime? date}) =>
    _record(id, RecordModel.typeLoan, amount, date: date);

RecordModel _repayment(
  String id,
  String loanId,
  double amount, {
  DateTime? date,
}) => _record(
  id,
  RecordModel.typeLoanRepayment,
  amount,
  loanId: loanId,
  date: date,
);

LoanModel _loanWith(double amount, List<double> repayments) {
  return LoanModel(
    record: _loan('loan', amount),
    repayments: [
      for (var i = 0; i < repayments.length; i++)
        _repayment('r$i', 'loan', repayments[i]),
    ],
  );
}

void main() {
  group('cash balance', () {
    test('a loan is deducted and a repayment is added back', () {
      final balance = RecordModel.cashBalance([
        _record('i', 'income', 10000),
        _record('e', 'expense', 2000),
        _record('v', 'investment', 1000),
        _loan('l', 3000),
        _repayment('r', 'l', 500),
      ]);

      expect(balance, 4500);
    });

    test('a loan fully repaid has no effect on the balance', () {
      final balance = RecordModel.cashBalance([
        _record('i', 'income', 1000),
        _loan('l', 400),
        _repayment('r1', 'l', 150),
        _repayment('r2', 'l', 250),
      ]);

      expect(balance, 1000);
    });
  });

  group('loan status', () {
    test('no repayments means unpaid, with the full amount owed', () {
      final loan = _loanWith(3000, []);

      expect(loan.status, LoanStatus.unpaid);
      expect(loan.repaid, 0);
      expect(loan.outstanding, 3000);
      expect(loan.progress, 0);
    });

    test('some repayments mean partially paid', () {
      final loan = _loanWith(3000, [1000, 500]);

      expect(loan.status, LoanStatus.partiallyPaid);
      expect(loan.repaid, 1500);
      expect(loan.outstanding, 1500);
      expect(loan.progress, 0.5);
      expect(loan.isSettled, isFalse);
    });

    test('repayments reaching the amount mean paid', () {
      final loan = _loanWith(3000, [1000, 2000]);

      expect(loan.status, LoanStatus.paid);
      expect(loan.outstanding, 0);
      expect(loan.progress, 1);
      expect(loan.isSettled, isTrue);
    });

    test('floating point noise does not leave a loan open', () {
      // 0.1 + 0.2 is 0.30000000000000004 in floating point.
      expect(_loanWith(0.3, [0.1, 0.2]).status, LoanStatus.paid);
      expect(_loanWith(100.1, [33.3, 33.4, 33.4]).status, LoanStatus.paid);
    });
  });

  group('repaymentError', () {
    final loan = _loanWith(3000, [1000]);

    test('accepts a partial amount and the exact balance', () {
      expect(loan.repaymentError(1), isNull);
      expect(loan.repaymentError(2000), isNull);
    });

    test('rejects more than is outstanding', () {
      expect(loan.repaymentError(2000.01), 'Only Tk 2000.00 is outstanding');
    });

    test('rejects amounts that are missing, zero, negative or not finite', () {
      for (final bad in [null, 0.0, -5.0, double.nan, double.infinity]) {
        expect(loan.repaymentError(bad), isNotNull, reason: '$bad');
      }
    });
  });

  group('normalizeRepayment', () {
    test('snaps to the exact balance when paying in full', () {
      final loan = _loanWith(100, [33.33]);

      expect(loan.normalizeRepayment(66.67), loan.outstanding);
    });

    test('leaves a partial amount alone', () {
      expect(_loanWith(100, []).normalizeRepayment(40), 40);
    });
  });

  group('amountEditError', () {
    final loan = _loanWith(3000, [1000]);

    test('accepts any amount covering what was already repaid', () {
      expect(loan.amountEditError(5000), isNull);
      expect(loan.amountEditError(1000), isNull);
    });

    test('rejects less than was already repaid', () {
      expect(loan.amountEditError(999), 'Tk 1000.00 has already been repaid');
    });

    test('rejects amounts that are missing, zero or negative', () {
      for (final bad in [null, 0.0, -1.0, double.nan]) {
        expect(loan.amountEditError(bad), isNotNull, reason: '$bad');
      }
    });
  });

  group('fromRecords', () {
    test('matches each repayment to its own loan', () {
      final loans = LoanModel.fromRecords([
        _loan('a', 100),
        _loan('b', 200),
        _repayment('r1', 'a', 10),
        _repayment('r2', 'b', 20),
        _repayment('r3', 'b', 30),
      ]);

      final a = loans.firstWhere((loan) => loan.id == 'a');
      final b = loans.firstWhere((loan) => loan.id == 'b');
      expect(a.repaid, 10);
      expect(b.repaid, 50);
    });

    test('ignores repayments whose loan no longer exists', () {
      final loans = LoanModel.fromRecords([
        _loan('a', 100),
        _repayment('r1', 'deleted', 10),
      ]);

      expect(loans, hasLength(1));
      expect(loans.single.repaid, 0);
    });

    test('lists open loans first, newest first in each group', () {
      final loans = LoanModel.fromRecords([
        _loan('paidNew', 100, date: DateTime(2026, 11, 9)),
        _repayment('r', 'paidNew', 100),
        _loan('openOld', 100, date: DateTime(2026, 1, 1)),
        _loan('openNew', 100, date: DateTime(2026, 10, 1)),
        _loan('paidOld', 100, date: DateTime(2025, 1, 1)),
        _repayment('r2', 'paidOld', 100),
      ]);

      expect(loans.map((loan) => loan.id), [
        'openNew',
        'openOld',
        'paidNew',
        'paidOld',
      ]);
    });

    test('lists each loan\'s repayments newest first', () {
      final loans = LoanModel.fromRecords([
        _loan('a', 100),
        _repayment('old', 'a', 10, date: DateTime(2026, 1, 1)),
        _repayment('new', 'a', 10, date: DateTime(2026, 6, 1)),
      ]);

      expect(loans.single.repayments.map((r) => r.id), ['new', 'old']);
    });
  });
}
