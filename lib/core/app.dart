import 'package:flutter/material.dart';

import 'routing/app_router.dart';
import 'theme/app_theme.dart';

class XunyinApp extends StatelessWidget {
  const XunyinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '寻音',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
