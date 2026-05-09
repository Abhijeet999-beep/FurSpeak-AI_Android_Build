import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:furspeak_ai/utils/media_utils.dart';
import 'package:furspeak_ai/config/app_colors.dart';

import 'package:furspeak_ai/data/models/dog_profile.dart';
import 'package:furspeak_ai/services/auth_service.dart';
import 'package:furspeak_ai/providers/auth_provider.dart';
import 'package:furspeak_ai/config/app_routes.dart';
import 'package:furspeak_ai/models/dog_model.dart';
import 'package:furspeak_ai/services/firestore_service.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:furspeak_ai/config/lottie_registry.dart';
import 'package:furspeak_ai/theme/app_animations.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _customBreedController = TextEditingController();
  final _notesController = TextEditingController();
  final _nameFocusNode = FocusNode();

  // Form State
  int _currentStep = 0;
  String? _profileImagePath;
  String? _selectedBreed;
  String? _selectedGender;
  DateTime? _selectedBirthday;
  double _weight = 10.0;
  String? _activityLevel;
  bool _isSaving = false;
  bool _checkingProfile = true;

  final List<String> _breeds = [
    'Labrador Retriever', 'German Shepherd', 'Golden Retriever',
    'Bulldog', 'Beagle', 'Poodle', 'Rottweiler', 'Yorkshire Terrier',
    'Boxer', 'Dachshund', 'Shih Tzu', 'Siberian Husky', 'Dobermann',
    'Chihuahua', 'Border Collie', 'Other',
  ];

  final List<Map<String, dynamic>> _activityLevels = [
    {'label': 'Low', 'icon': Icons.hotel_rounded, 'desc': 'Likes naps & short walks'},
    {'label': 'Moderate', 'icon': Icons.directions_walk_rounded, 'desc': 'Daily walks & play sessions'},
    {'label': 'High', 'icon': Icons.bolt_rounded, 'desc': 'Needs constant running & work'},
  ];

  @override
  void initState() {
    super.initState();
    _checkIfProfileExists();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _customBreedController.dispose();
    _notesController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkIfProfileExists() async {
    final isar = GetIt.instance<Isar>();
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.userId;
    
    if (uid == null || uid.isEmpty) {
      if (mounted) {
        setState(() => _checkingProfile = false);
        _requestNameFocusAfterBuild();
      }
      return;
    }
    
    final profile = await isar.dogProfiles.getByUserId(uid);
    if (profile != null && mounted) {
      authProvider.markProfileAsComplete();
    } else if (mounted) {
      setState(() => _checkingProfile = false);
      _requestNameFocusAfterBuild();
    }
  }

  /// Requests focus on the name field after the form is built and animations settle.
  void _requestNameFocusAfterBuild() {
    if (!mounted) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Delay to let StaggeredEntrance animations complete (index 2 = ~560ms)
      // 800ms is a safe buffer for real devices
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && _currentStep == 0 && !_checkingProfile) {
          FocusScope.of(context).requestFocus(_nameFocusNode);
          // Force keyboard visibility on some Android devices
          SystemChannels.textInput.invokeMethod('TextInput.show');
          
          // Second attempt if first one was too early
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && _currentStep == 0 && !_nameFocusNode.hasFocus) {
               FocusScope.of(context).requestFocus(_nameFocusNode);
               SystemChannels.textInput.invokeMethod('TextInput.show');
            }
          });
        }
      });
    });
  }

  void _nextPage() {
    if (_currentStep < 2) {
      if (_currentStep == 0 && _nameController.text.isEmpty) {
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your pup\'s name first! 🐾')),
        );
        return;
      }
      HapticFeedback.mediumImpact();
      _pageController.nextPage(duration: AppTheme.animMedium, curve: Curves.easeInOutCubic);
      setState(() => _currentStep++);
    } else {
      _onSave();
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      _pageController.previousPage(duration: AppTheme.animMedium, curve: Curves.easeInOutCubic);
      setState(() => _currentStep--);
    }
  }

  Future<void> _pickImage() async {
    HapticFeedback.mediumImpact();
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 90,
    );
    
    if (pickedFile != null) {
      final croppedFile = await MediaUtils.cropImage(
        File(pickedFile.path),
      );

      if (croppedFile != null && mounted) {
        setState(() => _profileImagePath = croppedFile.path);
      }
    }
  }

  Future<void> _onSave() async {
    if (_nameController.text.isEmpty || _selectedBreed == null) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete the basic details!')),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.heavyImpact();

    final breedToSave = _selectedBreed == 'Other' ? _customBreedController.text : _selectedBreed;
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.userId;

    if (uid == null) {
      setState(() => _isSaving = false);
      return;
    }

    try {
      final isar = GetIt.instance<Isar>();
      final profile = DogProfile(
        userId: uid,
        name: _nameController.text.trim(),
        breed: breedToSave ?? '',
        age: _selectedBirthday != null ? (DateTime.now().year - _selectedBirthday!.year) : 0,
        gender: _selectedGender,
        weight: _weight,
        birthday: _selectedBirthday,
        activityLevel: _activityLevel,
        notes: _notesController.text.trim(),
        imageUrl: _profileImagePath, // This would normally be a URL after upload
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await isar.writeTxn(() async {
        await isar.dogProfiles.put(profile);
      });

      // Sync to Firestore
      final firestoreService = GetIt.instance.isRegistered<FirestoreService>()
          ? GetIt.instance<FirestoreService>()
          : FirestoreService();
          
      final dogModel = DogModel(
        id: uid,
        name: profile.name,
        breed: profile.breed,
        gender: profile.gender,
        weight: profile.weight,
        birthday: profile.birthday,
        activityLevel: profile.activityLevel,
        notes: profile.notes,
        profileImageUrl: profile.imageUrl,
        createdAt: profile.createdAt,
      );
      await firestoreService.addDog(uid, dogModel);

      if (mounted) {
        context.read<AuthProvider>().markProfileAsComplete();
        _showSuccessAnimation();
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

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              child: Lottie.asset(
                LottieRegistry.get('dog_happy'),
                width: 200,
                height: 200,
                repeat: false,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.pets, size: 80, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'All Set! 🐾',
              style: AppTheme.headingStyle.copyWith(color: Colors.white, fontSize: 28),
            ),
            const SizedBox(height: 10),
            Text(
              '${_nameController.text} is ready to talk!',
              style: AppTheme.bodyStyle.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingProfile) {
      return Scaffold(
        backgroundColor: AppTheme.bgColor,
        body: Center(
          child: RepaintBoundary(
            child: Lottie.asset(
              LottieRegistry.get('loading'),
              width: 150,
              errorBuilder: (context, error, stackTrace) =>
                  const CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppTheme.bgColor,
        body: Stack(
          children: [
            // Background Decor
            _buildBackground(),
  
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildStepper(),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStep1Identity(),
                        _buildStep2Details(),
                        _buildStep3Physical(),
                      ],
                    ),
                  ),
                  _buildFooterNavigation(),
                ],
              ),
            ),
            
            if (_isSaving)
              Container(
                color: Colors.black26,
                child: Center(
                  child: PetMoodGlass(
                    borderRadius: AppTheme.borderRadiusExtraLarge,
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RepaintBoundary(
                            child: Lottie.asset(
                              LottieRegistry.get('loading'),
                              width: 100,
                              errorBuilder: (context, error, stackTrace) =>
                                  const CircularProgressIndicator(color: AppTheme.primaryColor),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Creating Profile...', style: AppTheme.titleStyle),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.warmGradient,
          ),
        ),
        Positioned(
          top: -50,
          right: -50,
          child: Opacity(
            opacity: 0.05,
            child: Icon(Icons.pets_rounded, size: 300, color: AppTheme.primaryColor),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -80,
          child: Opacity(
            opacity: 0.03,
            child: RepaintBoundary(
              child: Lottie.asset(
                LottieRegistry.get('paw_prints_bg'),
                width: 400,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Column(
        children: [
          Text(
            'Create Profile',
            style: AppTheme.headingStyle.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 4),
          Text(
            'Tell us about your furry friend',
            style: AppTheme.captionStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: AppTheme.animMedium,
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? AppTheme.primaryColor : AppTheme.surfaceContainerHigh,
                    boxShadow: isActive ? AppTheme.softShadow : null,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.poppins(
                        color: isActive ? Colors.white : AppTheme.textLightColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (index < 2)
                  Expanded(
                    child: AnimatedContainer(
                      duration: AppTheme.animMedium,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: index < _currentStep ? AppTheme.primaryColor : AppTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─── STEP 1: IDENTITY ──────────────────────────────────────────────────
  Widget _buildStep1Identity() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          StaggeredEntrance(
            children: [
              _buildAvatarPicker(),
              const SizedBox(height: 40),
              PetMoodGlass(
                borderRadius: AppTheme.borderRadiusExtraLarge,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.space24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Basic Identity', style: AppTheme.titleStyle),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        decoration: AppTheme.inputDecoration(
                          label: 'Dog\'s Name',
                          hint: 'e.g. Buddy',
                          prefixIcon: Icons.pets_rounded,
                        ),
                        style: AppTheme.bodyStyle,
                        onChanged: (_) => setState(() {}),
                        onFieldSubmitted: (_) => _nextPage(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return Center(
      child: SquishButton(
        onPressed: _pickImage,
        child: Stack(
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: AppTheme.floatShadow,
                image: _profileImagePath != null
                    ? DecorationImage(
                        image: FileImage(File(_profileImagePath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _profileImagePath == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_rounded, size: 40, color: AppTheme.primaryColor.withOpacity(0.4)),
                        const SizedBox(height: 8),
                        Text('Add Photo', style: AppTheme.captionStyle.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    )
                  : null,
            ).animate(target: _profileImagePath != null ? 1 : 0).shimmer(duration: 1.seconds),
            Positioned(
              bottom: 5,
              right: 5,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: const Icon(Icons.edit_rounded, size: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── STEP 2: DETAILS ───────────────────────────────────────────────────
  Widget _buildStep2Details() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Column(
        children: [
          StaggeredEntrance(
            children: [
              PetMoodGlass(
                borderRadius: AppTheme.borderRadiusExtraLarge,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.space24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tell us more', style: AppTheme.titleStyle),
                      const SizedBox(height: 24),
                      _buildBreedSelector(),
                      const SizedBox(height: 24),
                      _buildGenderSelector(),
                      const SizedBox(height: 24),
                      _buildBirthdayPicker(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreedSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedBreed,
          decoration: AppTheme.inputDecoration(
            label: 'Breed',
            prefixIcon: Icons.explore_rounded,
          ),
          items: _breeds.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
          onChanged: (v) => setState(() => _selectedBreed = v),
          style: AppTheme.bodyStyle,
          dropdownColor: Colors.white,
          borderRadius: AppTheme.borderRadiusMedium,
        ),
        if (_selectedBreed == 'Other') ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _customBreedController,
            decoration: AppTheme.inputDecoration(
              label: 'Specify Breed',
              prefixIcon: Icons.edit_note_rounded,
            ),
            style: AppTheme.bodyStyle,
          ),
        ],
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: ['Male', 'Female'].map((g) {
        final isSelected = _selectedGender == g;
        return Expanded(
          child: SquishButton(
            onPressed: () => setState(() => _selectedGender = g),
            child: AnimatedContainer(
              duration: AppTheme.animFast,
              margin: EdgeInsets.only(right: g == 'Male' ? 12 : 0),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceContainerLow,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: isSelected ? AppTheme.softShadow : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    g == 'Male' ? Icons.male_rounded : Icons.female_rounded,
                    color: isSelected ? Colors.white : AppTheme.textLightColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    g,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppTheme.textLightColor,
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

  Widget _buildBirthdayPicker() {
    return SquishButton(
      onPressed: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppTheme.primaryColor,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: AppTheme.textColor,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) setState(() => _selectedBirthday = date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: AppTheme.borderRadiusMedium,
        ),
        child: Row(
          children: [
            const Icon(Icons.cake_rounded, color: AppTheme.textLightColor, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Birthday', style: AppTheme.captionStyle.copyWith(fontSize: 12)),
                Text(
                  _selectedBirthday != null 
                      ? DateFormat('MMM dd, yyyy').format(_selectedBirthday!) 
                      : 'Select Birthday',
                  style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.calendar_today_rounded, color: AppTheme.primaryColor, size: 18),
          ],
        ),
      ),
    );
  }

  // ─── STEP 3: PHYSICAL ──────────────────────────────────────────────────
  Widget _buildStep3Physical() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Column(
        children: [
          StaggeredEntrance(
            children: [
              PetMoodGlass(
                borderRadius: AppTheme.borderRadiusExtraLarge,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.space24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Physical Stats', style: AppTheme.titleStyle),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Weight', style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                          Text('${_weight.toStringAsFixed(1)} kg', 
                            style: AppTheme.titleStyle.copyWith(color: AppTheme.primaryColor)),
                        ],
                      ),
                      Slider(
                        value: _weight,
                        min: 0.5,
                        max: 80.0,
                        divisions: 159,
                        activeColor: AppTheme.primaryColor,
                        inactiveColor: AppTheme.surfaceContainerHigh,
                        onChanged: (v) => setState(() => _weight = v),
                      ),
                      const SizedBox(height: 32),
                      Text('Activity Level', style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ..._activityLevels.map((level) {
                        final isSelected = _activityLevel == level['label'];
                        return SquishButton(
                          onPressed: () => setState(() => _activityLevel = level['label']),
                          child: AnimatedContainer(
                            duration: AppTheme.animFast,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.surfaceContainerLow,
                              borderRadius: AppTheme.borderRadiusMedium,
                            ),
                            child: Row(
                              children: [
                                Icon(level['icon'], color: isSelected ? AppTheme.primaryColor : AppTheme.textLightColor),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        level['label'],
                                        style: AppTheme.bodyStyle.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? AppTheme.primaryColor : AppTheme.textColor,
                                        ),
                                      ),
                                      Text(level['desc'], style: AppTheme.captionStyle.copyWith(fontSize: 12)),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: AppTheme.inputDecoration(
                          label: 'Additional Notes',
                          hint: 'Favorite treats, quirks, etc.',
                        ),
                        style: AppTheme.bodyStyle,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterNavigation() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              flex: 1,
              child: SquishButton(
                onPressed: _previousPage,
                child: TextButton(
                  onPressed: null, // Handled by SquishButton
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusPill),
                  ),
                  child: Text('Back', style: AppTheme.captionStyle.copyWith(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: SquishButton(
              onPressed: _nextPage,
              child: ElevatedButton(
                onPressed: null, // Handled by SquishButton
                style: AppTheme.primaryButtonStyle.copyWith(
                  minimumSize: WidgetStateProperty.all(const Size(double.infinity, 56)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_currentStep == 2 ? 'Complete' : 'Continue'),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
