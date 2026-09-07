import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../providers/auth_provider.dart';
import '../admin/admin_dashboard.dart';
import '../cooperative/cooperative_dashboard.dart';
import '../customer/customer_dashboard.dart';
import '../worker/onboarding/worker_pending_verification_screen.dart';
import '../worker/onboarding/worker_verification_screen.dart';
import '../worker/worker_dashboard.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'role_error_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    debugPrint('>>> [AuthWrapper] status=${authProvider.status}, user=${authProvider.currentUser?.email}, role=${authProvider.currentUser?.role}');

    switch (authProvider.status) {
      case AuthStatus.initial:
      case AuthStatus.loadingProfile:
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: LoadingIndicator(
            message: 'Loading CoopService session...',
          ),
        );

      case AuthStatus.unauthenticated:
      case AuthStatus.authenticating:
        return const LoginScreen();

      case AuthStatus.needsProfileCompletion:
        return const RegisterScreen();

      case AuthStatus.error:
        return RoleErrorScreen(
          message: authProvider.errorMessage,
        );

      case AuthStatus.authenticated:
        final user = authProvider.currentUser;
        if (user == null) {
          return const RoleErrorScreen(
            message: 'User session active, but Firestore profile snapshot could not be found.',
          );
        }

        final role = user.role.toLowerCase().trim();
        switch (role) {
          case AppConstants.roleCustomer:
            return const CustomerDashboard();
          case AppConstants.roleWorker:
            if (user.membershipStatus == AppConstants.membershipApproved &&
                user.verificationStatus == AppConstants.statusVerified) {
              return const WorkerDashboard();
            } else if (user.membershipStatus == AppConstants.membershipPending ||
                user.membershipStatus == AppConstants.membershipMoreInfoRequired ||
                user.membershipStatus == AppConstants.membershipRejected) {
              return const WorkerPendingVerificationScreen();
            } else {
              return const WorkerVerificationScreen();
            }
          case AppConstants.roleCooperativeHead:
            return const CooperativeDashboard();
          case AppConstants.roleAdmin:
            return const AdminDashboard();
          default:
            return RoleErrorScreen(
              message: 'Invalid role "${user.role}" found in Cloud Firestore.',
            );
        }
    }
  }
}
