// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evcilhayvan_mobil2/router/app_router.dart';
import 'package:evcilhayvan_mobil2/core/theme/app_theme.dart';
import 'package:evcilhayvan_mobil2/core/providers/theme_provider.dart';
import 'package:evcilhayvan_mobil2/core/providers/locale_provider.dart';
import 'package:evcilhayvan_mobil2/core/providers/onboarding_provider.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr', null);
  // Firebase — graceful if google-services.json not added yet
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  final onboardingSeen = await loadOnboardingSeen();

  // Load saved locale once before runApp (avoids calling load() on every build)
  final prefs = await SharedPreferences.getInstance();
  final localeCode = prefs.getString('app_locale') ?? 'tr';
  final savedLocale = Locale(localeCode);

  runApp(ProviderScope(
    overrides: [
      onboardingSeenProvider.overrideWith((ref) => onboardingSeen),
      localeProvider.overrideWith((ref) => LocaleNotifier(savedLocale)),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Evcil Hayvan App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
      ],
      routerConfig: ref.watch(routerProvider),
    );
  }
}
