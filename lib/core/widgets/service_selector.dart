import 'package:flutter/material.dart';
import '../../models/service_model.dart';
import '../../services/service_management_service.dart';
import '../theme/app_colors.dart';
import 'loading_indicator.dart';

class ServiceSelector extends StatefulWidget {
  final List<String> selectedServiceIds;
  final ValueChanged<List<String>> onChanged;
  final bool showHeader;

  const ServiceSelector({
    super.key,
    required this.selectedServiceIds,
    required this.onChanged,
    this.showHeader = true,
  });

  @override
  State<ServiceSelector> createState() => _ServiceSelectorState();
}

class _ServiceSelectorState extends State<ServiceSelector> {
  final ServiceManagementService _serviceManagementService =
      ServiceManagementService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Services Offered *',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.selectedServiceIds.length} Selected',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Select all services available in this cooperative society. (Only active services are shown)',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
        ],

        // Search Field for Services
        TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() {
              _searchQuery = val.trim().toLowerCase();
            });
          },
          decoration: InputDecoration(
            hintText: 'Search available services...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 12),

        // Stream Active Services from Firestore
        StreamBuilder<List<ServiceModel>>(
          stream: _serviceManagementService.streamActiveServices(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingIndicator(message: 'Loading active services...');
            }

            final activeServices = snapshot.data ?? [];

            if (activeServices.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: AppColors.statusPending, size: 32),
                    SizedBox(height: 8),
                    Text(
                      'No Active Services Available',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'An Administrator must create active services in the Service Master Catalog first.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }

            final filteredServices = activeServices.where((s) {
              if (_searchQuery.isEmpty) return true;
              return s.name.toLowerCase().contains(_searchQuery) ||
                  s.category.toLowerCase().contains(_searchQuery) ||
                  s.shortDescription.toLowerCase().contains(_searchQuery);
            }).toList();

            if (filteredServices.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No active services match your search.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              );
            }

            return Container(
              constraints: const BoxConstraints(maxHeight: 280),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: filteredServices.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final service = filteredServices[idx];
                  final isChecked = widget.selectedServiceIds.contains(service.id);

                  return CheckboxListTile(
                    value: isChecked,
                    activeColor: AppColors.primary,
                    dense: true,
                    title: Text(
                      service.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isChecked ? FontWeight.w700 : FontWeight.w500,
                        color: isChecked ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '${service.category} • ${service.shortDescription}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    onChanged: (bool? selected) {
                      final updated = List<String>.from(widget.selectedServiceIds);
                      if (selected == true) {
                        if (!updated.contains(service.id)) {
                          updated.add(service.id);
                        }
                      } else {
                        updated.remove(service.id);
                      }
                      widget.onChanged(updated);
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
