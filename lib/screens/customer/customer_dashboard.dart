import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.edit_note_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Edit Profile'),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
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
                            const SnackBar(
                              content: Text('Profile updated successfully!'),
                              backgroundColor: AppColors.statusVerified,
                            ),
                          );
                        }
                      } catch (e) {
                        setModalState(() => isSaving = false);
                        if (dialogCtx.mounted) {
                          ScaffoldMessenger.of(dialogCtx).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.statusError),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes'),
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.handshake_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                AppConstants.appName,
                style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Alerts',
            onPressed: () => _onNavigateTab(3),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.statusError),
            tooltip: 'Sign Out',
            onPressed: () => authProvider.signOut(),
          ),
        ],
      ),
      body: _buildBody(user),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() {
            _currentIndex = idx;
            if (idx != 2) _selectedCategoryFilter = null;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today_rounded),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Services',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Avatar & Name Card
          AppCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'C',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: AppColors.primary),
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
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Customer Member',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => _showEditProfileDialog(user),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Profile Details'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

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
                  Expanded(child: _buildStatTile('Total Bookings', '$totalCount', Icons.receipt_long_rounded, AppColors.primary)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatTile('Active Orders', '$activeCount', Icons.pending_actions_rounded, AppColors.statusPending)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatTile('Completed', '$completedCount', Icons.task_alt_rounded, AppColors.statusVerified)),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Contact & Location Details Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saved Information',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone_outlined, color: AppColors.primary),
                  title: const Text('Phone Number', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  subtitle: Text(user.phone.isNotEmpty ? user.phone : 'Not provided', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                  title: const Text('City & Region', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  subtitle: Text(user.location.isNotEmpty ? user.location : 'Coimbatore, Tamil Nadu', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                if (user.fullAddress != null && user.fullAddress!.isNotEmpty) ...[
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.home_outlined, color: AppColors.primary),
                    title: const Text('Service Address', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    subtitle: Text(user.fullAddress!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Community Trust Guarantee
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.statusVerifiedBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: AppColors.statusVerified, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cooperative Protection Guarantee',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'All services are backed by verified government-registered Cooperative Societies ensuring transparent and fair labor practices.',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sign Out Button
          ElevatedButton.icon(
            onPressed: () => authProvider.signOut(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusErrorBg,
              foregroundColor: AppColors.statusError,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatTile(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
