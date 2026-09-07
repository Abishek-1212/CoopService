import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CooperativeBookingsScreen extends StatelessWidget {
  final String? cooperativeId;

  const CooperativeBookingsScreen({
    super.key,
    this.cooperativeId,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'This is Booking Page',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
