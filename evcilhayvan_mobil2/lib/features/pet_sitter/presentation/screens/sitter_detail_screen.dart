import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_palette.dart';
import 'package:evcilhayvan_mobil2/features/auth/data/repositories/auth_repository.dart';
import '../../data/repositories/pet_sitter_repository.dart';
import '../../domain/models/pet_sitter_model.dart';

class SitterDetailScreen extends ConsumerWidget {
  final String sitterId;
  const SitterDetailScreen({super.key, required this.sitterId});

  String _r(String url) => url.startsWith('http') ? url : '$apiBaseUrl$url';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sitterDetailProvider(sitterId));
    final user = ref.watch(authProvider);

    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Hata: $e'))),
      data: (data) {
        final sitter = data['sitter'] as PetSitterModel;
        final reviews = data['reviews'] as List<SitterReview>;
        final photo = sitter.avatar?.isNotEmpty == true ? sitter.avatar! : (sitter.photos.isNotEmpty ? sitter.photos.first : '');

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: Colors.green.shade700,
                flexibleSpace: FlexibleSpaceBar(
                  background: photo.isNotEmpty
                      ? CachedNetworkImage(imageUrl: _r(photo), fit: BoxFit.cover)
                      : Container(color: Colors.indigo.shade100,
                          child: const Center(child: Icon(Icons.person, size: 80, color: Colors.indigo))),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Text(sitter.displayName,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          if (sitter.isVerified)
                            const Chip(
                              label: Text('Dogrulanmis', style: TextStyle(fontSize: 11)),
                              avatar: Icon(Icons.verified, size: 14, color: Colors.blue),
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Rating + Distance
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text('${sitter.rating.toStringAsFixed(1)} (${sitter.reviewCount} yorum)',
                              style: Theme.of(context).textTheme.bodyMedium),
                          if (sitter.distanceKm != null) ...[
                            const SizedBox(width: 16),
                            Icon(Icons.location_on, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            Text('${sitter.distanceKm!.toStringAsFixed(1)} km',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Availability
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: sitter.availability ? Colors.green.withOpacity(0.1) : Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          sitter.availability ? 'Simdi Musait' : 'Simdilik Dolu',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: sitter.availability ? Colors.green.shade700 : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bio
                      if (sitter.bio?.isNotEmpty == true) ...[
                        Text('Hakkinda', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(sitter.bio!, style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 16),
                      ],

                      // Services + Prices
                      Text('Hizmetler ve Fiyatlar',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: sitter.services.map((s) => ListTile(
                            leading: const Icon(Icons.pets, color: AppPalette.primary),
                            title: Text(s.label),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (s.pricePerHour > 0)
                                  Text('${s.pricePerHour.toInt()} TL/saat',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                if (s.pricePerDay > 0)
                                  Text('${s.pricePerDay.toInt()} TL/gun',
                                      style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          )).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Species
                      Text('Bakilan Turler',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(sitter.speciesLabel, style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 16),

                      // Address
                      if (sitter.address?.isNotEmpty == true) ...[
                        Text('Konum', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.location_on, color: AppPalette.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(sitter.address!)),
                        ]),
                        const SizedBox(height: 16),
                      ],

                      // Reviews
                      if (reviews.isNotEmpty) ...[
                        Text('Yorumlar (${reviews.length})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...reviews.map((r) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      child: Text((r.ownerName ?? '?')[0].toUpperCase()),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(r.ownerName ?? 'Kullanici',
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const Spacer(),
                                    ...List.generate(5, (i) => Icon(
                                      i < r.rating ? Icons.star : Icons.star_border,
                                      color: Colors.amber, size: 14,
                                    )),
                                  ],
                                ),
                                if (r.comment?.isNotEmpty == true) ...[
                                  const SizedBox(height: 6),
                                  Text(r.comment!),
                                ],
                              ],
                            ),
                          ),
                        )),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: user != null && sitter.availability
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: () => context.pushNamed('sitter-booking',
                          pathParameters: {'sitterId': sitter.id},
                          extra: sitter),
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('Rezervasyon Yap', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}
