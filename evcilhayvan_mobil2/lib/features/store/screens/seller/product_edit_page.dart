import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/product_controller.dart';
import '../../domain/models/product_model.dart';
import '../../providers/product_providers.dart';

class ProductEditPage extends ConsumerStatefulWidget {
  const ProductEditPage({super.key, required this.product});
  final ProductModel product;

  @override
  ConsumerState<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends ConsumerState<ProductEditPage> {
  final _formKey = GlobalKey<FormState>();
  late String name = widget.product.title;
  late String description = widget.product.description ?? '';
  late double price = widget.product.price;
  late int stock = widget.product.stock;
  late bool isActive = widget.product.isActive;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productControllerProvider);
    final controller = ref.read(productControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text("Ürün Düzenle")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: "Ürün adı"),
                onChanged: (v) => name = v,
              ),
              TextFormField(
                initialValue: description,
                decoration: const InputDecoration(labelText: "Açıklama"),
                onChanged: (v) => description = v,
              ),
              TextFormField(
                initialValue: price.toString(),
                decoration: const InputDecoration(labelText: "Fiyat"),
                keyboardType: TextInputType.number,
                onChanged: (v) => price = double.tryParse(v) ?? price,
              ),
              TextFormField(
                initialValue: stock.toString(),
                decoration: const InputDecoration(labelText: "Stok"),
                keyboardType: TextInputType.number,
                onChanged: (v) => stock = int.tryParse(v) ?? stock,
              ),
              SwitchListTile(
                value: isActive,
                title: const Text("Aktif"),
                onChanged: (v) => setState(() => isActive = v),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () async {
                        final data = {
                          "name": name,
                          "description": description,
                          "price": price,
                          "stock": stock,
                          "isActive": isActive,
                        };
                        await controller.update(widget.product.id, data);
                        ref.invalidate(sellerProductsProvider);
                        if (mounted) Navigator.pop(context);
                      },
                child: Text(state.isLoading ? 'Güncelleniyor...' : 'Güncelle'),
              ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Güncelleme başarısız.',
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
