import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_image_helper.dart';
import '../../../models/booking_model.dart';
import '../../../models/category_model.dart';
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.greenForest,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
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
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Booking placed with ${_selectedCooperative?.name ?? "Cooperative Society"}!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.greenForest,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final tradeIcon = CategoryModel.getIconForName(widget.service.category);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.backgroundMildGreen,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Pull Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8DEC7),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Title & Close Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE8F6EE), Color(0xFFD2EEDC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBCE0CC), width: 1.2),
                      ),
                      child: Icon(tradeIcon, color: AppColors.greenForest, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Book ${widget.service.name}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.greenDeep,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFDDECE3)),
                                ),
                                child: Text(
                                  widget.service.category,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.greenForest,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                '• Cooperative Certified',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFDDECE3)),
                        ),
                        child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2EFE7)),

              // Form content
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: [
                      // 1. Cooperative Fixed Rate Banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEBF7F0), Color(0xFFD9EFE2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBCE0CC), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.greenForest.withValues(alpha: 0.05),
                              offset: const Offset(0, 3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFBCE0CC)),
                              ),
                              child: const Icon(Icons.verified_rounded, color: AppColors.greenForest, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fair Estimate: ${widget.service.priceRange ?? "₹250 - ₹500"}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                      color: AppColors.greenDeep,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Fixed fair cooperative rates. Inspected & certified by local society. Pay securely after service completion.',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Preselected Worker (if any)
                      if (widget.preselectedWorker != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFDDECE3)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFFE8F6EE),
                                backgroundImage: AppImageHelper.getImageProvider(widget.preselectedWorker!.profilePhotoUrl),
                                child: widget.preselectedWorker!.profilePhotoUrl == null
                                    ? Text(
                                        widget.preselectedWorker!.fullName.isNotEmpty
                                            ? widget.preselectedWorker!.fullName[0].toUpperCase()
                                            : 'W',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.greenForest),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Assigned Professional',
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      widget.preselectedWorker!.fullName,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.greenDeep),
                                    ),
                                    Text(
                                      '${widget.preselectedWorker!.yearsOfExperience ?? "3+"} yrs experience • Verified Society Member',
                                      style: const TextStyle(fontSize: 11, color: AppColors.greenForest, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // 2. Cooperative Society Selection
                      Row(
                        children: const [
                          Icon(Icons.apartment_rounded, size: 16, color: AppColors.greenForest),
                          SizedBox(width: 6),
                          Text(
                            'Serving Cooperative Society',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.greenDeep,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_isLoadingCooperatives)
                        const LinearProgressIndicator(
                          minHeight: 2,
                          color: AppColors.greenForest,
                          backgroundColor: Color(0xFFE2EFE7),
                        )
                      else if (_availableCooperatives.isEmpty && _selectedCooperative == null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFDDECE3)),
                          ),
                          child: const Text(
                            'Cooperative will be allocated automatically based on your address.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFDDECE3)),
                          ),
                          child: DropdownButtonFormField<CooperativeModel>(
                            initialValue: _selectedCooperative,
                            isExpanded: true,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              prefixIcon: const Icon(Icons.location_city_rounded, color: AppColors.greenForest, size: 20),
                            ),
                            items: (_availableCooperatives.isNotEmpty ? _availableCooperatives : [_selectedCooperative!])
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        '${c.name} (${c.district ?? "Local"})',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (c) {
                              if (c != null) setState(() => _selectedCooperative = c);
                            },
                          ),
                        ),
                      const SizedBox(height: 18),

                      // 3. Scheduled Date & Time Slot
                      Row(
                        children: const [
                          Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.greenForest),
                          SizedBox(width: 6),
                          Text(
                            'Schedule Date & Time',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.greenDeep,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFDDECE3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F6EE),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.greenForest),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} (${_getDayName(_selectedDate)})',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.greenDeep),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F6EE),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFBCE0CC)),
                                ),
                                child: const Text(
                                  'Change',
                                  style: TextStyle(
                                    color: AppColors.greenForest,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Time Slot Selectors
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _timeSlots.map((slot) {
                          final isSelected = slot == _selectedTimeSlot;
                          return InkWell(
                            onTap: () => setState(() => _selectedTimeSlot = slot),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.greenForest : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppColors.greenForest : const Color(0xFFDDECE3),
                                  width: 1.2,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.greenForest.withValues(alpha: 0.25),
                                          offset: const Offset(0, 3),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isSelected ? Icons.check_circle_rounded : Icons.access_time_rounded,
                                    size: 13,
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    slot,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // 4. Service Address & Phone
                      Row(
                        children: const [
                          Icon(Icons.pin_drop_rounded, size: 16, color: AppColors.greenForest),
                          SizedBox(width: 6),
                          Text(
                            'Service Location & Contact',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.greenDeep,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFDDECE3)),
                        ),
                        child: TextFormField(
                          controller: _addressController,
                          cursorColor: AppColors.greenForest,
                          decoration: const InputDecoration(
                            hintText: 'Door No, Street, Landmark, Area',
                            hintStyle: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                            prefixIcon: Icon(Icons.home_outlined, color: AppColors.greenForest, size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your address' : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFDDECE3)),
                        ),
                        child: TextFormField(
                          controller: _phoneController,
                          cursorColor: AppColors.greenForest,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: '+91 98765 43210',
                            hintStyle: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                            prefixIcon: Icon(Icons.phone_outlined, color: AppColors.greenForest, size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                          validator: (v) => (v == null || v.trim().length < 10) ? 'Enter valid phone number' : null,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 5. Problem Description
                      Row(
                        children: const [
                          Icon(Icons.edit_note_rounded, size: 18, color: AppColors.greenForest),
                          SizedBox(width: 6),
                          Text(
                            'What needs fixing or servicing?',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.greenDeep,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFDDECE3)),
                        ),
                        child: TextField(
                          controller: _problemController,
                          cursorColor: AppColors.greenForest,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Bathroom switch sparking, tap leaking, ceiling fan vibrating...',
                            hintStyle: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(12),
                          ),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 6. Tactile Submit Button
                      _BounceButton(
                        onPressed: _isSubmitting ? null : _handleConfirmBooking,
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.greenForest],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.greenForest.withValues(alpha: 0.35),
                                offset: const Offset(0, 4),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'Confirm & Place Booking',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
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

// ---------------------------------------------------------------------------
// Tactile spring-back button for booking dialog
// ---------------------------------------------------------------------------
class _BounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const _BounceButton({
    required this.child,
    this.onPressed,
  });

  @override
  State<_BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<_BounceButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
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
    return GestureDetector(
      onTapDown: widget.onPressed == null ? null : (_) => _controller.forward(),
      onTapUp: widget.onPressed == null
          ? null
          : (_) {
              _controller.reverse();
              widget.onPressed?.call();
            },
      onTapCancel: widget.onPressed == null ? null : () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
