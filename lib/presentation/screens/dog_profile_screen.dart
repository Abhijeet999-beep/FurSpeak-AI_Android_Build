import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

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
      setState(() {
        _profileImagePath = pickedFile.path;
      });
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
      backgroundColor: const Color(0xFFFFFAF2), // Vanilla cream background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF7E8CE0)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Dog Profile',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Color(0xFF7E8CE0),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF7E8CE0)),
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
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Profile Image
                      Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF7E8CE0).withOpacity(0.1),
                              image: _profileImagePath != null
                                  ? DecorationImage(
                                      image:
                                          FileImage(File(_profileImagePath!)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF7E8CE0).withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _profileImagePath == null
                                ? const Icon(Icons.pets,
                                    size: 48, color: Color(0xFF7E8CE0))
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF7E8CE0),
                                shape: BoxShape.circle,
                              ),
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Dog's Name
                      Text(
                        _nameController.text.isEmpty
                            ? 'Your Dog\'s Name'
                            : _nameController.text,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Breed and Age
                      Text(
                        '${_selectedBreed ?? 'Breed'} • ${_ageController.text.isEmpty ? 'Age' : '${_ageController.text} yrs'}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Editable Fields
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(fontFamily: 'Inter'),
                        decoration: const InputDecoration(
                          labelText: '🐶 Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
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
                      DropdownButtonFormField<String>(
                        value: _selectedBreed,
                        items: _breeds
                            .map((breed) => DropdownMenuItem(
                                  value: breed,
                                  child: Text(breed,
                                      style:
                                          const TextStyle(fontFamily: 'Inter')),
                                ))
                            .toList(),
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedBreed = val);
                        },
                        decoration: const InputDecoration(
                          labelText: '🐕 Breed',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
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
                        style: const TextStyle(fontFamily: 'Inter'),
                        decoration: const InputDecoration(
                          labelText: '🎂 Age (in years)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
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
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Behavior Tags
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Behavior Tags',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _behaviorTags.map((tag) {
                          final isSelected =
                              _selectedTags.contains(tag['value']);
                          return FilterChip(
                            label: Text(tag['label']!),
                            selected: isSelected,
                            onSelected: (selected) {
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
                            backgroundColor: Colors.white,
                            selectedColor:
                                const Color(0xFF7E8CE0).withOpacity(0.2),
                            checkmarkColor: const Color(0xFF7E8CE0),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF7E8CE0)
                                  : Colors.grey[600],
                              fontFamily: 'Inter',
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF7E8CE0)
                                    : Colors.grey[300]!,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Save Button
                ElevatedButton(
                  onPressed: _onSave,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF43E97B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFF43E97B).withOpacity(0.2),
                    textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_rounded),
                      SizedBox(width: 8),
                      Text('Save Profile'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Reset Button
                TextButton(
                  onPressed: () {
                    setState(() {
                      _nameController.clear();
                      _ageController.clear();
                      _selectedBreed = null;
                      _profileImagePath = null;
                      _selectedTags.clear();
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
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
