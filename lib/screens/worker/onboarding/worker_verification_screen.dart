import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_image_helper.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/service_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/service_management_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/worker_verification_service.dart';
import 'select_cooperative_screen.dart';

class WorkerVerificationScreen extends StatefulWidget {
  const WorkerVerificationScreen({super.key});

  @override
  State<WorkerVerificationScreen> createState() => _WorkerVerificationScreenState();
}

class _WorkerVerificationScreenState extends State<WorkerVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final ServiceManagementService _serviceManagementService = ServiceManagementService();
  final StorageService _storageService = StorageService();
  final WorkerVerificationService _verificationService = WorkerVerificationService();

  // Basic Details Controllers
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _experienceYearsController = TextEditingController();
  final _addressController = TextEditingController();
  final _stateController = TextEditingController(text: 'Tamil Nadu');
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _bioController = TextEditingController();
  final _languagesController = TextEditingController();

  // Selected Services
  String? _selectedPrimaryServiceId;
  String? _selectedPrimaryServiceName;
  final List<String> _selectedSecondaryServiceIds = [];

  // Identity Proof
  String _selectedIdentityType = 'Aadhaar';

  // Files
  XFile? _profilePhotoFile;
  XFile? _identityDocFile;
  XFile? _addressProofFile;
  XFile? _skillCertFile;
  XFile? _driverLicenceFile;
  XFile? _experienceCertFile;

  // Existing or uploaded URLs
  String? _profilePhotoUrl;
  String? _identityDocUrl;
  String? _addressProofUrl;
  String? _skillCertUrl;
  String? _driverLicenceUrl;
  String? _experienceCertUrl;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user != null) {
        _populateExistingData(user);
      }
    });
  }

  void _populateExistingData(AppUser user) {
    _fullNameController.text = user.fullName;
    _phoneController.text = user.phone;
    _emailController.text = user.email;
    if (user.yearsOfExperience != null) {
      _experienceYearsController.text = user.yearsOfExperience.toString();
    }
    _addressController.text = user.fullAddress ?? user.location;
    _stateController.text = user.state ?? 'Tamil Nadu';
    _districtController.text = user.district ?? '';
    _cityController.text = user.city ?? '';
    _pincodeController.text = user.pincode ?? '';
    _bioController.text = user.bio ?? '';
    if (user.languagesKnown != null) {
      _languagesController.text = user.languagesKnown!.join(', ');
    }

    _selectedPrimaryServiceId = user.primaryServiceId;
    if (user.secondaryServiceIds != null) {
      _selectedSecondaryServiceIds.addAll(user.secondaryServiceIds!);
    }

    if (user.identityType != null && user.identityType!.isNotEmpty) {
      _selectedIdentityType = user.identityType!;
    }

    _profilePhotoUrl = user.profilePhotoUrl;
    _identityDocUrl = user.identityDocumentUrl;
    _addressProofUrl = user.addressProofUrl;
    if (user.skillCertificateUrls != null && user.skillCertificateUrls!.isNotEmpty) {
      _skillCertUrl = user.skillCertificateUrls!.first;
    }
    if (user.experienceCertificateUrls != null && user.experienceCertificateUrls!.isNotEmpty) {
      _experienceCertUrl = user.experienceCertificateUrls!.first;
    }

    setState(() {});
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _experienceYearsController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _bioController.dispose();
    _languagesController.dispose();
    super.dispose();
  }

  Future<XFile?> _pickImageOrFile({bool isCamera = false}) async {
    try {
      final picker = ImagePicker();
      return await picker.pickImage(
        source: isCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
    } catch (e) {
      debugPrint('File picker error: $e');
      return null;
    }
  }

  bool get _isDriverService {
    final name = (_selectedPrimaryServiceName ?? '').toLowerCase();
    return name.contains('driver') || name.contains('driving') || name.contains('chauffeur');
  }

  Future<void> _handleSaveAndProceed() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = 'Please fix the highlighted fields in the form.';
      });
      return;
    }

    if (_selectedPrimaryServiceId == null || _selectedPrimaryServiceId!.isEmpty) {
      setState(() {
        _errorMessage = 'Please choose your primary trade service.';
      });
      return;
    }

    // Check identity documents
    if (_identityDocFile == null && (_identityDocUrl == null || _identityDocUrl!.isEmpty)) {
      setState(() {
        _errorMessage = 'Please upload your Government Identity Document ($_selectedIdentityType).';
      });
      return;
    }

    if (_addressProofFile == null && (_addressProofUrl == null || _addressProofUrl!.isEmpty)) {
      setState(() {
        _errorMessage = 'Please upload your Address Proof document.';
      });
      return;
    }

    // Driver specific check
    if (_isDriverService && _driverLicenceFile == null && (_driverLicenceUrl == null || _driverLicenceUrl!.isEmpty)) {
      setState(() {
        _errorMessage = 'Driving Licence document is mandatory for Driver trade.';
      });
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('[WorkerVerification] Starting save and proceed flow...');

      // 1. Upload files if newly selected
      String? profilePhoto = _profilePhotoUrl;
      if (_profilePhotoFile != null) {
        debugPrint('[WorkerVerification] Uploading profile photo...');
        final bytes = await _profilePhotoFile!.readAsBytes();
        profilePhoto = await _storageService.uploadWorkerProfilePhoto(
          workerId: user.uid,
          bytes: bytes,
        );
      }

      String? identityDoc = _identityDocUrl;
      if (_identityDocFile != null) {
        debugPrint('[WorkerVerification] Uploading identity document...');
        final bytes = await _identityDocFile!.readAsBytes();
        identityDoc = await _storageService.uploadWorkerIdentityDocument(
          workerId: user.uid,
          docType: _selectedIdentityType,
          bytes: bytes,
        );
      }

      String? addressProof = _addressProofUrl;
      if (_addressProofFile != null) {
        debugPrint('[WorkerVerification] Uploading address proof...');
        final bytes = await _addressProofFile!.readAsBytes();
        addressProof = await _storageService.uploadWorkerAddressProof(
          workerId: user.uid,
          bytes: bytes,
        );
      }

      List<String> skillCerts = [];
      if (_skillCertUrl != null && _skillCertUrl!.isNotEmpty) {
        skillCerts.add(_skillCertUrl!);
      }
      if (_skillCertFile != null) {
        debugPrint('[WorkerVerification] Uploading skill certificate...');
        final bytes = await _skillCertFile!.readAsBytes();
        final url = await _storageService.uploadWorkerSkillCertificate(
          workerId: user.uid,
          certName: 'skill_certificate',
          bytes: bytes,
        );
        if (url != null) skillCerts.add(url);
      }

      // Add Driver Licence if applicable
      if (_isDriverService) {
        if (_driverLicenceFile != null) {
          debugPrint('[WorkerVerification] Uploading driving licence...');
          final bytes = await _driverLicenceFile!.readAsBytes();
          final url = await _storageService.uploadWorkerIdentityDocument(
            workerId: user.uid,
            docType: 'driving_licence',
            bytes: bytes,
          );
          if (url != null) skillCerts.add(url);
        } else if (_driverLicenceUrl != null && _driverLicenceUrl!.isNotEmpty) {
          skillCerts.add(_driverLicenceUrl!);
        }
      }

      List<String> expCerts = [];
      if (_experienceCertUrl != null && _experienceCertUrl!.isNotEmpty) {
        expCerts.add(_experienceCertUrl!);
      }
      if (_experienceCertFile != null) {
        debugPrint('[WorkerVerification] Uploading experience certificate...');
        final bytes = await _experienceCertFile!.readAsBytes();
        final url = await _storageService.uploadWorkerSkillCertificate(
          workerId: user.uid,
          certName: 'experience_certificate',
          bytes: bytes,
        );
        if (url != null) expCerts.add(url);
      }

      // 2. Build updated worker profile
      final languages = _languagesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final updatedWorker = user.copyWith(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        fullAddress: _addressController.text.trim(),
        location: '${_cityController.text.trim()}, ${_districtController.text.trim()}',
        state: _stateController.text.trim(),
        district: _districtController.text.trim(),
        city: _cityController.text.trim(),
        pincode: _pincodeController.text.trim(),
        primaryServiceId: _selectedPrimaryServiceId,
        secondaryServiceIds: _selectedSecondaryServiceIds,
        yearsOfExperience: int.tryParse(_experienceYearsController.text.trim()) ?? 0,
        experience: '${_experienceYearsController.text.trim()} years',
        bio: _bioController.text.trim(),
        languagesKnown: languages,
        identityType: _selectedIdentityType,
        identityDocumentUrl: identityDoc,
        addressProofUrl: addressProof,
        profilePhotoUrl: profilePhoto,
        skillCertificateUrls: skillCerts,
        experienceCertificateUrls: expCerts,
        serviceCategory: _selectedPrimaryServiceName,
      );

      // 3. Save to Firestore
      debugPrint('[WorkerVerification] Saving updated profile to Firestore...');
      await _verificationService
          .saveWorkerVerificationProfile(updatedWorker)
          .timeout(const Duration(seconds: 6));

      debugPrint('[WorkerVerification] Refreshing currentUser...');
      try {
        await authProvider.refreshCurrentUser().timeout(const Duration(seconds: 4));
      } catch (authErr) {
        debugPrint('[WorkerVerification] Non-fatal authProvider refresh error: $authErr');
      }

      debugPrint('[WorkerVerification] Proceeding to SelectCooperativeScreen...');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Profile and verification documents saved!')),
              ],
            ),
            backgroundColor: AppColors.greenForest,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        // 4. Navigate to Step 2: Choose Cooperative Society by District
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SelectCooperativeScreen(
              worker: updatedWorker,
              primaryServiceName: _selectedPrimaryServiceName ?? 'Service',
            ),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('[WorkerVerification] Error saving verification: $e\n$st');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to save verification details: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundMildGreen,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundMildGreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8F6EE), Color(0xFFD2EEDC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBCE0CC), width: 1.2),
              ),
              child: const Icon(Icons.handyman_rounded, color: AppColors.greenForest, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Worker Verification',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.greenDeep,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => authProvider.signOut(),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Neumorphic Step Indicator Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEBF7F0), Color(0xFFD9EFE2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFBCE0CC), width: 1.2),
                    boxShadow: [
                      const BoxShadow(
                        color: Colors.white,
                        offset: Offset(-2, -2),
                        blurRadius: 5,
                      ),
                      BoxShadow(
                        color: AppColors.greenDeep.withValues(alpha: 0.05),
                        offset: const Offset(2, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.greenForest,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.greenForest.withValues(alpha: 0.3),
                                  offset: const Offset(0, 3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.badge_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFBCE0CC)),
                                  ),
                                  child: const Text(
                                    'STEP 1 OF 2',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.greenForest,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Profile & Identity Verification',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.greenDeep,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Complete your profile and upload verification documents to join your local Cooperative Society.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Progress track
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: 0.5,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFC8DEC7),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.greenForest),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Error Banner (if any)
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.statusErrorBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.statusError.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.statusError, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.statusError, fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // 2. Profile Photo Card (Neumorphic)
                _buildNeumorphicCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.greenForest, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 34,
                          backgroundColor: const Color(0xFFE8F6EE),
                          backgroundImage: _profilePhotoFile != null
                              ? null
                              : AppImageHelper.getImageProvider(_profilePhotoUrl),
                          child: _profilePhotoFile != null
                              ? const Icon(Icons.check_circle_rounded, color: AppColors.greenForest, size: 34)
                              : (_profilePhotoUrl == null || _profilePhotoUrl!.isEmpty
                                  ? const Icon(Icons.person_rounded, size: 36, color: AppColors.greenForest)
                                  : null),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Profile Photo',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.greenDeep,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _profilePhotoFile != null
                                  ? 'Selected: ${_profilePhotoFile!.name}'
                                  : (_profilePhotoUrl != null
                                      ? 'Photo already uploaded'
                                      : 'Upload a clear professional photo'),
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final picked = await _pickImageOrFile();
                                if (picked != null) {
                                  setState(() {
                                    _profilePhotoFile = picked;
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F6EE),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFBCE0CC)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.camera_alt_rounded, size: 15, color: AppColors.greenForest),
                                    SizedBox(width: 6),
                                    Text(
                                      'Choose Photo',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.greenForest,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 3. Card 1: Personal & Contact Details
                _buildNeumorphicCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        icon: Icons.person_pin_rounded,
                        title: 'Personal & Contact Details',
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _fullNameController,
                        label: 'Full Name *',
                        prefixIcon: Icons.person_outline,
                        validator: (v) => Validators.validateRequired(v, 'Full Name'),
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _phoneController,
                        label: 'Phone Number *',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: Validators.validatePhone,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email Address (Read-only)',
                        prefixIcon: Icons.email_outlined,
                        readOnly: true,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _experienceYearsController,
                        label: 'Years of Experience *',
                        hint: 'e.g. 5',
                        prefixIcon: Icons.history_edu_outlined,
                        keyboardType: TextInputType.number,
                        validator: (v) => Validators.validateRequired(v, 'Years of Experience'),
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _addressController,
                        label: 'Full Address *',
                        hint: 'Door no., street name, area',
                        prefixIcon: Icons.home_outlined,
                        maxLines: 2,
                        validator: (v) => Validators.validateRequired(v, 'Address'),
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 420;
                          final districtField = CustomTextField(
                            controller: _districtController,
                            label: 'District *',
                            hint: 'e.g. Coimbatore',
                            prefixIcon: Icons.location_city_outlined,
                            validator: (v) => Validators.validateRequired(v, 'District'),
                          );
                          final cityField = CustomTextField(
                            controller: _cityController,
                            label: 'City / Taluk *',
                            hint: 'e.g. Pollachi',
                            prefixIcon: Icons.map_outlined,
                            validator: (v) => Validators.validateRequired(v, 'City / Taluk'),
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                districtField,
                                const SizedBox(height: 14),
                                cityField,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: districtField),
                              const SizedBox(width: 12),
                              Expanded(child: cityField),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 420;
                          final stateField = CustomTextField(
                            controller: _stateController,
                            label: 'State *',
                            prefixIcon: Icons.flag_outlined,
                            validator: (v) => Validators.validateRequired(v, 'State'),
                          );
                          final pincodeField = CustomTextField(
                            controller: _pincodeController,
                            label: 'Pincode *',
                            hint: '641001',
                            prefixIcon: Icons.pin_drop_outlined,
                            keyboardType: TextInputType.number,
                            validator: (v) => Validators.validateRequired(v, 'Pincode'),
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                stateField,
                                const SizedBox(height: 14),
                                pincodeField,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: stateField),
                              const SizedBox(width: 12),
                              Expanded(child: pincodeField),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 4. Card 2: Dynamic Services Selection
                _buildNeumorphicCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        icon: Icons.handyman_rounded,
                        title: 'Service & Trade Profession',
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Select your primary trade. Active cooperatives will be matched based on this service.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),

                      StreamBuilder<List<ServiceModel>>(
                        stream: _serviceManagementService.streamActiveServices(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const LoadingIndicator(message: 'Loading active services...');
                          }

                          final services = snapshot.data ?? [];
                          if (services.isEmpty) {
                            return const Text('No active services currently available.');
                          }

                          final hasMatching = services.any((s) => s.id == _selectedPrimaryServiceId);
                          if (!hasMatching && services.isNotEmpty) {
                            _selectedPrimaryServiceId = services.first.id;
                            _selectedPrimaryServiceName = services.first.name;
                          } else if (hasMatching && _selectedPrimaryServiceName == null) {
                            _selectedPrimaryServiceName =
                                services.firstWhere((s) => s.id == _selectedPrimaryServiceId).name;
                          }

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFDDECE3)),
                            ),
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedPrimaryServiceId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Primary Trade Service *',
                                prefixIcon: Icon(Icons.handyman_outlined, color: AppColors.greenForest),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              items: services.map((s) {
                                return DropdownMenuItem<String>(
                                  value: s.id,
                                  child: Text(
                                    '${s.name} (${s.category})',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  final s = services.firstWhere((element) => element.id == val);
                                  setState(() {
                                    _selectedPrimaryServiceId = val;
                                    _selectedPrimaryServiceName = s.name;
                                  });
                                }
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      CustomTextField(
                        controller: _bioController,
                        label: 'Short Bio / Work Summary (Optional)',
                        hint: 'Tell cooperatives about your expertise and previous projects...',
                        prefixIcon: Icons.description_outlined,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _languagesController,
                        label: 'Languages Known (Optional)',
                        hint: 'e.g. Tamil, English, Malayalam',
                        prefixIcon: Icons.translate_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 5. Card 3: Proof of Identity
                _buildNeumorphicCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        icon: Icons.verified_user_rounded,
                        title: 'Proof of Identity',
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Documents are kept safe and only verified by the Cooperative Society Head.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFDDECE3)),
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedIdentityType,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Government ID Type *',
                            prefixIcon: Icon(Icons.credit_card_outlined, color: AppColors.greenForest),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          items: AppConstants.identityDocumentTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedIdentityType = val;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ID Document Upload Row
                      _buildUploadRow(
                        title: 'Upload $_selectedIdentityType Proof *',
                        file: _identityDocFile,
                        existingUrl: _identityDocUrl,
                        icon: Icons.upload_file_rounded,
                        onPick: () async {
                          final picked = await _pickImageOrFile();
                          if (picked != null) {
                            setState(() {
                              _identityDocFile = picked;
                            });
                          }
                        },
                      ),
                      const Divider(height: 24, color: Color(0xFFEEF5F1)),

                      // Address Proof Upload Row
                      _buildUploadRow(
                        title: 'Upload Address Proof *',
                        file: _addressProofFile,
                        existingUrl: _addressProofUrl,
                        icon: Icons.home_work_outlined,
                        onPick: () async {
                          final picked = await _pickImageOrFile();
                          if (picked != null) {
                            setState(() {
                              _addressProofFile = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 6. Card 4: Skill & Professional Documents
                _buildNeumorphicCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildSectionHeader(
                              icon: Icons.workspace_premium_rounded,
                              title: 'Skill & Certifications',
                            ),
                          ),
                          if (_isDriverService)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFECACA)),
                              ),
                              child: const Text(
                                'Licence Required',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Upload certifications or training credentials that prove your craft.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),

                      if (_isDriverService) ...[
                        _buildUploadRow(
                          title: 'Driving Licence Copy (Mandatory for Drivers) *',
                          file: _driverLicenceFile,
                          existingUrl: _driverLicenceUrl,
                          icon: Icons.drive_eta_outlined,
                          onPick: () async {
                            final picked = await _pickImageOrFile();
                            if (picked != null) {
                              setState(() {
                                _driverLicenceFile = picked;
                              });
                            }
                          },
                        ),
                        const Divider(height: 24, color: Color(0xFFEEF5F1)),
                      ],

                      _buildUploadRow(
                        title: 'Skill / Trade Certificate (Recommended)',
                        file: _skillCertFile,
                        existingUrl: _skillCertUrl,
                        icon: Icons.workspace_premium_outlined,
                        onPick: () async {
                          final picked = await _pickImageOrFile();
                          if (picked != null) {
                            setState(() {
                              _skillCertFile = picked;
                            });
                          }
                        },
                      ),
                      const Divider(height: 24, color: Color(0xFFEEF5F1)),

                      _buildUploadRow(
                        title: 'Experience / Training Certificate (Optional)',
                        file: _experienceCertFile,
                        existingUrl: _experienceCertUrl,
                        icon: Icons.military_tech_outlined,
                        onPick: () async {
                          final picked = await _pickImageOrFile();
                          if (picked != null) {
                            setState(() {
                              _experienceCertFile = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 7. Guaranteed Overflow-Free Continue Button
                PrimaryButton(
                  text: 'Continue to Select Cooperative Society',
                  icon: Icons.arrow_forward_rounded,
                  isLoading: _isLoading,
                  onPressed: _handleSaveAndProceed,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Neumorphic Card Wrapper
  Widget _buildNeumorphicCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDECE3), width: 1.2),
        boxShadow: [
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-2, -2),
            blurRadius: 5,
          ),
          BoxShadow(
            color: AppColors.greenDeep.withValues(alpha: 0.05),
            offset: const Offset(2, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: child,
    );
  }

  // Section Header with Icon
  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F6EE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.greenForest, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: AppColors.greenDeep,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }

  // Upload Row Widget with Squircle & Soft Badge
  Widget _buildUploadRow({
    required String title,
    required XFile? file,
    required String? existingUrl,
    required IconData icon,
    required VoidCallback onPick,
  }) {
    final bool hasFile = file != null || (existingUrl != null && existingUrl.isNotEmpty);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: hasFile ? const Color(0xFFE8F6EE) : const Color(0xFFF3F8F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasFile ? const Color(0xFFBCE0CC) : const Color(0xFFDDECE3),
            ),
          ),
          child: Icon(
            hasFile ? Icons.check_circle_rounded : icon,
            color: hasFile ? AppColors.greenForest : AppColors.textSecondary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                file != null
                    ? 'Selected: ${file.name}'
                    : (existingUrl != null && existingUrl.isNotEmpty
                        ? 'Document on file'
                        : 'No file selected yet'),
                style: TextStyle(
                  fontSize: 11,
                  color: hasFile ? AppColors.greenForest : AppColors.textTertiary,
                  fontWeight: hasFile ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: hasFile ? const Color(0xFFE8F6EE) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasFile ? const Color(0xFFBCE0CC) : const Color(0xFFDDECE3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasFile ? Icons.refresh_rounded : Icons.upload_file_rounded,
                  size: 14,
                  color: AppColors.greenForest,
                ),
                const SizedBox(width: 4),
                Text(
                  hasFile ? 'Replace' : 'Upload',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greenForest,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
