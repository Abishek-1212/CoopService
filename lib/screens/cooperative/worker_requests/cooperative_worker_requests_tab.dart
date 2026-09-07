import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_image_helper.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../models/cooperative_join_request_model.dart';
import '../../../services/service_management_service.dart';
import '../../../services/worker_verification_service.dart';
import 'worker_request_detail_screen.dart';

class CooperativeWorkerRequestsTab extends StatefulWidget {
  final String? cooperativeId;

  const CooperativeWorkerRequestsTab({
    super.key,
    required this.cooperativeId,
  });

  @override
  State<CooperativeWorkerRequestsTab> createState() => _CooperativeWorkerRequestsTabState();
}

class _CooperativeWorkerRequestsTabState extends State<CooperativeWorkerRequestsTab>
    with SingleTickerProviderStateMixin {
  final WorkerVerificationService _verificationService = WorkerVerificationService();
  final ServiceManagementService _serviceService = ServiceManagementService();

  late TabController _tabController;
  Map<String, String> _serviceNames = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadServices();
  }

  Future<void> _loadServices() async {
    final services = await _serviceService.streamActiveServices().first;
    if (mounted) {
      setState(() {
        _serviceNames = {for (var s in services) s.id: s.name};
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cooperativeId == null || widget.cooperativeId!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.warning_amber_rounded, size: 48, color: AppColors.statusPending),
              SizedBox(height: 12),
              Text(
                'No Cooperative Society Assigned',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                'You must be assigned as the Head of a Cooperative Society by an Administrator to manage worker requests.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<List<CooperativeJoinRequestModel>>(
      stream: _verificationService.streamRequestsForCooperative(widget.cooperativeId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator(message: 'Loading worker requests...');
        }

        final allRequests = snapshot.data ?? [];
        final pendingRequests = allRequests.where((r) => r.isPending || r.isMoreInfoRequired).toList();
        final approvedRequests = allRequests.where((r) => r.isApproved).toList();
        final rejectedRequests = allRequests.where((r) => r.isRejected).toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Worker Verification Requests'),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Pending'),
                      if (pendingRequests.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.statusPending,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${pendingRequests.length}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(text: 'Approved (${approvedRequests.length})'),
                Tab(text: 'Rejected (${rejectedRequests.length})'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildRequestsList(pendingRequests, isPendingTab: true),
              _buildRequestsList(approvedRequests, isPendingTab: false),
              _buildRequestsList(rejectedRequests, isPendingTab: false),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestsList(List<CooperativeJoinRequestModel> requests, {required bool isPendingTab}) {
    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.people_outline_rounded, size: 52, color: AppColors.textTertiary),
              SizedBox(height: 12),
              Text(
                'No requests in this category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              SizedBox(height: 4),
              Text(
                'Worker membership applications sent to this cooperative society will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final req = requests[index];
        final serviceName = _serviceNames[req.primaryServiceId] ?? 'Service';

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primaryContainer,
                    backgroundImage: AppImageHelper.getImageProvider(req.profilePhotoUrl),
                    child: req.profilePhotoUrl == null || req.profilePhotoUrl!.isEmpty
                        ? Text(
                            req.workerName.isNotEmpty ? req.workerName[0].toUpperCase() : 'W',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.workerName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          serviceName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${req.workerCity ?? "City"}, ${req.workerDistrict ?? "District"}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(req.status),
                ],
              ),
              const Divider(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Phone: ${req.workerPhone}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  Text(
                    'Date: ${req.submittedAt.day}/${req.submittedAt.month}/${req.submittedAt.year}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WorkerRequestDetailScreen(request: req),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 38),
                      ),
                    ),
                  ),
                  if (isPendingTab) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WorkerRequestDetailScreen(request: req),
                          ),
                        );
                      },
                      icon: const Icon(Icons.verified_user_outlined, size: 16),
                      label: const Text('Review & Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(140, 38),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }
}
