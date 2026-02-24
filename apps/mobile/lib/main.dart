import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  // Keep native splash visible until async init completes
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Load translations before anything else
  await EasyLocalization.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
  );

  // Remove native splash — Flutter-level splash screen takes over
  FlutterNativeSplash.remove();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('sk'),
        Locale('en'),
        Locale('uk'),
        Locale('de'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('sk'),
      startLocale: const Locale('sk'),
      child: ProviderScope(
        observers: kDebugMode ? [_AppProviderObserver()] : [],
        child: const PebeeApp(),
      ),
    ),
  );
}

// ── Debug observer — active only in debug builds ───────────────────────────

/// Logs every Riverpod state change to the terminal.
/// Errors include the full stack trace so you can see exactly what Supabase
/// returned. This class is never instantiated in release builds.
class _AppProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (newValue is AsyncError) {
      debugPrint(
        '[Riverpod] ❌ ${provider.name ?? provider.runtimeType} error:\n'
        '${newValue.error}\n${newValue.stackTrace}',
      );
    } else if (newValue is AsyncLoading) {
      debugPrint('[Riverpod] ⏳ ${provider.name ?? provider.runtimeType} loading');
    } else if (newValue is AsyncData) {
      debugPrint('[Riverpod] ✅ ${provider.name ?? provider.runtimeType} updated');
    }
  }
}

// ── App widget ─────────────────────────────────────────────────────────────

class PebeeApp extends ConsumerWidget {
  const PebeeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Pebee Health',
      theme: AppTheme.light,
      routerConfig: router,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      debugShowCheckedModeBanner: false,
    );
  }
}
