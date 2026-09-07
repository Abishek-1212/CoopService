import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_image_helper.dart';
import '../../../core/widgets/app_card.dart';
import '../../../models/cooperative_model.dart';
import '../../../models/service_model.dart';
import '../../../models/user_model.dart';
import '../../../services/cooperative_service.dart';
import '../../../services/firestore_service.dart';
import '../../../services/service_management_service.dart';
import '../widgets/service_booking_dialog.dart';

class CustomerHomeTab extends StatefulWidget {
  final AppUser customer;
  final Function(int targetTab, {String? categoryFilter}) onNavigateTab;

  const CustomerHomeTab({
    super.key,
    required this.customer,
    required this.onNavigateTab,
  });

  @override
  State<CustomerHomeTab> createState() => _CustomerHomeTabState();
}

class _CustomerHomeTabState extends State<CustomerHomeTab> {
  final ServiceManagementService _serviceService = ServiceManagementService();
  final CooperativeService _cooperativeService = CooperativeService();
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _quickCategories = [
    {'name': 'Electrician', 'icon': Icons.bolt_rounded, 'color': Color(0xFFFFF3E0), 'iconColor': Color(0xFFE65100)},
    {'name': 'Plumber', 'icon': Icons.plumbing_rounded, 'color': Color(0xFFE1F5FE), 'iconColor': Color(0xFF0288D1)},
    {'name': 'Cleaning', 'icon': Icons.cleaning_services_rounded, 'color': Color(0xFFE8F5E9), 'iconColor': Color(0xFF2E7D32)},
    {'name': 'Carpenter', 'icon': Icons.carpenter_rounded, 'color': Color(0xFFEFEBE9), 'iconColor': Color(0xFF5D4037)},
    {'name': 'Painter', 'icon': Icons.format_paint_rounded, 'color': Color(0xFFF3E5F5), 'iconColor': Color(0xFF7B1FA2)},
    {'name': 'Appliance', 'icon': Icons.tv_rounded, 'color': Color(0xFFEDE7F6), 'iconColor': Color(0xFF512DA8)},
    {'name': 'Gardening', 'icon': Icons.yard_rounded, 'color': Color(0xFFF1F8E9), 'iconColor': Color(0xFF558B2F)},
    {'name': 'Locksmith', 'icon': Icons.lock_reset_rounded, 'color': Color(0xFFFFEBEE), 'iconColor': Color(0xFFC62828)},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            // 1. Customer Greeting & Location Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryContainer,
                    child: Text(
                      widget.customer.fullName.isNotEmpty ? widget.customer.fullName[0].toUpperCase() : 'C',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${widget.customer.fullName} 👋',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 13, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.customer.location.isNotEmpty ? widget.customer.location : 'Coimbatore, Tamil Nadu',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis,
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
            const SizedBox(height: 16),

            // 2. Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: InkWell(
                onTap: () => widget.onNavigateTab(2), // jump to services tab
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.search_rounded, color: AppColors.textTertiary, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Search electrician, plumber, cleaner...',
                          style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. Hero Promotional Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'COMMUNITY BACKED',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Trusted Local Cooperative Services',
                            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, height: 1.2),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Verified professionals. Regulated fair pricing. Zero hidden fees.',
                            style: TextStyle(color: Color(0xFFDBEAFE), fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => widget.onNavigateTab(2),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1E3A8A),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Book a Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.handshake_rounded, color: Colors.white, size: 36),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 4. Quick Categories Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Explore by Trade',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.onNavigateTab(2),
                    child: const Text('View All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 96,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _quickCategories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final cat = _quickCategories[index];
                  return InkWell(
                    onTap: () => widget.onNavigateTab(2, categoryFilter: cat['name']),
                    borderRadius: BorderRadius.circular(14),
                    child: Column(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: cat['color'] as Color,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(cat['icon'] as IconData, color: cat['iconColor'] as Color, size: 28),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat['name'] as String,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // 5. Featured / Popular Services (Live from Firestore)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Popular Household Services',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.onNavigateTab(2),
                    child: const Text('See Directory', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<ServiceModel>>(
              stream: _serviceService.streamActiveServices(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }

                final services = snapshot.data ?? [];
                if (services.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Text(
                      'No active services listed yet.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  );
                }

                return SizedBox(
                  height: 200,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: services.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return _buildServiceCard(service);
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // 6. Registered Local Cooperative Societies (Live from Firestore)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: const [
                  Icon(Icons.apartment_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Local Cooperative Societies',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<CooperativeModel>>(
              stream: _cooperativeService.streamCooperatives(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)));
                }

                final coops = (snapshot.data ?? []).where((c) => c.isActive).toList();
                if (coops.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text('No cooperative societies available right now.', style: TextStyle(color: AppColors.textSecondary)),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: coops.length > 3 ? 3 : coops.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final coop = coops[index];
                    return AppCard(
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.groups_rounded, color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  coop.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Reg: ${coop.registrationNumber} • ${coop.district ?? "District"}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Area: ${coop.primaryServiceArea}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.statusVerifiedBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Registered', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.statusVerified)),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 28),

            // 7. Verified Society Workers (Live from Firestore)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: const [
                  Icon(Icons.verified_user_rounded, color: AppColors.statusVerified, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Verified Society Workers',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<AppUser>>(
              stream: _firestoreService.streamAllWorkers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)));
                }

                final workers = (snapshot.data ?? []).where((w) {
                  return w.membershipStatus == AppConstants.membershipApproved ||
                      w.verificationStatus == AppConstants.statusVerified;
                }).toList();

                if (workers.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text('Workers are completing verification.', style: TextStyle(color: AppColors.textSecondary)),
                  );
                }

                return SizedBox(
                  height: 160,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: workers.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final worker = workers[index];
                      return Container(
                        width: 220,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.primaryContainer,
                                  backgroundImage: AppImageHelper.getImageProvider(worker.profilePhotoUrl),
                                  child: worker.profilePhotoUrl == null
                                      ? Text(worker.fullName.isNotEmpty ? worker.fullName[0].toUpperCase() : 'W')
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        worker.fullName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        worker.serviceCategory ?? 'Professional',
                                        style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(Icons.verified_rounded, color: AppColors.statusVerified, size: 14),
                                const SizedBox(width: 4),
                                const Expanded(
                                  child: Text(
                                    'Verified Member',
                                    style: TextStyle(fontSize: 10, color: AppColors.statusVerified, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${worker.yearsOfExperience ?? "2+"} yrs exp',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(ServiceModel service) {
    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.build_circle_rounded, color: AppColors.primary, size: 28),
            ),
            const Spacer(),
            Text(
              service.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              service.category,
              style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              service.priceRange ?? '₹250 - ₹500',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 32,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await ServiceBookingDialog.show(
                    context,
                    service: service,
                    customer: widget.customer,
                  );
                  if (result == true) {
                    widget.onNavigateTab(1); // navigate to Bookings tab
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Book', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
