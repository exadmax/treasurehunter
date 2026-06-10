import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'app_router.dart';
import 'app_theme.dart';
import 'services/hunt_service.dart';
import 'services/hunt_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TreasureHunterApp());
}

class TreasureHunterApp extends StatelessWidget {
  const TreasureHunterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final service = HuntService();
    return MultiProvider(
      providers: [
        Provider<HuntService>.value(value: service),
        ChangeNotifierProvider(create: (_) => HuntProvider(service)),
      ],
      child: MaterialApp.router(
        title: 'Caça ao Tesouro',
        theme: buildTheme(),
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
