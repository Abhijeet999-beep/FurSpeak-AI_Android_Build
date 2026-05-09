import 'package:cloud_firestore/cloud_firestore.dart';

class DogModel {
  final String id;
  final String name;
  final String breed;
  final String? gender;
  final double? weight;
  final DateTime? birthday;
  final String? activityLevel;
  final String? notes;
  final String? profileImageUrl;
  final DateTime? createdAt;

  DogModel({
    required this.id,
    required this.name,
    required this.breed,
    this.gender,
    this.weight,
    this.birthday,
    this.activityLevel,
    this.notes,
    this.profileImageUrl,
    this.createdAt,
  });

  factory DogModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return DogModel(
      id: doc.id,
      name: data['name'] ?? '',
      breed: data['breed'] ?? '',
      gender: data['gender'],
      weight: (data['weight'] as num?)?.toDouble(),
      birthday: data['birthday'] != null ? (data['birthday'] as Timestamp).toDate() : null,
      activityLevel: data['activityLevel'],
      notes: data['notes'],
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
      'gender': gender,
      'weight': weight,
      'birthday': birthday != null ? Timestamp.fromDate(birthday!) : null,
      'activityLevel': activityLevel,
      'notes': notes,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
