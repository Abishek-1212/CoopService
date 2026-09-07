import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../models/booking_model.dart';
import '../../../models/user_model.dart';
import '../../../services/booking_service.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.cancel_outlined, color: AppColors.statusError),
            SizedBox(width: 8),
            Text('Cancel Booking'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel booking ${booking.bookingNumber} for ${booking.serviceName}?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason for cancellation (optional)',
                hintText: 'e.g. Schedule conflict, problem resolved...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            onPressed: () async {
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
                    const SnackBar(
                      content: Text('Booking cancelled.'),
                      backgroundColor: AppColors.textSecondary,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.statusError),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusError,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Cancel'),
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
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.bookingNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                    ),
                    Text(booking.serviceName, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  ],
                ),
                _buildStatusChip(booking.status),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow(Icons.apartment_rounded, 'Cooperative Society', booking.cooperativeName ?? 'Assigned Society'),
            _buildDetailRow(Icons.calendar_today_rounded, 'Scheduled Date', '${booking.scheduledDate.day}/${booking.scheduledDate.month}/${booking.scheduledDate.year}'),
            _buildDetailRow(Icons.access_time_rounded, 'Time Slot', booking.timeSlot),
            _buildDetailRow(Icons.home_outlined, 'Service Address', booking.customerAddress),
            _buildDetailRow(Icons.payments_outlined, 'Estimated Fair Price', booking.estimatedPrice ?? '₹250 - ₹500'),
            if (booking.workerName != null)
              _buildDetailRow(Icons.person_rounded, 'Assigned Professional', '${booking.workerName} (${booking.workerPhone ?? ""})'),
            if (booking.problemDescription != null && booking.problemDescription!.isNotEmpty)
              _buildDetailRow(Icons.notes_rounded, 'Problem Details', booking.problemDescription!),
            if (booking.cancellationReason != null)
              _buildDetailRow(Icons.cancel_outlined, 'Cancellation Note', booking.cancellationReason!),
            const SizedBox(height: 20),
            if (booking.isPending || booking.isConfirmed)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showCancelDialog(booking);
                },
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Cancel This Booking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusErrorBg,
                  foregroundColor: AppColors.statusError,
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Bookings',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Track live progress and history of your household services.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                  tooltip: 'Refresh',
                  onPressed: () => setState(() {}),
                ),
              ],
            ),
          ),

          // Filter Pills
          Container(
            height: 50,
            color: AppColors.surface,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildFilterChip('All'),
                _buildFilterChip('Active'),
                _buildFilterChip('Completed'),
                _buildFilterChip('Cancelled'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Live Bookings Stream
          Expanded(
            child: StreamBuilder<List<BookingModel>>(
              stream: _bookingService.streamCustomerBookings(widget.customer.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator(message: 'Retrieving your bookings...');
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
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 54, color: AppColors.textTertiary),
                          const SizedBox(height: 12),
                          Text(
                            allBookings.isEmpty ? 'No Bookings Yet' : 'No $_filterStatus Bookings',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            allBookings.isEmpty
                                ? 'Need an electrician, plumber, or home cleaning? Explore certified cooperative services and schedule anytime.'
                                : 'Try selecting another status tab above.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                          ),
                          if (allBookings.isEmpty) ...[
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              onPressed: () => widget.onNavigateTab(2), // jump to Services tab
                              icon: const Icon(Icons.handyman_rounded, size: 16),
                              label: const Text('Browse Services'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final booking = filtered[index];
                    return _buildBookingCard(booking);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filterStatus == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primaryContainer,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() => _filterStatus = label);
          }
        },
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: ID & Status
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.confirmation_number_outlined, color: AppColors.primary, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.bookingNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusChip(booking.status),
            ],
          ),
          const Divider(height: 18),

          // Service Title & Cooperative
          Text(
            booking.serviceName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            booking.cooperativeName ?? 'Cooperative Society',
            style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),

          // Scheduled Date & Time
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                '${booking.scheduledDate.day}/${booking.scheduledDate.month}/${booking.scheduledDate.year}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                booking.timeSlot,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  booking.customerAddress,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          if (booking.workerName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Assigned: ${booking.workerName}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showBookingDetailsModal(booking),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 36),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('View Details', style: TextStyle(fontSize: 12)),
                ),
              ),
              if (booking.isPending || booking.isConfirmed) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _showCancelDialog(booking),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.statusError,
                    minimumSize: const Size(80, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case AppConstants.bookingConfirmed:
        bg = AppColors.statusVerifiedBg;
        text = AppColors.statusVerified;
        label = 'Confirmed';
        break;
      case AppConstants.bookingInProgress:
        bg = AppColors.primaryContainer;
        text = AppColors.primary;
        label = 'In Progress';
        break;
      case AppConstants.bookingCompleted:
        bg = AppColors.statusVerifiedBg;
        text = AppColors.statusVerified;
        label = 'Completed';
        break;
      case AppConstants.bookingCancelled:
        bg = AppColors.statusErrorBg;
        text = AppColors.statusError;
        label = 'Cancelled';
        break;
      default:
        bg = AppColors.statusPendingBg;
        text = AppColors.statusPending;
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }
}
