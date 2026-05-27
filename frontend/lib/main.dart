import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'core/config/env_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
  );

  // Give the browser engine time to settle its WebGL context before the first frame
  if (kIsWeb) {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  runApp(
    const ProviderScope(
      child: SafePathApp(),
    ),
  );
}

class SafePathApp extends ConsumerWidget {
  const SafePathApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeSettings = ref.watch(themeProvider);
    
    // Initialize heartbeat service
    ref.watch(heartbeatProvider);

    return MaterialApp.router(
      title: 'Safe Path',
      theme: AppTheme.getTheme(themeSettings.mode, themeSettings.primaryColor, themeSettings.secondaryColor),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
