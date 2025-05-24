import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:furspeak_ai/presentation/screens/home_screen.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:go_router/go_router.dart';
import 'package:furspeak_ai/data/models/dog_profile.dart';
import 'package:furspeak_ai/services/auth_service.dart';
import 'package:furspeak_ai/config/app_routes.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _profileImagePath;
  String? _selectedBreed;
  bool _checkingProfile = true;
  String? _customBreed;
  final List<String> _breeds = [
    'Labrador Retriever',
    'German Shepherd',
    'Golden Retriever',
    'Bulldog',
    'Beagle',
    'Poodle',
    'Rottweiler',
    'Yorkshire Terrier',
    'Boxer',
    'Dachshund',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    // Guest check is now handled by route guard, so only check for existing profile
    _checkIfProfileExists();
  }

  Future<void> _checkIfProfileExists() async {
    final isar = GetIt.instance<Isar>();
    final authService = GetIt.instance<AuthService>();
    final user = authService.currentUser;
    if (user == null) {
      setState(() => _checkingProfile = false);
      return;
    }
    final profile = await isar.dogProfiles.getByUserId(user.id);
    if (profile != null) {
      // Profile exists, skip setup
      if (mounted) {
        context.goHome();
      }
    } else {
      setState(() => _checkingProfile = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    HapticFeedback.selectionClick();
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImagePath = pickedFile.path;
      });
    }
  }

  void _onSkip() {
    HapticFeedback.lightImpact();
    context.goHome();
  }

  void _onSave() async {
    HapticFeedback.mediumImpact();
    if (_formKey.currentState?.validate() ?? false) {
      final breedToSave =
          _selectedBreed == 'Other' ? _customBreed : _selectedBreed;
      final authService = GetIt.instance<AuthService>();
      final user = authService.currentUser;

      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to save profile')),
          );
          context.go(AppRoutes.login);
        }
        return;
      }

      try {
        final isar = GetIt.instance<Isar>();
        final profile = DogProfile(
          userId: user.id,
          name: _nameController.text,
          breed: breedToSave ?? '',
          age: (double.tryParse(_ageController.text) ?? 0).toInt(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await isar.writeTxn(() async {
          await isar.dogProfiles.put(profile);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile saved successfully')),
          );
          context.goHome();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving profile: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingProfile) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      appBar: AppBar(
        title: const Text('Setup Dog Profile',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: Color(0xFF007BFF))),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Image
                Center(
                  child: Tooltip(
                    message: _profileImagePath == null
                        ? 'Tap to add a profile photo'
                        : 'Tap to change photo',
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Semantics(
                        label: _profileImagePath == null
                            ? 'Default dog avatar'
                            : 'Dog profile photo',
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFBDBDBD).withOpacity(0.15),
                            image: _profileImagePath != null
                                ? DecorationImage(
                                    image: FileImage(File(_profileImagePath!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _profileImagePath == null
                              ? const Icon(Icons.pets,
                                  size: 48, color: Color(0xFF007BFF))
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Dog's Name
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(fontFamily: 'Inter'),
                  decoration: const InputDecoration(
                    labelText: 'Dog\'s Name',
                    prefixIcon: Icon(Icons.pets),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your dog\'s name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Breed Dropdown
                Tooltip(
                  message: 'Select your dog\'s breed',
                  child: DropdownButtonFormField<String>(
                    value: _selectedBreed,
                    items: _breeds
                        .map((breed) => DropdownMenuItem(
                              value: breed,
                              child: Text(breed,
                                  style: const TextStyle(fontFamily: 'Inter')),
                            ))
                        .toList(),
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedBreed = val;
                        if (val != 'Other') _customBreed = null;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Breed',
                      prefixIcon: Icon(Icons.pets),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your dog\'s breed';
                      }
                      return null;
                    },
                  ),
                ),
                if (_selectedBreed == 'Other') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Custom Breed Name',
                      prefixIcon: Icon(Icons.edit),
                    ),
                    onChanged: (val) => _customBreed = val,
                    validator: (val) {
                      if (_selectedBreed == 'Other' &&
                          (val == null || val.isEmpty)) {
                        return 'Please enter the breed name';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                // Age
                TextFormField(
                  controller: _ageController,
                  style: const TextStyle(fontFamily: 'Inter'),
                  decoration: const InputDecoration(
                    labelText: 'Age (in years)',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your dog\'s age';
                    }
                    final age = double.tryParse(value);
                    if (age == null || age <= 0) {
                      return 'Please enter a valid age';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                // Save Button
                ElevatedButton(
                  onPressed: _onSave,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF007BFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFF007BFF).withOpacity(0.2),
                    textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  child: const Text('Save Profile'),
                ),
                const SizedBox(height: 16),
                // Skip Button (moved here)
                TextButton(
                  onPressed: _onSkip,
                  child: const Text('Skip',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF007BFF),
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
