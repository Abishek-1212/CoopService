import 'package:flutter/material.dart';
import '../../models/cooperative_model.dart';
import '../../models/user_model.dart';
import '../theme/app_colors.dart';
import 'app_card.dart';

class CooperativeCard extends StatelessWidget {
  final CooperativeModel cooperative;
  final AppUser? headUser;
  final VoidCallback onTap;

  const CooperativeCard({
    super.key,
    required this.cooperative,
    this.headUser,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = cooperative.isActive;
    final bool hasHead = cooperative.hasHead && headUser != null;

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
                  color: AppColors.greenMint.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: AppColors.greenForest,
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
                            cooperative.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.greenDeep,
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
                      'Reg #: ${cooperative.registrationNumber}',
                      style: const TextStyle(
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
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.neuBorder),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.greenForest),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  cooperative.primaryServiceArea,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                cooperative.contactPhone,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F7F3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.neuBorder, width: 1.0),
            ),
            child: Row(
              children: [
                Icon(
                  hasHead ? Icons.verified_user_rounded : Icons.warning_amber_rounded,
                  size: 16,
                  color: hasHead ? AppColors.greenForest : AppColors.statusPending,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasHead
                        ? 'Head: ${headUser!.fullName}'
                        : 'No Cooperative Head Assigned',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasHead ? AppColors.greenDeep : AppColors.statusPending,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
