import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/product_providers.dart';
import 'product_add_page.dart';
import 'product_edit_page.dart';

class ProductsPage extends ConsumerWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(sellerProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Ürünlerim")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductAddPage()),
        ),
        child: const Icon(Icons.add),
      ),
      body: products.when(
        data: (list) => ListView.builder(
          itemCount: list.length,
          itemBuilder: (ctx, i) {
            final p = list[i];
            return ListTile(
              title: Text(p.title),
              subtitle: Text("Stok: ${p.stock} • ${p.isActive ? "Aktif" : "Pasif"}"),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductEditPage(product: p)),
              ),
            );
          },
        ),
        loading: () => const Center(child: Text('Yükleniyor...')),
        error: (e, _) => const Center(child: Text('Ürünler yüklenemedi.')),
      ),
    );
  }
}
