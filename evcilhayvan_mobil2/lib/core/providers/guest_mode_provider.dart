import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kullanıcı "Giriş yapmadan devam et" butonuna bastığında true olur.
/// Uygulama açıldığında her seferinde false başlar (kalıcı değil).
final StateProvider<bool> guestModeProvider = StateProvider<bool>(
  (ref) => false,
);
