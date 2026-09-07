import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/cooperative_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/service_management_service.dart';
import '../../../services/worker_verification_service.dart';
import 'worker_pending_verification_screen.dart';

class SelectCooperativeScreen extends StatefulWidget {
  final AppUser worker;
  final String primaryServiceName;

  const SelectCooperativeScreen({
    super.key,
    required this.worker,
    required this.primaryServiceName,
  });

  @override
  State<SelectCooperativeScreen> createState() => _SelectCooperativeScreenState();
}

class _SelectCooperativeScreenState extends State<SelectCooperativeScreen> {
  final WorkerVerificationService _verificationService = WorkerVerificationService();
  final ServiceManagementService _serviceService = ServiceManagementService();

  late String _selectedDistrict;
  List<String> _districts = [];
  bool _isLoadingDistricts = true;
  bool _isSubmitting = false;

  Map<String, String> _serviceNameMap = {};

  @override
  void initState() {
    super.initState();
    _selectedDistrict = widget.worker.district?.trim().isNotEmpty == true
        ? widget.worker.district!.trim()
        : 'Coimbatore';
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final districts = await _verificationService.getAvailableDistricts();
    final allServices = await _serviceService.streamActiveServices().first;

    final map = <String, String>{};
    for (var s in allServices) {
      map[s.id] = s.name;
    }

    if (mounted) {
      setState(() {
        _districts = districts;
        _serviceNameMap = map;
        if (!_districts.contains(_selectedDistrict) && _districts.isNotEmpty) {
          _districts.insert(0, _selectedDistrict);
        }
        _isLoadingDistricts = false;
      });
    }
  }

  void _handleRequestToJoin(CooperativeModel coop) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Confirm Request',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Do you want to send your membership and verification request to:',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coop.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Registration: ${coop.registrationNumber}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Primary Service: ${widget.primaryServiceName}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your profile details, identity proof, and skill certificates will be forwarded to this Cooperative Head for verification.',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
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
                Navigator.pop(dialogCtx);
                await _executeJoinRequest(coop);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Send Request'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeJoinRequest(CooperativeModel coop) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      await _verificationService.submitJoinRequest(
        worker: widget.worker,
        cooperative: coop,
      );

      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshCurrentUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Join request submitted to ${coop.name}!'),
            backgroundColor: AppColors.statusVerified,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate to Step 3: Pending Screen (replace all onboarding routes)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const WorkerPendingVerificationScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: $e'),
            backgroundColor: AppColors.statusError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Choose Cooperative Society'),
      ),
      body: _isSubmitting
          ? const LoadingIndicator(message: 'Submitting join request to Cooperative Head...')
          : SafeArea(
              child: Column(
                children: [
                  // Step Indicator Header
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Step 2 of 2: Location & Society Selection',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Selected Trade: ${widget.primaryServiceName}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // District Selector Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: AppCard(
                      child: Row(
                        children: [
                          const Icon(Icons.map_rounded, color: AppColors.primary, size: 22),
                          const SizedBox(width: 12),
                          const Text(
                            'District:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _isLoadingDistricts
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedDistrict,
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                      items: _districts.map((d) {
                                        return DropdownMenuItem(
                                          value: d,
                                          child: Text(d, overflow: TextOverflow.ellipsis),
                                        );
                                      }).toList(),
                                      selectedItemBuilder: (BuildContext context) {
                                        return _districts.map((d) {
                                          return Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(d, overflow: TextOverflow.ellipsis, maxLines: 1),
                                          );
                                        }).toList();
                                      },
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _selectedDistrict = val;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Available Cooperative Societies in this District:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),

                  // List of Matching Cooperatives
                  Expanded(
                    child: StreamBuilder<List<CooperativeModel>>(
                      stream: _verificationService.streamCooperativesByDistrictAndService(
                        district: _selectedDistrict,
                        serviceId: widget.worker.primaryServiceId ?? '',
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const LoadingIndicator(message: 'Searching matching cooperative societies...');
                        }

                        final cooperatives = snapshot.data ?? [];

                        if (cooperatives.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(28.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: const BoxDecoration(
                                      color: AppColors.statusPendingBg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.search_off_rounded, size: 48, color: AppColors.statusPending),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No Active Cooperative Societies Found in $_selectedDistrict',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'No registered cooperative society offering "${widget.primaryServiceName}" was found for $_selectedDistrict. Try switching to a neighboring district above.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: cooperatives.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final coop = cooperatives[index];
                            return _buildCooperativeCard(coop);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCooperativeCard(CooperativeModel coop) {
    // Collect covered cities / areas
    final List<String> coveredAreas = [];
    if (coop.primaryServiceArea.isNotEmpty) {
      coveredAreas.add(coop.primaryServiceArea);
    }
    if (coop.city != null && coop.city!.isNotEmpty && !coveredAreas.contains(coop.city)) {
      coveredAreas.add(coop.city!);
    }
    for (var area in coop.additionalServiceAreas) {
      if (area.isNotEmpty && !coveredAreas.contains(area)) {
        coveredAreas.add(area);
      }
    }

    final coveredAreasText = coveredAreas.isNotEmpty ? coveredAreas.join(', ') : 'All areas in ${coop.district}';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Logo, Name, Reg #
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  image: coop.logoUrl != null && coop.logoUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(coop.logoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: coop.logoUrl == null || coop.logoUrl!.isEmpty
                    ? const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 30)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coop.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Registration: ${coop.registrationNumber}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_city_outlined, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${coop.district ?? "Tamil Nadu"}, ${coop.state ?? "India"}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusVerifiedBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.statusVerified,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Covered Cities / Operating Areas Section
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.navigation_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Operating Cities & Covered Areas:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        coveredAreasText,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Services Offered Chips
          const Text(
            'Services Offered:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: coop.serviceIds.map((sid) {
              final isMatchingWorker = sid == widget.worker.primaryServiceId;
              final sName = _serviceNameMap[sid] ?? 'Service';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isMatchingWorker ? AppColors.primaryContainer : AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isMatchingWorker ? AppColors.primary : AppColors.border,
                    width: isMatchingWorker ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isMatchingWorker) ...[
                      const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      sName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isMatchingWorker ? FontWeight.bold : FontWeight.normal,
                        color: isMatchingWorker ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Request to Join Button
          PrimaryButton(
            text: 'Request to Join',
            icon: Icons.send_rounded,
            onPressed: () => _handleRequestToJoin(coop),
          ),
        ],
      ),
    );
  }
}
