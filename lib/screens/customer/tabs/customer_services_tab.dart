import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../models/service_model.dart';
import '../../../models/user_model.dart';
import '../../../services/service_management_service.dart';
import '../widgets/service_booking_dialog.dart';

class CustomerServicesTab extends StatefulWidget {
  final AppUser customer;
  final String? initialCategory;
  final Function(int targetTab) onNavigateTab;

  const CustomerServicesTab({
    super.key,
    required this.customer,
    this.initialCategory,
    required this.onNavigateTab,
  });

  @override
  State<CustomerServicesTab> createState() => _CustomerServicesTabState();
}

class _CustomerServicesTabState extends State<CustomerServicesTab> {
  final ServiceManagementService _serviceService = ServiceManagementService();

  String _searchQuery = '';
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header & Search Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service Directory',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Explore regulated cooperative trade services with fair transparent pricing.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search service by name or skill...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ],
            ),
          ),

          // Category Chips Bar
          Container(
            height: 52,
            color: AppColors.surface,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildCategoryChip('All'),
                ...AppConstants.serviceCategories.map((c) => _buildCategoryChip(c)),
              ],
            ),
          ),
          const Divider(height: 1),

          // Services Stream List
          Expanded(
            child: StreamBuilder<List<ServiceModel>>(
              stream: _serviceService.streamActiveServices(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator(message: 'Loading active services...');
                }

                final allServices = snapshot.data ?? [];
                final filtered = allServices.where((s) {
                  final query = _searchQuery.trim().toLowerCase();
                  final matchesQuery = query.isEmpty ||
                      s.name.toLowerCase().contains(query) ||
                      s.shortDescription.toLowerCase().contains(query) ||
                      s.category.toLowerCase().contains(query) ||
                      s.requiredSkills.any((k) => k.toLowerCase().contains(query));

                  final matchesCat = _selectedCategory == 'All' ||
                      s.category.toLowerCase() == _selectedCategory.toLowerCase() ||
                      s.name.toLowerCase().contains(_selectedCategory.toLowerCase());

                  return matchesQuery && matchesCat;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.handyman_outlined, size: 54, color: AppColors.textTertiary),
                          const SizedBox(height: 12),
                          Text(
                            allServices.isEmpty ? 'No Services Available' : 'No matching services found',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            allServices.isEmpty
                                ? 'Services will appear here once registered by an Administrator.'
                                : 'Try searching for a different keyword or switching categories.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final service = filtered[index];
                    return _buildFullServiceCard(service);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory.toLowerCase() == category.toLowerCase();
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(category),
        selected: isSelected,
        selectedColor: AppColors.primaryContainer,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedCategory = category);
          }
        },
      ),
    );
  }

  Widget _buildFullServiceCard(ServiceModel service) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.build_circle_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        service.category,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                service.priceRange ?? '₹250 - ₹500',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            service.shortDescription.isNotEmpty ? service.shortDescription : 'Professional household service delivered by verified cooperative members.',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          if (service.requiredSkills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: service.requiredSkills.map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(skill, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                );
              }).toList(),
            ),
          ],
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: const [
                    Icon(Icons.verified_rounded, size: 14, color: AppColors.statusVerified),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Cooperative Quality Assured',
                        style: TextStyle(fontSize: 11, color: AppColors.statusVerified, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(96, 36),
                ),
                icon: const Icon(Icons.calendar_month_rounded, size: 15),
                label: const Text('Book Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
