import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final String iconKey;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.iconKey = 'handyman',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return CategoryModel(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'],
      iconKey: map['iconKey'] ?? 'handyman',
      isActive: map['isActive'] ?? true,
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt']),
    );
  }

  factory CategoryModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CategoryModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'iconKey': iconKey,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    String? iconKey,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconKey: iconKey ?? this.iconKey,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Visual Icon Mapping
  IconData get iconData {
    return getIconForName(iconKey.isNotEmpty ? iconKey : name);
  }

  static IconData getIconForName(String keyOrName) {
    final lower = keyOrName.toLowerCase().trim();

    if (lower.contains('electr') || lower.contains('bolt')) {
      return Icons.bolt_rounded;
    } else if (lower.contains('plumb') || lower.contains('water') || lower.contains('pipe')) {
      return Icons.plumbing_rounded;
    } else if (lower.contains('clean') || lower.contains('sweep') || lower.contains('maid')) {
      return Icons.cleaning_services_rounded;
    } else if (lower.contains('paint') || lower.contains('wall') || lower.contains('color')) {
      return Icons.format_paint_rounded;
    } else if (lower.contains('carpen') || lower.contains('wood') || lower.contains('furniture')) {
      return Icons.chair_rounded;
    } else if (lower.contains('appliance') || lower.contains('fridge') || lower.contains('kitchen') || lower.contains('machine')) {
      return Icons.kitchen_rounded;
    } else if (lower.contains('garden') || lower.contains('yard') || lower.contains('lawn') || lower.contains('plant')) {
      return Icons.yard_rounded;
    } else if (lower.contains('lock') || lower.contains('key')) {
      return Icons.lock_rounded;
    } else if (lower.contains('ac') || lower.contains('hvac') || lower.contains('cool') || lower.contains('air')) {
      return Icons.ac_unit_rounded;
    } else if (lower.contains('transport') || lower.contains('shift') || lower.contains('move') || lower.contains('truck')) {
      return Icons.local_shipping_rounded;
    } else if (lower.contains('construct') || lower.contains('mason') || lower.contains('build')) {
      return Icons.construction_rounded;
    } else if (lower.contains('security') || lower.contains('guard') || lower.contains('shield')) {
      return Icons.shield_rounded;
    } else if (lower.contains('pest') || lower.contains('bug')) {
      return Icons.pest_control_rounded;
    } else if (lower.contains('maint') || lower.contains('repair') || lower.contains('tool') || lower.contains('handy')) {
      return Icons.handyman_rounded;
    }
    return Icons.category_rounded;
  }

  // Pre-configured icon choices for Admin Icon Picker
  static const List<Map<String, dynamic>> availableIcons = [
    {'key': 'handyman', 'label': 'Maintenance', 'icon': Icons.handyman_rounded},
    {'key': 'bolt', 'label': 'Electrical', 'icon': Icons.bolt_rounded},
    {'key': 'plumbing', 'label': 'Plumbing', 'icon': Icons.plumbing_rounded},
    {'key': 'cleaning_services', 'label': 'Cleaning', 'icon': Icons.cleaning_services_rounded},
    {'key': 'chair', 'label': 'Carpentry', 'icon': Icons.chair_rounded},
    {'key': 'format_paint', 'label': 'Painting', 'icon': Icons.format_paint_rounded},
    {'key': 'kitchen', 'label': 'Appliances', 'icon': Icons.kitchen_rounded},
    {'key': 'yard', 'label': 'Gardening', 'icon': Icons.yard_rounded},
    {'key': 'ac_unit', 'label': 'AC & HVAC', 'icon': Icons.ac_unit_rounded},
    {'key': 'construction', 'label': 'Construction', 'icon': Icons.construction_rounded},
    {'key': 'local_shipping', 'label': 'Transport', 'icon': Icons.local_shipping_rounded},
    {'key': 'lock', 'label': 'Locksmith', 'icon': Icons.lock_rounded},
    {'key': 'pest_control', 'label': 'Pest Control', 'icon': Icons.pest_control_rounded},
    {'key': 'shield', 'label': 'Security', 'icon': Icons.shield_rounded},
    {'key': 'category', 'label': 'General', 'icon': Icons.category_rounded},
  ];
}
