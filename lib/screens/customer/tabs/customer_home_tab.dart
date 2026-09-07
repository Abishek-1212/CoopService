import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/booking_model.dart';
import '../../../models/category_model.dart';
import '../../../models/service_model.dart';
import '../../../models/user_model.dart';
import '../../../services/booking_service.dart';
import '../../../services/category_service.dart';
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
  final CategoryService _categoryService = CategoryService();
  final BookingService _bookingService = BookingService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category, [List<CategoryModel>? categoriesList]) {
    if (categoriesList != null) {
      for (var c in categoriesList) {
        if (c.name.toLowerCase() == category.toLowerCase()) {
          return c.iconData;
        }
      }
    }
    return CategoryModel.getIconForName(category);
  }

  String _getServiceRating(int index) {
    const ratings = ['4.9', '4.8', '4.9', '4.7', '5.0', '4.8'];
    return ratings[index % ratings.length];
  }

  int _getServiceReviewCount(int index) {
    const counts = [128, 94, 156, 82, 210, 67];
    return counts[index % counts.length];
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = widget.customer.fullName.trim().isNotEmpty
        ? widget.customer.fullName.trim().split(' ').first
        : 'Customer';
    final String location = widget.customer.location.trim().isNotEmpty
        ? widget.customer.location.trim()
        : 'Coimbatore, Tamil Nadu';

    return Scaffold(
      backgroundColor: AppColors.backgroundMildGreen,
      body: RefreshIndicator(
        color: AppColors.greenForest,
        onRefresh: () async => setState(() {}),
        child: StreamBuilder<List<CategoryModel>>(
          stream: _categoryService.streamActiveCategories(),
          builder: (context, catSnapshot) {
            final dynamicCategories = catSnapshot.data ?? [];

            return StreamBuilder<List<ServiceModel>>(
              stream: _serviceService.streamActiveServices(),
              builder: (context, servicesSnapshot) {
                final allServices = servicesSnapshot.data ?? [];

                // Extract distinct trades / categories dynamically
                final List<String> adminCategories = [];
                if (dynamicCategories.isNotEmpty) {
                  for (var c in dynamicCategories) {
                    adminCategories.add(c.name);
                  }
                } else {
                  for (var s in allServices) {
                    final cat = s.category.trim();
                    if (cat.isNotEmpty && !adminCategories.contains(cat)) {
                      adminCategories.add(cat);
                    }
                  }
                  if (adminCategories.isEmpty) {
                    adminCategories.addAll([
                      'Electrician',
                      'Plumber',
                      'Cleaning',
                      'Carpenter',
                      'Painter',
                      'Appliance',
                      'Gardening',
                      'Locksmith',
                    ]);
                  }
                }

            // Filter services by search query or selected category
            List<ServiceModel> displayedServices = allServices;
            if (_searchQuery.isNotEmpty) {
              displayedServices = displayedServices.where((s) {
                final name = s.name.toLowerCase();
                final cat = s.category.toLowerCase();
                final desc = (s.description ?? '').toLowerCase();
                return name.contains(_searchQuery) ||
                    cat.contains(_searchQuery) ||
                    desc.contains(_searchQuery);
              }).toList();
            } else if (_selectedCategory != null) {
              displayedServices = displayedServices.where((s) {
                return s.category.toLowerCase() == _selectedCategory!.toLowerCase();
              }).toList();
            }

            return ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 90),
              children: [
                // 1. Header: Greeting & Location Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFDCE7E1), width: 1),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.neuDarkShadow,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'C',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.greenForest,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, $displayName',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 11,
                                  color: AppColors.greenForest,
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    location,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
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
                const SizedBox(height: 12),

                // 2. Search Bar (Fixed inner white rectangle artifact with ClipRRect & transparent fill)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _searchQuery.isNotEmpty
                            ? AppColors.greenForest
                            : const Color(0xFFD4E2DA),
                        width: 1.0,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.white,
                          offset: Offset(-2, -2),
                          blurRadius: 5,
                        ),
                        BoxShadow(
                          color: AppColors.neuDarkShadow,
                          offset: Offset(2, 3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: TextField(
                        controller: _searchController,
                        cursorColor: AppColors.greenForest,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim().toLowerCase();
                          });
                        },
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search services, electrician, repairs...',
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textTertiary,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.greenForest,
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          filled: false,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Active Booking Card (Only shown if booking exists!)
                StreamBuilder<List<BookingModel>>(
                  stream: _bookingService.streamCustomerBookings(widget.customer.uid),
                  builder: (context, bookingSnapshot) {
                    if (!bookingSnapshot.hasData) return const SizedBox.shrink();
                    final activeBookings = bookingSnapshot.data!.where((b) {
                      return b.status == AppConstants.bookingPending ||
                          b.status == AppConstants.bookingConfirmed ||
                          b.status == AppConstants.bookingInProgress;
                    }).toList();

                    if (activeBookings.isEmpty) return const SizedBox.shrink();
                    final activeBooking = activeBookings.first;

                    return Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
                      child: _buildActiveBookingCard(activeBooking),
                    );
                  },
                ),

                // 4. Unified Cooperative Trust & Guarantee Card
                _buildTrustGuaranteeCard(),
                const SizedBox(height: 24),

                // 5. Explore by Trade Section (Dynamic Admin Services Categories)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Explore by Trade',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_selectedCategory != null)
                        GestureDetector(
                          onTap: () => setState(() => _selectedCategory = null),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.greenMint.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _selectedCategory!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.greenDeep,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.close_rounded, size: 12, color: AppColors.greenDeep),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Dynamic Trade Horizontal Squircles
                SizedBox(
                  height: 94,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: adminCategories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final catName = adminCategories[index];
                      final bool isSelected = _selectedCategory == catName;
                      final IconData icon = _getCategoryIcon(catName, dynamicCategories);

                      return _BounceButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategory = isSelected ? null : catName;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 68,
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.greenMint.withValues(alpha: 0.35)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.greenForest
                                        : const Color(0xFFE0EBE4),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.white,
                                      offset: Offset(-2, -2),
                                      blurRadius: 4,
                                    ),
                                    BoxShadow(
                                      color: AppColors.neuDarkShadow,
                                      offset: Offset(1, 3),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  icon,
                                  color: isSelected
                                      ? AppColors.greenForest
                                      : AppColors.greenForest.withValues(alpha: 0.85),
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                catName,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  color: isSelected ? AppColors.greenForest : AppColors.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 5. Seasonal & Trending Needs (Smart Recommendations)
                if (_searchQuery.isEmpty && _selectedCategory == null) ...[
                  const SizedBox(height: 20),
                  _buildSeasonalSection(),
                ],
                const SizedBox(height: 22),

                // 6. Popular Services Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _searchQuery.isNotEmpty
                              ? 'Search Results'
                              : (_selectedCategory != null
                                  ? '$_selectedCategory Services'
                                  : 'Popular Services'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_searchQuery.isNotEmpty || _selectedCategory != null)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                              _selectedCategory = null;
                            });
                          },
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.greenForest,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Services List / Horizontal Carousel with ⭐ Ratings and Fixed Rates
                if (servicesSnapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.greenForest),
                      ),
                    ),
                  )
                else if (displayedServices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFDCE7E1), width: 1),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.search_off_rounded, size: 36, color: AppColors.textTertiary),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No services matching "$_searchQuery"'
                                : 'No services available in this trade right now.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_searchQuery.isNotEmpty || _selectedCategory != null)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: displayedServices.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final service = displayedServices[index];
                      return _buildVerticalServiceCard(service, index);
                    },
                  )
                else
                  SizedBox(
                    height: 204,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: displayedServices.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final service = displayedServices[index];
                        return _buildPopularServiceCard(service, index);
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    ),
  ),
);
  }

  // Active Booking Card Widget
  Widget _buildActiveBookingCard(BookingModel booking) {
    String statusLabel = 'Booking Confirmed';
    Color statusBg = AppColors.greenMint.withValues(alpha: 0.4);
    Color statusColor = AppColors.greenDeep;

    if (booking.status == AppConstants.bookingPending) {
      statusLabel = 'Pending Confirmation';
      statusBg = const Color(0xFFFEF3C7);
      statusColor = const Color(0xFFB45309);
    } else if (booking.status == AppConstants.bookingInProgress) {
      statusLabel = 'In Progress';
      statusBg = const Color(0xFFDBEAFE);
      statusColor = const Color(0xFF1D4ED8);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD4E2DA), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(-2, -2),
            blurRadius: 5,
          ),
          BoxShadow(
            color: AppColors.neuDarkShadow,
            offset: Offset(2, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.greenEmerald,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'ACTIVE BOOKING',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: AppColors.greenForest,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.serviceName,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${booking.scheduledDate.day}/${booking.scheduledDate.month}/${booking.scheduledDate.year} • ${booking.timeSlot}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _BounceButton(
                onPressed: () => widget.onNavigateTab(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.greenForest],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.greenForest.withValues(alpha: 0.25),
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Track',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Unified Cooperative Trust & Guarantee Card
  Widget _buildTrustGuaranteeCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE8E1), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C064E3B),
            offset: Offset(0, 4),
            blurRadius: 14,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white,
            offset: Offset(0, -1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.greenForest,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                'COOPERATIVE ASSURED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.greenForest,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.greenMint.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '100% Quality Seal',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greenDeep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: const Color(0xFFEEF5F1),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTrustCardItem(
                  icon: Icons.gpp_good_rounded,
                  title: 'Cooperative Head',
                  subtitle: 'Verification',
                  iconColor: AppColors.greenForest,
                  badgeBg: const Color(0xFFE8F6EE),
                  badgeBorder: const Color(0xFFCEEBD8),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildTrustCardItem(
                  icon: Icons.currency_rupee_rounded,
                  title: 'Fair Rates',
                  subtitle: 'Transparent',
                  iconColor: const Color(0xFF0D9488),
                  badgeBg: const Color(0xFFE6F8F3),
                  badgeBorder: const Color(0xFFC7EFE4),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildTrustCardItem(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Warranty',
                  subtitle: 'Guaranteed',
                  iconColor: AppColors.greenForest,
                  badgeBg: const Color(0xFFE8F6EE),
                  badgeBorder: const Color(0xFFCEEBD8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustCardItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color badgeBg,
    required Color badgeBorder,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: badgeBorder,
              width: 1.0,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 22,
              color: iconColor,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: iconColor,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Popular Services Horizontal Card with ⭐ Ratings & Fixed Rate
  Widget _buildPopularServiceCard(ServiceModel service, int index) {
    final rating = _getServiceRating(index);
    final reviews = _getServiceReviewCount(index);
    final price = service.priceRange?.isNotEmpty == true
        ? service.priceRange!
        : '₹199 fixed';

    return Container(
      width: 172,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EBE5), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(-2, -2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: AppColors.neuDarkShadow,
            offset: Offset(2, 3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: AppColors.greenMint.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(service.category),
                    color: AppColors.greenForest,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 15, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 2),
                    Text(
                      rating,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Text(
              service.name,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              '⭐ $rating ($reviews reviews)',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: AppColors.greenForest,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 34,
              child: _BounceButton(
                onPressed: () async {
                  final result = await ServiceBookingDialog.show(
                    context,
                    service: service,
                    customer: widget.customer,
                  );
                  if (result == true) {
                    widget.onNavigateTab(1);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.greenForest],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.greenForest.withValues(alpha: 0.22),
                        offset: const Offset(0, 2),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Book Now',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
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

  // Vertical Service Card for Search & Filter Results
  Widget _buildVerticalServiceCard(ServiceModel service, int index) {
    final rating = _getServiceRating(index);
    final reviews = _getServiceReviewCount(index);
    final price = service.priceRange?.isNotEmpty == true
        ? service.priceRange!
        : '₹199 fixed';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EBE5), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: AppColors.neuDarkShadow,
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.greenMint.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _getCategoryIcon(service.category),
              color: AppColors.greenForest,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 2),
                    Text(
                      '$rating ($reviews) • $price',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _BounceButton(
            onPressed: () async {
              final result = await ServiceBookingDialog.show(
                context,
                service: service,
                customer: widget.customer,
              );
              if (result == true) {
                widget.onNavigateTab(1);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.greenForest],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.greenForest.withValues(alpha: 0.25),
                    offset: const Offset(0, 2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Book Now',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Seasonal & Trending Needs Section
  Widget _buildSeasonalSection() {
    final List<Map<String, dynamic>> seasonalItems = [
      {
        'tag': '☀️ SUMMER ESSENTIAL',
        'title': 'AC Master Servicing & Fan Tune-up',
        'subtitle': 'Gas check, filter sanitization & speed fix',
        'badge': '₹399 fixed',
        'icon': Icons.ac_unit_rounded,
        'gradient': const [Color(0xFFE8F5E9), Color(0xFFD4EEDC)],
        'borderColor': const Color(0xFFC3E5CE),
        'textColor': const Color(0xFF14532D),
        'tagBg': const Color(0xFFDCFCE7),
        'tagColor': const Color(0xFF15803D),
        'query': 'Electrician',
      },
      {
        'tag': '💧 MONSOON READY',
        'title': 'Roof Waterproofing & Drain Clearing',
        'subtitle': 'Prevent wall seepage & drain backups',
        'badge': 'Guaranteed fix',
        'icon': Icons.water_drop_rounded,
        'gradient': const [Color(0xFFE0F2FE), Color(0xFFCCE8FA)],
        'borderColor': const Color(0xFFB8DEFA),
        'textColor': const Color(0xFF0C4A6E),
        'tagBg': const Color(0xFFE0F2FE),
        'tagColor': const Color(0xFF0369A1),
        'query': 'Plumber',
      },
      {
        'tag': '✨ FESTIVE FRESH',
        'title': 'Deep Home Cleaning & Wall Painting',
        'subtitle': 'Kitchen, bathroom & living disinfection',
        'badge': 'Best Value',
        'icon': Icons.cleaning_services_rounded,
        'gradient': const [Color(0xFFFFF7ED), Color(0xFFFED7AA)],
        'borderColor': const Color(0xFFFDC38A),
        'textColor': const Color(0xFF7C2D12),
        'tagBg': const Color(0xFFFFEDD5),
        'tagColor': const Color(0xFFC2410C),
        'query': 'Cleaning',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: const [
              Icon(Icons.wb_sunny_rounded, size: 16, color: Color(0xFFF59E0B)),
              SizedBox(width: 6),
              Text(
                'Seasonal & Trending Needs',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: seasonalItems.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = seasonalItems[index];
              return _BounceButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = item['query'] as String;
                  });
                },
                child: Container(
                  width: 275,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: item['gradient'] as List<Color>,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: item['borderColor'] as Color,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        offset: const Offset(0, 3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: item['tagBg'] as Color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item['tag'] as String,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: item['tagColor'] as Color,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item['title'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: item['textColor'] as Color,
                                height: 1.2,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item['subtitle'] as String,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: (item['textColor'] as Color).withValues(alpha: 0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: item['tagColor'] as Color,
                          size: 21,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tactile spring-back button for interactive elements
// ---------------------------------------------------------------------------
class _BounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const _BounceButton({
    required this.child,
    this.onPressed,
  });

  @override
  State<_BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<_BounceButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed == null ? null : (_) => _controller.forward(),
      onTapUp: widget.onPressed == null
          ? null
          : (_) {
              _controller.reverse();
              widget.onPressed?.call();
            },
      onTapCancel: widget.onPressed == null ? null : () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
