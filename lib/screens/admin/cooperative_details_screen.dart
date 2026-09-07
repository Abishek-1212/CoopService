import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../models/cooperative_model.dart';
import '../../models/service_model.dart';
import '../../models/user_model.dart';
import '../../services/cooperative_service.dart';
import '../../services/firestore_service.dart';
import '../../services/service_management_service.dart';
import 'add_cooperative_screen.dart';
import 'assign_cooperative_head_screen.dart';

class CooperativeDetailsScreen extends StatefulWidget {
  final String cooperativeId;

  const CooperativeDetailsScreen({
    super.key,
    required this.cooperativeId,
  });

  @override
  State<CooperativeDetailsScreen> createState() => _CooperativeDetailsScreenState();
}

class _CooperativeDetailsScreenState extends State<CooperativeDetailsScreen> {
  final CooperativeService _cooperativeService = CooperativeService();
  final ServiceManagementService _serviceManagementService = ServiceManagementService();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CooperativeModel?>(
      stream: _cooperativeService.streamCooperativeById(widget.cooperativeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: LoadingIndicator(message: 'Loading cooperative details...'),
          );
        }

        final coop = snapshot.data;
        if (coop == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Cooperative Not Found')),
            body: const Center(child: Text('This cooperative society no longer exists.')),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(coop.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Cooperative',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddCooperativeScreen(cooperative: coop),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Header Banner
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 36),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        coop.name,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: coop.isActive ? AppColors.statusVerifiedBg : AppColors.statusErrorBg,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        coop.isActive ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: coop.isActive ? AppColors.statusVerified : AppColors.statusError,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Registration #: ${coop.registrationNumber}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.map_outlined, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        coop.primaryServiceArea,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (coop.description != null && coop.description!.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          coop.description!,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Services Offered (Dynamic Resolution of serviceIds -> services Collection)
                const Text(
                  'Services Offered',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                _buildServicesOfferedSection(coop.serviceIds),

                const SizedBox(height: 24),

                // Location & Area Breakdown
                const Text(
                  'Geographical Service Area',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                AppCard(
                  child: Column(
                    children: [
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.explore_outlined, color: AppColors.primary),
                        title: const Text('Primary Operating Service Area'),
                        subtitle: Text(coop.primaryServiceArea, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const Divider(),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_city_outlined, color: AppColors.primary),
                        title: const Text('City / District / State'),
                        subtitle: Text(
                          '${coop.city ?? "N/A"}, ${coop.district ?? "N/A"}, ${coop.state ?? "N/A"} - Pincode: ${coop.pincode ?? "N/A"}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Cooperative Head Section
                const Text(
                  'Cooperative Head Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                _buildHeadSection(context, coop),

                const SizedBox(height: 24),

                // Contact Details
                const Text(
                  'Contact & Office Address',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                AppCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.phone_outlined, color: AppColors.primary),
                        title: const Text('Phone Number'),
                        subtitle: Text(coop.contactPhone),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.email_outlined, color: AppColors.primary),
                        title: const Text('Email Address'),
                        subtitle: Text(coop.contactEmail),
                      ),
                      if (coop.address != null && coop.address!.isNotEmpty) ...[
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                          title: const Text('Office Address'),
                          subtitle: Text(coop.address!),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Documents Section
                if (coop.registrationDocumentUrl != null && coop.registrationDocumentUrl!.isNotEmpty) ...[
                  const Text(
                    'Society Legal Documents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    child: ListTile(
                      leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                      title: const Text('Cooperative Registration Certificate'),
                      subtitle: const Text('Verified Document'),
                      trailing: const Icon(Icons.open_in_new_rounded, color: AppColors.primary),
                      onTap: () {
                        // Open document URL
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Cooperative Workers Stream Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Assigned Workers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    StreamBuilder<List<AppUser>>(
                      stream: _firestoreService.streamWorkersByCooperative(coop.id),
                      builder: (context, snap) {
                        final count = snap.data?.length ?? 0;
                        return Text(
                          '$count Total',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _buildWorkersSection(coop.id),

                const SizedBox(height: 24),

                // Society Controls
                ElevatedButton.icon(
                  onPressed: () async {
                    await _cooperativeService.toggleCooperativeStatus(coop.id, coop.status);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(coop.isActive ? 'Cooperative deactivated.' : 'Cooperative activated.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: coop.isActive ? AppColors.statusErrorBg : AppColors.statusVerifiedBg,
                    foregroundColor: coop.isActive ? AppColors.statusError : AppColors.statusVerified,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  icon: Icon(coop.isActive ? Icons.block_rounded : Icons.check_circle_rounded),
                  label: Text(coop.isActive ? 'Deactivate Society' : 'Activate Society'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildServicesOfferedSection(List<String> serviceIds) {
    if (serviceIds.isEmpty) {
      return AppCard(
        child: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.statusPending),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No service categories selected for this cooperative society.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<ServiceModel>>(
      future: _serviceManagementService.getServicesByIds(serviceIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator(message: 'Resolving services...');
        }

        final resolvedServices = snapshot.data ?? [];

        if (resolvedServices.isEmpty) {
          return AppCard(
            child: Text(
              '${serviceIds.length} Service ID(s) linked, but no service metadata found in master catalog.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          );
        }

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Offering ${resolvedServices.length} Master Service(s):',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: resolvedServices.map((service) {
                  return Chip(
                    avatar: Icon(
                      service.isActive ? Icons.check_circle_outline_rounded : Icons.pause_circle_outline_rounded,
                      size: 16,
                      color: service.isActive ? AppColors.statusVerified : AppColors.statusError,
                    ),
                    label: Text(
                      service.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: service.isActive ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                    backgroundColor: service.isActive ? AppColors.primaryContainer : AppColors.surfaceVariant,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeadSection(BuildContext context, CooperativeModel coop) {
    if (!coop.hasHead) {
      return AppCard(
        backgroundColor: AppColors.statusPendingBg,
        child: Column(
          children: [
            Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: AppColors.statusPending, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No Cooperative Head is currently assigned to this society.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AssignCooperativeHeadScreen(cooperative: coop),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
              ),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Assign Cooperative Head'),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<AppUser?>(
      stream: _firestoreService.streamUserProfile(coop.cooperativeHeadId!),
      builder: (context, snapshot) {
        final headUser = snapshot.data;

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryContainer,
                    child: Text(
                      headUser?.fullName.isNotEmpty == true ? headUser!.fullName[0].toUpperCase() : 'H',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headUser?.fullName ?? 'Cooperative Head',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          headUser?.email ?? '',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        Text(
                          headUser?.phone ?? '',
                          style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Operating Area: ${headUser?.serviceArea ?? coop.primaryServiceArea}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssignCooperativeHeadScreen(cooperative: coop),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: const Text('Change Head', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWorkersSection(String coopId) {
    return StreamBuilder<List<AppUser>>(
      stream: _firestoreService.streamWorkersByCooperative(coopId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final workers = snapshot.data ?? [];
        if (workers.isEmpty) {
          return AppCard(
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: AppColors.textTertiary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No workers assigned to this cooperative yet.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: workers.map<Widget>((w) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.surfaceVariant,
                      child: Text(
                        w.fullName.isNotEmpty ? w.fullName[0] : 'W',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w.fullName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            w.serviceCategory ?? 'Worker',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: w.verificationStatus == AppConstants.statusVerified
                            ? AppColors.statusVerifiedBg
                            : AppColors.statusPendingBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        w.verificationStatus ?? 'Pending',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: w.verificationStatus == AppConstants.statusVerified
                              ? AppColors.statusVerified
                              : AppColors.statusPending,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
