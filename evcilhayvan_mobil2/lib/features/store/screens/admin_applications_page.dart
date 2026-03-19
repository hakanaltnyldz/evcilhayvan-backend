import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/seller_providers.dart';

class AdminApplicationsPage extends ConsumerWidget {
  const AdminApplicationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(adminApplicationsProvider);
    final repo = ref.watch(sellerRepoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Satıcı Başvuruları")),
      body: apps.when(
        data: (list) => ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, i) {
            final a = list[i];
            return ListTile(
              title: Text(a.companyName),
              subtitle: Text("Durum: ${a.status}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () async {
                      await repo.approve(a.id!);
                      ref.refresh(adminApplicationsProvider);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () async {
                      await repo.reject(a.id!, reason: "Admin reddi");
                      ref.refresh(adminApplicationsProvider);
                    },
                  ),
                ],
              ),
            );
          },
        ),
        loading: () => const Center(child: Text('Yükleniyor...')),
        error: (e, _) => const Center(child: Text('Başvurular yüklenemedi.')),
      ),
    );
  }
}
