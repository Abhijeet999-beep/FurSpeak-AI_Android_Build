import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/dog_model.dart';
import '../models/dog_history_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Users ---
  Future<void> createUser(UserModel user) async {
    final docRef = _db.collection('users').doc(user.id);
    final docSnap = await docRef.get();
    if (!docSnap.exists) {
      await docRef.set(user.toMap(), SetOptions(merge: true));
    }
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  // --- Dogs ---
  Future<bool> hasAnyDogs(String uid) async {
    final snap = await _db.collection('users').doc(uid).collection('dogs').limit(1).get();
    return snap.docs.isNotEmpty;
  }

  Future<void> addDog(String uid, DogModel dog) async {
    await _db.collection('users').doc(uid).collection('dogs').doc(dog.id).set(dog.toMap());
  }

  Stream<List<DogModel>> getDogs(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('dogs')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => DogModel.fromFirestore(doc)).toList());
  }

  Future<void> updateDog(String uid, DogModel dog) async {
    await _db.collection('users').doc(uid).collection('dogs').doc(dog.id).update(dog.toMap());
  }

  Future<void> deleteDog(String uid, String dogId) async {
    await _db.collection('users').doc(uid).collection('dogs').doc(dogId).delete();
  }

  // --- Dog History ---
  Future<void> addDogHistory(String uid, String dogId, DogHistoryModel history) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('dogs')
        .doc(dogId)
        .collection('history')
        .doc(history.id)
        .set(history.toMap());
  }

  Stream<List<DogHistoryModel>> getDogHistory(String uid, String dogId) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('dogs')
        .doc(dogId)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => DogHistoryModel.fromFirestore(doc)).toList());
  }
}
