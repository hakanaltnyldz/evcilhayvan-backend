import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kOnboardingKey = 'onboarding_seen';

/// Whether the user has completed the onboarding flow.
/// Initialized in main() via override with the actual stored value.
final StateProvider<bool> onboardingSeenProvider = StateProvider<bool>(
  (ref) => false,
);

Future<bool> loadOnboardingSeen() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingKey) ?? false;
}

Future<void> markOnboardingSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingKey, true);
}
