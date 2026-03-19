import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/seller_application_controller.dart';
import '../domain/models/seller_application_model.dart';

class SellerApplyPage extends ConsumerStatefulWidget {
  const SellerApplyPage({super.key});

  @override
  ConsumerState<SellerApplyPage> createState() => _SellerApplyPageState();
}

class _SellerApplyPageState extends ConsumerState<SellerApplyPage> {
  final _formKey = GlobalKey<FormState>();
  String companyName = '';
  String companyTitle = '';
  String taxNumber = '';
  String taxOffice = '';
  String address = '';
  String contactInfo = '';
  String iban = '';
  bool kvkkAccepted = false;
  bool contractAccepted = false;
  bool submitted = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sellerApplicationControllerProvider);
    final controller = ref.read(sellerApplicationControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Satıcı Ol')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Firma adı'),
                onChanged: (v) => companyName = v,
                validator: (v) => (v == null || v.isEmpty) ? 'Zorunlu' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Firma unvanı'),
                onChanged: (v) => companyTitle = v,
                validator: (v) => (v == null || v.isEmpty) ? 'Zorunlu' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Vergi numarası'),
                onChanged: (v) => taxNumber = v,
                validator: (v) => (v == null || v.isEmpty) ? 'Zorunlu' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Vergi dairesi'),
                onChanged: (v) => taxOffice = v,
                validator: (v) => (v == null || v.isEmpty) ? 'Zorunlu' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Adres'),
                onChanged: (v) => address = v,
                validator: (v) => (v == null || v.isEmpty) ? 'Zorunlu' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'İletişim'),
                onChanged: (v) => contactInfo = v,
                validator: (v) => (v == null || v.isEmpty) ? 'Zorunlu' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'IBAN'),
                onChanged: (v) => iban = v,
                validator: (v) => (v == null || v.isEmpty) ? 'Zorunlu' : null,
              ),
              CheckboxListTile(
                value: kvkkAccepted,
                onChanged: (v) => setState(() => kvkkAccepted = v ?? false),
                title: const Text('KVKK metnini onaylıyorum'),
              ),
              CheckboxListTile(
                value: contractAccepted,
                onChanged: (v) => setState(() => contractAccepted = v ?? false),
                title: const Text('Satıcı sözleşmesini onaylıyorum'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () {
                        if (!_formKey.currentState!.validate()) return;
                        if (!kvkkAccepted || !contractAccepted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Onaylar zorunlu')),
                          );
                          return;
                        }
                        final model = SellerApplicationModel(
                          companyName: companyName,
                          companyTitle: companyTitle,
                          taxNumber: taxNumber,
                          taxOffice: taxOffice,
                          address: address,
                          contactInfo: contactInfo,
                          iban: iban,
                          kvkkAccepted: kvkkAccepted,
                          contractAccepted: contractAccepted,
                        );
                        setState(() => submitted = true);
                        controller.submit(model);
                      },
                child: Text(state.isLoading ? 'Gönderiliyor...' : 'Başvuru gönder'),
              ),
              const SizedBox(height: 16),
              state.hasError
                  ? const Text(
                      'Başvuru gönderilemedi.',
                      style: TextStyle(color: Colors.red),
                    )
                  : const SizedBox.shrink(),
              submitted && !state.isLoading && !state.hasError
                  ? const Text('Başvurunuz inceleniyor')
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
