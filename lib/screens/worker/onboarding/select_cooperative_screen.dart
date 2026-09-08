import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F6EE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBCE0CC)),
                ),
                child: const Icon(Icons.apartment_rounded, color: AppColors.greenForest, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Confirm Request',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenDeep,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Do you want to send your membership and verification request to:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEBF7F0), Color(0xFFD9EFE2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBCE0CC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coop.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: AppColors.greenDeep,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Registration #: ${coop.registrationNumber}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                    Text(
                      'District: ${coop.district ?? "Local"}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.greenForest, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'The Cooperative Society Head will review your submitted documents and approve your trade membership.',
                style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary, height: 1.3),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                _executeJoinRequest(coop);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenForest,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Send Request', style: TextStyle(fontWeight: FontWeight.w800)),
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
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Join request submitted to ${coop.name}!')),
              ],
            ),
            backgroundColor: AppColors.greenForest,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        // Navigate to Step 3: Pending Screen
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              child: const Icon(Icons.apartment_rounded, color: AppColors.greenForest, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Select Cooperative',
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
      ),
      body: _isSubmitting
          ? const LoadingIndicator(message: 'Submitting join request to Cooperative Head...')
          : SafeArea(
              child: Column(
                children: [
                  // 1. Neumorphic Step Indicator Header
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEBF7F0), Color(0xFFD9EFE2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFBCE0CC), width: 1.2),
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
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.greenForest,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.greenForest.withValues(alpha: 0.3),
                                    offset: const Offset(0, 3),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFBCE0CC)),
                                    ),
                                    child: const Text(
                                      'STEP 2 OF 2',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.greenForest,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Society Selection',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.greenDeep,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFBCE0CC)),
                              ),
                              child: Text(
                                widget.primaryServiceName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.greenForest,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: const LinearProgressIndicator(
                            value: 1.0,
                            minHeight: 6,
                            backgroundColor: Color(0xFFC8DEC7),
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.greenForest),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. District Selector Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFDDECE3)),
                        boxShadow: [
                          const BoxShadow(
                            color: Colors.white,
                            offset: Offset(-2, -2),
                            blurRadius: 4,
                          ),
                          BoxShadow(
                            color: AppColors.greenDeep.withValues(alpha: 0.04),
                            offset: const Offset(1, 3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F6EE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.map_rounded, color: AppColors.greenForest, size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'District:',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.greenDeep),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _isLoadingDistricts
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.greenForest),
                                  )
                                : DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedDistrict,
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.greenForest),
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                      items: _districts.map((d) {
                                        return DropdownMenuItem(
                                          value: d,
                                          child: Text(d, overflow: TextOverflow.ellipsis),
                                        );
                                      }).toList(),
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
                    padding: EdgeInsets.fromLTRB(22, 14, 22, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Available Societies in this District:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.greenDeep,
                        ),
                      ),
                    ),
                  ),

                  // 3. List of Matching Cooperatives
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
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFFDE68A)),
                                    ),
                                    child: const Icon(Icons.search_off_rounded, size: 40, color: Color(0xFFD97706)),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'No Active Societies in $_selectedDistrict',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.greenDeep,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'No registered cooperative society offering "${widget.primaryServiceName}" was found in $_selectedDistrict. Try switching to a neighboring district above.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
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

    return Container(
      padding: const EdgeInsets.all(16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8F6EE), Color(0xFFD2EEDC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBCE0CC)),
                  image: coop.logoUrl != null && coop.logoUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(coop.logoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: coop.logoUrl == null || coop.logoUrl!.isEmpty
                    ? const Icon(Icons.apartment_rounded, color: AppColors.greenForest, size: 26)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coop.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.greenDeep,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Reg. No: ${coop.registrationNumber}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_city_rounded, size: 12, color: AppColors.greenForest),
                        const SizedBox(width: 4),
                        Text(
                          '${coop.district ?? "Tamil Nadu"}, ${coop.state ?? "India"}',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.greenForest),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F6EE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBCE0CC)),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenForest,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFEEF5F1)),

          // Covered Cities / Operating Areas Section
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF6FAF7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2EFE7)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.navigation_rounded, size: 16, color: AppColors.greenForest),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Operating Areas:',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        coveredAreasText,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.greenDeep),
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
                  color: isMatchingWorker ? const Color(0xFFE8F6EE) : const Color(0xFFF3F8F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isMatchingWorker ? AppColors.greenForest : const Color(0xFFDDECE3),
                    width: isMatchingWorker ? 1.3 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isMatchingWorker) ...[
                      const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.greenForest),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      sName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isMatchingWorker ? FontWeight.w800 : FontWeight.w500,
                        color: isMatchingWorker ? AppColors.greenForest : AppColors.textPrimary,
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
            text: 'Request to Join Society',
            icon: Icons.send_rounded,
            onPressed: () => _handleRequestToJoin(coop),
          ),
        ],
      ),
    );
  }
}
