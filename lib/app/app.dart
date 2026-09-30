import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/storage/session_storage.dart';
import 'config/app_config.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_preview_screen.dart';

/// Root AceEdx Application Widget.
///
/// Supports either router-based navigation or direct preview.
class AceEdxApp extends StatefulWidget {
  final GoRouter? router;
  final SessionStorage? sessionStorage;
  final bool showPreview;

  const AceEdxApp({
    super.key,
    this.router,
    this.sessionStorage,
    this.showPreview = false,
  });

  @override
  State<AceEdxApp> createState() => _AceEdxAppState();
}

class _AceEdxAppState extends State<AceEdxApp> {
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    if (widget.router != null) {
      _router = widget.router;
    } else if (widget.sessionStorage != null) {
      _router = AppRouter.createRouter(widget.sessionStorage!);
    } else {
      _initAsyncRouter();
    }
  }

  Future<void> _initAsyncRouter() async {
    final storage = await SessionStorage.init();
    if (mounted) {
      setState(() {
        _router = AppRouter.createRouter(storage);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showPreview) {
      return MaterialApp(
        title: AppConfig.current.appTitle,
        debugShowCheckedModeBanner: AppConfig.isDev,
        theme: AppTheme.lightTheme,
        home: const ThemePreviewScreen(),
      );
    }

    if (_router != null) {
      return MaterialApp.router(
        title: AppConfig.current.appTitle,
        debugShowCheckedModeBanner: AppConfig.isDev,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
      );
    }

    return MaterialApp(
      title: AppConfig.current.appTitle,
      debugShowCheckedModeBanner: AppConfig.isDev,
      theme: AppTheme.lightTheme,
      home: const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
