import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/role_selector.dart';
import '../../models/service_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/service_management_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final ServiceManagementService _serviceManagementService = ServiceManagementService();

  static const List<String> _defaultAdminServices = [
    'Electrician',
    'Plumber',
    'Carpenter',
    'Appliance Repair',
    'Painter',
    'Housekeeping & Cleaning',
    'Gardening & Landscaping',
    'Pest Control',
    'Locksmith',
  ];

  String _selectedRole = AppConstants.roleCustomer;
  String _selectedCategory = 'Electrician';

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Worker specific
  final _experienceController = TextEditingController();

  bool _isGoogleMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.googlePrefillData != null) {
        setState(() {
          _isGoogleMode = true;
          _emailController.text = authProvider.googlePrefillData!.email;
          if (authProvider.googlePrefillData!.displayName != null) {
            _fullNameController.text = authProvider.googlePrefillData!.displayName!;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.registerUser(
      fullName: _fullNameController.text,
      email: _emailController.text.trim().toLowerCase(),
      phone: _phoneController.text,
      location: _locationController.text,
      role: _selectedRole,
      password: _isGoogleMode ? null : _passwordController.text,
      serviceCategory: _selectedRole == AppConstants.roleWorker ? _selectedCategory : null,
      experience: _selectedRole == AppConstants.roleWorker ? _experienceController.text : null,
      certifications: null,
    );

    if (success && mounted) {
      // Return back to AuthWrapper which will automatically route to dashboard
      Navigator.popUntil(context, (route) => route.isFirst);
    } else if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppColors.statusError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
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
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text(
                    "CoopService",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.greenForest,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Role Selector (Customer vs Worker ONLY)
                RoleSelector(
                  selectedRole: _selectedRole,
                  onRoleChanged: (role) {
                    setState(() {
                      _selectedRole = role;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Common Fields
                CustomTextField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  hint: 'John Doe',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) => Validators.validateRequired(v, 'Full Name'),
                ),
                const SizedBox(height: 16),

                // Email Field (Read only if Google mode)
                CustomTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'name@example.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  readOnly: _isGoogleMode,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: '+1 234 567 8900',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _locationController,
                  label: 'Location / City',
                  hint: 'Downtown, Sector 5',
                  prefixIcon: Icons.location_on_outlined,
                  validator: (v) => Validators.validateRequired(v, 'Location'),
                ),
                const SizedBox(height: 16),

                // Password Fields (ONLY if non-Google mode)
                if (!_isGoogleMode) ...[
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: '••••••••',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: Validators.validatePassword,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    hint: '••••••••',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: (v) => Validators.validateConfirmPassword(
                      v,
                      _passwordController.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Worker Specific Fields
                if (_selectedRole == AppConstants.roleWorker) ...[
                  const Divider(color: AppColors.border, height: 32),
                  const Text(
                    "Worker Profile & Experience",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Service Provided Dropdown (services added by Admin)
                  StreamBuilder<List<ServiceModel>>(
                    stream: _serviceManagementService.streamActiveServices(),
                    builder: (context, snapshot) {
                      final List<String> availableServices = [];
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        for (var s in snapshot.data!) {
                          if (s.name.isNotEmpty && !availableServices.contains(s.name)) {
                            availableServices.add(s.name);
                          }
                        }
                      }
                      
                      // Fallback to default admin services if none in Firestore yet
                      if (availableServices.isEmpty) {
                        availableServices.addAll(_defaultAdminServices);
                      }

                      if (!availableServices.contains(_selectedCategory)) {
                        _selectedCategory = availableServices.first;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Service Provided (Skill)',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.handyman_outlined, color: AppColors.textSecondary, size: 20),
                              fillColor: AppColors.surface,
                              filled: true,
                            ),
                            items: availableServices.map((serviceName) {
                              return DropdownMenuItem(
                                value: serviceName,
                                child: Text(serviceName, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedCategory = val;
                                });
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _experienceController,
                    label: 'Experience (Years)',
                    hint: 'e.g. 5 Years',
                    prefixIcon: Icons.history_edu_outlined,
                    validator: (v) => Validators.validateRequired(v, 'Experience'),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 16),

                // Registration Button
                PrimaryButton(
                  text: _isGoogleMode ? 'Complete Registration' : 'Register Account',
                  isLoading: authProvider.isLoading,
                  onPressed: _handleRegister,
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
