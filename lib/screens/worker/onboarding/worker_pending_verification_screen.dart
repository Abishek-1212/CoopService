import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../models/cooperative_join_request_model.dart';
import '../../../models/cooperative_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/cooperative_service.dart';
import '../../../services/worker_verification_service.dart';
import 'worker_verification_screen.dart';

class WorkerPendingVerificationScreen extends StatefulWidget {
  const WorkerPendingVerificationScreen({super.key});

  @override
  State<WorkerPendingVerificationScreen> createState() => _WorkerPendingVerificationScreenState();
}

class _WorkerPendingVerificationScreenState extends State<WorkerPendingVerificationScreen> {
  final WorkerVerificationService _verificationService = WorkerVerificationService();
  final CooperativeService _cooperativeService = CooperativeService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User session not found.')),
      );
    }

    return StreamBuilder<CooperativeJoinRequestModel?>(
      stream: _verificationService.streamWorkerJoinRequest(user.uid),
      builder: (context, requestSnap) {
        if (requestSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: LoadingIndicator(message: 'Checking membership request status...'),
          );
        }

        final request = requestSnap.data;

        // If request was approved and user refreshed, AuthWrapper will automatically route to WorkerDashboard.
        if (request != null && request.isApproved) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            authProvider.refreshCurrentUser();
          });
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Verification & Membership Status'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh Status',
                onPressed: () {
                  authProvider.refreshCurrentUser();
                  setState(() {});
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: AppColors.statusError),
                tooltip: 'Sign Out',
                onPressed: () => authProvider.signOut(),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusHeroCard(request, user),
                  const SizedBox(height: 20),

                  if (request != null && request.cooperativeId.isNotEmpty)
                    StreamBuilder<CooperativeModel?>(
                      stream: _cooperativeService.streamCooperativeById(request.cooperativeId),
                      builder: (context, coopSnap) {
                        final coop = coopSnap.data;
                        return _buildSocietySummaryCard(coop, request, user);
                      },
                    ),

                  const SizedBox(height: 20),
                  _buildRestrictedAccessInfoCard(),

                  const SizedBox(height: 20),
                  _buildSubmittedDocumentsPreview(user, request),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusHeroCard(CooperativeJoinRequestModel? request, dynamic user) {
    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;
    String statusTitle;
    String statusSubtitle;

    if (request == null) {
      statusColor = AppColors.statusPending;
      statusBgColor = AppColors.statusPendingBg;
      statusIcon = Icons.hourglass_top_rounded;
      statusTitle = 'Verification Pending';
      statusSubtitle = 'Your verification profile has been created. Awaiting Cooperative Head review.';
    } else if (request.isApproved) {
      statusColor = AppColors.statusVerified;
      statusBgColor = AppColors.statusVerifiedBg;
      statusIcon = Icons.verified_rounded;
      statusTitle = 'Membership Approved!';
      statusSubtitle = 'Your worker verification is complete! You can now start receiving customer jobs.';
    } else if (request.isRejected) {
      statusColor = AppColors.statusError;
      statusBgColor = AppColors.statusErrorBg;
      statusIcon = Icons.cancel_rounded;
      statusTitle = 'Verification Request Rejected';
      statusSubtitle = 'The Cooperative Head was unable to verify your profile with the submitted documents.';
    } else if (request.isMoreInfoRequired) {
      statusColor = AppColors.primary;
      statusBgColor = AppColors.primaryContainer;
      statusIcon = Icons.info_rounded;
      statusTitle = 'More Information Required';
      statusSubtitle = 'The Cooperative Head has requested additional details or clearer documents.';
    } else {
      statusColor = AppColors.statusPending;
      statusBgColor = AppColors.statusPendingBg;
      statusIcon = Icons.hourglass_top_rounded;
      statusTitle = 'Verification Pending';
      statusSubtitle = 'Your membership request has been submitted successfully and is awaiting review.';
    }

    return AppCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: statusBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, size: 52, color: statusColor),
          ),
          const SizedBox(height: 14),
          Text(
            statusTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            statusSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),

          // Display Rejection Reason if rejected
          if (request != null && request.isRejected && request.rejectionReason != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.statusErrorBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.statusError),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: AppColors.statusError, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Reason for Rejection:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.statusError, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.rejectionReason!,
                    style: const TextStyle(fontSize: 13, color: AppColors.statusError),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WorkerVerificationScreen()),
                );
              },
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('Update Profile & Resubmit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ],

          // Display More Info Requested message if applicable
          if (request != null && request.isMoreInfoRequired && request.requestedInfoMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.message_outlined, color: AppColors.primary, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Message from Cooperative Head:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.requestedInfoMessage!,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WorkerVerificationScreen()),
                );
              },
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Upload Requested Documents & Resubmit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSocietySummaryCard(CooperativeModel? coop, CooperativeJoinRequestModel request, dynamic user) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Requested Cooperative Society',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.apartment_rounded, color: AppColors.primary),
            ),
            title: Text(
              coop?.name ?? 'Cooperative Society',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              'Registration #: ${coop?.registrationNumber ?? "Pending"}\nPrimary Service Area: ${coop?.primaryServiceArea ?? "Local Unit"}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Primary Trade:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Text(
                user.serviceCategory ?? 'Worker Trade',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Submitted On:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Text(
                '${request.submittedAt.day}/${request.submittedAt.month}/${request.submittedAt.year}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRestrictedAccessInfoCard() {
    return AppCard(
      backgroundColor: AppColors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.statusPendingBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_clock_outlined, color: AppColors.statusPending, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Access Limitations While Pending',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                ),
                SizedBox(height: 4),
                Text(
                  'To protect cooperative customers and ensure safety, customer jobs, booking requests, and earnings features are locked until your identity and trade skills are verified by the Cooperative Head.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedDocumentsPreview(dynamic user, CooperativeJoinRequestModel? request) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Submitted Documents',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WorkerVerificationScreen()),
                  );
                },
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Edit', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListTile(
            dense: true,
            leading: const Icon(Icons.credit_card_outlined, color: AppColors.primary),
            title: Text('${user.identityType ?? "Govt ID"} Proof'),
            subtitle: Text(user.identityDocumentUrl != null && user.identityDocumentUrl!.isNotEmpty
                ? 'Document uploaded securely'
                : 'Not uploaded'),
            trailing: const Icon(Icons.check_circle, color: AppColors.statusVerified, size: 18),
          ),
          const Divider(),
          ListTile(
            dense: true,
            leading: const Icon(Icons.home_outlined, color: AppColors.primary),
            title: const Text('Address Proof'),
            subtitle: Text(user.addressProofUrl != null && user.addressProofUrl!.isNotEmpty
                ? 'Document uploaded securely'
                : 'Not uploaded'),
            trailing: const Icon(Icons.check_circle, color: AppColors.statusVerified, size: 18),
          ),
          const Divider(),
          ListTile(
            dense: true,
            leading: const Icon(Icons.workspace_premium_outlined, color: AppColors.primary),
            title: const Text('Skill & Professional Certificates'),
            subtitle: Text(user.skillCertificateUrls != null && user.skillCertificateUrls!.isNotEmpty
                ? '${user.skillCertificateUrls!.length} certificate(s) on file'
                : 'Optional / None uploaded'),
            trailing: Icon(
              user.skillCertificateUrls != null && user.skillCertificateUrls!.isNotEmpty
                  ? Icons.check_circle
                  : Icons.info_outline,
              color: user.skillCertificateUrls != null && user.skillCertificateUrls!.isNotEmpty
                  ? AppColors.statusVerified
                  : AppColors.textTertiary,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
