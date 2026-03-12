import 'store_model.dart';

class ProductModel {
  final String id;
  final String title;
  final String? description;
  final double price;
  final List<String> photos;
  final int stock;
  final bool isActive;
  final String? categoryId;
  final String? sellerId;
  final StoreModel? store;

  ProductModel({
    required this.id,
    required this.title,
    required this.price,
    this.description,
    this.photos = const [],
    this.stock = 0,
    this.isActive = true,
    this.categoryId,
    this.sellerId,
    this.store,
  });

  List<String> get images => photos;
  String get displayName => title;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawPhotos =
        (json['images'] as List<dynamic>?) ??
            (json['photos'] as List<dynamic>?) ??
            const <dynamic>[];
    final dynamic categoryRaw = json['category'];

    return ProductModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['name'] ?? json['title'] ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      photos: rawPhotos.whereType<String>().toList(),
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] != null ? json['isActive'] as bool : true,
      categoryId: categoryRaw is Map<String, dynamic>
          ? categoryRaw['_id'] as String?
          : categoryRaw as String?,
      sellerId: json['seller'] as String?,
      store: json['store'] != null && json['store'] is Map<String, dynamic>
          ? StoreModel.fromJson(json['store'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": title,
        if (description != null) "description": description,
        "price": price,
        "stock": stock,
        "images": photos,
        if (categoryId != null) "category": categoryId,
        "isActive": isActive,
      };
}
