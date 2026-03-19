// lib/features/favorites/domain/models/favorite_model.dart

import 'package:evcilhayvan_mobil2/features/pets/domain/models/pet_model.dart';
import 'package:evcilhayvan_mobil2/features/store/domain/models/product_model.dart';
import 'package:evcilhayvan_mobil2/features/store/domain/models/store_model.dart';

class FavoriteModel {
  final String id;
  final String itemType; // 'pet', 'product', 'store'
  final dynamic item; // Can be Pet, Product, or Store
  final DateTime createdAt;

  FavoriteModel({
    required this.id,
    required this.itemType,
    required this.item,
    required this.createdAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    final itemType = json['itemType'] as String;
    final itemData = json['item'];

    dynamic parsedItem;
    if (itemData is Map<String, dynamic>) {
      switch (itemType) {
        case 'pet':
          parsedItem = Pet.fromJson(itemData);
          break;
        case 'product':
          parsedItem = ProductModel.fromJson(itemData);
          break;
        case 'store':
          parsedItem = StoreModel.fromJson(itemData);
          break;
        default:
          parsedItem = itemData;
      }
    } else {
      parsedItem = itemData;
    }

    return FavoriteModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      itemType: itemType,
      item: parsedItem,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  // Type-safe getters
  Pet? get asPet => itemType == 'pet' && item is Pet ? item as Pet : null;
  ProductModel? get asProduct =>
      itemType == 'product' && item is ProductModel ? item as ProductModel : null;
  StoreModel? get asStore =>
      itemType == 'store' && item is StoreModel ? item as StoreModel : null;

  static DateTime _parseDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return DateTime.now();
  }
}
