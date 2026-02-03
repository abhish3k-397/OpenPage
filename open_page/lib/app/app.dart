import 'package:flutter/material.dart';
import 'router.dart';
import 'theme.dart';

class OpenPageApp extends StatelessWidget {
  const OpenPageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenPage',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routes: AppRouter.routes,
      initialRoute: '/check',
      debugShowCheckedModeBanner: false,
    );
  }
}
