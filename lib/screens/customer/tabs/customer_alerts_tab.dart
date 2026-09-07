import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../models/booking_model.dart';
import '../../../models/user_model.dart';
import '../../../services/booking_service.dart';

/// Customer "Activity & Alerts" Tab - Unique modern design with mild green aesthetic,
/// tactile animated buttons, squircle notification cards, and status-color indicators.
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
  String _filterType = 'All'; // All, Bookings, System

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundMildGreen,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Mild Green styling and animated refresh
            _buildHeader(),

            // Filter Tabs Bar
            _buildFilterSelector(),

            // Alerts List Stream
            Expanded(
              child: StreamBuilder<List<BookingModel>>(
                stream: _bookingService.streamCustomerBookings(widget.customer.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingIndicator(message: 'Loading live alerts...');
                  }

                  final bookings = snapshot.data ?? [];
                  final List<Map<String, dynamic>> alerts = [];

                  // 1. Cooperative Guarantee Welcome Alert (System)
                  if (_filterType == 'All' || _filterType == 'System') {
                    alerts.add({
                      'type': 'System',
                      'title': 'Welcome to CoopService!',
                      'description': 'Your verified customer account is active. Explore licensed trade services backed by local Cooperative Societies.',
                      'time': 'Active',
                      'icon': Icons.handshake_rounded,
                      'color': AppColors.primary,
                      'isActionable': true,
                      'actionLabel': 'Explore Services',
                      'targetTab': 2,
                    });

                    alerts.add({
                      'type': 'System',
                      'title': 'Cooperative Price Protection',
                      'description': 'All labor rates and repair estimates are regulated by cooperative guidelines to prevent arbitrary contractor surge charges.',
                      'time': 'Assured',
                      'icon': Icons.shield_rounded,
                      'color': AppColors.greenForest,
                      'isActionable': false,
                    });
                  }

                  // 2. Booking-based live alerts (Bookings)
                  if (_filterType == 'All' || _filterType == 'Bookings') {
                    for (var b in bookings) {
                      if (b.isPending) {
                        alerts.add({
                          'type': 'Bookings',
                          'title': 'Booking Dispatched (#${b.bookingNumber})',
                          'description': 'Your request for ${b.serviceName} was sent to ${b.cooperativeName ?? "the Cooperative Society"}. A certified worker is being assigned.',
                          'time': '${b.createdAt.day} ${_monthName(b.createdAt.month)}',
                          'icon': Icons.hourglass_top_rounded,
                          'color': AppColors.statusPending,
                          'isActionable': true,
                          'actionLabel': 'View in Bookings',
                          'targetTab': 1,
                        });
                      } else if (b.isConfirmed) {
                        alerts.add({
                          'type': 'Bookings',
                          'title': 'Specialist Assigned (#${b.bookingNumber})',
                          'description': '${b.workerName ?? "A verified specialist"} is scheduled for ${b.serviceName} on ${b.scheduledDate.day} ${_monthName(b.scheduledDate.month)} (${b.timeSlot}).',
                          'time': '${b.updatedAt.day} ${_monthName(b.updatedAt.month)}',
                          'icon': Icons.verified_user_rounded,
                          'color': AppColors.greenEmerald,
                          'isActionable': true,
                          'actionLabel': 'Track Progress',
                          'targetTab': 1,
                        });
                      } else if (b.isInProgress) {
                        alerts.add({
                          'type': 'Bookings',
                          'title': 'Service In Progress (#${b.bookingNumber})',
                          'description': 'Work has commenced for ${b.serviceName} with ${b.workerName ?? "specialist"}.',
                          'time': '${b.updatedAt.day} ${_monthName(b.updatedAt.month)}',
                          'icon': Icons.bolt_rounded,
                          'color': AppColors.primary,
                          'isActionable': true,
                          'actionLabel': 'Track Progress',
                          'targetTab': 1,
                        });
                      } else if (b.isCompleted) {
                        alerts.add({
                          'type': 'Bookings',
                          'title': 'Service Completed (#${b.bookingNumber})',
                          'description': 'Your ${b.serviceName} service has concluded successfully. Thank you for supporting certified cooperative trade labor.',
                          'time': '${b.updatedAt.day} ${_monthName(b.updatedAt.month)}',
                          'icon': Icons.task_alt_rounded,
                          'color': AppColors.greenForest,
                          'isActionable': true,
                          'actionLabel': 'View Receipt',
                          'targetTab': 1,
                        });
                      } else if (b.isCancelled) {
                        alerts.add({
                          'type': 'Bookings',
                          'title': 'Booking Cancelled (#${b.bookingNumber})',
                          'description': 'Booking for ${b.serviceName} was cancelled: ${b.cancellationReason ?? "Cancelled by customer."}',
                          'time': '${b.updatedAt.day} ${_monthName(b.updatedAt.month)}',
                          'icon': Icons.cancel_outlined,
                          'color': AppColors.statusError,
                          'isActionable': false,
                        });
                      }
                    }
                  }

                  if (alerts.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildAlertCard(alert),
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
                        'Activity & Alerts',
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
                          Icon(Icons.circle, size: 8, color: AppColors.greenEmerald),
                          SizedBox(width: 5),
                          Text(
                            'Live Feed',
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
                  'Live dispatch notifications & cooperative announcements',
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
      {'key': 'All', 'label': 'All Alerts', 'icon': Icons.notifications_none_rounded},
      {'key': 'Bookings', 'label': 'Bookings', 'icon': Icons.calendar_today_rounded},
      {'key': 'System', 'label': 'Announcements', 'icon': Icons.campaign_outlined},
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
          final isSelected = _filterType == tab['key'];

          return _BounceButton(
            onTap: () => setState(() => _filterType = tab['key'] as String),
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

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final color = alert['color'] as Color;
    final isActionable = alert['isActionable'] == true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDECE3), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E064E3B),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
          BoxShadow(
            color: Color(0x05064E3B),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Squircle Icon Badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Icon(alert['icon'] as IconData, color: color, size: 22),
          ),
          const SizedBox(width: 14),

          // Alert Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        alert['title'] as String,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF8F3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDDECE3)),
                      ),
                      child: Text(
                        alert['time'] as String,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  alert['description'] as String,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (isActionable) ...[
                  const SizedBox(height: 10),
                  _BounceButton(
                    onTap: () {
                      final targetTab = (alert['targetTab'] as int?) ?? 1;
                      widget.onNavigateTab(targetTab);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.greenForest],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x220F766E),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            alert['actionLabel'] as String? ?? 'View Details',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
                child: const Icon(
                  Icons.notifications_off_rounded,
                  size: 32,
                  color: AppColors.greenForest,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Alerts At The Moment',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Updates regarding technician visits, society confirmations, and dispatch notifications will appear here in real time.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              _BounceButton(
                onTap: () => widget.onNavigateTab(2), // jump to Services
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
