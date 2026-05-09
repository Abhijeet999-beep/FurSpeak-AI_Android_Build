import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:furspeak_ai/utils/media_utils.dart';
import 'package:image_cropper/image_cropper.dart';

class DogProfileScreen extends StatefulWidget {
  const DogProfileScreen({super.key});

  @override
  State<DogProfileScreen> createState() => _DogProfileScreenState();
}

class _DogProfileScreenState extends State<DogProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _profileImagePath;
  String? _selectedBreed;
  List<String> _selectedTags = [];

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

  final List<Map<String, String>> _behaviorTags = [
    {'label': 'Playful 🎾', 'value': 'playful'},
    {'label': 'Sleepy 😴', 'value': 'sleepy'},
    {'label': 'Protective 🛡️', 'value': 'protective'},
    {'label': 'Friendly 🐾', 'value': 'friendly'},
    {'label': 'Energetic ⚡', 'value': 'energetic'},
    {'label': 'Calm 🧘', 'value': 'calm'},
  ];

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
      final croppedFile = await MediaUtils.cropImage(
        File(pickedFile.path),
      );

      if (croppedFile != null) {
        setState(() {
          _profileImagePath = croppedFile.path;
        });
      }
    }
  }

  void _onSave() {
    HapticFeedback.mediumImpact();
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: Save profile to database
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully! 🐾'),
          backgroundColor: Color(0xFF43E97B),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Dog Profile',
          style: AppTheme.headingStyle.copyWith(fontSize: 20, color: AppTheme.primaryColor),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryColor),
            onPressed: () {
              // TODO: Toggle edit mode
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Card
                PetMoodGlass(
                  color: AppTheme.surfaceActive,
                  opacity: 0.7,
                  borderRadius: AppTheme.borderRadiusExtraLarge,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.05), width: 1.5),
                      borderRadius: AppTheme.borderRadiusExtraLarge,
                    ),
                    child: Column(
                      children: [
                        // Profile Image
                        Stack(
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryColor.withOpacity(0.05),
                                image: _profileImagePath != null
                                    ? DecorationImage(
                                        image: FileImage(File(_profileImagePath!)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1), width: 4),
                                boxShadow: AppTheme.softShadow,
                              ),
                              child: _profileImagePath == null
                                  ? const Icon(Icons.pets_rounded, size: 56, color: AppTheme.primaryColor)
                                  : null,
                            ),
                            Positioned(
                              right: 4,
                              bottom: 4,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                    boxShadow: AppTheme.softShadow,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Dog's Name
                        Text(
                          _nameController.text.isEmpty ? 'Your Dog\'s Name' : _nameController.text,
                          style: AppTheme.headingStyle.copyWith(fontSize: 26),
                        ),
                        const SizedBox(height: 8),
                        // Breed and Age
                        Text(
                          '${_selectedBreed ?? 'Breed'} • ${_ageController.text.isEmpty ? 'Age' : '${_ageController.text} yrs'}',
                          style: AppTheme.bodyStyle.copyWith(color: AppTheme.textLightColor),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Editable Fields
                PetMoodGlass(
                  color: AppTheme.surfaceActive,
                  opacity: 0.6,
                  borderRadius: AppTheme.borderRadiusExtraLarge,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.05), width: 1.5),
                      borderRadius: AppTheme.borderRadiusExtraLarge,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Profile',
                          style: AppTheme.titleStyle.copyWith(color: AppTheme.primaryColor),
                        ),
                        const SizedBox(height: 24),
                        // Name Field
                        TextFormField(
                          controller: _nameController,
                          style: AppTheme.bodyStyle,
                          decoration: AppTheme.inputDecoration(label: '🐶 Name', hint: 'Enter name'),
                          onChanged: (_) => setState(() {}),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your dog\'s name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Breed Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedBreed,
                          dropdownColor: AppTheme.surfaceActive,
                          style: AppTheme.bodyStyle,
                          items: _breeds
                              .map((breed) => DropdownMenuItem(
                                    value: breed,
                                    child: Text(breed),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedBreed = val);
                          },
                          decoration: AppTheme.inputDecoration(label: '🐕 Breed'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select your dog\'s breed';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Age Field
                        TextFormField(
                          controller: _ageController,
                          style: AppTheme.bodyStyle,
                          decoration: AppTheme.inputDecoration(label: '🎂 Age (in years)'),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Behavior Tags
                PetMoodGlass(
                  color: AppTheme.surfaceActive,
                  opacity: 0.6,
                  borderRadius: AppTheme.borderRadiusExtraLarge,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.05), width: 1.5),
                      borderRadius: AppTheme.borderRadiusExtraLarge,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Behavior Tags',
                          style: AppTheme.titleStyle.copyWith(color: AppTheme.primaryColor),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 12,
                          children: _behaviorTags.map((tag) {
                            final isSelected = _selectedTags.contains(tag['value']);
                            return FilterChip(
                              label: Text(tag['label']!),
                              selected: isSelected,
                              onSelected: (selected) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  if (selected) {
                                    if (_selectedTags.length < 3) {
                                      _selectedTags.add(tag['value']!);
                                    }
                                  } else {
                                    _selectedTags.remove(tag['value']);
                                  }
                                });
                              },
                              backgroundColor: AppTheme.surfaceLow,
                              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                              checkmarkColor: AppTheme.primaryColor,
                              labelStyle: AppTheme.bodyStyle.copyWith(
                                color: isSelected ? AppTheme.primaryColor : AppTheme.textLightColor,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: isSelected ? AppTheme.primaryColor.withOpacity(0.3) : Colors.transparent,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Save Button
                ElevatedButton.icon(
                  onPressed: _onSave,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Save Profile'),
                  style: AppTheme.successButtonStyle.copyWith(
                    padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 18)),
                  ),
                ),
                const SizedBox(height: 16),
                // Reset Button
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _nameController.clear();
                      _ageController.clear();
                      _selectedBreed = null;
                      _profileImagePath = null;
                      _selectedTags.clear();
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textLightColor,
                    textStyle: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Reset Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
