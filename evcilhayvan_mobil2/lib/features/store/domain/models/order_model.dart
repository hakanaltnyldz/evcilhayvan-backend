class ItemReview {
  final String id;
  final int rating;
  final String comment;

  ItemReview({
    required this.id,
    required this.rating,
    required this.comment,
  });

  factory ItemReview.fromJson(Map<String, dynamic> json) {
    return ItemReview(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment']?.toString() ?? '',
    );
  }
}

class OrderItem {
  final String productId;
  final String name;
  final String? image;
  final int quantity;
  final double price;
  final ItemReview? myReview;

  OrderItem({
    required this.productId,
    required this.name,
    this.image,
    required this.quantity,
    required this.price,
    this.myReview,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    String productId = '';
    String name = '';
    String? image;

    if (product is Map<String, dynamic>) {
      productId = product['_id']?.toString() ?? product['id']?.toString() ?? '';
      name = product['name']?.toString() ?? product['title']?.toString() ?? '';
      final images = product['images'] as List? ?? product['photos'] as List? ?? [];
      image = images.isNotEmpty ? images.first?.toString() : null;
    } else if (product is String) {
      productId = product;
    }

    // Parse myReview if exists
    ItemReview? myReview;
    if (json['myReview'] != null && json['myReview'] is Map<String, dynamic>) {
      myReview = ItemReview.fromJson(json['myReview']);
    }

    return OrderItem(
      productId: productId,
      name: json['name']?.toString() ?? name,
      image: json['image']?.toString() ?? image,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      myReview: myReview,
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'quantity': quantity,
      };

  double get total => price * quantity;
}

class ShippingAddress {
  final String? street;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;

  ShippingAddress({
    this.street,
    this.city,
    this.state,
    this.zipCode,
    this.country,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      street: json['street']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      zipCode: json['zipCode']?.toString(),
      country: json['country']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (street != null) 'street': street,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (zipCode != null) 'zipCode': zipCode,
        if (country != null) 'country': country,
      };

  String get fullAddress {
    final parts = [street, city, state, zipCode, country]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.join(', ');
  }
}

enum OrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled;

  static OrderStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Beklemede';
      case OrderStatus.processing:
        return 'Hazırlanıyor';
      case OrderStatus.shipped:
        return 'Kargoda';
      case OrderStatus.delivered:
        return 'Teslim Edildi';
      case OrderStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  String get icon {
    switch (this) {
      case OrderStatus.pending:
        return '⏳';
      case OrderStatus.processing:
        return '📦';
      case OrderStatus.shipped:
        return '🚚';
      case OrderStatus.delivered:
        return '✅';
      case OrderStatus.cancelled:
        return '❌';
    }
  }
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded;

  static PaymentStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'paid':
        return PaymentStatus.paid;
      case 'failed':
        return PaymentStatus.failed;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Ödeme Bekleniyor';
      case PaymentStatus.paid:
        return 'Ödendi';
      case PaymentStatus.failed:
        return 'Başarısız';
      case PaymentStatus.refunded:
        return 'İade Edildi';
    }
  }
}

class OrderModel {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final ShippingAddress? shippingAddress;
  final String? paymentMethod;
  final String? notes;
  final String? trackingNumber;
  final String? trackingCompany;
  final DateTime createdAt;
  final DateTime updatedAt;

  // For seller view
  final double? sellerTotal;
  final String? buyerName;
  final String? buyerEmail;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    this.shippingAddress,
    this.paymentMethod,
    this.notes,
    this.trackingNumber,
    this.trackingCompany,
    required this.createdAt,
    required this.updatedAt,
    this.sellerTotal,
    this.buyerName,
    this.buyerEmail,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    String userId = '';
    String? buyerName;
    String? buyerEmail;

    if (user is Map<String, dynamic>) {
      userId = user['_id']?.toString() ?? user['id']?.toString() ?? '';
      buyerName = user['name']?.toString();
      buyerEmail = user['email']?.toString();
    } else if (user is String) {
      userId = user;
    }

    return OrderModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: userId,
      items: (json['items'] as List?)
              ?.map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: OrderStatus.fromString(json['status']?.toString()),
      paymentStatus: PaymentStatus.fromString(json['paymentStatus']?.toString()),
      shippingAddress: json['shippingAddress'] != null
          ? ShippingAddress.fromJson(json['shippingAddress'] as Map<String, dynamic>)
          : null,
      paymentMethod: json['paymentMethod']?.toString(),
      notes: json['notes']?.toString(),
      trackingNumber: json['trackingNumber']?.toString(),
      trackingCompany: json['trackingCompany']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      sellerTotal: (json['sellerTotal'] as num?)?.toDouble(),
      buyerName: buyerName,
      buyerEmail: buyerEmail,
    );
  }

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}

class OrderStats {
  final int totalOrders;
  final int pendingOrders;
  final int processingOrders;
  final int shippedOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final double totalRevenue;
  final int totalItemsSold;

  OrderStats({
    required this.totalOrders,
    required this.pendingOrders,
    required this.processingOrders,
    required this.shippedOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.totalRevenue,
    required this.totalItemsSold,
  });

  factory OrderStats.fromJson(Map<String, dynamic> json) {
    return OrderStats(
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      pendingOrders: (json['pendingOrders'] as num?)?.toInt() ?? 0,
      processingOrders: (json['processingOrders'] as num?)?.toInt() ?? 0,
      shippedOrders: (json['shippedOrders'] as num?)?.toInt() ?? 0,
      deliveredOrders: (json['deliveredOrders'] as num?)?.toInt() ?? 0,
      cancelledOrders: (json['cancelledOrders'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalItemsSold: (json['totalItemsSold'] as num?)?.toInt() ?? 0,
    );
  }

  int get activeOrders => pendingOrders + processingOrders + shippedOrders;
}

class RevenueChartPoint {
  final String month; // "2024-01"
  final double revenue;
  final int orders;

  const RevenueChartPoint({
    required this.month,
    required this.revenue,
    required this.orders,
  });

  factory RevenueChartPoint.fromJson(Map<String, dynamic> json) {
    return RevenueChartPoint(
      month: json['month']?.toString() ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      orders: (json['orders'] as num?)?.toInt() ?? 0,
    );
  }

  /// Short label e.g. "Oca", "Şub"
  String get shortLabel {
    const labels = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    final parts = month.split('-');
    if (parts.length < 2) return month;
    final m = int.tryParse(parts[1]) ?? 0;
    return (m >= 1 && m <= 12) ? labels[m] : month;
  }
}
