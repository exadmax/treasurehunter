import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/admin/admin_setup_screen.dart';
import '../screens/admin/admin_treasures_screen.dart';
import '../screens/admin/admin_lobby_screen.dart';
import '../screens/hunter/hunter_register_screen.dart';
import '../screens/hunter/hunter_waiting_screen.dart';
import '../screens/hunter/hunter_main_screen.dart';
import '../screens/common/leaderboard_screen.dart';
import '../screens/common/podium_screen.dart';
import '../screens/home_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const HomeScreen(),
    ),
    // Admin routes
    GoRoute(
      path: '/admin/setup',
      builder: (_, __) => const AdminSetupScreen(),
    ),
    GoRoute(
      path: '/admin/treasures/:huntId',
      builder: (_, state) =>
          AdminTreasuresScreen(huntId: state.pathParameters['huntId']!),
    ),
    GoRoute(
      path: '/admin/lobby/:huntId',
      builder: (_, state) =>
          AdminLobbyScreen(huntId: state.pathParameters['huntId']!),
    ),
    // Hunter routes
    GoRoute(
      path: '/hunt/:huntId/register',
      builder: (_, state) =>
          HunterRegisterScreen(huntId: state.pathParameters['huntId']!),
    ),
    GoRoute(
      path: '/hunt/:huntId/waiting/:hunterId',
      builder: (_, state) => HunterWaitingScreen(
        huntId: state.pathParameters['huntId']!,
        hunterId: state.pathParameters['hunterId']!,
      ),
    ),
    GoRoute(
      path: '/hunt/:huntId/play/:hunterId',
      builder: (_, state) => HunterMainScreen(
        huntId: state.pathParameters['huntId']!,
        hunterId: state.pathParameters['hunterId']!,
      ),
    ),
    // Shared routes
    GoRoute(
      path: '/hunt/:huntId/leaderboard',
      builder: (_, state) =>
          LeaderboardScreen(huntId: state.pathParameters['huntId']!),
    ),
    GoRoute(
      path: '/hunt/:huntId/podium',
      builder: (_, state) =>
          PodiumScreen(huntId: state.pathParameters['huntId']!),
    ),
  ],
  errorBuilder: (_, state) => Scaffold(
    body: Center(child: Text('Página não encontrada: ${state.error}')),
  ),
);
