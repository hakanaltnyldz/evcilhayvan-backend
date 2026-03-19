import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_config.dart';
import 'main.dart';

void main() {
  AppConfig.init(
    apiBaseUrl: const String.fromEnvironment('API_BASE', defaultValue: 'http://10.0.2.2:4000'),
    flavor: 'dev',
  );
  runApp(const ProviderScope(child: MyApp()));
}
