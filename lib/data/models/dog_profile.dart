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
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  DogProfile({
    required this.userId,
    required this.name,
    required this.breed,
    required this.age,
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
    String? imageUrl,
  }) {
    return DogProfile(
      userId: userId,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
