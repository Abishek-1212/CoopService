import 'package:flutter/material.dart';
import '../../models/cooperative_model.dart';
import '../../models/service_model.dart';
import '../../services/cooperative_service.dart';
import '../theme/app_colors.dart';
import 'app_card.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleStatus;

  const ServiceCard({
    super.key,
    required this.service,
    required this.onTap,
    this.onEdit,
    this.onToggleStatus,
  });

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('electric')) return Icons.bolt_rounded;
    if (cat.contains('plumb')) return Icons.water_drop_rounded;
    if (cat.contains('clean')) return Icons.cleaning_services_rounded;
    if (cat.contains('paint')) return Icons.format_paint_rounded;
    if (cat.contains('garden')) return Icons.yard_rounded;
    if (cat.contains('transport') || cat.contains('logistics') || cat.contains('driver')) return Icons.directions_car_rounded;
    if (cat.contains('care') || cat.contains('person')) return Icons.volunteer_activism_rounded;
    if (cat.contains('tech') || cat.contains('appliance')) return Icons.build_circle_rounded;
    if (cat.contains('security')) return Icons.security_rounded;
    if (cat.contains('construct') || cat.contains('mason')) return Icons.foundation_rounded;
    return Icons.handyman_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = service.isActive;
    final CooperativeService coopService = CooperativeService();

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(service.category),
                  color: AppColors.primary,
                  size: 26,
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
                            service.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.statusVerifiedBg : AppColors.statusErrorBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isActive ? AppColors.statusVerified : AppColors.statusError,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      service.category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            service.shortDescription,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: StreamBuilder<List<CooperativeModel>>(
                  stream: coopService.streamCooperativesByServiceId(service.id),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    return Row(
                      children: [
                        const Icon(Icons.apartment_outlined, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '$count ${count == 1 ? "Society" : "Societies"} Offering',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (service.priceRange != null && service.priceRange!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    service.priceRange!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
