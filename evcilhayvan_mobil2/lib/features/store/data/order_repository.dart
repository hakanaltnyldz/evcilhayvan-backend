import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/features/store/domain/models/order_model.dart';
import 'package:evcilhayvan_mobil2/features/store/domain/models/cart_item_model.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final client = ApiClient();
  return OrderRepository(client);
});

final myOrdersProvider = FutureProvider.autoDispose<List<OrderModel>>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getMyOrders();
});

final sellerOrdersProvider = FutureProvider.autoDispose<List<OrderModel>>((
  ref,
) {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getSellerOrders();
});

final sellerOrderStatsProvider = FutureProvider.autoDispose<OrderStats>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getSellerOrderStats();
});

final sellerRevenueChartProvider =
    FutureProvider.autoDispose<List<RevenueChartPoint>>((ref) {
      final repo = ref.watch(orderRepositoryProvider);
      return repo.getSellerRevenueChart();
    });

final sellerProductStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
      final repo = ref.watch(orderRepositoryProvider);
      return repo.getSellerProductStats();
    });

final sellerCouponPerformanceProvider =
    FutureProvider.autoDispose<List<SellerCouponPerformance>>((ref) {
      final repo = ref.watch(orderRepositoryProvider);
      return repo.getSellerCouponPerformance();
    });

class OrderRepository {
  final ApiClient _client;
  OrderRepository(this._client);
  Dio get _dio => _client.dio;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw ApiError.fromDio(e);
    } catch (e) {
      throw ApiError(e.toString());
    }
  }

  // === CUSTOMER METHODS ===

  /// Sipariş oluştur
  Future<OrderModel> createOrder({
    required List<CartItemModel> items,
    ShippingAddress? shippingAddress,
    String? paymentMethod,
    String? notes,
    String? couponCode,
    Map<String, dynamic>? guestInfo,
  }) {
    return _guard(() async {
      final orderItems = items
          .map(
            (item) => {
              'productId': item.productId,
              'quantity': item.quantity,
              if (item.selectedVariants.isNotEmpty)
                'selectedVariants': item.selectedVariants
                    .map((v) => v.toJson())
                    .toList(),
            },
          )
          .toList();

      final response = await _dio.post(
        '/api/orders',
        data: {
          'items': orderItems,
          if (shippingAddress != null)
            'shippingAddress': shippingAddress.toJson(),
          if (paymentMethod != null) 'paymentMethod': paymentMethod,
          if (notes != null) 'notes': notes,
          if (couponCode != null) 'couponCode': couponCode,
          if (guestInfo != null) 'guestInfo': guestInfo,
        },
      );

      return OrderModel.fromJson(response.data['order']);
    });
  }

  Future<OrderModel> resolveSellerReturnRequest(
    String orderId,
    String status, {
    String? note,
  }) {
    return _guard(() async {
      final response = await _dio.patch(
        '/api/seller/orders/$orderId/return-status',
        data: {
          'status': status,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      return OrderModel.fromJson(response.data['order']);
    });
  }

  /// Siparişlerimi getir
  Future<List<OrderModel>> getMyOrders() {
    return _guard(() async {
      final response = await _dio.get('/api/orders/my');
      final List<dynamic> ordersJson = (response.data['orders'] as List?) ?? [];
      return ordersJson
          .whereType<Map<String, dynamic>>()
          .map(OrderModel.fromJson)
          .toList();
    });
  }

  /// Sipariş detayı
  Future<OrderModel> getOrderById(String orderId) {
    return _guard(() async {
      final response = await _dio.get('/api/orders/$orderId');
      return OrderModel.fromJson(response.data['order']);
    });
  }

  /// Siparişi iptal et
  Future<OrderModel> cancelOrder(String orderId) {
    return _guard(() async {
      final response = await _dio.patch('/api/orders/$orderId/cancel');
      return OrderModel.fromJson(response.data['order']);
    });
  }

  // === SELLER METHODS ===

  /// Satıcının siparişlerini getir
  Future<List<OrderModel>> getSellerOrders() {
    return _guard(() async {
      final response = await _dio.get('/api/seller/orders');
      final List<dynamic> ordersJson = (response.data['orders'] as List?) ?? [];
      return ordersJson
          .whereType<Map<String, dynamic>>()
          .map(OrderModel.fromJson)
          .toList();
    });
  }

  /// Sipariş durumunu güncelle
  Future<OrderModel> updateOrderStatus(
    String orderId,
    String status, {
    String? trackingNumber,
    String? carrier,
  }) {
    return _guard(() async {
      final response = await _dio.patch(
        '/api/seller/orders/$orderId/status',
        data: {
          'status': status,
          if (trackingNumber != null && trackingNumber.isNotEmpty)
            'trackingNumber': trackingNumber,
          if (carrier != null && carrier.isNotEmpty) 'carrier': carrier,
        },
      );
      return OrderModel.fromJson(response.data['order']);
    });
  }

  /// Satıcı sipariş istatistikleri
  Future<OrderStats> getSellerOrderStats() {
    return _guard(() async {
      final response = await _dio.get('/api/seller/orders/stats');
      return OrderStats.fromJson(response.data['stats']);
    });
  }

  /// Satıcı aylık gelir grafiği (son 6 ay)
  Future<List<RevenueChartPoint>> getSellerRevenueChart() {
    return _guard(() async {
      final response = await _dio.get('/api/seller/orders/chart');
      final List<dynamic> raw = (response.data['chart'] as List?) ?? [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(RevenueChartPoint.fromJson)
          .toList();
    });
  }

  /// Satıcının ürünlerine gelen yorumlar (paginated)
  Future<SellerReviewsResponse> getSellerReviews({int page = 1, int? rating}) {
    return _guard(() async {
      final query = StringBuffer('/api/seller/reviews?page=$page&limit=20');
      if (rating != null) query.write('&rating=$rating');
      final response = await _dio.get(query.toString());
      return SellerReviewsResponse.fromJson(response.data as Map<String, dynamic>);
    });
  }

  /// Satıcının kuponlarının performans istatistikleri
  Future<List<SellerCouponPerformance>> getSellerCouponPerformance() {
    return _guard(() async {
      final response = await _dio.get('/api/seller/coupons/performance');
      final List<dynamic> raw = (response.data['coupons'] as List?) ?? [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(SellerCouponPerformance.fromJson)
          .toList();
    });
  }

  /// Satıcı ürün istatistikleri (durum dağılımı + top ürünler)
  Future<Map<String, dynamic>> getSellerProductStats() {
    return _guard(() async {
      final response = await _dio.get('/api/seller/stats');
      return {
        'orderStatusBreakdown':
            response.data['orderStatusBreakdown'] as Map<String, dynamic>? ??
            {},
        'topProducts':
            (response.data['topProducts'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
        'avgOrderValue':
            (response.data['avgOrderValue'] as num?)?.toDouble() ?? 0.0,
      };
    });
  }
}
