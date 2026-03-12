import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class TokenStorage {
  static const _accessKey = 'accessToken';
  static const _refreshKey = 'refreshToken';

  Future<String?> get accessToken async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey);
  }

  Future<String?> get refreshToken async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  Future<void> saveTokens({String? accessToken, String? refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    if (accessToken != null) await prefs.setString(_accessKey, accessToken);
    if (refreshToken != null) await prefs.setString(_refreshKey, refreshToken);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }
}

class ApiError implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  ApiError(this.message, {this.code, this.details});

  factory ApiError.fromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return ApiError(
        data['message']?.toString() ?? e.message ?? 'Bilinmeyen hata',
        code: data['code']?.toString(),
        details: data['details'],
      );
    }
    return ApiError(e.message ?? 'Bilinmeyen hata', code: e.type.name);
  }

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._internal() {
    _setup();
  }

  factory ApiClient() => _instance;
  static final ApiClient _instance = ApiClient._internal();

  final Dio dio = Dio();
  final TokenStorage _tokenStorage = TokenStorage();
  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  TokenStorage get tokenStorage => _tokenStorage;

  void _setup() {
    dio.options = BaseOptions(
      baseUrl: AppConfig.current.apiBaseUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: {'Content-Type': 'application/json'},
    );

    dio.interceptors.add(QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        await _attachAuth(options);
        return handler.next(options);
      },
      onError: (error, handler) async {
        final shouldRefresh = error.response?.statusCode == 401 && _shouldRetry(error.requestOptions);
        if (shouldRefresh && await _refreshAndRebuildAuth(error.requestOptions)) {
          final clone = await _retry(error.requestOptions);
          return handler.resolve(clone);
        }
        return handler.next(error);
      },
    ));

    if (kDebugMode) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onError: (error, handler) {
            final status = error.response?.statusCode;
            final body = error.response?.data;
            debugPrint(
              '[DIO][ERROR] ${error.requestOptions.method} ${error.requestOptions.uri} -> ${status ?? 'n/a'}',
            );
            if (body != null) {
              debugPrint('[DIO][ERROR][BODY] ${body.toString()}');
            }
            return handler.next(error);
          },
        ),
      );
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestBody: true,
          responseBody: true,
          error: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }
  }

  Future<void> _attachAuth(RequestOptions options) async {
    final isPublic = options.extra['requiresAuth'] == false ||
        options.path.contains('/api/auth/login') ||
        options.path.contains('/api/auth/register') ||
        options.path.contains('/api/auth/refresh');
    if (isPublic) return;

    final token = await _tokenStorage.accessToken;
    if (token != null && (options.headers['Authorization'] == null)) {
      options.headers['Authorization'] = 'Bearer $token';
    }
  }

  bool _shouldRetry(RequestOptions options) {
    if (options.extra['retried'] == true) return false;
    final method = options.method.toUpperCase();
    return method == 'GET' || method == 'PUT' || method == 'PATCH' || method == 'DELETE' || options.extra['idempotent'] == true;
  }

  Future<bool> _refreshAndRebuildAuth(RequestOptions failedRequest) async {
    final refresh = await _tokenStorage.refreshToken;
    if (refresh == null) return false;

    if (_isRefreshing) {
      try {
        await _refreshCompleter?.future;
        final newAccess = await _tokenStorage.accessToken;
        if (newAccess != null) {
          failedRequest.headers['Authorization'] = 'Bearer $newAccess';
          failedRequest.extra['retried'] = true;
          return true;
        }
        return false;
      } catch (_) {
        return false;
      }
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<void>();

    try {
      final response = await dio.post(
        '/api/auth/refresh',
        data: {'refreshToken': refresh},
        options: Options(headers: {'Authorization': null}),
      );
      final newAccess = response.data['token'] as String?;
      final newRefresh = response.data['refreshToken'] as String?;
      await _tokenStorage.saveTokens(accessToken: newAccess, refreshToken: newRefresh ?? refresh);
      failedRequest.headers['Authorization'] = 'Bearer $newAccess';
      failedRequest.extra['retried'] = true;
      _refreshCompleter?.complete();
      return newAccess != null;
    } catch (e) {
      await _tokenStorage.clear();
      _refreshCompleter?.completeError(e);
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) {
    return dio.fetch(requestOptions);
  }

  Future<void> persistTokens({String? accessToken, String? refreshToken}) {
    return _tokenStorage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<void> clearTokens() => _tokenStorage.clear();
}

// Backwards-compatible wrapper for existing usages.
class HttpClient {
  Dio get dio => ApiClient().dio;
  TokenStorage get tokenStorage => ApiClient().tokenStorage;
}

// Legacy helper to keep older code paths working.
String get apiBaseUrl => AppConfig.current.apiBaseUrl;
