import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/product_controller.dart';
import '../../domain/models/product_model.dart';
import '../../providers/product_providers.dart';
import '../../providers/store_providers.dart' as catalog;

class ProductAddPage extends ConsumerStatefulWidget {
  const ProductAddPage({super.key});

  @override
  ConsumerState<ProductAddPage> createState() => _ProductAddPageState();
}

class _ProductAddPageState extends ConsumerState<ProductAddPage> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String description = '';
  double price = 0;
  int stock = 0;
  String? categoryId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productControllerProvider);
    final controller = ref.read(productControllerProvider.notifier);
    final categoriesAsync = ref.watch(catalog.categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Ürün Ekle")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: "Ürün adı"),
                onChanged: (v) => name = v,
                validator: (v) => (v == null || v.isEmpty) ? "Zorunlu" : null,
              ),
              const SizedBox(height: 12),
              categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return const Text('Kategori bulunamadı.');
                  }
                  return DropdownButtonFormField<String>(
                    value: categoryId,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => categoryId = value),
                    validator: (_) => categoryId == null ? 'Kategori seçin' : null,
                  );
                },
                loading: () => const Text('Kategoriler yükleniyor...'),
                error: (e, _) => Text('Kategoriler yüklenemedi: $e'),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Açıklama"),
                onChanged: (v) => description = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Fiyat"),
                keyboardType: TextInputType.number,
                onChanged: (v) => price = double.tryParse(v) ?? 0,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Stok"),
                keyboardType: TextInputType.number,
                onChanged: (v) => stock = int.tryParse(v) ?? 0,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        final model = ProductModel(
                          id: "",
                          title: name,
                          description: description,
                          price: price,
                          stock: stock,
                          photos: const [],
                          isActive: true,
                          categoryId: categoryId,
                        );
                        await controller.create(model);
                        ref.invalidate(sellerProductsProvider);
                        if (mounted) Navigator.pop(context);
                      },
                child: Text(state.isLoading ? "Kaydediliyor..." : "Kaydet"),
              ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    state.error.toString(),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
