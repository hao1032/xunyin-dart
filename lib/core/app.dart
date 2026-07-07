import 'package:flutter/material.dart';

import 'routing/app_router.dart';

class XunyinApp extends StatelessWidget {
  const XunyinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '寻音',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff0f766e),
          brightness: Brightness.light,
        ),
        cardTheme: const CardThemeData(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
      routerConfig: appRouter,
    );
  }
}
