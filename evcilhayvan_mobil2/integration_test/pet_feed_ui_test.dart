import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/features/pets/data/repositories/pets_repository.dart';
import 'package:evcilhayvan_mobil2/features/pets/domain/models/pet_model.dart';
import 'package:evcilhayvan_mobil2/features/pets/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Home shows empty state when no pets', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          petFeedProvider.overrideWith(() => _FakePetFeedNotifier(const [])),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Henuz ilan yok'), findsOneWidget);
  });

  testWidgets('Home shows error view on failure', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          petFeedProvider.overrideWith(() => _ErrorPetFeedNotifier()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.textContaining('Test hata'), findsOneWidget);
  });
}

class _FakePetFeedNotifier extends PetFeedNotifier {
  _FakePetFeedNotifier(this._pets);
  final List<Pet> _pets;

  @override
  Future<List<Pet>> build() async => _pets;
}

class _ErrorPetFeedNotifier extends PetFeedNotifier {
  @override
  Future<List<Pet>> build() {
    throw ApiError('Test hata');
  }
}
