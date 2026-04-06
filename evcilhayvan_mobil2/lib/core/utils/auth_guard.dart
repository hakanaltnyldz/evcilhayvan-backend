import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Misafir kullanıcı auth gerektiren işlem yapmaya çalıştığında dialog gösterir.
/// true döndürürse işleme devam et, false ise iptal et.
Future<bool> showLoginRequired(BuildContext context, {String? reason}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.lock_outline, color: Color(0xFF2D6A4F), size: 22),
          SizedBox(width: 8),
          Text('Giriş Gerekiyor', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Text(
        reason ?? 'Bu işlemi yapabilmek için giriş yapman gerekiyor.',
        style: const TextStyle(fontSize: 14, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Vazgeç', style: TextStyle(color: Colors.grey)),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx, false);
            ctx.pushNamed('login');
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2D6A4F),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Giriş Yap'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx, false);
            ctx.pushNamed('register');
          },
          child: const Text('Kayıt Ol', style: TextStyle(color: Color(0xFF40916C), fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
  return result == true;
}
