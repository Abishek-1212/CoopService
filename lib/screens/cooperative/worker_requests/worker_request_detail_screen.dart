import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_image_helper.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/cooperative_join_request_model.dart';
import '../../../models/service_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/service_management_service.dart';
import '../../../services/worker_verification_service.dart';

class WorkerRequestDetailScreen extends StatefulWidget {
  final CooperativeJoinRequestModel request;

  const WorkerRequestDetailScreen({
    super.key,
    required this.request,
  });

  @override
  State<WorkerRequestDetailScreen> createState() => _WorkerRequestDetailScreenState();
}

class _WorkerRequestDetailScreenState extends State<WorkerRequestDetailScreen> {
  final WorkerVerificationService _verificationService = WorkerVerificationService();
  final ServiceManagementService _serviceService = ServiceManagementService();

  late CooperativeJoinRequestModel _request;
  ServiceModel? _primaryService;
  bool _isProcessingAction = false;

  @override
  void initState() {
    super.initState();
    _request = widget.request;
    _loadPrimaryService();
  }

  Future<void> _loadPrimaryService() async {
    final s = await _serviceService.getServiceById(_request.primaryServiceId);
    if (mounted) {
      setState(() {
        _primaryService = s;
      });
    }
  }

  void _showImageDocumentPreview(String title, String? url) {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document has no valid preview URL.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppBar(
                title: Text(title, style: const TextStyle(fontSize: 16)),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: AppImageHelper.buildImage(
                      url,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmApprove() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.verified_user_rounded, color: AppColors.statusVerified),
              SizedBox(width: 8),
              Text('Approve Worker'),
            ],
          ),
          content: Text(
            'Are you sure you want to approve ${_request.workerName} as a verified worker of your cooperative society?\n\nThis will link the worker to your cooperative and allow them to start receiving customer jobs.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                await _executeApproval();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusVerified,
                foregroundColor: Colors.white,
              ),
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeApproval() async {
    final head = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (head == null) return;

    setState(() {
      _isProcessingAction = true;
    });

    try {
      await _verificationService.approveWorkerRequest(
        requestId: _request.requestId,
        workerId: _request.workerId,
        cooperativeId: _request.cooperativeId,
        cooperativeHeadId: head.uid,
        primaryServiceId: _request.primaryServiceId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_request.workerName} has been approved successfully!'),
            backgroundColor: AppColors.statusVerified,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approval failed: $e'),
            backgroundColor: AppColors.statusError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAction = false;
        });
      }
    }
  }

  void _showRejectDialog() {
    String selectedReason = 'Invalid Identity Proof';
    final customReasonController = TextEditingController();

    final List<String> reasons = [
      'Invalid Identity Proof',
      'Documents Not Clear',
      'Skill Certificate Missing',
      'Service Not Available',
      'Outside Service Area',
      'Information Mismatch',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.cancel_outlined, color: AppColors.statusError),
                  SizedBox(width: 8),
                  Text('Reject Worker Request'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select a reason for rejecting this verification request:',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedReason,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Rejection Reason',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: reasons
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    selectedItemBuilder: (BuildContext context) {
                      return reasons.map((r) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(r, overflow: TextOverflow.ellipsis, maxLines: 1),
                        );
                      }).toList();
                    },
                    onChanged: (v) {
                      if (v != null) {
                        setModalState(() {
                          selectedReason = v;
                        });
                      }
                    },
                  ),
                  if (selectedReason == 'Other') ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: customReasonController,
                      decoration: InputDecoration(
                        labelText: 'Specify Reason',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final finalReason = selectedReason == 'Other' && customReasonController.text.trim().isNotEmpty
                        ? customReasonController.text.trim()
                        : selectedReason;

                    Navigator.pop(dialogCtx);
                    await _executeRejection(finalReason);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusError,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Reject Request'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _executeRejection(String reason) async {
    final head = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (head == null) return;

    setState(() {
      _isProcessingAction = true;
    });

    try {
      await _verificationService.rejectWorkerRequest(
        requestId: _request.requestId,
        workerId: _request.workerId,
        cooperativeHeadId: head.uid,
        rejectionReason: reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request rejected. Worker has been notified.'),
            backgroundColor: AppColors.statusError,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rejection failed: $e'),
            backgroundColor: AppColors.statusError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAction = false;
        });
      }
    }
  }

  void _showRequestMoreInfoDialog() {
    final messageController = TextEditingController(
      text: 'Please upload a clearer copy of your identity proof and skill certificate.',
    );

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.info_outline, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Request Information'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Explain what document or detail the worker needs to provide or correct:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                decoration: InputDecoration(
                  labelText: 'Instruction to Worker',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final msg = messageController.text.trim();
                if (msg.isEmpty) return;

                Navigator.pop(dialogCtx);
                await _executeRequestMoreInfo(msg);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Send Message'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeRequestMoreInfo(String message) async {
    final head = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (head == null) return;

    setState(() {
      _isProcessingAction = true;
    });

    try {
      await _verificationService.requestMoreInformation(
        requestId: _request.requestId,
        workerId: _request.workerId,
        cooperativeHeadId: head.uid,
        message: message,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Requested more information from worker.'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update request: $e'),
            backgroundColor: AppColors.statusError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAction = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceTitle = _primaryService?.name ?? 'Loading...';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${_request.workerName} Details'),
      ),
      body: _isProcessingAction
          ? const LoadingIndicator(message: 'Updating worker verification status...')
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card with Worker Profile
                    AppCard(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AppColors.primaryContainer,
                            backgroundImage: AppImageHelper.getImageProvider(_request.profilePhotoUrl),
                            child: _request.profilePhotoUrl == null || _request.profilePhotoUrl!.isEmpty
                                ? const Icon(Icons.person_rounded, size: 36, color: AppColors.primary)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _request.workerName,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  serviceTitle,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${_request.workerCity ?? ""}, ${_request.workerDistrict ?? ""}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _buildStatusBadge(_request.status),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // SECTION 1: WORKER PROFILE
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WORKER PROFILE',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(Icons.person_outline, 'Full Name', _request.workerName),
                          _buildDetailRow(Icons.email_outlined, 'Email', _request.workerEmail),
                          _buildDetailRow(Icons.phone_outlined, 'Phone Number', _request.workerPhone),
                          _buildDetailRow(
                            Icons.home_outlined,
                            'Address',
                            '${_request.workerCity ?? ""}, ${_request.workerDistrict ?? ""}, ${_request.workerState ?? ""}',
                          ),
                          _buildDetailRow(Icons.pin_drop_outlined, 'Pincode', _request.workerPincode ?? 'N/A'),
                          _buildDetailRow(Icons.handyman_outlined, 'Primary Service', serviceTitle),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // SECTION 2: IDENTITY DOCUMENTS
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'IDENTITY DOCUMENTS',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          const SizedBox(height: 12),
                          _buildDocumentTile(
                            title: '${_request.identityType ?? "Government ID"} Proof',
                            url: _request.identityDocumentUrl,
                            icon: Icons.credit_card_outlined,
                          ),
                          const Divider(),
                          _buildDocumentTile(
                            title: 'Address Proof',
                            url: _request.addressProofUrl,
                            icon: Icons.home_work_outlined,
                          ),
                          if (_request.profilePhotoUrl != null && _request.profilePhotoUrl!.isNotEmpty) ...[
                            const Divider(),
                            _buildDocumentTile(
                              title: 'Profile Photograph',
                              url: _request.profilePhotoUrl,
                              icon: Icons.face_rounded,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // SECTION 3: SKILL & PROFESSIONAL DOCUMENTS
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SKILL DOCUMENTS',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          const SizedBox(height: 12),
                          if (_request.skillCertificateUrls.isNotEmpty)
                            ..._request.skillCertificateUrls.asMap().entries.map((entry) {
                              return Column(
                                children: [
                                  if (entry.key > 0) const Divider(),
                                  _buildDocumentTile(
                                    title: 'Skill / Professional Certificate #${entry.key + 1}',
                                    url: entry.value,
                                    icon: Icons.workspace_premium_outlined,
                                  ),
                                ],
                              );
                            })
                          else
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'No professional trade certificates uploaded.',
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ),
                          if (_request.experienceCertificateUrls.isNotEmpty) ...[
                            const Divider(),
                            ..._request.experienceCertificateUrls.map((url) {
                              return _buildDocumentTile(
                                title: 'Experience Certificate',
                                url: url,
                                icon: Icons.military_tech_outlined,
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // SECTION 4: COOPERATIVE REQUEST DETAILS
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'COOPERATIVE REQUEST DETAILS',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            Icons.calendar_today_outlined,
                            'Submitted Date',
                            '${_request.submittedAt.day}/${_request.submittedAt.month}/${_request.submittedAt.year}',
                          ),
                          _buildDetailRow(Icons.rule_folder_outlined, 'Request Status', _request.status.toUpperCase()),
                          if (_request.rejectionReason != null)
                            _buildDetailRow(Icons.cancel_outlined, 'Rejection Reason', _request.rejectionReason!),
                          if (_request.requestedInfoMessage != null)
                            _buildDetailRow(Icons.message_outlined, 'Cooperative Head Note', _request.requestedInfoMessage!),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons (Visible only if request is pending or more info required)
                    if (_request.isPending || _request.isMoreInfoRequired) ...[
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              text: 'Approve Worker',
                              icon: Icons.check_circle_rounded,
                              backgroundColor: AppColors.statusVerified,
                              onPressed: _confirmApprove,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _showRejectDialog,
                              icon: const Icon(Icons.cancel_rounded, color: AppColors.statusError),
                              label: const Text('Reject Request', style: TextStyle(color: AppColors.statusError)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.statusError),
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _showRequestMoreInfoDialog,
                              icon: const Icon(Icons.info_outline, color: AppColors.primary),
                              label: const Text('Request More Info', style: TextStyle(color: AppColors.primary)),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case AppConstants.membershipApproved:
        bg = AppColors.statusVerifiedBg;
        text = AppColors.statusVerified;
        label = 'Approved';
        break;
      case AppConstants.membershipRejected:
        bg = AppColors.statusErrorBg;
        text = AppColors.statusError;
        label = 'Rejected';
        break;
      case AppConstants.membershipMoreInfoRequired:
        bg = AppColors.primaryContainer;
        text = AppColors.primary;
        label = 'More Info';
        break;
      default:
        bg = AppColors.statusPendingBg;
        text = AppColors.statusPending;
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: text),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTile({
    required String title,
    required String? url,
    required IconData icon,
  }) {
    final bool hasUrl = url != null && url.isNotEmpty;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: hasUrl ? AppColors.primaryContainer : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: hasUrl ? AppColors.primary : AppColors.textTertiary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(
        hasUrl ? 'Document uploaded' : 'Not provided',
        style: TextStyle(fontSize: 11, color: hasUrl ? AppColors.statusVerified : AppColors.textTertiary),
      ),
      trailing: hasUrl
          ? OutlinedButton.icon(
              onPressed: () => _showImageDocumentPreview(title, url),
              icon: const Icon(Icons.visibility_outlined, size: 14),
              label: const Text('View', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
              ),
            )
          : null,
    );
  }
}
