import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_image_helper.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/statistic_card.dart';
import '../../models/booking_model.dart';
import '../../models/cooperative_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../../services/cooperative_service.dart';
import 'tabs/worker_jobs_tab.dart';

class WorkerDashboard extends StatefulWidget {
  const WorkerDashboard({super.key});

  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
  int _currentIndex = 0;
  final CooperativeService _cooperativeService = CooperativeService();
  final BookingService _bookingService = BookingService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return StreamBuilder<List<BookingModel>>(
      stream: user != null ? _bookingService.streamBookingsForWorker(user) : Stream.value([]),
      builder: (context, snapshot) {
        final allBookings = snapshot.data ?? [];
        final pendingCount = allBookings
            .where((b) => b.isPending && (b.workerId == null || b.workerId!.isEmpty || b.workerId == user?.uid))
            .length;

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
                    Icons.handyman_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Worker Dashboard',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: AppColors.statusError),
                tooltip: 'Logout',
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
              });
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: pendingCount > 0,
                  label: Text('$pendingCount'),
                  child: const Icon(Icons.work_outline),
                ),
                selectedIcon: Badge(
                  isLabelVisible: pendingCount > 0,
                  label: Text('$pendingCount'),
                  child: const Icon(Icons.work_rounded),
                ),
                label: 'Jobs',
              ),
              const NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Earnings',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: pendingCount > 0,
                  child: const Icon(Icons.notifications_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: pendingCount > 0,
                  child: const Icon(Icons.notifications_rounded),
                ),
                label: 'Alerts',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(AppUser? user) {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab(user);
      case 1:
        return _buildJobsTab(user);
      case 2:
        return _buildEarningsTab(user);
      case 3:
        return _buildAlertsTab(user);
      case 4:
      default:
        return _buildProfileTab(user);
    }
  }

  Widget _buildHomeTab(AppUser? user) {
    final coopId = user?.cooperativeId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Status Card
          AppCard(
            backgroundColor: AppColors.surface,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primaryContainer,
                  backgroundImage: AppImageHelper.getImageProvider(user?.profilePhotoUrl),
                  child: user?.profilePhotoUrl == null || user!.profilePhotoUrl!.isEmpty
                      ? Text(
                          user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'W',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.primary),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${user?.fullName ?? "Worker"}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Trade: ${user?.serviceCategory ?? "Professional"}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.statusVerifiedBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.verified_rounded, size: 12, color: AppColors.statusVerified),
                                SizedBox(width: 4),
                                Text(
                                  'Verified Member',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.statusVerified,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // PROMINENT COOPERATIVE SOCIETY DETAILS CARD
          const Text(
            'Your Cooperative Society',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),

          if (coopId != null && coopId.isNotEmpty)
            StreamBuilder<CooperativeModel?>(
              stream: _cooperativeService.streamCooperativeById(coopId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator(message: 'Loading cooperative society details...');
                }

                final coop = snapshot.data;
                if (coop == null) {
                  return AppCard(
                    child: Column(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.statusPending, size: 36),
                        const SizedBox(height: 8),
                        Text('Cooperative ID: $coopId'),
                        const SizedBox(height: 4),
                        const Text(
                          'Society details are being synchronized.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                // Collect covered cities / operating areas
                final List<String> coveredAreas = [];
                if (coop.primaryServiceArea.isNotEmpty) {
                  coveredAreas.add(coop.primaryServiceArea);
                }
                if (coop.city != null && coop.city!.isNotEmpty && !coveredAreas.contains(coop.city)) {
                  coveredAreas.add(coop.city!);
                }
                for (var area in coop.additionalServiceAreas) {
                  if (area.isNotEmpty && !coveredAreas.contains(area)) {
                    coveredAreas.add(area);
                  }
                }
                final coveredAreasText = coveredAreas.isNotEmpty ? coveredAreas.join(', ') : 'All areas in ${coop.district}';

                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  coop.name,
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Registration #: ${coop.registrationNumber}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'District: ${coop.district ?? "Tamil Nadu"}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.statusVerifiedBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Active Unit',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.statusVerified),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 22),

                      // Covered Cities
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.navigation_outlined, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Covered Cities & Operating Area:',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  coveredAreasText,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Cooperative Contact
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              coop.contactPhone.isNotEmpty ? coop.contactPhone : 'Support available',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.email_outlined, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              coop.contactEmail.isNotEmpty ? coop.contactEmail : 'Email on file',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            )
          else
            AppCard(
              child: const Text('No Cooperative Society linked yet.'),
            ),

          const SizedBox(height: 24),

          // Live Customer Requests & Today's Service Metrics
          StreamBuilder<List<BookingModel>>(
            stream: user != null ? _bookingService.streamBookingsForWorker(user) : Stream.value([]),
            builder: (context, snapshot) {
              final allBookings = snapshot.data ?? [];
              final availableRequests = allBookings
                  .where((b) => b.isPending && (b.workerId == null || b.workerId!.isEmpty || b.workerId == user?.uid))
                  .toList();
              final activeJobs = allBookings
                  .where((b) => b.workerId == user?.uid && (b.isConfirmed || b.isInProgress))
                  .toList();
              final completedToday = allBookings
                  .where((b) =>
                      b.workerId == user?.uid &&
                      b.isCompleted &&
                      b.createdAt.day == DateTime.now().day &&
                      b.createdAt.month == DateTime.now().month &&
                      b.createdAt.year == DateTime.now().year)
                  .toList();
              final allCompleted = allBookings
                  .where((b) => b.workerId == user?.uid && b.isCompleted)
                  .toList();

              int dayEarnings = 0;
              for (final job in (completedToday.isNotEmpty ? completedToday : allCompleted)) {
                final match = RegExp(r'\d+').firstMatch(job.estimatedPrice ?? '');
                if (match != null) {
                  dayEarnings += int.parse(match.group(0)!);
                } else {
                  dayEarnings += 350;
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // High Priority Banner if customer requested a service!
                  if (availableRequests.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.statusVerified.withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.statusVerified.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.statusVerified,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '⚡ ${availableRequests.length} Customer Request${availableRequests.length > 1 ? "s" : ""} Received!',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20)),
                                    ),
                                    Text(
                                      'Service: ${availableRequests.first.serviceName} • ${availableRequests.first.timeSlot}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Customer: ${availableRequests.first.customerName} (${availableRequests.first.customerAddress.isNotEmpty ? availableRequests.first.customerAddress : (availableRequests.first.customerDistrict ?? "Location provided")})',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1B5E20)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() => _currentIndex = 1);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.statusVerified,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.touch_app_rounded, size: 16),
                                label: const Text('View & Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Work Statistics Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Today\'s Service Metrics',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (activeJobs.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${activeJobs.length} Active Job${activeJobs.length > 1 ? "s" : ""}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ],
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
                        title: 'Assigned Jobs',
                        value: '${activeJobs.length} Active',
                        icon: Icons.work_outline,
                        color: AppColors.primary,
                        onTap: () {
                          setState(() {
                            _currentIndex = 1;
                          });
                        },
                      ),
                      StatisticCard(
                        title: 'Completed',
                        value: '${completedToday.isNotEmpty ? completedToday.length : allCompleted.length} Gigs',
                        icon: Icons.task_alt_rounded,
                        color: AppColors.statusVerified,
                        onTap: () {
                          setState(() {
                            _currentIndex = 1;
                          });
                        },
                      ),
                      StatisticCard(
                        title: 'Earnings',
                        value: '₹$dayEarnings',
                        icon: Icons.currency_rupee_rounded,
                        color: AppColors.accent,
                        onTap: () {
                          setState(() {
                            _currentIndex = 2;
                          });
                        },
                      ),
                      StatisticCard(
                        title: 'Customer Rating',
                        value: '4.9 ⭐',
                        icon: Icons.star_outline_rounded,
                        color: Colors.amber,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildJobsTab(AppUser? user) {
    if (user == null) {
      return const LoadingIndicator(message: 'Loading worker dispatch...');
    }
    return WorkerJobsTab(worker: user);
  }

  Widget _buildEarningsTab(AppUser? user) {
    if (user == null) return const LoadingIndicator(message: 'Loading earnings...');

    return StreamBuilder<List<BookingModel>>(
      stream: _bookingService.streamBookingsForWorker(user),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator(message: 'Calculating worker payouts...');
        }

        final all = snapshot.data ?? [];
        final completed = all.where((b) => b.workerId == user.uid && b.isCompleted).toList();

        int totalGross = 0;
        for (final b in completed) {
          final match = RegExp(r'\d+').firstMatch(b.estimatedPrice ?? '');
          totalGross += match != null ? int.parse(match.group(0)!) : 350;
        }

        final welfareFund = (totalGross * 0.05).round();
        final netPayout = totalGross - welfareFund;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Earnings Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Net Payout', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(
                      '₹$netPayout',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Gross Revenue', style: TextStyle(color: Colors.white70, fontSize: 11), overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text('₹$totalGross', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Coop Welfare (5%)', style: TextStyle(color: Colors.white70, fontSize: 11), overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text('₹$welfareFund', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Completed Gigs', style: TextStyle(color: Colors.white70, fontSize: 11), overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text('${completed.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Completed Services History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),

              if (completed.isEmpty)
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Center(
                      child: Column(
                        children: const [
                          Icon(Icons.receipt_long_outlined, size: 44, color: AppColors.textSecondary),
                          SizedBox(height: 10),
                          Text('No Completed Gigs Yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 4),
                          Text(
                            'Accept incoming customer requests in the Jobs tab to start earning with your cooperative society.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: completed.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final job = completed[index];
                    final match = RegExp(r'\d+').firstMatch(job.estimatedPrice ?? '');
                    final fee = match != null ? match.group(0)! : '350';

                    return AppCard(
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.statusVerified.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.statusVerified),
                        ),
                        title: Text(job.serviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: Text('Customer: ${job.customerName}\n${job.scheduledDate.day}/${job.scheduledDate.month}/${job.scheduledDate.year} • ${job.timeSlot}'),
                        isThreeLine: true,
                        trailing: Text(
                          '₹$fee',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.statusVerified),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertsTab(AppUser? user) {
    if (user == null) return const LoadingIndicator(message: 'Loading alerts...');

    return StreamBuilder<List<BookingModel>>(
      stream: _bookingService.streamBookingsForWorker(user),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator(message: 'Checking for alerts...');
        }

        final all = snapshot.data ?? [];
        final available = all
            .where((b) => b.isPending && (b.workerId == null || b.workerId!.isEmpty || b.workerId == user.uid))
            .toList();
        final active = all
            .where((b) => b.workerId == user.uid && (b.isConfirmed || b.isInProgress))
            .toList();

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Dispatch Notifications & Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Real-time customer bookings, job assignments, and cooperative updates.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            if (available.isNotEmpty) ...[
              const Text('Incoming Customer Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.statusVerified)),
              const SizedBox(height: 8),
              ...available.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.statusVerified.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.flash_on_rounded, color: AppColors.statusVerified, size: 20),
                        ),
                        title: Text('New Request: ${b.serviceName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('From: ${b.customerName} • Slot: ${b.timeSlot}\nLocation: ${b.customerAddress.isNotEmpty ? b.customerAddress : (b.customerDistrict ?? "Address provided")}'),
                        isThreeLine: true,
                        trailing: ElevatedButton(
                          onPressed: () {
                            setState(() => _currentIndex = 1);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.statusVerified,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Accept', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
            ],

            if (active.isNotEmpty) ...[
              const Text('Active Service Orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
              const SizedBox(height: 8),
              ...active.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.work_rounded, color: AppColors.primary, size: 20),
                        ),
                        title: Text('Scheduled: ${b.serviceName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('Customer: ${b.customerName} • ${b.customerPhone}\nStatus: ${b.status.toUpperCase()}'),
                        isThreeLine: true,
                        trailing: TextButton(
                          onPressed: () {
                            setState(() => _currentIndex = 1);
                          },
                          child: const Text('Open'),
                        ),
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
            ],

            // Cooperative Announcement Item
            AppCard(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.campaign_outlined, color: AppColors.primary),
                ),
                title: const Text('Cooperative Dispatch Protocol Active', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('All customer bookings for your trade skill are dispatched instantly. Keep your availability active to claim high-demand slots.'),
              ),
            ),
          ],
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
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primaryContainer,
            backgroundImage: AppImageHelper.getImageProvider(user?.profilePhotoUrl),
            child: user?.profilePhotoUrl == null || user!.profilePhotoUrl!.isEmpty
                ? const Icon(Icons.handyman_rounded, size: 48, color: AppColors.primary)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            user?.fullName ?? 'Worker Name',
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
                  leading: const Icon(Icons.apartment_rounded, color: AppColors.primary),
                  title: const Text('Belonging Cooperative Society'),
                  subtitle: Text(user?.cooperativeId != null ? 'Assigned Society (${user!.cooperativeId})' : 'Not Linked'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.handyman_outlined, color: AppColors.primary),
                  title: const Text('Trade Skill'),
                  subtitle: Text(user?.serviceCategory ?? 'General Service'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                  title: const Text('Service Area / District'),
                  subtitle: Text(user?.district != null ? '${user!.district}, Tamil Nadu' : 'Not set'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined, color: AppColors.statusVerified),
                  title: const Text('Verification Status'),
                  subtitle: const Text('Verified Member of Cooperative Society'),
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
