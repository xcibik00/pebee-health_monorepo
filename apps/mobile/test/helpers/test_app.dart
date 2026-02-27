import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Call once in [setUpAll] for each test file that uses [pumpApp].
Future<void> initTestEnvironment() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
}

/// Empty asset loader so [.tr()] returns the raw key string.
/// This lets tests assert on translation keys without loading JSON files.
class _EmptyAssetLoader extends AssetLoader {
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {};
}

/// Pumps [child] inside a fully configured test shell:
/// EasyLocalization → ProviderScope → MaterialApp.router (GoRouter).
///
/// Returns the [GoRouter] instance so tests can inspect navigation state.
/// Translation keys (e.g. `'auth.login.title'`) appear as-is in the widget
/// tree because [_EmptyAssetLoader] returns no translations.
Future<GoRouter> pumpApp(
  WidgetTester tester, {
  required Widget child,
  String initialRoute = '/test',
  List<Override> overrides = const [],
}) async {
  final router = GoRouter(
    initialLocation: initialRoute,
    routes: [
      GoRoute(path: '/test', builder: (_, __) => child),
      GoRoute(
        path: '/login',
        builder: (_, __) => const Scaffold(body: Text('LOGIN_ROUTE')),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, __) => const Scaffold(body: Text('SIGNUP_ROUTE')),
      ),
      GoRoute(
        path: '/email-verification',
        builder: (_, __) => const Scaffold(body: Text('VERIFY_ROUTE')),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) =>
            const Scaffold(body: Text('FORGOT_PASSWORD_ROUTE')),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, __) =>
            const Scaffold(body: Text('RESET_PASSWORD_ROUTE')),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const Scaffold(body: Text('HOME_ROUTE')),
      ),
      GoRoute(
        path: '/home/dashboard',
        builder: (_, __) => const Scaffold(body: Text('DASHBOARD_ROUTE')),
      ),
      GoRoute(
        path: '/home/therapist',
        builder: (_, __) => const Scaffold(body: Text('THERAPIST_ROUTE')),
      ),
      GoRoute(
        path: '/home/mri-reader',
        builder: (_, __) =>
            const Scaffold(body: Text('MRI_READER_ROUTE')),
      ),
      GoRoute(
        path: '/home/wellbeing',
        builder: (_, __) =>
            const Scaffold(body: Text('WELLBEING_ROUTE')),
      ),
    ],
  );

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      assetLoader: _EmptyAssetLoader(),
      child: ProviderScope(
        overrides: overrides,
        child: Builder(
          builder: (context) => MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return router;
}
