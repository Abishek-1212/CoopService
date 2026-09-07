import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../models/booking_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../../services/firestore_service.dart';
import 'tabs/customer_alerts_tab.dart';
import 'tabs/customer_bookings_tab.dart';
import 'tabs/customer_home_tab.dart';
import 'tabs/customer_services_tab.dart';
import '../../core/widgets/floating_pill_nav_bar.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  final BookingService _bookingService = BookingService();
  final FirestoreService _firestoreService = FirestoreService();

  int _currentIndex = 0;
  String? _selectedCategoryFilter;

  void _onNavigateTab(int targetTab, {String? categoryFilter}) {
    setState(() {
      _currentIndex = targetTab;
      _selectedCategoryFilter = categoryFilter;
    });
  }

  void _showEditProfileDialog(AppUser user) {
    final nameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phone);
    final locationController = TextEditingController(text: user.location);
    final addressController = TextEditingController(text: user.fullAddress ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF8F3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD4E6DC)),
                ),
                child: const Icon(Icons.edit_note_rounded, color: AppColors.greenForest, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Edit Profile',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.greenDeep),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: nameController,
                  label: 'Full Name',
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: phoneController,
                  label: 'Phone Number',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: locationController,
                  label: 'City / District',
                  prefixIcon: Icons.location_city_outlined,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: addressController,
                  label: 'Default Service Address',
                  prefixIcon: Icons.home_outlined,
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            _BounceButton(
              onTap: isSaving
                  ? null
                  : () async {
                      setModalState(() => isSaving = true);
                      try {
                        final updated = user.copyWith(
                          fullName: nameController.text.trim(),
                          phone: phoneController.text.trim(),
                          location: locationController.text.trim(),
                          fullAddress: addressController.text.trim(),
                        );
                        await _firestoreService.createUserProfile(updated);
                        if (context.mounted) {
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          await auth.refreshCurrentUser();
                        }
                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text('Profile updated successfully!'),
                                ],
                              ),
                              backgroundColor: AppColors.greenForest,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      } catch (e) {
                        setModalState(() => isSaving = false);
                        if (dialogCtx.mounted) {
                          ScaffoldMessenger.of(dialogCtx).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppColors.statusError,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.greenForest],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x330F766E),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text(
                        'Save Changes',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundMildGreen,
        body: Center(child: CircularProgressIndicator(color: AppColors.greenForest)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundMildGreen,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundMildGreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDCE7E1), width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0C064E3B),
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.handshake_rounded,
                color: AppColors.greenForest,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                AppConstants.appName,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.greenForest,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          _BounceButton(
            onTap: () => _onNavigateTab(3),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDCE7E1)),
              ),
              child: const Icon(Icons.notifications_none_rounded, color: AppColors.greenDeep, size: 20),
            ),
          ),
          _BounceButton(
            onTap: () => authProvider.signOut(),
            child: Container(
              margin: const EdgeInsets.fromLTRB(4, 8, 14, 8),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.statusError, size: 20),
            ),
          ),
        ],
      ),
      body: _buildBody(user),
      bottomNavigationBar: FloatingPillNavBar(
        currentIndex: _currentIndex,
        onTap: (idx) {
          setState(() {
            _currentIndex = idx;
            if (idx != 2) _selectedCategoryFilter = null;
          });
        },
        items: const [
          FloatingNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
          ),
          FloatingNavItem(
            icon: Icons.calendar_today_outlined,
            activeIcon: Icons.calendar_today_rounded,
            label: 'Bookings',
          ),
          FloatingNavItem(
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view_rounded,
            label: 'Services',
          ),
          FloatingNavItem(
            icon: Icons.notifications_outlined,
            activeIcon: Icons.notifications_rounded,
            label: 'Alerts',
          ),
          FloatingNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppUser user) {
    switch (_currentIndex) {
      case 0:
        return CustomerHomeTab(
          customer: user,
          onNavigateTab: _onNavigateTab,
        );
      case 1:
        return CustomerBookingsTab(
          customer: user,
          onNavigateTab: _onNavigateTab,
        );
      case 2:
        return CustomerServicesTab(
          key: ValueKey(_selectedCategoryFilter),
          customer: user,
          initialCategory: _selectedCategoryFilter,
          onNavigateTab: _onNavigateTab,
        );
      case 3:
        return CustomerAlertsTab(
          customer: user,
          onNavigateTab: _onNavigateTab,
        );
      case 4:
      default:
        return _buildProfileTab(user);
    }
  }

  Widget _buildProfileTab(AppUser user) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Column(
        children: [
          // Avatar & Name Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFDDECE3), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0E064E3B),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8F6EE), Color(0xFFD2EEDC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFBCE0CC), width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x18047857),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'C',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 32,
                        color: AppColors.greenForest,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.fullName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF8F3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD4E6DC)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, size: 13, color: AppColors.greenEmerald),
                      SizedBox(width: 5),
                      Text(
                        'Verified Customer Member',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.greenForest),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _BounceButton(
                  onTap: () => _showEditProfileDialog(user),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F8F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD4E6DC)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined, size: 15, color: AppColors.greenForest),
                        SizedBox(width: 6),
                        Text(
                          'Edit Profile Details',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
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
          const SizedBox(height: 14),

          // Live Activity Stats from Firestore
          StreamBuilder<List<BookingModel>>(
            stream: _bookingService.streamCustomerBookings(user.uid),
            builder: (context, snapshot) {
              final bookings = snapshot.data ?? [];
              final totalCount = bookings.length;
              final activeCount = bookings.where((b) => b.isPending || b.isConfirmed || b.isInProgress).length;
              final completedCount = bookings.where((b) => b.isCompleted).length;

              return Row(
                children: [
                  Expanded(child: _buildStatTile('Total Bookings', '$totalCount', Icons.receipt_long_rounded, AppColors.greenForest)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatTile('Active Orders', '$activeCount', Icons.pending_actions_rounded, AppColors.statusPending)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatTile('Completed', '$completedCount', Icons.task_alt_rounded, AppColors.greenEmerald)),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Contact & Location Details Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFDDECE3), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0E064E3B),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.contact_mail_outlined, size: 18, color: AppColors.greenForest),
                    SizedBox(width: 8),
                    Text(
                      'Saved Information',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.phone_outlined, 'Phone Number', user.phone.isNotEmpty ? user.phone : 'Not provided'),
                const Divider(height: 16, color: Color(0xFFE8F1EC)),
                _buildInfoRow(Icons.location_on_outlined, 'City & Region', user.location.isNotEmpty ? user.location : 'Coimbatore, Tamil Nadu'),
                if (user.fullAddress != null && user.fullAddress!.isNotEmpty) ...[
                  const Divider(height: 16, color: Color(0xFFE8F1EC)),
                  _buildInfoRow(Icons.home_outlined, 'Service Address', user.fullAddress!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Community Trust Guarantee Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFDDECE3), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0E064E3B),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: AppColors.greenForest, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cooperative Protection Guarantee',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'All services are backed by government-registered Cooperative Societies ensuring transparent and fair labor practices.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Sign Out Tactile Button
          _BounceButton(
            onTap: () => authProvider.signOut(),
            child: Container(
              width: double.infinity,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECDD3)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18EF4444),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, size: 18, color: AppColors.statusError),
                  SizedBox(width: 8),
                  Text(
                    'Sign Out',
                    style: TextStyle(
                      color: AppColors.statusError,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF8F3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.greenForest),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDECE3), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A064E3B),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Tactile bounce button with physical press micro-interaction
class _BounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _BounceButton({
    required this.child,
    this.onTap,
  });

  @override
  State<_BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<_BounceButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
