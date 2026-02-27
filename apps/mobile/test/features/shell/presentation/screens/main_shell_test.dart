import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pebee_mobile/features/auth/providers/auth_provider.dart';
import 'package:pebee_mobile/features/shell/presentation/screens/main_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/mocks.dart';

/// Empty asset loader so [.tr()] returns the raw key string.
class _EmptyAssetLoader extends AssetLoader {
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {};
}

void main() {
  late FakeAuthNotifier fakeNotifier;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    fakeNotifier = FakeAuthNotifier();
  });

  /// Pumps a GoRouter with StatefulShellRoute directly (not via pumpApp)
  /// so we can use the real shell route mechanism.
  Future<void> pumpMainShell(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/shell/tab1',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/shell/tab1',
                builder: (_, __) =>
                    const Center(child: Text('TAB_1_CONTENT')),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/shell/tab2',
                builder: (_, __) =>
                    const Center(child: Text('TAB_2_CONTENT')),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/shell/tab3',
                builder: (_, __) =>
                    const Center(child: Text('TAB_3_CONTENT')),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/shell/tab4',
                builder: (_, __) =>
                    const Center(child: Text('TAB_4_CONTENT')),
              ),
            ]),
          ],
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
          overrides: [
            authNotifierProvider.overrideWith(() => fakeNotifier),
          ],
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
  }

  group('MainShell', () {
    testWidgets('renders 4 navigation destinations', (tester) async {
      await pumpMainShell(tester);

      expect(find.byType(NavigationDestination), findsNWidgets(4));
    });

    testWidgets('renders app bar with title', (tester) async {
      await pumpMainShell(tester);

      expect(find.text('Pebee Health'), findsOneWidget);
    });

    testWidgets('renders logout button', (tester) async {
      await pumpMainShell(tester);

      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('renders tab labels', (tester) async {
      await pumpMainShell(tester);

      expect(find.text('dashboard.tabs.home'), findsOneWidget);
      expect(find.text('dashboard.tabs.therapist'), findsOneWidget);
      expect(find.text('dashboard.tabs.mriReader'), findsOneWidget);
      expect(find.text('dashboard.tabs.wellbeing'), findsOneWidget);
    });

    testWidgets('first tab content is visible', (tester) async {
      await pumpMainShell(tester);

      expect(find.text('TAB_1_CONTENT'), findsOneWidget);
    });
  });
}
