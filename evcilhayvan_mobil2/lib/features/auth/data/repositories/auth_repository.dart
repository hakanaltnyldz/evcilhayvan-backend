// lib/features/auth/data/repositories/auth_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/features/pets/data/repositories/pets_repository.dart';

import '../../domain/user_model.dart';

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier(ref);
});

final allUsersProvider = FutureProvider<List<User>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.getAllUsers();
});

final userPublicProfileProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, userId) async {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getUserPublicProfile(userId);
});

class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier(this.ref) : super(null) {
    _restoreSession();
  }

  final Ref ref;

  Future<void> _restoreSession() async {
    final token = await ApiClient().tokenStorage.accessToken;
    if (token == null || token.isEmpty) return;

    try {
      final user = await ref.read(authRepositoryProvider).me();
      state = user;
    } catch (_) {
      await ApiClient().clearTokens();
      state = null;
    }
  }

  void loginSuccess(User user) {
    state = user;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = null;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ApiClient();
  return AuthRepository(client);
});

class AuthRepository {
  AuthRepository(this._client);

  final ApiClient _client;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw ApiError.fromDio(e);
    } catch (e) {
      throw ApiError(e.toString());
    }
  }

  Future<void> _persistTokens(Map<String, dynamic> data) async {
    final token = data['token'] as String?;
    final refresh = data['refreshToken'] as String?;
    if (token != null) {
      await _client.persistTokens(accessToken: token, refreshToken: refresh);
    }
  }

  Future<User> _persistAndParseUser(Response response) async {
    await _persistTokens(response.data as Map<String, dynamic>);
    final userJson = response.data['user'] as Map<String, dynamic>?;
    if (userJson == null) throw ApiError('Beklenmeyen yanit');
    return User.fromJson(userJson);
  }

  Future<List<User>> getAllUsers() {
    return _guard(() async {
      final response = await _client.dio.get('/api/auth/users');
      final List<dynamic> userListJson = response.data['users'] ?? [];
      return userListJson.map((json) => User.fromJson(Map<String, dynamic>.from(json))).toList();
    });
  }

  Future<User> updateProfile({required String name, required String city, required String about}) {
    return _guard(() async {
      final response = await _client.dio.put(
        '/api/auth/me',
        data: {'name': name, 'city': city, 'about': about},
      );
      return User.fromJson(Map<String, dynamic>.from(response.data['user']));
    });
  }

  Future<User> login(String email, String password) {
    return _guard(() async {
      try {
        final response = await _client.dio.post(
          '/api/auth/login',
          data: {'email': email, 'password': password},
        );
        return _persistAndParseUser(response);
      } on DioException catch (e) {
        final apiError = ApiError.fromDio(e);
        if (apiError.code == 'email_not_verified') {
          throw VerificationRequiredException(
            apiError.message,
            email: email,
          );
        }
        throw apiError;
      }
    });
  }

  Future<String> register({required String name, required String email, required String password, String? city}) {
    return _guard(() async {
      final response = await _client.dio.post(
        '/api/auth/register',
        data: {'name': name, 'email': email, 'password': password, 'city': city},
      );
      return response.data['email'] ?? email;
    });
  }

  Future<User> verifyEmail({required String email, required String code}) {
    return _guard(() async {
      final response = await _client.dio.post('/api/auth/verify-email', data: {'email': email, 'code': code});
      return _persistAndParseUser(response);
    });
  }

  Future<void> forgotPassword({required String email}) {
    return _guard(() async {
      await _client.dio.post('/api/auth/forgot-password', data: {'email': email});
    });
  }

  Future<void> resetPassword({required String email, required String code, required String newPassword}) {
    return _guard(() async {
      await _client.dio.post(
        '/api/auth/reset-password',
        data: {'email': email, 'code': code, 'newPassword': newPassword},
      );
    });
  }

  Future<User> me() {
    return _guard(() async {
      final response = await _client.dio.get('/api/auth/me');
      final Map<String, dynamic> userJson = response.data['user'];
      return User.fromJson(userJson);
    });
  }

  Future<void> logout() async {
    await _client.clearTokens();
  }

  Future<User> uploadAvatar(XFile imageFile) {
    return _guard(() async {
      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        "avatar": await MultipartFile.fromFile(imageFile.path, filename: fileName),
      });
      final response = await _client.dio.post('/api/auth/avatar', data: formData);
      return User.fromJson(Map<String, dynamic>.from(response.data['user']));
    });
  }

  Future<User> loginWithGoogleToken(String idToken) {
    return _guard(() async {
      final response = await _client.dio.post('/api/auth/oauth/google', data: {'idToken': idToken});
      return _persistAndParseUser(response);
    });
  }

  Future<User> loginWithFacebookToken(String accessToken) {
    return _guard(() async {
      final response = await _client.dio.post('/api/auth/oauth/facebook', data: {'accessToken': accessToken});
      return _persistAndParseUser(response);
    });
  }

  Future<Map<String, dynamic>> getUserPublicProfile(String userId) {
    return _guard(() async {
      final response = await _client.dio.get('/api/auth/users/$userId');
      return response.data as Map<String, dynamic>;
    });
  }
}

class VerificationRequiredException implements Exception {
  final String message;
  final String email;
  VerificationRequiredException(this.message, {required this.email});

  @override
  String toString() => message;
}
