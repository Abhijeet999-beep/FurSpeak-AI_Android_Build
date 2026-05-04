import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:furspeak_ai/data/models/dog_profile.dart';
import 'package:furspeak_ai/services/auth_service.dart';
import 'package:furspeak_ai/providers/auth_provider.dart';
import 'package:furspeak_ai/config/app_routes.dart';
import 'package:furspeak_ai/models/dog_model.dart';
import 'package:furspeak_ai/services/firestore_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _notesController = TextEditingController();

  String? _profileImagePath;
  String? _selectedBreed;
  String? _selectedGender;
  String? _customBreed;
  bool _checkingProfile = true;
  bool _isSaving = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const _primaryColor = Color(0xFF6C63FF);
  static const _accentColor = Color(0xFFFF6584);
  static const _bgColor = Color(0xFFF8F7FF);

  final List<String> _breeds = [
    'Labrador Retriever', 'German Shepherd', 'Golden Retriever',
    'Bulldog', 'Beagle', 'Poodle', 'Rottweiler', 'Yorkshire Terrier',
    'Boxer', 'Dachshund', 'Shih Tzu', 'Siberian Husky', 'Dobermann',
    'Chihuahua', 'Border Collie', 'Other',
  ];

  final List<String> _genders = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _checkIfProfileExists();
  }

  Future<void> _checkIfProfileExists() async {
    final isar = GetIt.instance<Isar>();
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.userId;
    if (uid == null || uid.isEmpty) {
      // GoRouter guard should prevent this, but handle gracefully
      if (mounted) setState(() => _checkingProfile = false);
      return;
    }
    final profile = await isar.dogProfiles.getByUserId(uid);
    if (profile != null && mounted) {
      authProvider.markProfileAsComplete();
    } else if (mounted) {
      setState(() => _checkingProfile = false);
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _notesController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    HapticFeedback.selectionClick();
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (pickedFile != null && mounted) {
      setState(() => _profileImagePath = pickedFile.path);
    }
  }

  void _onSkip() {
    HapticFeedback.lightImpact();
    context.read<AuthProvider>().markProfileAsComplete();
  }

  /// Fire-and-forget Firestore sync — does not block navigation.
  Future<void> _syncToFirestore(String uid, DogProfile profile) async {
    try {
      final firestoreService = GetIt.instance.isRegistered<FirestoreService>()
          ? GetIt.instance<FirestoreService>()
          : FirestoreService();
      final dogModel = DogModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: profile.name,
        breed: profile.breed,
        createdAt: profile.createdAt,
      );
      await firestoreService.addDog(uid, dogModel);
    } catch (e) {
      debugPrint('Firestore sync failed (non-blocking): $e');
    }
  }

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    HapticFeedback.mediumImpact();

    setState(() => _isSaving = true);

    final breedToSave = _selectedBreed == 'Other' ? _customBreed : _selectedBreed;
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.userId;

    // Defensive: GoRouter guard should ensure we never reach here unauthenticated
    if (uid == null || uid.isEmpty) {
      if (mounted) {
        setState(() => _isSaving = false);
      }
      return;
    }

    try {
      final isar = GetIt.instance<Isar>();
      final profile = DogProfile(
        userId: uid,
        name: _nameController.text.trim(),
        breed: breedToSave ?? '',
        age: (double.tryParse(_ageController.text) ?? 0).toInt(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await isar.writeTxn(() async {
        await isar.dogProfiles.put(profile);
      });

      // Background Firestore sync — fire-and-forget (non-blocking)
      _syncToFirestore(uid, profile);

      if (mounted) {
        context.read<AuthProvider>().markProfileAsComplete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('${profile.name}\'s profile saved! 🐾'),
            ]),
            backgroundColor: _primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingProfile) {
      return const Scaffold(
        backgroundColor: _bgColor,
        body: Center(
          child: CircularProgressIndicator(color: _primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            _buildSliverHeader(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAvatarPicker(),
                      const SizedBox(height: 32),
                      _buildSectionLabel('Basic Info'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _nameController,
                        label: "Dog's Name",
                        icon: Icons.pets,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter your dog\'s name' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildGenderSelector(),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _ageController,
                        label: 'Age (years)',
                        icon: Icons.cake_outlined,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter age';
                          final a = double.tryParse(v);
                          if (a == null || a <= 0 || a > 30) return 'Enter a valid age (1–30)';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSectionLabel('Breed'),
                      const SizedBox(height: 12),
                      _buildBreedDropdown(),
                      if (_selectedBreed == 'Other') ...[
                        const SizedBox(height: 12),
                        _buildTextField(
                          label: 'Enter Breed Name',
                          icon: Icons.edit_outlined,
                          onChanged: (v) => _customBreed = v,
                          validator: (v) => (_selectedBreed == 'Other' &&
                              (v == null || v.isEmpty))
                              ? 'Enter breed name' : null,
                        ),
                      ],
                      const SizedBox(height: 24),
                      _buildSectionLabel('Notes (Optional)'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _notesController,
                        label: 'Any special notes about your dog...',
                        icon: Icons.note_alt_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 36),
                      _buildSaveButton(),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _isSaving ? null : _onSkip,
                        child: Text(
                          'Set up later',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontFamily: 'Inter',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Meet Your Pup 🐾',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryColor, Color(0xFF9C89FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 24, top: 24),
              child: Icon(Icons.pets, size: 80, color: Colors.white.withOpacity(0.15)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                image: _profileImagePath != null
                    ? DecorationImage(
                        image: FileImage(File(_profileImagePath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _profileImagePath == null
                  ? const Icon(Icons.pets, size: 52, color: _primaryColor)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accentColor,
                ),
                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Color(0xFF444444),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(fontFamily: 'Inter', fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primaryColor, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: _genders.map((g) {
        final selected = _selectedGender == g;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedGender = g);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: g == 'Male' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected ? _primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: selected
                    ? [BoxShadow(color: _primaryColor.withOpacity(0.3), blurRadius: 8)]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    g == 'Male' ? Icons.male : Icons.female,
                    color: selected ? Colors.white : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    g,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBreedDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBreed,
      items: _breeds.map((breed) => DropdownMenuItem(
        value: breed,
        child: Text(breed, style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
      )).toList(),
      onChanged: (val) {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedBreed = val;
          if (val != 'Other') _customBreed = null;
        });
      },
      validator: (v) => (v == null || v.isEmpty) ? 'Select your dog\'s breed' : null,
      decoration: InputDecoration(
        labelText: 'Select Breed',
        prefixIcon: const Icon(Icons.search, color: _primaryColor, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
        ),
      ),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(14),
    );
  }

  Widget _buildSaveButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [_primaryColor, Color(0xFF9C89FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Save Profile',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
