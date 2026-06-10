import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/hunt_provider.dart';
import '../models/hunt.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hunt = context.watch<HuntProvider>().hunt;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.travel_explore,
                    size: 96, color: Color(0xFFFFB703)),
                const SizedBox(height: 24),
                Text(
                  'Caça ao Tesouro! 🏴‍☠️',
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF023047),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Encontre todos os tesouros!',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.brown,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                if (hunt != null && hunt.status != HuntStatus.waiting) ...[
                  _buildHuntCard(context, hunt),
                  const SizedBox(height: 24),
                ],
                ElevatedButton.icon(
                  onPressed: () {
                    if (hunt != null) {
                      context.go('/hunt/${hunt.id}/register');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Nenhuma caçada disponível no momento.'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Sou Caçador!'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.go('/admin/setup'),
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Administrador'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    foregroundColor: const Color(0xFF023047),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHuntCard(BuildContext context, Hunt hunt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.flag, color: Color(0xFFFFB703), size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hunt.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    hunt.status == HuntStatus.active
                        ? '🟢 Em andamento'
                        : '🏆 Finalizada',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
