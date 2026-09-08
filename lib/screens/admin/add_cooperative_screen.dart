import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/service_selector.dart';
import '../../models/cooperative_model.dart';
import '../../services/cooperative_service.dart';
import '../../services/storage_service.dart';

class AddCooperativeScreen extends StatefulWidget {
  final CooperativeModel? cooperative;

  const AddCooperativeScreen({super.key, this.cooperative});

  @override
  State<AddCooperativeScreen> createState() => _AddCooperativeScreenState();
}

class _AddCooperativeScreenState extends State<AddCooperativeScreen> {
  final _formKey = GlobalKey<FormState>();
  final CooperativeService _cooperativeService = CooperativeService();
  final StorageService _storageService = StorageService();

  // Controllers
  final _nameController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  final _stateController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _areaController = TextEditingController();

  // Services offered selection (Selected Service IDs)
  List<String> _selectedServiceIds = [];

  // File Upload State
  XFile? _regDocFile;
  XFile? _logoFile;
  XFile? _coverFile;

  String? _uploadedRegDocUrl;
  String? _uploadedLogoUrl;
  String? _uploadedCoverUrl;

  String _status = AppConstants.statusActive;
  bool _isLoading = false;
  String? _errorMessage;

  bool get _isEditing => widget.cooperative != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final c = widget.cooperative!;
      _nameController.text = c.name;
      _regNumberController.text = c.registrationNumber;
      _descriptionController.text = c.description ?? '';

      _phoneController.text = c.contactPhone;
      _emailController.text = c.contactEmail;
      _addressController.text = c.address ?? '';

      _stateController.text = c.state ?? '';
      _districtController.text = c.district ?? '';
      _cityController.text = c.city ?? '';
      _pincodeController.text = c.pincode ?? '';
      _areaController.text = c.primaryServiceArea;

      _selectedServiceIds = List<String>.from(c.serviceIds);

      _uploadedRegDocUrl = c.registrationDocumentUrl;
      _uploadedLogoUrl = c.logoUrl;
      _uploadedCoverUrl = c.coverImageUrl;

      _status = c.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regNumberController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _pickRegistrationDocument() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickMedia();
      if (picked != null) {
        setState(() {
          _regDocFile = picked;
        });
      }
    } catch (e) {
      debugPrint('Document picker error: $e');
    }
  }

  Future<void> _pickLogoImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _logoFile = picked;
        });
      }
    } catch (e) {
      debugPrint('Logo picker error: $e');
    }
  }

  Future<void> _pickCoverImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _coverFile = picked;
        });
      }
    } catch (e) {
      debugPrint('Cover picker error: $e');
    }
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedServiceIds.isEmpty) {
      setState(() {
        _errorMessage = 'Please select at least one service offered by this cooperative society.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final now = DateTime.now();
      final tempId = _isEditing ? widget.cooperative!.id : DateTime.now().millisecondsSinceEpoch.toString();

      // Upload registration document if selected
      String? regDocUrl = _uploadedRegDocUrl;
      if (_regDocFile != null) {
        final bytes = await _regDocFile!.readAsBytes();
        regDocUrl = await _storageService.uploadCooperativeDocument(
          coopId: tempId,
          docName: _regDocFile!.name,
          bytes: bytes,
        );
      }

      // Upload logo if selected
      String? logoUrl = _uploadedLogoUrl;
      if (_logoFile != null) {
        final bytes = await _logoFile!.readAsBytes();
        logoUrl = await _storageService.uploadCooperativeImage(
          coopId: tempId,
          type: 'logo',
          bytes: bytes,
        );
      }

      // Upload cover image if selected
      String? coverUrl = _uploadedCoverUrl;
      if (_coverFile != null) {
        final bytes = await _coverFile!.readAsBytes();
        coverUrl = await _storageService.uploadCooperativeImage(
          coopId: tempId,
          type: 'cover',
          bytes: bytes,
        );
      }

      if (_isEditing) {
        final updatedCoop = widget.cooperative!.copyWith(
          name: _nameController.text.trim(),
          registrationNumber: _regNumberController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          contactPhone: _phoneController.text.trim(),
          contactEmail: _emailController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
          district: _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
          city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
          pincode: _pincodeController.text.trim().isEmpty ? null : _pincodeController.text.trim(),
          primaryServiceArea: _areaController.text.trim(),
          serviceIds: _selectedServiceIds,
          registrationDocumentUrl: regDocUrl,
          logoUrl: logoUrl,
          coverImageUrl: coverUrl,
          status: _status,
          updatedAt: now,
        );
        await _cooperativeService.updateCooperative(updatedCoop);
      } else {
        final newCoop = CooperativeModel(
          id: '',
          name: _nameController.text.trim(),
          registrationNumber: _regNumberController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          contactPhone: _phoneController.text.trim(),
          contactEmail: _emailController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
          district: _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
          city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
          pincode: _pincodeController.text.trim().isEmpty ? null : _pincodeController.text.trim(),
          primaryServiceArea: _areaController.text.trim(),
          serviceIds: _selectedServiceIds,
          registrationDocumentUrl: regDocUrl,
          logoUrl: logoUrl,
          coverImageUrl: coverUrl,
          status: _status,
          cooperativeHeadId: null,
          createdAt: now,
          updatedAt: now,
        );
        await _cooperativeService.createCooperative(newCoop);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Cooperative society updated successfully.'
                : 'Cooperative society created successfully.'),
            backgroundColor: AppColors.statusVerified,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to save cooperative: $e';
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

  Widget _buildSectionHeader(String number, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.greenMint.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.greenForest,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.greenDeep,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundMildGreen,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundMildGreen,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Cooperative' : 'Register Cooperative Society',
          style: const TextStyle(
            color: AppColors.greenDeep,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.statusErrorBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.statusError.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.statusError),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.statusError, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // SECTION 1 — BASIC INFORMATION
                _buildSectionHeader('SECTION 1', 'BASIC INFORMATION'),
                AppCard(
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _nameController,
                        label: 'Cooperative Society Name *',
                        hint: 'e.g. Metro Household Services Cooperative',
                        prefixIcon: Icons.apartment_rounded,
                        validator: (v) => Validators.validateRequired(v, 'Society Name'),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _regNumberController,
                        label: 'Registration Number *',
                        hint: 'e.g. REG-COOP-2026-081',
                        prefixIcon: Icons.badge_outlined,
                        validator: (v) => Validators.validateRequired(v, 'Registration Number'),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _descriptionController,
                        label: 'Society Description',
                        hint: 'Summary of cooperative objectives and history...',
                        prefixIcon: Icons.description_outlined,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),

                // SECTION 2 — CONTACT INFORMATION
                _buildSectionHeader('SECTION 2', 'CONTACT INFORMATION'),
                AppCard(
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _phoneController,
                        label: 'Official Phone Number *',
                        hint: '+1 555 019 2831',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: Validators.validatePhone,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _emailController,
                        label: 'Official Email *',
                        hint: 'contact@metrocoop.org',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.validateEmail,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _addressController,
                        label: 'Office Address',
                        hint: 'Suite 402, Community Hub Building',
                        prefixIcon: Icons.location_on_outlined,
                      ),
                    ],
                  ),
                ),

                // SECTION 3 — LOCATION & GEOGRAPHICAL AREA
                _buildSectionHeader('SECTION 3', 'LOCATION & SERVICE AREA'),
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _stateController,
                              label: 'State',
                              hint: 'e.g. California',
                              prefixIcon: Icons.map_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              controller: _districtController,
                              label: 'District',
                              hint: 'e.g. Central',
                              prefixIcon: Icons.holiday_village_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _cityController,
                              label: 'City / Taluk',
                              hint: 'e.g. San Jose',
                              prefixIcon: Icons.location_city_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              controller: _pincodeController,
                              label: 'Pincode',
                              hint: 'e.g. 95112',
                              prefixIcon: Icons.pin_drop_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _areaController,
                        label: 'Primary Operating Service Area *',
                        hint: 'e.g. Sector 5, Downtown & East Zone',
                        prefixIcon: Icons.explore_outlined,
                        validator: (v) => Validators.validateRequired(v, 'Primary Service Area'),
                      ),
                    ],
                  ),
                ),

                // SECTION 4 — SERVICES OFFERED (DYNAMIC DART/FIRESTORE SELECTOR)
                _buildSectionHeader('SECTION 4', 'SERVICES OFFERED'),
                AppCard(
                  child: ServiceSelector(
                    selectedServiceIds: _selectedServiceIds,
                    onChanged: (updatedList) {
                      setState(() {
                        _selectedServiceIds = updatedList;
                        _errorMessage = null;
                      });
                    },
                  ),
                ),

                // SECTION 5 — SOCIETY DOCUMENTS
                _buildSectionHeader('SECTION 5', 'SOCIETY DOCUMENTS'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upload Registration Certificate & Supporting Docs',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _pickRegistrationDocument,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.greenForest,
                          side: const BorderSide(color: AppColors.neuBorder, width: 1.2),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        icon: const Icon(Icons.upload_file_rounded, color: AppColors.greenForest),
                        label: Text(
                          _regDocFile != null
                              ? 'Selected: ${_regDocFile!.name}'
                              : _uploadedRegDocUrl != null
                                  ? 'Replace Document'
                                  : 'Choose Document (PDF/Image)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

                // SECTION 6 — SOCIETY IDENTITY
                _buildSectionHeader('SECTION 6', 'SOCIETY IDENTITY'),
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickLogoImage,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.greenForest,
                                side: const BorderSide(color: AppColors.neuBorder, width: 1.2),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              icon: const Icon(Icons.image_outlined, color: AppColors.greenForest),
                              label: Text(
                                _logoFile != null ? 'Logo Selected' : 'Upload Logo',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickCoverImage,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.greenForest,
                                side: const BorderSide(color: AppColors.neuBorder, width: 1.2),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              icon: const Icon(Icons.panorama_outlined, color: AppColors.greenForest),
                              label: Text(
                                _coverFile != null ? 'Cover Selected' : 'Upload Cover',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // SECTION 7 — COOPERATIVE HEAD
                _buildSectionHeader('SECTION 7', 'COOPERATIVE HEAD'),
                AppCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.statusPendingBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_off_rounded, color: AppColors.statusPending, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Cooperative Head: Not Assigned',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Assign head separately from the Admin Dashboard after creating the society.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // SECTION 8 — STATUS
                _buildSectionHeader('SECTION 8', 'SOCIETY STATUS'),
                AppCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Active Platform Status',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Inactive societies are hidden from worker registration & bookings',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: _status == AppConstants.statusActive,
                        activeTrackColor: AppColors.greenMint,
                        activeThumbColor: AppColors.greenForest,
                        onChanged: (val) {
                          setState(() {
                            _status = val ? AppConstants.statusActive : AppConstants.statusInactive;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                PrimaryButton(
                  text: _isEditing ? 'Update Cooperative Society' : 'Create Cooperative Society',
                  isLoading: _isLoading,
                  onPressed: _handleSubmit,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
