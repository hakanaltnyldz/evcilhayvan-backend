import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/store_providers.dart';
import 'product_detail_page.dart';

class StoreHomePage extends ConsumerStatefulWidget {
  const StoreHomePage({super.key});

  @override
  ConsumerState<StoreHomePage> createState() => _StoreHomePageState();
}

class _StoreHomePageState extends ConsumerState<StoreHomePage> {
  String? selectedCategory;

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(storeProductsProvider((category: selectedCategory, q: null)));
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mağaza')),
      body: Column(
        children: [
          categories.when(
            data: (list) => SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                itemBuilder: (ctx, i) {
                  final c = list[i];
                  final selected = selectedCategory == c.id;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: ChoiceChip(
                      label: Text(c.name),
                      selected: selected,
                      onSelected: (_) => setState(() {
                        selectedCategory = selected ? null : c.id;
                      }),
                    ),
                  );
                },
              ),
            ),
            loading: () => const SizedBox(
              height: 48,
              child: Center(child: Text('Yükleniyor...')),
            ),
            error: (e, _) => const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Kategoriler yüklenemedi.'),
            ),
          ),
          Expanded(
            child: products.when(
              data: (list) => ListView.builder(
                itemCount: list.length,
                itemBuilder: (ctx, i) => ListTile(
                  title: Text(list[i].title),
                  subtitle: Text("${list[i].price.toStringAsFixed(2)} TL"),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProductDetailPage(id: list[i].id)),
                  ),
                ),
              ),
              loading: () => const Center(child: Text('Ürünler yükleniyor...')),
              error: (e, _) => const Center(child: Text('Ürünler yüklenemedi.')),
            ),
          ),
        ],
      ),
    );
  }
}
