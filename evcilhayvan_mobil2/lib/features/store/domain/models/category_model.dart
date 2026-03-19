import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? icon;
  final String color;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.color = '#6C5CE7',
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      icon: json['icon'],
      color: json['color'] ?? '#6C5CE7',
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'slug': slug,
        if (icon != null) 'icon': icon,
        'color': color,
      };

  // Hex string'i Color'a çevir
  Color get colorValue {
    try {
      final hex = color.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF6C5CE7);
    }
  }

  // İkon adına göre Flutter icon döndür
  IconData get iconData {
    switch (icon) {
      case 'dry_food':
        return Icons.restaurant;
      case 'wet_food':
        return Icons.soup_kitchen;
      case 'treat':
        return Icons.cookie;
      case 'vitamin':
        return Icons.medication;
      case 'toy':
        return Icons.smart_toy;
      case 'chew_toy':
        return Icons.pets;
      case 'interactive':
        return Icons.sports_esports;
      case 'leash':
        return Icons.link;
      case 'clothing':
        return Icons.checkroom;
      case 'collar':
        return Icons.sell;
      case 'bed':
        return Icons.bed;
      case 'cage':
        return Icons.home;
      case 'bowl':
        return Icons.ramen_dining;
      case 'litter':
        return Icons.delete_outline;
      case 'shampoo':
        return Icons.shower;
      case 'brush':
        return Icons.brush;
      case 'nail':
        return Icons.content_cut;
      case 'ear_care':
        return Icons.hearing;
      case 'dental':
        return Icons.mood;
      case 'flea':
        return Icons.bug_report;
      case 'medicine':
        return Icons.local_hospital;
      case 'training':
        return Icons.school;
      case 'aquarium':
        return Icons.water;
      case 'bird':
        return Icons.flutter_dash;
      case 'rodent':
        return Icons.cruelty_free;
      default:
        return Icons.category;
    }
  }
}
