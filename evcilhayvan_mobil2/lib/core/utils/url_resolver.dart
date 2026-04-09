// lib/core/utils/url_resolver.dart
import 'package:evcilhayvan_mobil2/core/http.dart';

/// Sunucudan gelen relative ya da absolute URL'yi tam URL'ye çevirir.
///
/// Kullanım:
/// ```dart
/// Image.network(resolveImageUrl(product.imageUrl))
/// CachedNetworkImage(imageUrl: resolveImageUrl(user.avatarUrl))
/// ```
String resolveImageUrl(String? path) {
  if (path == null || path.trim().isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  // Başındaki '/' varsa iki kez eklemeyi önle
  final base = apiBaseUrl.endsWith('/') ? apiBaseUrl.substring(0, apiBaseUrl.length - 1) : apiBaseUrl;
  final p = path.startsWith('/') ? path : '/$path';
  return '$base$p';
}

/// Liste versiyonu — birden fazla URL'yi tek seferde çözer.
List<String> resolveImageUrls(List<String?> paths) =>
    paths.map(resolveImageUrl).where((url) => url.isNotEmpty).toList();
