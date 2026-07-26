import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'l10n/app_localizations.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_client.dart';
import 'services/auto_sync_service.dart';
import 'services/locale_service.dart';
import 'services/reminder_service.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await LocaleController.instance.load();
  await ThemeController.instance.load();
  await ReminderService.instance.init();
  final api = ApiClient();
  AutoSyncService.instance.attach(api);
  final loggedIn = await api.isLoggedIn();
  if (loggedIn) {
    await AutoSyncService.instance.start();
  }
  runApp(PcelinjakApp(api: api, startHome: loggedIn));
  FlutterNativeSplash.remove();
}

class PcelinjakApp extends StatelessWidget {
  const PcelinjakApp({super.key, required this.api, required this.startHome});

  final ApiClient api;
  final bool startHome;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        LocaleController.instance,
        ThemeController.instance,
      ]),
      builder: (context, _) {
        final locale = LocaleController.instance.locale;
        return MaterialApp(
          onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeController.instance.themeMode,
          locale: locale,
          supportedLocales: LocaleController.supported,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: startHome ? HomeScreen(api: api) : AuthScreen(api: api),
        );
      },
    );
  }
}
