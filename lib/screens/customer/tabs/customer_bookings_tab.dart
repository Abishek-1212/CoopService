import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../models/booking_model.dart';
import '../../../models/category_model.dart';
import '../../../models/user_model.dart';
import '../../../services/booking_service.dart';

/// Customer "My Bookings" Tab - Unique modern design with mild green aesthetic,
/// tactile animated buttons, ticket-style booking cards, and live status tracking.
class CustomerBookingsTab extends StatefulWidget {
  final AppUser customer;
  final Function(int targetTab) onNavigateTab;

  const CustomerBookingsTab({
    super.key,
    required this.customer,
    required this.onNavigateTab,
  });

  @override
  State<CustomerBookingsTab> createState() => _CustomerBookingsTabState();
}

class _CustomerBookingsTabState extends State<CustomerBookingsTab> {
  final BookingService _bookingService = BookingService();

  String _filterStatus = 'All'; // All, Active, Completed, Cancelled

  void _showCancelDialog(BookingModel booking) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.statusErrorBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.cancel_outlined, color: AppColors.statusError, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Cancel Booking',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel booking #${booking.bookingNumber} for ${booking.serviceName}?',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Reason for cancellation (optional)',
                hintText: 'e.g. Schedule change, resolved elsewhere...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.backgroundMildGreen,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFD4E6DC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFD4E6DC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Keep Booking', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          _BounceButton(
            onTap: () async {
              Navigator.pop(dialogCtx);
              try {
                await _bookingService.cancelBooking(
                  booking.id,
                  reason: reasonController.text.trim().isNotEmpty
                      ? reasonController.text.trim()
                      : 'Cancelled by customer',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 10),
                          Text('Booking successfully cancelled.'),
                        ],
                      ),
                      backgroundColor: AppColors.textPrimary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.statusError,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.statusError,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33EF4444),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Text(
                'Confirm Cancel',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDetailsModal(BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: AppColors.backgroundMildGreen,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Color(0x2A064E3B),
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFBFD8CB),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Modal Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD8EFE2), Color(0xFFC2E4D0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBCE0CC)),
                    ),
                    child: Icon(
                      CategoryModel.getIconForName(
                        booking.serviceCategory.isNotEmpty ? booking.serviceCategory : booking.serviceName,
                      ),
                      color: AppColors.greenForest,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.serviceName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Booking ID: #${booking.bookingNumber}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  _PulsingStatusBadge(status: booking.status),
                ],
              ),
            ),

            const Divider(height: 16, color: Color(0xFFD6E8DE)),

            // Scrollable Content
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  // Step Progress Tracker
                  _buildProgressTracker(booking.status),
                  const SizedBox(height: 16),

                  // Service & Schedule Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFDDECE3)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A064E3B),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SCHEDULE & LOCATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: AppColors.greenForest,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDetailItem(
                          Icons.calendar_today_rounded,
                          'Date',
                          '${booking.scheduledDate.day} ${_monthName(booking.scheduledDate.month)} ${booking.scheduledDate.year}',
                        ),
                        _buildDetailItem(Icons.access_time_rounded, 'Time Window', booking.timeSlot),
                        _buildDetailItem(Icons.place_rounded, 'Service Address', booking.customerAddress),
                        if (booking.customerPhone.isNotEmpty)
                          _buildDetailItem(Icons.phone_rounded, 'Contact Phone', booking.customerPhone),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cooperative & Specialist Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFDDECE3)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A064E3B),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'COOPERATIVE ASSURANCE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: AppColors.greenForest,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDetailItem(
                          Icons.apartment_rounded,
                          'Society',
                          booking.cooperativeName ?? 'Assigned Cooperative Society',
                        ),
                        if (booking.workerName != null)
                          _buildDetailItem(
                            Icons.badge_rounded,
                            'Certified Worker',
                            '${booking.workerName} ${booking.workerPhone != null ? "(${booking.workerPhone})" : ""}',
                          )
                        else
                          _buildDetailItem(
                            Icons.info_outline_rounded,
                            'Specialist',
                            'Being assigned by local cooperative head',
                          ),
                        _buildDetailItem(
                          Icons.payments_rounded,
                          'Estimated Fair Price',
                          booking.estimatedPrice ?? '₹250 - ₹500 (Fair Society Rate)',
                        ),
                      ],
                    ),
                  ),

                  if (booking.problemDescription != null && booking.problemDescription!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFDDECE3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'REPORTED ISSUE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: AppColors.greenForest,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            booking.problemDescription!,
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (booking.cancellationReason != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFFECDD3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CANCELLATION NOTE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: AppColors.statusError,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            booking.cancellationReason!,
                            style: const TextStyle(fontSize: 13, color: AppColors.statusError),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Action Buttons in Modal
                  Row(
                    children: [
                      if (booking.isPending || booking.isConfirmed)
                        Expanded(
                          child: _BounceButton(
                            onTap: () {
                              Navigator.pop(ctx);
                              _showCancelDialog(booking);
                            },
                            child: Container(
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFFECACA)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cancel_outlined, size: 18, color: AppColors.statusError),
                                  SizedBox(width: 8),
                                  Text(
                                    'Cancel Booking',
                                    style: TextStyle(
                                      color: AppColors.statusError,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (booking.isPending || booking.isConfirmed) const SizedBox(width: 12),
                      Expanded(
                        child: _BounceButton(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.greenForest],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x330F766E),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
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
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF8F3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: AppColors.greenForest),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
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

  Widget _buildProgressTracker(String currentStatus) {
    final stages = [
      {'key': AppConstants.bookingPending, 'label': 'Requested', 'icon': Icons.edit_note_rounded},
      {'key': AppConstants.bookingConfirmed, 'label': 'Confirmed', 'icon': Icons.thumb_up_alt_rounded},
      {'key': AppConstants.bookingInProgress, 'label': 'In Progress', 'icon': Icons.bolt_rounded},
      {'key': AppConstants.bookingCompleted, 'label': 'Completed', 'icon': Icons.check_circle_rounded},
    ];

    int activeIndex = 0;
    if (currentStatus == AppConstants.bookingConfirmed) activeIndex = 1;
    if (currentStatus == AppConstants.bookingInProgress) activeIndex = 2;
    if (currentStatus == AppConstants.bookingCompleted) activeIndex = 3;
    final isCancelled = currentStatus == AppConstants.bookingCancelled;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDECE3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A064E3B),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LIVE STATUS JOURNEY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColors.greenForest,
                ),
              ),
              if (isCancelled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.statusErrorBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Cancelled',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.statusError),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(stages.length, (index) {
              final stage = stages[index];
              final isDone = !isCancelled && index <= activeIndex;
              final isCurrent = !isCancelled && index == activeIndex;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDone
                                  ? (isCurrent ? AppColors.greenForest : const Color(0xFFD8EFE2))
                                  : (isCancelled ? const Color(0xFFF1F5F9) : const Color(0xFFF1F5F9)),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDone
                                    ? (isCurrent ? AppColors.greenDeep : const Color(0xFFA5D6B7))
                                    : const Color(0xFFE2E8F0),
                                width: isCurrent ? 2 : 1.2,
                              ),
                              boxShadow: isCurrent
                                  ? [
                                      const BoxShadow(
                                        color: Color(0x33047857),
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              stage['icon'] as IconData,
                              size: 18,
                              color: isDone
                                  ? (isCurrent ? Colors.white : AppColors.greenForest)
                                  : AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            stage['label'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                              color: isDone ? AppColors.textPrimary : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (index < stages.length - 1)
                      Container(
                        width: 16,
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        color: !isCancelled && index < activeIndex
                            ? AppColors.greenForest
                            : const Color(0xFFE2E8F0),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundMildGreen,
      body: SafeArea(
        child: Column(
          children: [
            // Unique Header with Mild Green styling and animated refresh
            _buildHeader(),

            // Animated Filter Tabs Switcher
            _buildFilterSelector(),

            // Stream of Customer Bookings
            Expanded(
              child: StreamBuilder<List<BookingModel>>(
                stream: _bookingService.streamCustomerBookings(widget.customer.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingIndicator(message: 'Loading your bookings...');
                  }

                  final allBookings = snapshot.data ?? [];
                  final filtered = allBookings.where((b) {
                    if (_filterStatus == 'All') return true;
                    if (_filterStatus == 'Active') return b.isPending || b.isConfirmed || b.isInProgress;
                    if (_filterStatus == 'Completed') return b.isCompleted;
                    if (_filterStatus == 'Cancelled') return b.isCancelled;
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyState(allBookings.isEmpty);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final booking = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildBookingCard(booking),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.backgroundMildGreen,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'My Bookings',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.greenDeep,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7EFE1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBCE0CC)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_rounded, size: 12, color: AppColors.greenForest),
                          SizedBox(width: 4),
                          Text(
                            'Co-op Assured',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.greenForest,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'Real-time updates & certified history of home services',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _AnimatedRefreshButton(
            onRefresh: () => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSelector() {
    final tabs = [
      {'key': 'All', 'label': 'All', 'icon': Icons.layers_rounded},
      {'key': 'Active', 'label': 'Active', 'icon': Icons.bolt_rounded},
      {'key': 'Completed', 'label': 'Completed', 'icon': Icons.check_circle_outline_rounded},
      {'key': 'Cancelled', 'label': 'Cancelled', 'icon': Icons.cancel_outlined},
    ];

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isSelected = _filterStatus == tab['key'];

          return _BounceButton(
            onTap: () => setState(() => _filterStatus = tab['key'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFFE4EFE8),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? const Color(0xFFBCE0CC) : const Color(0xFFD4E6DC),
                  width: isSelected ? 1.5 : 1.0,
                ),
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          color: Color(0x180F766E),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tab['icon'] as IconData,
                    size: 15,
                    color: isSelected ? AppColors.greenForest : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tab['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? AppColors.greenDeep : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isCompletelyEmpty) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFDDECE3)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10064E3B),
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE6F5ED), Color(0xFFCEECDB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFBCE0CC), width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18047857),
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  isCompletelyEmpty ? Icons.home_repair_service_rounded : Icons.search_off_rounded,
                  size: 32,
                  color: AppColors.greenForest,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isCompletelyEmpty ? 'No Bookings Yet' : 'No $_filterStatus Bookings',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isCompletelyEmpty
                    ? 'Book certified electricians, plumbers, painters and carpenters at government verified cooperative fair rates.'
                    : 'You have no bookings under the "$_filterStatus" status at the moment.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              _BounceButton(
                onTap: () => widget.onNavigateTab(2), // jump to Services tab
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.greenForest],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x330F766E),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.handyman_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Browse Services',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDECE3), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E064E3B),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: Color(0x06064E3B),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Trade Icon Squircle + Service Name + Ref # + Status Badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Squircle Trade Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8F6EE), Color(0xFFD2EEDC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBCE0CC)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x10047857),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    CategoryModel.getIconForName(
                      booking.serviceCategory.isNotEmpty ? booking.serviceCategory : booking.serviceName,
                    ),
                    color: AppColors.greenForest,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Service Name & Booking Ref
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F6F3),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFDDECE3)),
                            ),
                            child: Text(
                              '#${booking.bookingNumber}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          if (booking.serviceCategory.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                booking.serviceCategory,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.greenForest,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Pulsing Status Pill
                _PulsingStatusBadge(status: booking.status),
              ],
            ),
          ),

          // Perforated Ticket Divider
          const _TicketDivider(),

          // Card Middle: Date, Time Slot, Society & Location
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: Column(
              children: [
                // Date & Time capsules
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F8F5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2EDE6)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.greenForest),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${booking.scheduledDate.day} ${_monthName(booking.scheduledDate.month)} ${booking.scheduledDate.year}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F8F5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2EDE6)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 13, color: AppColors.greenForest),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                booking.timeSlot,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Assigned Cooperative or Worker Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAF8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE7EFE9)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        booking.workerName != null ? Icons.person_rounded : Icons.storefront_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          booking.workerName != null
                              ? 'Assigned: ${booking.workerName}'
                              : (booking.cooperativeName ?? 'Cooperative Society Assured'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.verified_rounded, size: 13, color: AppColors.greenEmerald),
                    ],
                  ),
                ),

                // Service Address
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        booking.customerAddress,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Action Bar with Fair Price and Animated Buttons
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FCFA),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: Color(0xFFE8F1EC), width: 1.0),
              ),
            ),
            child: Row(
              children: [
                // Estimated Fair Price Pill
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ESTIMATED FAIR RATE',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        booking.estimatedPrice ?? '₹250 - ₹500',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.greenDeep,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                if (booking.isPending || booking.isConfirmed) ...[
                  _BounceButton(
                    onTap: () => _showCancelDialog(booking),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.statusError,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                _BounceButton(
                  onTap: () => _showBookingDetailsModal(booking),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.greenForest],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x2A0F766E),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Details',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 13, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }
}

/// Tactile bounce button with physical press micro-interaction
class _BounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _BounceButton({
    required this.child,
    this.onTap,
  });

  @override
  State<_BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<_BounceButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Animated Status Badge with breathing glowing dot
class _PulsingStatusBadge extends StatefulWidget {
  final String status;

  const _PulsingStatusBadge({required this.status});

  @override
  State<_PulsingStatusBadge> createState() => _PulsingStatusBadgeState();
}

class _PulsingStatusBadgeState extends State<_PulsingStatusBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color textColor;
    Color dotColor;
    String label;
    bool shouldPulse = false;

    switch (widget.status) {
      case AppConstants.bookingConfirmed:
        bg = const Color(0xFFE0F2FE);
        border = const Color(0xFFBAE6FD);
        textColor = const Color(0xFF0369A1);
        dotColor = const Color(0xFF0284C7);
        label = 'Confirmed';
        shouldPulse = true;
        break;
      case AppConstants.bookingInProgress:
        bg = const Color(0xFFDCFCE7);
        border = const Color(0xFF86EFAC);
        textColor = const Color(0xFF15803D);
        dotColor = const Color(0xFF16A34A);
        label = 'In Progress';
        shouldPulse = true;
        break;
      case AppConstants.bookingCompleted:
        bg = const Color(0xFFD1FAE5);
        border = const Color(0xFFA7F3D0);
        textColor = const Color(0xFF047857);
        dotColor = const Color(0xFF10B981);
        label = 'Completed';
        break;
      case AppConstants.bookingCancelled:
        bg = const Color(0xFFFEE2E2);
        border = const Color(0xFFFECACA);
        textColor = const Color(0xFFB91C1C);
        dotColor = const Color(0xFFEF4444);
        label = 'Cancelled';
        break;
      default: // pending
        bg = const Color(0xFFFEF3C7);
        border = const Color(0xFFFDE68A);
        textColor = const Color(0xFFB45309);
        dotColor = const Color(0xFFF59E0B);
        label = 'Pending';
        shouldPulse = true;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (shouldPulse)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _pulseAnimation.value,
                  child: Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: dotColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          else
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dotted Perforated Ticket Divider line
class _TicketDivider extends StatelessWidget {
  const _TicketDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        const dashSpacing = 4.0;
        final dashCount = (boxWidth / (dashWidth + dashSpacing)).floor();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return const SizedBox(
                width: dashWidth,
                height: dashHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xFFD6E8DE)),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

/// Animated 360-degree spinning refresh button
class _AnimatedRefreshButton extends StatefulWidget {
  final VoidCallback onRefresh;

  const _AnimatedRefreshButton({required this.onRefresh});

  @override
  State<_AnimatedRefreshButton> createState() => _AnimatedRefreshButtonState();
}

class _AnimatedRefreshButtonState extends State<_AnimatedRefreshButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerRefresh() {
    _controller.forward(from: 0.0);
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return _BounceButton(
      onTap: _triggerRefresh,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBCE0CC)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10064E3B),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: _controller.value * 2 * math.pi,
              child: const Icon(
                Icons.refresh_rounded,
                color: AppColors.greenForest,
                size: 20,
              ),
            );
          },
        ),
      ),
    );
  }
}
