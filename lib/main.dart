import 'package:flutter/material.dart';

import 'app/app_root.dart';
import 'design/theme/app_theme.dart';

void main() {
  runApp(const PerfectDayApp());
}

class PerfectDayApp extends StatelessWidget {
  const PerfectDayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perfect Day',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AppRoot(),
    );
  }
}
