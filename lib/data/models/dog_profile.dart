import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';

part 'dog_profile.g.dart';

@collection
@JsonSerializable()
class DogProfile {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  final String userId;

  final String name;
  final String breed;
  final int age;
  final String? gender;
  final double? weight;
  final DateTime? birthday;
  final String? activityLevel;
  final String? notes;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  DogProfile({
    required this.userId,
    required this.name,
    required this.breed,
    required this.age,
    this.gender,
    this.weight,
    this.birthday,
    this.activityLevel,
    this.notes,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DogProfile.fromJson(Map<String, dynamic> json) =>
      _$DogProfileFromJson(json);
  Map<String, dynamic> toJson() => _$DogProfileToJson(this);

  DogProfile copyWith({
    String? name,
    String? breed,
    int? age,
    String? gender,
    double? weight,
    DateTime? birthday,
    String? activityLevel,
    String? notes,
    String? imageUrl,
  }) {
    return DogProfile(
      userId: userId,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      birthday: birthday ?? this.birthday,
      activityLevel: activityLevel ?? this.activityLevel,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
