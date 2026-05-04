import 'package:flutter/material.dart';
import 'dart:async';
import '../models/dog_model.dart';
import '../services/firestore_service.dart';

class DogProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<DogModel> _dogs = [];
  DogModel? _selectedDog;
  bool _isLoading = false;
  StreamSubscription? _dogsSubscription;

  List<DogModel> get dogs => _dogs;
  DogModel? get selectedDog => _selectedDog;
  bool get isLoading => _isLoading;

  void listenToDogs(String uid) {
    _isLoading = true;
    // Don't notify listeners here if this is called in InitState and we can just wait, but typically we want to show loading
    notifyListeners();

    _dogsSubscription?.cancel();
    _dogsSubscription = _firestoreService.getDogs(uid).listen((dogList) {
      _dogs = dogList;
      _isLoading = false;
      notifyListeners();
    });
  }

  void selectDog(DogModel dog) {
    _selectedDog = dog;
    notifyListeners();
  }

  Future<void> addDog(String uid, DogModel dog) async {
    await _firestoreService.addDog(uid, dog);
  }

  Future<void> updateDog(String uid, DogModel dog) async {
    await _firestoreService.updateDog(uid, dog);
  }

  Future<void> deleteDog(String uid, String dogId) async {
    await _firestoreService.deleteDog(uid, dogId);
    if (_selectedDog?.id == dogId) {
      _selectedDog = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _dogsSubscription?.cancel();
    super.dispose();
  }
}
