import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/cooperative_card.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../models/cooperative_model.dart';
import '../../../models/service_model.dart';
import '../../../models/user_model.dart';
import '../../../services/cooperative_service.dart';
import '../../../services/firestore_service.dart';
import '../../../services/service_management_service.dart';
import '../cooperative_details_screen.dart';
import 'edit_service_screen.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceId;

  const ServiceDetailsScreen({
    super.key,
    required this.serviceId,
  });

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  final ServiceManagementService _serviceManagementService =
      ServiceManagementService();
  final CooperativeService _cooperativeService = CooperativeService();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Service Master Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Service',
            onPressed: () async {
              final navigator = Navigator.of(context);
              final service = await _serviceManagementService.getServiceById(widget.serviceId);
              if (service != null && mounted) {
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => EditServiceScreen(service: service),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<ServiceModel?>(
          future: _serviceManagementService.getServiceById(widget.serviceId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingIndicator(message: 'Loading service details...');
            }

            final service = snapshot.data;
            if (service == null) {
              return const Center(child: Text('Service not found.'));
            }

            final bool isActive = service.isActive;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Overview Header Card
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.handyman_rounded, color: AppColors.primary, size: 32),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    service.category,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive ? AppColors.statusVerifiedBg : AppColors.statusErrorBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isActive ? 'ACTIVE' : 'INACTIVE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isActive ? AppColors.statusVerified : AppColors.statusError,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        Text(
                          service.shortDescription,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (service.description != null && service.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            service.description!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Service Specifications Card
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Service Specifications',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.payments_outlined, color: AppColors.primary),
                          title: const Text('Estimated Starting Price / Range'),
                          subtitle: Text(service.priceRange ?? 'Not Specified'),
                        ),
                        const Divider(),

                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.psychology_outlined, color: AppColors.primary),
                          title: const Text('Required Skills & Qualifications'),
                          subtitle: service.requiredSkills.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: service.requiredSkills.map((skill) {
                                      return Chip(
                                        label: Text(skill, style: const TextStyle(fontSize: 11)),
                                        padding: const EdgeInsets.all(4),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      );
                                    }).toList(),
                                  ),
                                )
                              : const Text('No specific skill requirements listed'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Participating Cooperative Societies Section
                  const Text(
                    'Cooperative Societies Offering This Service',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  StreamBuilder<List<CooperativeModel>>(
                    stream: _cooperativeService.streamCooperativesByServiceId(widget.serviceId),
                    builder: (context, coopSnap) {
                      if (coopSnap.connectionState == ConnectionState.waiting) {
                        return const LoadingIndicator(message: 'Loading offering societies...');
                      }

                      final offeringCoops = coopSnap.data ?? [];

                      if (offeringCoops.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Center(
                            child: Column(
                              children: const [
                                Icon(Icons.apartment_outlined, size: 36, color: AppColors.textTertiary),
                                SizedBox(height: 8),
                                Text(
                                  'No Cooperative Society Currently Offers This Service',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Cooperative Societies can select this service in their settings or during society setup.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return StreamBuilder<List<AppUser>>(
                        stream: _firestoreService.streamAllUsers(),
                        builder: (context, userSnap) {
                          final usersList = userSnap.data ?? [];
                          final Map<String, AppUser> userMap = {
                            for (var u in usersList) u.uid: u
                          };

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: offeringCoops.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, idx) {
                              final coop = offeringCoops[idx];
                              final headUser = coop.cooperativeHeadId != null ? userMap[coop.cooperativeHeadId] : null;

                              return CooperativeCard(
                                cooperative: coop,
                                headUser: headUser,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CooperativeDetailsScreen(cooperativeId: coop.id),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
