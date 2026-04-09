import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_config.dart';
import 'main.dart';

void main() {
  AppConfig.init(
    apiBaseUrl: const String.fromEnvironment(
      'API_BASE',
      defaultValue: 'https://evcilhayvan-backend.onrender.com',
    ),
    flavor: 'prod',
  );
  runApp(const ProviderScope(child: MyApp()));
}
