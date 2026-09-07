import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/cooperative_model.dart';
import '../../models/user_model.dart';
import '../../services/cooperative_service.dart';
import '../../services/firestore_service.dart';

class AssignCooperativeHeadScreen extends StatefulWidget {
  final CooperativeModel cooperative;

  const AssignCooperativeHeadScreen({
    super.key,
    required this.cooperative,
  });

  @override
  State<AssignCooperativeHeadScreen> createState() => _AssignCooperativeHeadScreenState();
}

class _AssignCooperativeHeadScreenState extends State<AssignCooperativeHeadScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final CooperativeService _cooperativeService = CooperativeService();

  final _searchController = TextEditingController();
  final _serviceAreaController = TextEditingController();

  AppUser? _selectedUser;
  String _searchQuery = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _serviceAreaController.text = widget.cooperative.primaryServiceArea;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _serviceAreaController.dispose();
    super.dispose();
  }

  void _showConfirmationDialog(AppUser user) {
    final area = _serviceAreaController.text.trim();
    if (area.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please specify the assigned operating service area.'),
          backgroundColor: AppColors.statusError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Assignment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.4),
                children: [
                  const TextSpan(text: 'Are you sure you want to assign '),
                  TextSpan(
                    text: user.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const TextSpan(text: ' as the '),
                  const TextSpan(
                    text: 'Cooperative Head',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' of '),
                  TextSpan(
                    text: widget.cooperative.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assigned Area: $area',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'User role will be updated to cooperative_head in Firestore.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performAssignment(user, area);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Assignment'),
          ),
        ],
      ),
    );
  }

  void _performAssignment(AppUser user, String area) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      await _cooperativeService.assignCooperativeHead(
        cooperativeId: widget.cooperative.id,
        userId: user.uid,
        serviceArea: area,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cooperative Head assigned successfully.'),
            backgroundColor: AppColors.statusVerified,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign Cooperative Head: $e'),
            backgroundColor: AppColors.statusError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Assign Cooperative Head'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Selected Cooperative Info Card
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.cooperative.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Reg #: ${widget.cooperative.registrationNumber}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Operating Area Input
                  CustomTextField(
                    controller: _serviceAreaController,
                    label: 'Assigned Service Operating Area',
                    hint: 'e.g. Sector 5 & Downtown Area',
                    prefixIcon: Icons.map_outlined,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Search Bar & Filter Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search user by name, email, or phone...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Firestore Users Stream List
            Expanded(
              child: StreamBuilder<List<AppUser>>(
                stream: _firestoreService.streamCandidateHeadUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingIndicator(message: 'Fetching users from Firestore...');
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading users: ${snapshot.error}'),
                    );
                  }

                  final allUsers = snapshot.data ?? [];
                  final filteredUsers = allUsers.where((u) {
                    if (_searchQuery.isEmpty) return true;
                    return u.fullName.toLowerCase().contains(_searchQuery) ||
                        u.email.toLowerCase().contains(_searchQuery) ||
                        u.phone.contains(_searchQuery);
                  }).toList();

                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person_search_rounded, size: 48, color: AppColors.textTertiary),
                            const SizedBox(height: 12),
                            const Text(
                              'No matching registered users found.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Ensure the candidate user has registered an account in CoopService.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredUsers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final user = filteredUsers[idx];
                      final isSelected = _selectedUser?.uid == user.uid;
                      final isAlreadyHeadOfThis = widget.cooperative.cooperativeHeadId == user.uid;

                      return AppCard(
                        onTap: () {
                          setState(() {
                            _selectedUser = user;
                          });
                        },
                        backgroundColor: isSelected ? AppColors.primaryContainer.withValues(alpha: 0.4) : AppColors.surface,
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                              color: isSelected ? AppColors.primary : AppColors.textTertiary,
                            ),
                            const SizedBox(width: 12),
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primaryContainer,
                              child: Text(
                                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          user.fullName,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isAlreadyHeadOfThis)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.statusVerifiedBg,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'Current Head',
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.statusVerified),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user.email,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceVariant,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Role: ${user.role}',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        user.phone,
                                        style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Bottom Confirmation Bar
            if (_selectedUser != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 10,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: PrimaryButton(
                  text: 'Assign ${_selectedUser!.fullName} as Head',
                  isLoading: _isSubmitting,
                  onPressed: () => _showConfirmationDialog(_selectedUser!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
