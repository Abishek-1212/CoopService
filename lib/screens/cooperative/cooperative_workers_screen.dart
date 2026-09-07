import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_image_helper.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../models/cooperative_join_request_model.dart';
import '../../models/cooperative_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/service_management_service.dart';
import '../../services/worker_verification_service.dart';
import 'worker_requests/worker_request_detail_screen.dart';

class CooperativeWorkersScreen extends StatefulWidget {
  final String? cooperativeId;

  const CooperativeWorkersScreen({
    super.key,
    this.cooperativeId,
  });

  @override
  State<CooperativeWorkersScreen> createState() => _CooperativeWorkersScreenState();
}

class _CooperativeWorkersScreenState extends State<CooperativeWorkersScreen>
    with SingleTickerProviderStateMixin {
  final WorkerVerificationService _verificationService = WorkerVerificationService();
  final ServiceManagementService _serviceService = ServiceManagementService();

  late TabController _tabController;

  CooperativeModel? _activeCooperative;
  List<CooperativeModel> _allCooperatives = [];
  bool _isLoadingCooperative = true;
  String _workerSearchQuery = '';
  String? _selectedFilterService;
  Map<String, String> _serviceNameMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    // 1. Load active services mapping
    try {
      final services = await _serviceService.streamActiveServices().first;
      _serviceNameMap = {for (var s in services) s.id: s.name};
    } catch (_) {}

    // 2. Resolve cooperative for this head
    if (user != null) {
      final coop = await _verificationService.getCooperativeForHead(
        user.uid,
        preferredCooperativeId: widget.cooperativeId ?? user.cooperativeId,
      );

      // Also get list of active cooperatives so head can switch if needed
      try {
        final all = await _verificationService.streamActiveCooperatives().first;
        _allCooperatives = all;
      } catch (_) {}

      if (mounted) {
        setState(() {
          _activeCooperative = coop;
          _isLoadingCooperative = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingCooperative = false;
        });
      }
    }
  }

  void _showSwitchSocietyDialog() {
    if (_allCooperatives.isEmpty) return;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Switch Cooperative Society'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _allCooperatives.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final c = _allCooperatives[index];
                final isSelected = c.id == _activeCooperative?.id;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected ? AppColors.primary : AppColors.primaryContainer,
                    child: Icon(
                      Icons.apartment_rounded,
                      color: isSelected ? Colors.white : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    c.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${c.district ?? "District"} • Reg: ${c.registrationNumber}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                  onTap: () {
                    setState(() {
                      _activeCooperative = c;
                    });
                    Navigator.pop(dialogCtx);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showWorkerDetailsModal(AppUser worker) {
    final primaryService = _serviceNameMap[worker.primaryServiceId] ??
        worker.serviceCategory ??
        'Service Professional';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Worker Profile & Verification',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Profile Banner
                        AppCard(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: AppColors.primaryContainer,
                                backgroundImage: AppImageHelper.getImageProvider(worker.profilePhotoUrl),
                                child: worker.profilePhotoUrl == null || worker.profilePhotoUrl!.isEmpty
                                    ? Text(
                                        worker.fullName.isNotEmpty ? worker.fullName[0].toUpperCase() : 'W',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: AppColors.primary),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      worker.fullName,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryContainer,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        primaryService,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.statusVerifiedBg,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.verified_rounded, size: 12, color: AppColors.statusVerified),
                                          SizedBox(width: 4),
                                          Text(
                                            'Verified Society Member',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.statusVerified),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Contact & Location Details
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Contact & Address Information',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.phone_outlined, 'Phone', worker.phone),
                              _buildInfoRow(Icons.email_outlined, 'Email', worker.email),
                              _buildInfoRow(Icons.location_on_outlined, 'Location', '${worker.city ?? ""}, ${worker.district ?? ""}'),
                              if (worker.fullAddress != null && worker.fullAddress!.isNotEmpty)
                                _buildInfoRow(Icons.home_outlined, 'Address', worker.fullAddress!),
                              if (worker.state != null && worker.state!.isNotEmpty)
                                _buildInfoRow(Icons.map_outlined, 'State & PIN', '${worker.state}, ${worker.pincode ?? ""}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Professional Details
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Experience & Qualifications',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.work_outline, 'Experience', '${worker.yearsOfExperience ?? worker.experience ?? "0"} years'),
                              if (worker.languagesKnown != null && worker.languagesKnown!.isNotEmpty)
                                _buildInfoRow(Icons.language_outlined, 'Languages', worker.languagesKnown!.join(', ')),
                              if (worker.bio != null && worker.bio!.isNotEmpty)
                                _buildInfoRow(Icons.description_outlined, 'Bio', worker.bio!),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Verification Documents & Proofs
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Verification Documents & Proofs',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              if (worker.identityDocumentUrl != null && worker.identityDocumentUrl!.isNotEmpty)
                                _buildDocumentPreviewTile(
                                  title: 'Government Identity (${worker.identityType ?? "Govt ID"})',
                                  url: worker.identityDocumentUrl!,
                                  icon: Icons.badge_outlined,
                                ),
                              if (worker.addressProofUrl != null && worker.addressProofUrl!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                _buildDocumentPreviewTile(
                                  title: 'Address Proof Document',
                                  url: worker.addressProofUrl!,
                                  icon: Icons.receipt_long_outlined,
                                ),
                              ],
                              if (worker.skillCertificateUrls != null && worker.skillCertificateUrls!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                for (int i = 0; i < worker.skillCertificateUrls!.length; i++)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: _buildDocumentPreviewTile(
                                      title: 'Skill / Trade Certificate ${i + 1}',
                                      url: worker.skillCertificateUrls![i],
                                      icon: Icons.card_membership_outlined,
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDocumentPreviewTile({
    required String title,
    required String url,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AppImageHelper.buildImage(
                url,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Tap preview to inspect full size',
                  style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.visibility_outlined, color: AppColors.primary, size: 20),
            tooltip: 'View Document',
            onPressed: () => _showFullScreenImage(title, url),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(String title, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBar(
                    title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: InteractiveViewer(
                        child: AppImageHelper.buildImage(url, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmApproveDirectly(CooperativeJoinRequestModel req) {
    final coop = _activeCooperative;
    if (coop == null) return;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.verified_user_rounded, color: AppColors.statusVerified),
            SizedBox(width: 8),
            Text('Approve & Enrol Worker'),
          ],
        ),
        content: Text(
          'Are you sure you want to approve ${req.workerName} as a verified worker of ${coop.name}?\n\n'
          'The worker will be officially enrolled under your Cooperative Society and granted access to receive customer jobs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await _executeApproval(req);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusVerified,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm & Enrol'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeApproval(CooperativeJoinRequestModel req) async {
    final head = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final coop = _activeCooperative;
    if (head == null || coop == null) return;

    try {
      await _verificationService.approveWorkerRequest(
        requestId: req.requestId,
        workerId: req.workerId,
        cooperativeId: coop.id,
        cooperativeHeadId: head.uid,
        primaryServiceId: req.primaryServiceId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${req.workerName} is now an enrolled, verified worker of ${coop.name}!'),
            backgroundColor: AppColors.statusVerified,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Switch to Enrolled Workers tab
        _tabController.animateTo(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approval error: $e'),
            backgroundColor: AppColors.statusError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCooperative) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingIndicator(message: 'Loading Cooperative Society data...'),
      );
    }

    final coop = _activeCooperative;
    if (coop == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 54, color: AppColors.statusPending),
                const SizedBox(height: 14),
                const Text(
                  'No Cooperative Society Available',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'An active cooperative society must be registered by an Administrator before workers can be managed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _initializeData,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry Connection'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Covered areas
    final List<String> coveredAreas = [];
    if (coop.primaryServiceArea.isNotEmpty) coveredAreas.add(coop.primaryServiceArea);
    if (coop.city != null && coop.city!.isNotEmpty && !coveredAreas.contains(coop.city)) {
      coveredAreas.add(coop.city!);
    }
    for (var a in coop.additionalServiceAreas) {
      if (a.isNotEmpty && !coveredAreas.contains(a)) coveredAreas.add(a);
    }
    final coveredCitiesText = coveredAreas.isNotEmpty ? coveredAreas.join(', ') : (coop.district ?? 'Operating Region');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Cooperative Society Header Banner
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 28),
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
                                  coop.name,
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_allCooperatives.length > 1)
                                TextButton.icon(
                                  onPressed: _showSwitchSocietyDialog,
                                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                                  label: const Text('Switch', style: TextStyle(fontSize: 12)),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Reg No: ${coop.registrationNumber} • ${coop.district ?? "District"}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_city_rounded, size: 13, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Covered Cities: $coveredCitiesText',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Streams for Counter Badges
          StreamBuilder<List<AppUser>>(
            stream: _verificationService.streamWorkersForCooperative(coop.id),
            builder: (context, workersSnap) {
              final enrolledCount = workersSnap.data?.length ?? 0;

              return StreamBuilder<List<CooperativeJoinRequestModel>>(
                stream: _verificationService.streamRequestsForCooperative(coop.id),
                builder: (context, requestsSnap) {
                  final allRequests = requestsSnap.data ?? [];
                  final pendingCount = allRequests.where((r) => r.isPending || r.isMoreInfoRequired).length;

                  return Container(
                    color: AppColors.surface,
                    child: TabBar(
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
                              const Icon(Icons.badge_rounded, size: 16),
                              const SizedBox(width: 6),
                              Text('Enrolled Workers ($enrolledCount)'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.how_to_reg_rounded, size: 16),
                              const SizedBox(width: 6),
                              const Text('Join Requests'),
                              if (pendingCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.statusPending,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$pendingCount',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_rounded, size: 16),
                              SizedBox(width: 6),
                              Text('History'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),

          // Tab Bar View Body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Enrolled Workers of this Society
                _buildEnrolledWorkersTab(coop.id),

                // Tab 2: Pending Join Requests
                _buildJoinRequestsTab(coop.id, isPendingOnly: true),

                // Tab 3: History of Requests
                _buildJoinRequestsTab(coop.id, isPendingOnly: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrolledWorkersTab(String cooperativeId) {
    return StreamBuilder<List<AppUser>>(
      stream: _verificationService.streamWorkersForCooperative(cooperativeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator(message: 'Loading enrolled society workers...');
        }

        final allWorkers = snapshot.data ?? [];
        final filteredWorkers = allWorkers.where((w) {
          final query = _workerSearchQuery.trim().toLowerCase();
          final matchesQuery = query.isEmpty ||
              w.fullName.toLowerCase().contains(query) ||
              w.phone.contains(query) ||
              (w.serviceCategory ?? '').toLowerCase().contains(query);

          final matchesService = _selectedFilterService == null ||
              w.primaryServiceId == _selectedFilterService ||
              w.serviceCategory == _selectedFilterService;

          return matchesQuery && matchesService;
        }).toList();

        return Column(
          children: [
            // Search & Filter Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search workers by name, trade or phone...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _workerSearchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => setState(() => _workerSearchQuery = ''),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (v) => setState(() => _workerSearchQuery = v),
                    ),
                  ),
                ],
              ),
            ),

            // Worker List
            Expanded(
              child: filteredWorkers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline_rounded, size: 54, color: AppColors.textTertiary),
                            const SizedBox(height: 12),
                            Text(
                              allWorkers.isEmpty
                                  ? 'No Workers Enrolled Yet'
                                  : 'No workers match your search',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              allWorkers.isEmpty
                                  ? 'When workers submit verification requests and you approve them, they will appear here as active members of this cooperative society.'
                                  : 'Try adjusting your search query or filters.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
                            ),
                            if (allWorkers.isEmpty) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _tabController.animateTo(1),
                                icon: const Icon(Icons.how_to_reg_rounded, size: 18),
                                label: const Text('Check Join Requests'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredWorkers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final worker = filteredWorkers[index];
                        final primaryService = _serviceNameMap[worker.primaryServiceId] ??
                            worker.serviceCategory ??
                            'Service Professional';

                        return AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: AppColors.primaryContainer,
                                    backgroundImage: AppImageHelper.getImageProvider(worker.profilePhotoUrl),
                                    child: worker.profilePhotoUrl == null || worker.profilePhotoUrl!.isEmpty
                                        ? Text(
                                            worker.fullName.isNotEmpty ? worker.fullName[0].toUpperCase() : 'W',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          worker.fullName,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          primaryService,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${worker.city ?? "City"}, ${worker.district ?? "District"}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.statusVerifiedBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.verified_rounded, size: 12, color: AppColors.statusVerified),
                                        SizedBox(width: 4),
                                        Text(
                                          'Verified Member',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.statusVerified),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        worker.phone,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.work_history_outlined, size: 14, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${worker.yearsOfExperience ?? worker.experience ?? "0"} yrs exp',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () => _showWorkerDetailsModal(worker),
                                icon: const Icon(Icons.person_outline_rounded, size: 16),
                                label: const Text('View Full Worker Profile & Documents'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 38),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildJoinRequestsTab(String cooperativeId, {required bool isPendingOnly}) {
    return StreamBuilder<List<CooperativeJoinRequestModel>>(
      stream: _verificationService.streamRequestsForCooperative(cooperativeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator(message: 'Loading requests...');
        }

        final all = snapshot.data ?? [];
        final requests = isPendingOnly
            ? all.where((r) => r.isPending || r.isMoreInfoRequired).toList()
            : all.where((r) => r.isApproved || r.isRejected).toList();

        if (requests.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPendingOnly ? Icons.how_to_reg_outlined : Icons.history_rounded,
                    size: 52,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isPendingOnly ? 'No Pending Join Requests' : 'No Request History',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPendingOnly
                        ? 'Applications submitted by workers wanting to join this cooperative society will appear here.'
                        : 'Past approvals and rejections will be cataloged here.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
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
            final serviceName = _serviceNameMap[req.primaryServiceId] ?? 'Service Professional';

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
                      _buildStatusBadge(req.status),
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
                  if (req.identityType != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Document: ${req.identityType}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    ),
                  ],
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
                          label: const Text('Review Application'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 38),
                          ),
                        ),
                      ),
                      if (isPendingOnly) ...[
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _confirmApproveDirectly(req),
                          icon: const Icon(Icons.verified_user_rounded, size: 16),
                          label: const Text('Approve & Enrol'),
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
      },
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
