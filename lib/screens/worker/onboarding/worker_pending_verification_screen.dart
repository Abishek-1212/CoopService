import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/primary_button.dart';
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
        backgroundColor: AppColors.backgroundMildGreen,
        body: Center(child: Text('User session not found.')),
      );
    }

    return StreamBuilder<CooperativeJoinRequestModel?>(
      stream: _verificationService.streamWorkerJoinRequest(user.uid),
      builder: (context, requestSnap) {
        if (requestSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundMildGreen,
            body: LoadingIndicator(message: 'Checking membership request status...'),
          );
        }

        final request = requestSnap.data;

        // If request was approved, refresh profile to route to WorkerDashboard
        if (request != null && request.isApproved) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            authProvider.refreshCurrentUser();
          });
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundMildGreen,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundMildGreen,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8F6EE), Color(0xFFD2EEDC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBCE0CC), width: 1.2),
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppColors.greenForest, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Membership Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.greenDeep,
                      letterSpacing: -0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.greenForest),
                tooltip: 'Refresh Status',
                onPressed: () {
                  authProvider.refreshCurrentUser();
                  setState(() {});
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () => authProvider.signOut(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 16),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusHeroCard(request, user),
                  const SizedBox(height: 18),

                  if (request != null && request.cooperativeId.isNotEmpty)
                    StreamBuilder<CooperativeModel?>(
                      stream: _cooperativeService.streamCooperativeById(request.cooperativeId),
                      builder: (context, coopSnap) {
                        final coop = coopSnap.data;
                        return _buildSocietySummaryCard(coop, request, user);
                      },
                    ),

                  const SizedBox(height: 18),
                  _buildRestrictedAccessInfoCard(),

                  const SizedBox(height: 18),
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
    Color statusBorderColor;
    IconData statusIcon;
    String statusTitle;
    String statusSubtitle;

    if (request == null) {
      statusColor = const Color(0xFFD97706);
      statusBgColor = const Color(0xFFFEF3C7);
      statusBorderColor = const Color(0xFFFDE68A);
      statusIcon = Icons.hourglass_top_rounded;
      statusTitle = 'Verification Pending';
      statusSubtitle = 'Your verification profile has been created. Awaiting Cooperative Head review.';
    } else if (request.isApproved) {
      statusColor = AppColors.greenForest;
      statusBgColor = const Color(0xFFE8F6EE);
      statusBorderColor = const Color(0xFFBCE0CC);
      statusIcon = Icons.verified_rounded;
      statusTitle = 'Membership Approved!';
      statusSubtitle = 'Your worker verification is complete! You can now start receiving customer jobs.';
    } else if (request.isRejected) {
      statusColor = const Color(0xFFDC2626);
      statusBgColor = const Color(0xFFFEE2E2);
      statusBorderColor = const Color(0xFFFECACA);
      statusIcon = Icons.cancel_rounded;
      statusTitle = 'Verification Request Rejected';
      statusSubtitle = 'The Cooperative Head was unable to verify your profile with the submitted documents.';
    } else if (request.isMoreInfoRequired) {
      statusColor = AppColors.primary;
      statusBgColor = const Color(0xFFE6F8F3);
      statusBorderColor = const Color(0xFFC7EFE4);
      statusIcon = Icons.info_rounded;
      statusTitle = 'More Information Required';
      statusSubtitle = 'The Cooperative Head has requested additional details or clearer documents.';
    } else {
      statusColor = const Color(0xFFD97706);
      statusBgColor = const Color(0xFFFEF3C7);
      statusBorderColor = const Color(0xFFFDE68A);
      statusIcon = Icons.hourglass_top_rounded;
      statusTitle = 'Verification Pending';
      statusSubtitle = 'Your membership request has been submitted successfully and is awaiting review.';
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDECE3), width: 1.2),
        boxShadow: [
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-2, -2),
            blurRadius: 5,
          ),
          BoxShadow(
            color: AppColors.greenDeep.withValues(alpha: 0.05),
            offset: const Offset(2, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: statusBgColor,
              shape: BoxShape.circle,
              border: Border.all(color: statusBorderColor, width: 2),
            ),
            child: Icon(statusIcon, size: 48, color: statusColor),
          ),
          const SizedBox(height: 16),
          Text(
            statusTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: statusColor,
              letterSpacing: -0.3,
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
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Reason for Rejection:',
                        style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFDC2626), fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.rejectionReason!,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF991B1B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: 'Update Profile & Resubmit',
              icon: Icons.edit_note_rounded,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WorkerVerificationScreen()),
                );
              },
            ),
          ],

          // Display More Info Requested message if applicable
          if (request != null && request.isMoreInfoRequired && request.requestedInfoMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F8F3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC7EFE4)),
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
                        style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.requestedInfoMessage!,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: 'Upload Documents & Resubmit',
              icon: Icons.upload_file_rounded,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WorkerVerificationScreen()),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSocietySummaryCard(CooperativeModel? coop, CooperativeJoinRequestModel request, dynamic user) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDECE3), width: 1.2),
        boxShadow: [
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-2, -2),
            blurRadius: 5,
          ),
          BoxShadow(
            color: AppColors.greenDeep.withValues(alpha: 0.05),
            offset: const Offset(2, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F6EE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.apartment_rounded, color: AppColors.greenForest, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Requested Cooperative Society',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenDeep,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8F6EE), Color(0xFFD2EEDC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBCE0CC)),
              ),
              child: const Icon(Icons.apartment_rounded, color: AppColors.greenForest, size: 22),
            ),
            title: Text(
              coop?.name ?? 'Cooperative Society',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.greenDeep),
            ),
            subtitle: Text(
              'Reg #: ${coop?.registrationNumber ?? "Pending"}\nPrimary Area: ${coop?.primaryServiceArea ?? "Local Unit"}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          const Divider(height: 20, color: Color(0xFFEEF5F1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Primary Trade:', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F6EE),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBCE0CC)),
                ),
                child: Text(
                  user.serviceCategory ?? 'Worker Trade',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.greenForest),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Submitted On:', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              Text(
                '${request.submittedAt.day}/${request.submittedAt.month}/${request.submittedAt.year}',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRestrictedAccessInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFEF9C3), Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Icon(Icons.lock_clock_outlined, color: Color(0xFFD97706), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Access Limitations While Pending',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF92400E)),
                ),
                SizedBox(height: 4),
                Text(
                  'To protect cooperative customers and ensure safety, customer jobs, booking requests, and earnings features unlock once your identity and trade skills are certified by the Cooperative Head.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF78350F), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedDocumentsPreview(dynamic user, CooperativeJoinRequestModel? request) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDECE3), width: 1.2),
        boxShadow: [
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-2, -2),
            blurRadius: 5,
          ),
          BoxShadow(
            color: AppColors.greenDeep.withValues(alpha: 0.05),
            offset: const Offset(2, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F6EE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.folder_shared_rounded, color: AppColors.greenForest, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Submitted Documents',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.greenDeep,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WorkerVerificationScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F6EE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBCE0CC)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.edit_rounded, size: 12, color: AppColors.greenForest),
                      SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.greenForest),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDocTile(
            icon: Icons.credit_card_outlined,
            title: '${user.identityType ?? "Govt ID"} Proof',
            subtitle: user.identityDocumentUrl != null && user.identityDocumentUrl!.isNotEmpty
                ? 'Document uploaded securely'
                : 'Not uploaded',
            hasFile: user.identityDocumentUrl != null && user.identityDocumentUrl!.isNotEmpty,
          ),
          const Divider(height: 16, color: Color(0xFFEEF5F1)),
          _buildDocTile(
            icon: Icons.home_outlined,
            title: 'Address Proof',
            subtitle: user.addressProofUrl != null && user.addressProofUrl!.isNotEmpty
                ? 'Document uploaded securely'
                : 'Not uploaded',
            hasFile: user.addressProofUrl != null && user.addressProofUrl!.isNotEmpty,
          ),
          const Divider(height: 16, color: Color(0xFFEEF5F1)),
          _buildDocTile(
            icon: Icons.workspace_premium_outlined,
            title: 'Skill & Professional Certificates',
            subtitle: user.skillCertificateUrls != null && user.skillCertificateUrls!.isNotEmpty
                ? '${user.skillCertificateUrls!.length} certificate(s) on file'
                : 'Optional / None uploaded',
            hasFile: user.skillCertificateUrls != null && user.skillCertificateUrls!.isNotEmpty,
          ),
        ],
      ),
    );
  }

  Widget _buildDocTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool hasFile,
  }) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: hasFile ? const Color(0xFFE8F6EE) : const Color(0xFFF3F8F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: hasFile ? const Color(0xFFBCE0CC) : const Color(0xFFDDECE3)),
        ),
        child: Icon(icon, color: hasFile ? AppColors.greenForest : AppColors.textSecondary, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      trailing: Icon(
        hasFile ? Icons.check_circle_rounded : Icons.info_outline_rounded,
        color: hasFile ? AppColors.greenForest : AppColors.textTertiary,
        size: 18,
      ),
    );
  }
}
