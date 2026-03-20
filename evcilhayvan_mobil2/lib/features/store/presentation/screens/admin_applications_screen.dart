import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/seller_providers.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';

class AdminApplicationsPage extends ConsumerWidget {
  const AdminApplicationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(adminApplicationsProvider);
    final repo = ref.watch(sellerRepoProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.adminAppsTitle)),
      body: apps.when(
        data: (list) => ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, i) {
            final a = list[i];
            return ListTile(
              title: Text(a.companyName),
              subtitle: Text(AppLocalizations.of(context)!.adminAppsStatus(a.status)),
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
        loading: () => Center(child: Text(AppLocalizations.of(context)!.loading)),
        error: (e, _) => Center(child: Text(AppLocalizations.of(context)!.adminAppsLoadErr)),
      ),
    );
  }
}
