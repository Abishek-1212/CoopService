import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/statistic_card.dart';
import '../../models/cooperative_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/cooperative_service.dart';
import '../../services/firestore_service.dart';
import 'add_cooperative_screen.dart';
import 'cooperative_list_screen.dart';
import 'services/services_list_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  final CooperativeService _cooperativeService = CooperativeService();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'COOPSERVICE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Platform Administration',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppColors.statusErrorBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppColors.statusError, size: 20),
              tooltip: 'Logout',
              onPressed: () => authProvider.signOut(),
            ),
          ),
        ],
      ),
      body: _buildBody(user),
      bottomNavigationBar: _buildNeumorphicBottomBar(),
    );
  }

  Widget _buildNeumorphicBottomBar() {
    final navItems = [
      {'icon': Icons.grid_view_rounded, 'tooltip': 'Dashboard'},
      {'icon': Icons.apartment_rounded, 'tooltip': 'Cooperatives'},
      {'icon': Icons.category_rounded, 'tooltip': 'Services'},
      {'icon': Icons.people_alt_rounded, 'tooltip': 'Users'},
      {'icon': Icons.badge_rounded, 'tooltip': 'Workers'},
      {'icon': Icons.person_rounded, 'tooltip': 'Profile'},
    ];

    return SafeArea(
      child: Container(
        height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.8),
              blurRadius: 10,
              offset: const Offset(-3, -3),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double totalWidth = constraints.maxWidth;
            final double itemWidth = totalWidth / navItems.length;
            const double circleDiameter = 42.0;
            final double activeLeft = (itemWidth * _currentIndex) + (itemWidth - circleDiameter) / 2;

            return Stack(
              children: [
                // Animated Sliding Active Circle Indicator
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.fastOutSlowIn,
                  left: activeLeft,
                  top: (constraints.maxHeight - circleDiameter) / 2,
                  child: Container(
                    width: circleDiameter,
                    height: circleDiameter,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),

                // Navigation Items Row
                Row(
                  children: List.generate(navItems.length, (idx) {
                    final isSelected = _currentIndex == idx;
                    final IconData icon = navItems[idx]['icon'] as IconData;
                    final String tooltip = navItems[idx]['tooltip'] as String;

                    return Expanded(
                      child: Tooltip(
                        message: tooltip,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentIndex = idx;
                            });
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 250),
                              scale: isSelected ? 1.15 : 1.0,
                              child: Icon(
                                icon,
                                size: 22,
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(AppUser? user) {
    switch (_currentIndex) {
      case 0:
        return _buildOverviewTab(user);
      case 1:
        return const CooperativeListScreen();
      case 2:
        return const ServicesListScreen();
      case 3:
        return _buildUsersTab();
      case 4:
        return _buildWorkersTab();
      case 5:
      default:
        return _buildProfileTab(user);
    }
  }

  Widget _buildOverviewTab(AppUser? user) {
    return StreamBuilder<List<CooperativeModel>>(
      stream: _cooperativeService.streamCooperatives(),
      builder: (context, coopSnap) {
        return StreamBuilder<List<AppUser>>(
          stream: _firestoreService.streamAllUsers(),
          builder: (context, userSnap) {
            if (coopSnap.connectionState == ConnectionState.waiting ||
                userSnap.connectionState == ConnectionState.waiting) {
              return const LoadingIndicator(message: 'Loading admin dashboard...');
            }

            final coops = coopSnap.data ?? [];
            final users = userSnap.data ?? [];

            final totalCoops = coops.length;
            final totalHeads = users.where((u) => u.isCooperativeHead).length;
            final totalWorkers = users.where((u) => u.isWorker).length;
            final totalCustomers = users.where((u) => u.isCustomer).length;
            final pendingWorkers = users.where((u) => u.isWorker && u.verificationStatus == AppConstants.statusPending).length;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Executive Admin Welcome Hero Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primaryContainer, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, AppColors.primaryDark],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: AppColors.statusVerified,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.surface, width: 2.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'SUPER ADMIN',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primary,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.statusVerifiedBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: const [
                                        Icon(Icons.check_circle_rounded, size: 10, color: AppColors.statusVerified),
                                        SizedBox(width: 4),
                                        Text(
                                          'ACTIVE',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.statusVerified,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Welcome back, ${user?.fullName ?? "Administrator"}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Full Platform Governance & Master Controls Active',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Real-time Platform Statistics Grid
                  const Text(
                    'Platform Statistics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.15,
                    children: [
                      StatisticCard(
                        title: 'Cooperative Societies',
                        value: '$totalCoops',
                        icon: Icons.apartment_rounded,
                        color: AppColors.primary,
                        onTap: () {
                          setState(() {
                            _currentIndex = 1;
                          });
                        },
                      ),
                      StatisticCard(
                        title: 'Cooperative Heads',
                        value: '$totalHeads',
                        icon: Icons.verified_user_rounded,
                        color: AppColors.accent,
                      ),
                      StatisticCard(
                        title: 'Total Workers',
                        value: '$totalWorkers',
                        icon: Icons.handyman_rounded,
                        color: AppColors.statusVerified,
                        onTap: () {
                          setState(() {
                            _currentIndex = 4;
                          });
                        },
                      ),
                      StatisticCard(
                        title: 'Total Customers',
                        value: '$totalCustomers',
                        icon: Icons.people_alt_rounded,
                        color: AppColors.primaryDark,
                        onTap: () {
                          setState(() {
                            _currentIndex = 3;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  StatisticCard(
                    title: 'Pending Worker Verifications',
                    value: '$pendingWorkers Pending',
                    icon: Icons.hourglass_top_rounded,
                    color: AppColors.statusPending,
                  ),

                  const SizedBox(height: 28),

                  // System Control & Quick Actions
                  const Text(
                    'Platform Governance Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  AppCard(
                    onTap: () {
                      setState(() {
                        _currentIndex = 2;
                      });
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.category_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Manage Master Services Catalog',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Create, edit, and activate platform service types for cooperatives',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  AppCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddCooperativeScreen(),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add_business_rounded, color: AppColors.accent, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Register New Cooperative Society',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Add a new regional cooperative society with dynamic service offerings',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  AppCard(
                    onTap: () {
                      setState(() {
                        _currentIndex = 1;
                      });
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.domain_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Manage Societies & Assign Heads',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'View society list, edit details, and assign registered users as Cooperative Heads',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUsersTab() {
    return StreamBuilder<List<AppUser>>(
      stream: _firestoreService.streamAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator(message: 'Loading platform users...');
        }

        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Center(child: Text('No users found in Firestore.'));
        }

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text('All Registered Users (${users.length})'),
          ),
          body: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final u = users[idx];
              return AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryContainer,
                      child: Text(
                        u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u.fullName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          Text(u.email, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(u.phone, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        u.role,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildWorkersTab() {
    return StreamBuilder<List<AppUser>>(
      stream: _firestoreService.streamAllWorkers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator(message: 'Loading platform workers...');
        }

        final workers = snapshot.data ?? [];
        if (workers.isEmpty) {
          return const Center(child: Text('No registered workers found in Firestore.'));
        }

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text('Registered Workers (${workers.length})'),
          ),
          body: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: workers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final w = workers[idx];
              return AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryContainer,
                      child: Text(
                        w.fullName.isNotEmpty ? w.fullName[0].toUpperCase() : 'W',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w.fullName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Skill: ${w.serviceCategory ?? "General"} • ${w.experience ?? "N/A"}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          Text(w.email, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: w.verificationStatus == AppConstants.statusVerified
                            ? AppColors.statusVerifiedBg
                            : AppColors.statusPendingBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        w.verificationStatus ?? 'Pending',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: w.verificationStatus == AppConstants.statusVerified
                              ? AppColors.statusVerified
                              : AppColors.statusPending,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProfileTab(AppUser? user) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          const CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primaryContainer,
            child: Icon(Icons.admin_panel_settings_rounded, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            user?.fullName ?? 'Administrator',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.security_rounded, color: AppColors.primary),
                  title: const Text('System Role'),
                  subtitle: const Text('Super Administrator (admin)'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined, color: AppColors.primary),
                  title: const Text('Access Permissions'),
                  subtitle: const Text('Full Platform Read/Write & User Assignment'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => authProvider.signOut(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusErrorBg,
              foregroundColor: AppColors.statusError,
              minimumSize: const Size(double.infinity, 50),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
