import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case AppConstants.statusVerified:
        bg = AppColors.statusVerifiedBg;
        fg = AppColors.statusVerified;
        label = 'Verified Worker';
        icon = Icons.verified_rounded;
        break;
      case AppConstants.statusRejected:
        bg = AppColors.statusErrorBg;
        fg = AppColors.statusError;
        label = 'Verification Declined';
        icon = Icons.cancel_outlined;
        break;
      case AppConstants.statusPending:
      default:
        bg = AppColors.statusPendingBg;
        fg = AppColors.statusPending;
        label = 'Verification Pending';
        icon = Icons.hourglass_top_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
