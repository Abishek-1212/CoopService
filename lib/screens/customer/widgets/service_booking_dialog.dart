import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_image_helper.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/booking_model.dart';
import '../../../models/cooperative_model.dart';
import '../../../models/service_model.dart';
import '../../../models/user_model.dart';
import '../../../services/booking_service.dart';
import '../../../services/cooperative_service.dart';

class ServiceBookingDialog extends StatefulWidget {
  final ServiceModel service;
  final AppUser customer;
  final CooperativeModel? preselectedCooperative;
  final AppUser? preselectedWorker;

  const ServiceBookingDialog({
    super.key,
    required this.service,
    required this.customer,
    this.preselectedCooperative,
    this.preselectedWorker,
  });

  static Future<bool?> show(
    BuildContext context, {
    required ServiceModel service,
    required AppUser customer,
    CooperativeModel? preselectedCooperative,
    AppUser? preselectedWorker,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ServiceBookingDialog(
        service: service,
        customer: customer,
        preselectedCooperative: preselectedCooperative,
        preselectedWorker: preselectedWorker,
      ),
    );
  }

  @override
  State<ServiceBookingDialog> createState() => _ServiceBookingDialogState();
}

class _ServiceBookingDialogState extends State<ServiceBookingDialog> {
  final BookingService _bookingService = BookingService();
  final CooperativeService _cooperativeService = CooperativeService();

  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _problemController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = '09:00 AM - 12:00 PM';
  CooperativeModel? _selectedCooperative;
  List<CooperativeModel> _availableCooperatives = [];
  bool _isLoadingCooperatives = true;
  bool _isSubmitting = false;

  final List<String> _timeSlots = [
    '09:00 AM - 12:00 PM',
    '12:00 PM - 03:00 PM',
    '03:00 PM - 06:00 PM',
    '06:00 PM - 08:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.customer.fullAddress ?? widget.customer.location;
    _phoneController.text = widget.customer.phone;
    _loadCooperatives();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _problemController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadCooperatives() async {
    if (widget.preselectedCooperative != null) {
      if (mounted) {
        setState(() {
          _selectedCooperative = widget.preselectedCooperative;
          _isLoadingCooperatives = false;
        });
      }
      return;
    }

    try {
      final coops = await _cooperativeService.streamCooperatives().first;
      // Filter active cooperatives that offer this service or in general
      final matching = coops.where((c) {
        return c.isActive && (c.serviceIds.contains(widget.service.id) || c.serviceIds.isEmpty);
      }).toList();

      final list = matching.isNotEmpty ? matching : coops.where((c) => c.isActive).toList();

      if (mounted) {
        setState(() {
          _availableCooperatives = list;
          _selectedCooperative = list.isNotEmpty ? list.first : null;
          _isLoadingCooperatives = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingCooperatives = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleConfirmBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final booking = BookingModel(
        id: '',
        bookingNumber: '',
        customerId: widget.customer.uid,
        customerName: widget.customer.fullName,
        customerPhone: _phoneController.text.trim(),
        customerAddress: _addressController.text.trim(),
        customerCity: widget.customer.city,
        customerDistrict: widget.customer.district,
        serviceId: widget.service.id,
        serviceName: widget.service.name,
        serviceCategory: widget.service.category,
        serviceIconUrl: widget.service.iconUrl ?? widget.service.imageUrl,
        cooperativeId: _selectedCooperative?.id,
        cooperativeName: _selectedCooperative?.name ?? 'Assigned Cooperative Society',
        workerId: widget.preselectedWorker?.uid,
        workerName: widget.preselectedWorker?.fullName,
        workerPhone: widget.preselectedWorker?.phone,
        workerPhotoUrl: widget.preselectedWorker?.profilePhotoUrl,
        scheduledDate: _selectedDate,
        timeSlot: _selectedTimeSlot,
        problemDescription: _problemController.text.trim(),
        status: AppConstants.bookingPending,
        estimatedPrice: widget.service.priceRange ?? '₹250 - ₹500',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _bookingService.createBooking(booking);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking confirmed with ${_selectedCooperative?.name ?? "Cooperative"}!'),
            backgroundColor: AppColors.statusVerified,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking error: $e'),
            backgroundColor: AppColors.statusError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Pull Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title & Close
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.handyman_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Book ${widget.service.name}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          Text(
                            widget.service.category,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Form content
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Pricing Banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_outlined, color: AppColors.primary, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Standard Estimate: ${widget.service.priceRange ?? "₹250 - ₹500"}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Fixed fair cooperative rates. Pay securely after service completion.',
                                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Assigned / Preselected Worker (if any)
                      if (widget.preselectedWorker != null) ...[
                        AppCard(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primaryContainer,
                                backgroundImage: AppImageHelper.getImageProvider(widget.preselectedWorker!.profilePhotoUrl),
                                child: widget.preselectedWorker!.profilePhotoUrl == null
                                    ? Text(widget.preselectedWorker!.fullName[0].toUpperCase())
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Requested Professional:', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                                    Text(
                                      widget.preselectedWorker!.fullName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      '${widget.preselectedWorker!.yearsOfExperience ?? "3+"} years experience • Verified',
                                      style: const TextStyle(fontSize: 11, color: AppColors.statusVerified),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 1. Cooperative Society Selection
                      const Text(
                        'Serving Cooperative Society',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      if (_isLoadingCooperatives)
                        const LinearProgressIndicator(minHeight: 2)
                      else if (_availableCooperatives.isEmpty && _selectedCooperative == null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text('Cooperative will be assigned automatically based on your location.'),
                        )
                      else
                        DropdownButtonFormField<CooperativeModel>(
                          initialValue: _selectedCooperative,
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            prefixIcon: const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 20),
                          ),
                          items: (_availableCooperatives.isNotEmpty ? _availableCooperatives : [_selectedCooperative!])
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                      '${c.name} (${c.district ?? "Local"})',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (c) {
                            if (c != null) setState(() => _selectedCooperative = c);
                          },
                        ),
                      const SizedBox(height: 20),

                      // 2. Scheduled Date & Time Slot
                      const Text(
                        'Schedule Date & Time',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} (${_getDayName(_selectedDate)})',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ),
                              const Text('Change', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Time Slot Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _timeSlots.map((slot) {
                          final isSelected = slot == _selectedTimeSlot;
                          return ChoiceChip(
                            label: Text(slot),
                            selected: isSelected,
                            selectedColor: AppColors.primaryContainer,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedTimeSlot = slot);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // 3. Service Address & Phone
                      const Text(
                        'Service Location & Contact',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _addressController,
                        label: 'Complete Service Address',
                        hint: 'Door No, Street, Landmark, Area',
                        prefixIcon: Icons.home_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your address' : null,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _phoneController,
                        label: 'Contact Phone Number',
                        hint: '+91 98765 43210',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v == null || v.trim().length < 10) ? 'Enter valid phone number' : null,
                      ),
                      const SizedBox(height: 20),

                      // 4. Problem Description / Instructions
                      const Text(
                        'What needs fixing or servicing?',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _problemController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'e.g. Bathroom light switch not working, ceiling fan making rattling noise...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      PrimaryButton(
                        text: 'Confirm & Place Booking',
                        isLoading: _isSubmitting,
                        onPressed: _handleConfirmBooking,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}
