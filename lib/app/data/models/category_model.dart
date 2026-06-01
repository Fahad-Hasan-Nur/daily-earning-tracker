import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;

  const CategoryModel({required this.id, required this.name});

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = (data['name'] ?? '').toString().trim();
    return CategoryModel(
      id: doc.id,
      name: name.isNotEmpty ? name : 'Other category',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name};
  }

  static CategoryModel other() =>
      const CategoryModel(id: 'other', name: 'Other category');

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CategoryModel && other.id == id && other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, name);
}
