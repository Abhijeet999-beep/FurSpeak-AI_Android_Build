import 'package:cloud_firestore/cloud_firestore.dart';

class DogModel {
  final String id;
  final String name;
  final String breed;
  final String? profileImageUrl;
  final DateTime? createdAt;

  DogModel({
    required this.id,
    required this.name,
    required this.breed,
    this.profileImageUrl,
    this.createdAt,
  });

  factory DogModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return DogModel(
      id: doc.id,
      name: data['name'] ?? '',
      breed: data['breed'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'breed': breed,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
