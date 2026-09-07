import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/cooperative_card.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../models/cooperative_model.dart';
import '../../models/user_model.dart';
import '../../services/cooperative_service.dart';
import '../../services/firestore_service.dart';
import 'add_cooperative_screen.dart';
import 'cooperative_details_screen.dart';

class CooperativeListScreen extends StatefulWidget {
  const CooperativeListScreen({super.key});

  @override
  State<CooperativeListScreen> createState() => _CooperativeListScreenState();
}

class _CooperativeListScreenState extends State<CooperativeListScreen> {
  final CooperativeService _cooperativeService = CooperativeService();
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Active, Inactive

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar & Search
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Cooperative Societies',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddCooperativeScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Society', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Search Field
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by society name or operating area...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filter Chips (All, Active, Inactive)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Active'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Inactive'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Stream List of Cooperatives & Users
            Expanded(
              child: StreamBuilder<List<CooperativeModel>>(
                stream: _cooperativeService.streamCooperatives(),
                builder: (context, coopSnapshot) {
                  if (coopSnapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingIndicator(message: 'Loading cooperative societies...');
                  }

                  if (coopSnapshot.hasError) {
                    return Center(
                      child: Text('Error loading cooperatives: ${coopSnapshot.error}'),
                    );
                  }

                  final allCooperatives = coopSnapshot.data ?? [];

                  if (allCooperatives.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.apartment_rounded, size: 40, color: AppColors.primary),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No cooperative societies have been added yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Click "Add Society" above to register the first cooperative society and assign its head.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AddCooperativeScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add Cooperative Society'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Stream all users to map cooperativeHeadId to headUser profile
                  return StreamBuilder<List<AppUser>>(
                    stream: _firestoreService.streamAllUsers(),
                    builder: (context, userSnapshot) {
                      final usersList = userSnapshot.data ?? [];
                      final Map<String, AppUser> userMap = {
                        for (var u in usersList) u.uid: u
                      };

                      // Filter cooperatives by search & status filter
                      final filteredList = allCooperatives.where((c) {
                        final matchesSearch = _searchQuery.isEmpty ||
                            c.name.toLowerCase().contains(_searchQuery) ||
                            c.primaryServiceArea.toLowerCase().contains(_searchQuery) ||
                            c.registrationNumber.toLowerCase().contains(_searchQuery);

                        bool matchesStatus = true;
                        if (_statusFilter == 'Active') {
                          matchesStatus = c.status == AppConstants.statusActive;
                        } else if (_statusFilter == 'Inactive') {
                          matchesStatus = c.status == AppConstants.statusInactive;
                        }

                        return matchesSearch && matchesStatus;
                      }).toList();

                      if (filteredList.isEmpty) {
                        return const Center(
                          child: Text(
                            'No cooperative societies match your filter criteria.',
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredList.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, idx) {
                          final coop = filteredList[idx];
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _statusFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primaryContainer,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      onSelected: (val) {
        if (val) {
          setState(() {
            _statusFilter = label;
          });
        }
      },
    );
  }
}
