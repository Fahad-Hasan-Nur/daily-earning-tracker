import 'package:cloud_firestore/cloud_firestore.dart';

class RecordModel {
  /// Money lent to someone. Leaves the cash balance.
  static const typeLoan = 'loan';

  /// Money a borrower paid back. Returns to the cash balance.
  static const typeLoanRepayment = 'loan_repayment';

  /// Shared by loans and their repayments so they can be queried together.
  static const loanCategoryId = 'loan';

  final String id;
  final String userId;
  final double amount;
  final String categoryId;
  final String category; // For loans and repayments: the borrower's name
  final String
  type; // 'income', 'expense', 'investment', 'loan' or 'loan_repayment'
  final DateTime date;
  final String? loanId; // Repayments only: the loan being paid back

  RecordModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.categoryId,
    required this.category,
    required this.type,
    required this.date,
    this.loanId,
  });

  bool get isLoan => type == typeLoan;
  bool get isLoanRepayment => type == typeLoanRepayment;
  bool get isLoanEntry => isLoan || isLoanRepayment;

  /// The title shown for this record in transaction lists.
  String get displayTitle {
    if (isLoan) return 'Loan to $category';
    if (isLoanRepayment) return 'Repayment from $category';
    return category;
  }

  /// How this record changes the cash balance.
  double get cashEffect =>
      type == 'income' || isLoanRepayment ? amount : -amount;

  static double cashBalance(Iterable<RecordModel> records) =>
      records.fold(0.0, (total, record) => total + record.cashEffect);

  factory RecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final categoryIdValue = data['categoryId'];
    final categoryId =
        categoryIdValue is String && categoryIdValue.trim().isNotEmpty
        ? categoryIdValue
        : 'other';
    final categoryValue = data['category'];
    final category = categoryValue is String && categoryValue.trim().isNotEmpty
        ? categoryValue
        : 'Other category';

    return RecordModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      categoryId: categoryId,
      category: category,
      type: data['type'] ?? 'expense',
      date: (data['date'] as Timestamp).toDate(),
      loanId: data['loanId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'categoryId': categoryId,
      'category': category,
      'type': type,
      'date': Timestamp.fromDate(date),
      if (loanId != null) 'loanId': loanId,
    };
  }
}
