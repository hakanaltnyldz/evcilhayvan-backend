import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';

final storeDioProvider = Provider<Dio>((ref) {
  // ApiClient singleton kullan - token interceptor'ı içerir
  return ApiClient().dio;
});
