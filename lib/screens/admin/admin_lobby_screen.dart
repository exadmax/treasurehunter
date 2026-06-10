import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/hunt.dart';
import '../../models/hunter.dart';
import '../../services/hunt_service.dart';

class AdminLobbyScreen extends StatelessWidget {
  final String huntId;
  const AdminLobbyScreen({super.key, required this.huntId});

  @override
  Widget build(BuildContext context) {
    final service = context.read<HuntService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sala de Espera 🎉'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/treasures/$huntId'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            tooltip: 'Placar',
            onPressed: () => context.go('/hunt/$huntId/leaderboard'),
          ),
        ],
      ),
      body: StreamBuilder<Hunt?>(
        stream: service.watchHunt(huntId),
        builder: (context, huntSnap) {
          final hunt = huntSnap.data;
          return StreamBuilder<List<Hunter>>(
            stream: service.watchHunters(huntId),
            builder: (context, huntersSnap) {
              final hunters = huntersSnap.data ?? [];

              return Column(
                children: [
                  _StatusBanner(hunt: hunt, hunterCount: hunters.length),
                  Expanded(
                    child: hunters.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.hourglass_empty,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('Aguardando caçadores...',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 18)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: hunters.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) =>
                                _HunterTile(hunter: hunters[i]),
                          ),
                  ),
                  _ActionButtons(
                    huntId: huntId,
                    hunt: hunt,
                    hunterCount: hunters.length,
                    service: service,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final Hunt? hunt;
  final int hunterCount;

  const _StatusBanner({this.hunt, required this.hunterCount});

  @override
  Widget build(BuildContext context) {
    final status = hunt?.status;
    Color bgColor;
    String text;

    switch (status) {
      case HuntStatus.active:
        bgColor = Colors.green.withOpacity(0.15);
        text = '🟢 Caçada em andamento';
        break;
      case HuntStatus.finished:
        bgColor = Colors.purple.withOpacity(0.15);
        text = '🏆 Caçada finalizada';
        break;
      default:
        bgColor = Colors.blue.withOpacity(0.1);
        text = '⏳ Aguardando ($hunterCount caçador${hunterCount != 1 ? 'es' : ''})';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: bgColor,
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          textAlign: TextAlign.center),
    );
  }
}

class _HunterTile extends StatelessWidget {
  final Hunter hunter;
  const _HunterTile({required this.hunter});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: hunter.selfieUrl != null
              ? NetworkImage(hunter.selfieUrl!)
              : null,
          backgroundColor: const Color(0xFFFFB703),
          child: hunter.selfieUrl == null
              ? Text(hunter.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white))
              : null,
        ),
        title: Text(hunter.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: hunter.collectedCount > 0
            ? Chip(
                label: Text('${hunter.collectedCount} 💎'),
                backgroundColor: const Color(0xFFFFB703).withOpacity(0.2),
              )
            : null,
      ),
    );
  }
}

class _ActionButtons extends StatefulWidget {
  final String huntId;
  final Hunt? hunt;
  final int hunterCount;
  final HuntService service;

  const _ActionButtons({
    required this.huntId,
    required this.hunt,
    required this.hunterCount,
    required this.service,
  });

  @override
  State<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<_ActionButtons> {
  bool _starting = false;
  bool _clearing = false;

  Future<void> _startHunt() async {
    if (widget.hunterCount < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('São necessários pelo menos 2 caçadores!')),
      );
      return;
    }
    setState(() => _starting = true);
    try {
      await widget.service.updateHuntStatus(
          widget.huntId, HuntStatus.active);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Limpar Dados'),
        content: const Text(
            'Isso apagará TODOS os dados da caçada (caçadores, tesouros e imagens).\n\nConfirmar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _clearing = true);
    try {
      await widget.service.clearSession(widget.huntId);
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao limpar dados: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hunt = widget.hunt;
    final isWaiting = hunt?.status == HuntStatus.waiting;
    final isActive = hunt?.status == HuntStatus.active;
    final isFinished = hunt?.status == HuntStatus.finished;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (isFinished)
            ElevatedButton.icon(
              onPressed: () =>
                  context.go('/hunt/${widget.huntId}/podium'),
              icon: const Icon(Icons.emoji_events),
              label: const Text('Ver Pódio'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          if (isWaiting || isActive) ...[
            if (isWaiting)
              ElevatedButton.icon(
                onPressed: _starting ? null : _startHunt,
                icon: _starting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.play_arrow),
                label: const Text('Iniciar Caçada'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
            if (isActive)
              ElevatedButton.icon(
                onPressed: () =>
                    context.go('/hunt/${widget.huntId}/leaderboard'),
                icon: const Icon(Icons.leaderboard),
                label: const Text('Ver Placar ao Vivo'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _clearing ? null : _clearData,
            icon: _clearing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.delete_forever,
                    color: Colors.red),
            label: const Text('Limpar Dados do Jogo',
                style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
