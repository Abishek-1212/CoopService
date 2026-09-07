import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../models/booking_model.dart';
import '../../../models/user_model.dart';
import '../../../services/booking_service.dart';

class CustomerAlertsTab extends StatefulWidget {
  final AppUser customer;
  final Function(int targetTab) onNavigateTab;

  const CustomerAlertsTab({
    super.key,
    required this.customer,
    required this.onNavigateTab,
  });

  @override
  State<CustomerAlertsTab> createState() => _CustomerAlertsTabState();
}

class _CustomerAlertsTabState extends State<CustomerAlertsTab> {
  final BookingService _bookingService = BookingService();

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
                        'Activity & Alerts',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Stay updated with live booking dispatches and announcements.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                  onPressed: () => setState(() {}),
                ),
              ],
            ),
          ),

          // Alerts List from Bookings
          Expanded(
            child: StreamBuilder<List<BookingModel>>(
              stream: _bookingService.streamCustomerBookings(widget.customer.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator(message: 'Loading alerts...');
                }

                final bookings = snapshot.data ?? [];

                // Combine booking events and cooperative announcements
                final List<Map<String, dynamic>> alerts = [];

                // 1. Cooperative Guarantee Welcome Alert
                alerts.add({
                  'title': 'Welcome to CoopService!',
                  'description': 'Your account is active. Explore verified trade services backed by local Cooperative Societies.',
                  'time': 'Just now',
                  'icon': Icons.handshake_rounded,
                  'color': AppColors.primary,
                  'isActionable': false,
                });

                // 2. Booking-based live alerts
                for (var b in bookings) {
                  if (b.isPending) {
                    alerts.add({
                      'title': 'Booking Dispatched (${b.bookingNumber})',
                      'description': 'Your request for ${b.serviceName} was sent to ${b.cooperativeName ?? "the Cooperative Society"}. Awaiting worker assignment.',
                      'time': '${b.createdAt.day}/${b.createdAt.month}',
                      'icon': Icons.hourglass_top_rounded,
                      'color': AppColors.statusPending,
                      'isActionable': true,
                    });
                  } else if (b.isConfirmed) {
                    alerts.add({
                      'title': 'Worker Confirmed (${b.bookingNumber})',
                      'description': '${b.workerName ?? "A verified technician"} has been scheduled for ${b.serviceName} on ${b.scheduledDate.day}/${b.scheduledDate.month} (${b.timeSlot}).',
                      'time': '${b.updatedAt.day}/${b.updatedAt.month}',
                      'icon': Icons.verified_user_rounded,
                      'color': AppColors.statusVerified,
                      'isActionable': true,
                    });
                  } else if (b.isCompleted) {
                    alerts.add({
                      'title': 'Service Completed (${b.bookingNumber})',
                      'description': 'The ${b.serviceName} job has been marked completed. Thank you for using cooperative services!',
                      'time': '${b.updatedAt.day}/${b.updatedAt.month}',
                      'icon': Icons.task_alt_rounded,
                      'color': AppColors.statusVerified,
                      'isActionable': true,
                    });
                  } else if (b.isCancelled) {
                    alerts.add({
                      'title': 'Booking Cancelled (${b.bookingNumber})',
                      'description': 'Booking for ${b.serviceName} was cancelled: ${b.cancellationReason ?? "No reason provided."}',
                      'time': '${b.updatedAt.day}/${b.updatedAt.month}',
                      'icon': Icons.cancel_outlined,
                      'color': AppColors.statusError,
                      'isActionable': false,
                    });
                  }
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: alerts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    return AppCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (alert['color'] as Color).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(alert['icon'] as IconData, color: alert['color'] as Color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        alert['title'] as String,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                    Text(
                                      alert['time'] as String,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  alert['description'] as String,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                if (alert['isActionable'] == true) ...[
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => widget.onNavigateTab(1),
                                    child: const Text(
                                      'View in Bookings →',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                ],
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
          ),
        ],
      ),
    );
  }
}
