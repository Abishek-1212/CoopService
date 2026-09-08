import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../models/booking_model.dart';
import '../../../models/user_model.dart';
import '../../../services/booking_service.dart';

class WorkerJobsTab extends StatefulWidget {
  final AppUser worker;

  const WorkerJobsTab({
    super.key,
    required this.worker,
  });

  @override
  State<WorkerJobsTab> createState() => _WorkerJobsTabState();
}

class _WorkerJobsTabState extends State<WorkerJobsTab>
    with SingleTickerProviderStateMixin {
  final BookingService _bookingService = BookingService();

  late TabController _tabController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _confirmAcceptJob(BookingModel booking) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_outline_rounded, color: AppColors.statusVerified),
            SizedBox(width: 8),
            Expanded(child: Text('Accept Service Request', overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: Text(
          'Do you want to accept the request for ${booking.serviceName} from ${booking.customerName} on ${booking.scheduledDate.day}/${booking.scheduledDate.month} (${booking.timeSlot})?\n\n'
          'The customer will be notified that you are assigned to this service.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              setState(() => _isProcessing = true);
              try {
                await _bookingService.acceptJob(
                  bookingId: booking.id,
                  worker: widget.worker,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Job for ${booking.serviceName} accepted! Customer notified.'),
                      backgroundColor: AppColors.statusVerified,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  // Switch to Active Jobs tab
                  _tabController.animateTo(1);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.statusError),
                  );
                }
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusVerified,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accept & Confirm'),
          ),
        ],
      ),
    );
  }

  void _updateJobStatus(BookingModel booking, String newStatus) async {
    setState(() => _isProcessing = true);
    try {
      if (newStatus == AppConstants.bookingInProgress) {
        await _bookingService.startJob(booking.id);
      } else if (newStatus == AppConstants.bookingCompleted) {
        await _bookingService.completeJob(booking.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == AppConstants.bookingCompleted
                ? 'Job completed! Great work.'
                : 'Service marked in progress.'),
            backgroundColor: AppColors.statusVerified,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.statusError),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundMildGreen,
      body: StreamBuilder<List<BookingModel>>(
        stream: _bookingService.streamBookingsForWorker(widget.worker),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Checking for customer requests...');
          }

          final allBookings = snapshot.data ?? [];
          final availableRequests = allBookings
              .where((b) => b.isPending && (b.workerId == null || b.workerId!.isEmpty || b.workerId == widget.worker.uid))
              .toList();
          final activeJobs = allBookings
              .where((b) => b.workerId == widget.worker.uid && (b.isConfirmed || b.isInProgress))
              .toList();
          final completedJobs = allBookings
              .where((b) => b.workerId == widget.worker.uid && b.isCompleted)
              .toList();

          return Column(
            children: [
              // Top Header
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
                            'Customer Service Requests',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Receive customer gigs from your Cooperative Society and accept instantly.',
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

              // Tabs
              Container(
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
                          const Icon(Icons.notifications_active_outlined, size: 16),
                          const SizedBox(width: 6),
                          const Text('Available'),
                          if (availableRequests.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.statusPending,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${availableRequests.length}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.engineering_outlined, size: 16),
                          const SizedBox(width: 6),
                          Text('My Active (${activeJobs.length})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.task_alt_rounded, size: 16),
                          const SizedBox(width: 6),
                          Text('Done (${completedJobs.length})'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAvailableRequestsView(availableRequests),
                    _buildActiveJobsView(activeJobs),
                    _buildCompletedJobsView(completedJobs),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvailableRequestsView(List<BookingModel> requests) {
    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.inbox_outlined, size: 54, color: AppColors.textTertiary),
              SizedBox(height: 12),
              Text(
                'No New Customer Requests',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              SizedBox(height: 6),
              Text(
                'When customers place bookings for your trade under your cooperative society, they will arrive here instantly.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
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
        final booking = requests[index];
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          child: const Icon(Icons.flash_on_rounded, color: AppColors.primary, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking.bookingNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.statusPendingBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('New Customer Request', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.statusPending)),
                  ),
                ],
              ),
              const Divider(height: 18),

              // Service & Customer
              Text(
                booking.serviceName,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                'Customer: ${booking.customerName}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),

              // Scheduled Time
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '${booking.scheduledDate.day}/${booking.scheduledDate.month}/${booking.scheduledDate.year}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 14),
                  const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(booking.timeSlot, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              if (booking.problemDescription != null && booking.problemDescription!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes_rounded, size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          booking.problemDescription!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Price & Action
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Fair Estimate:', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                        Text(
                          booking.estimatedPrice ?? '₹250 - ₹500',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _confirmAcceptJob(booking),
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text('Accept Request', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveJobsView(List<BookingModel> jobs) {
    if (jobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.work_outline_rounded, size: 52, color: AppColors.textTertiary),
              SizedBox(height: 12),
              Text(
                'No Active Jobs In Progress',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              SizedBox(height: 4),
              Text(
                'When you accept customer requests from the "Available" tab, they will be listed here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final job = jobs[index];
        final isInProgress = job.isInProgress;

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      job.bookingNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isInProgress ? AppColors.primaryContainer : AppColors.statusVerifiedBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isInProgress ? 'In Progress' : 'Confirmed & Assigned',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isInProgress ? AppColors.primary : AppColors.statusVerified,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 18),

              Text(
                job.serviceName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                'Customer: ${job.customerName} • ${job.customerPhone}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text('${job.scheduledDate.day}/${job.scheduledDate.month}/${job.scheduledDate.year}'),
                  const SizedBox(width: 14),
                  const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(job.timeSlot),
                ],
              ),
              const SizedBox(height: 4),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      job.customerAddress,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  if (!isInProgress)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : () => _updateJobStatus(job, AppConstants.bookingInProgress),
                        icon: const Icon(Icons.play_arrow_rounded, size: 16),
                        label: const Text('Start Job'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : () => _updateJobStatus(job, AppConstants.bookingCompleted),
                        icon: const Icon(Icons.task_alt_rounded, size: 16),
                        label: const Text('Mark as Completed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.statusVerified,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompletedJobsView(List<BookingModel> jobs) {
    if (jobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.history_rounded, size: 52, color: AppColors.textTertiary),
              SizedBox(height: 12),
              Text(
                'No Completed Jobs Yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              SizedBox(height: 4),
              Text(
                'Completed customer services and earnings records will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final job = jobs[index];
        return AppCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.statusVerifiedBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.task_alt_rounded, color: AppColors.statusVerified, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.serviceName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Customer: ${job.customerName} • ${job.scheduledDate.day}/${job.scheduledDate.month}/${job.scheduledDate.year}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Earned: ${job.estimatedPrice ?? "Fair rate"}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
