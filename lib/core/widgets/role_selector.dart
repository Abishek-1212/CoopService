import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'neumorphic_segmented_switcher.dart';

class RoleSelector extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;

  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicSegmentedSwitcher<String>(
      selectedValue: selectedRole,
      onChanged: onRoleChanged,
      height: 54,
      items: const [
        SegmentItem<String>(
          value: AppConstants.roleCustomer,
          label: 'Customer',
          icon: Icons.person_rounded,
        ),
        SegmentItem<String>(
          value: AppConstants.roleWorker,
          label: 'Worker',
          icon: Icons.handyman_rounded,
        ),
      ],
    );
  }
}
