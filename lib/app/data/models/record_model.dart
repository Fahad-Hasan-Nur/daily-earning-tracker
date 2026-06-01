import 'package:cloud_firestore/cloud_firestore.dart';

class RecordModel {
final String id;
  final String userId;
  final double amount;
  final String category;
  final String type; // 'income' or 'expense'
  final DateTime date;

  RecordModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
  });

  factory RecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecordModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      category: data['category'] ?? '',
      type: data['type'] ?? 'expense',
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'category': category,
      'type': type,
      'date': Timestamp.fromDate(date),
    };
  }
}
