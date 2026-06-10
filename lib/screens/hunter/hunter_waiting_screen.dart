import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/hunt.dart';
import '../../services/hunt_service.dart';

class HunterWaitingScreen extends StatelessWidget {
  final String huntId;
  final String hunterId;

  const HunterWaitingScreen({
    super.key,
    required this.huntId,
    required this.hunterId,
  });

  @override
  Widget build(BuildContext context) {
    final service = context.read<HuntService>();

    return StreamBuilder<Hunt?>(
      stream: service.watchHunt(huntId),
      builder: (context, snap) {
        final hunt = snap.data;

        // Redirect when game starts
        if (hunt?.status == HuntStatus.active) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/hunt/$huntId/play/$hunterId');
            }
          });
        }

        // Redirect when game finishes
        if (hunt?.status == HuntStatus.finished) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/hunt/$huntId/podium');
            }
          });
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFFF8E1),
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🏴‍☠️', style: TextStyle(fontSize: 80)),
                    const SizedBox(height: 32),
                    Text(
                      hunt?.name ?? 'Caça ao Tesouro',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF023047),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Aguardando o administrador\niniciar o jogo...',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.brown,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    const SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 5,
                        color: Color(0xFFFFB703),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      hunt?.mode == GameMode.differential
                          ? '⚔️ Modo: Diferencial\n(Cada tesouro é único!)'
                          : '🤝 Modo: Cumulativo\n(Todos podem pegar tudo!)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
