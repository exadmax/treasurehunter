import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/hunter.dart';
import '../../utils/rank_utils.dart';
import '../../services/hunt_service.dart';

class PodiumScreen extends StatelessWidget {
  final String huntId;
  const PodiumScreen({super.key, required this.huntId});

  @override
  Widget build(BuildContext context) {
    final service = context.read<HuntService>();

    return Scaffold(
      backgroundColor: const Color(0xFF023047),
      body: StreamBuilder<List<Hunter>>(
        stream: service.watchHunters(huntId),
        builder: (context, snap) {
          final hunters = sortHuntersByRank(snap.data ?? []);
          final top3 = hunters.take(3).toList();

          return SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                const Text(
                  '🏆 Pódio 🏆',
                  style: TextStyle(
                    color: Color(0xFFFFB703),
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Parabéns aos campeões!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: top3.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFFFB703)))
                      : _PodiumDisplay(top3: top3),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (hunters.length > 3) ...[
                        _OtherRankings(hunters: hunters.skip(3).toList()),
                        const SizedBox(height: 16),
                      ],
                      TextButton.icon(
                        onPressed: () => context.go('/'),
                        icon: const Icon(Icons.home,
                            color: Colors.white70),
                        label: const Text('Início',
                            style: TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
        final aTs = a.lastCaptureTimestamp?.millisecondsSinceEpoch ?? 0;
        final bTs = b.lastCaptureTimestamp?.millisecondsSinceEpoch ?? 0;
        if (aTs == 0 && bTs == 0) return 0;
        if (aTs == 0) return 1;
        if (bTs == 0) return -1;
        return aTs.compareTo(bTs);
      });
  }
}

class _PodiumDisplay extends StatelessWidget {
  final List<Hunter> top3;
  const _PodiumDisplay({required this.top3});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (top3.length >= 2)
          _PodiumPlace(
            hunter: top3[1],
            place: 2,
            height: 120,
            color: const Color(0xFFC0C0C0),
            emoji: '🥈',
          ),
        const SizedBox(width: 8),
        _PodiumPlace(
          hunter: top3[0],
          place: 1,
          height: 160,
          color: const Color(0xFFFFD700),
          emoji: '🥇',
        ),
        const SizedBox(width: 8),
        if (top3.length >= 3)
          _PodiumPlace(
            hunter: top3[2],
            place: 3,
            height: 90,
            color: const Color(0xFFCD7F32),
            emoji: '🥉',
          ),
      ],
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  final Hunter hunter;
  final int place;
  final double height;
  final Color color;
  final String emoji;

  const _PodiumPlace({
    required this.hunter,
    required this.place,
    required this.height,
    required this.color,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = place == 1 ? 72.0 : 56.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 8),
        CircleAvatar(
          radius: avatarSize / 2,
          backgroundImage: hunter.selfieUrl != null
              ? NetworkImage(hunter.selfieUrl!)
              : null,
          backgroundColor: color,
          child: hunter.selfieUrl == null
              ? Text(
                  hunter.name[0].toUpperCase(),
                  style: TextStyle(
                      fontSize: avatarSize * 0.4,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                )
              : null,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 90,
          child: Text(
            hunter.name,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: place == 1 ? 14 : 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '${hunter.collectedCount} 💎',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Container(
          width: 90,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text(
              '#$place',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: place == 1 ? 28 : 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OtherRankings extends StatelessWidget {
  final List<Hunter> hunters;
  const _OtherRankings({required this.hunters});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(color: Colors.white30),
        for (int i = 0; i < hunters.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '#${i + 4}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                CircleAvatar(
                  radius: 16,
                  backgroundImage: hunters[i].selfieUrl != null
                      ? NetworkImage(hunters[i].selfieUrl!)
                      : null,
                  backgroundColor: Colors.grey,
                  child: hunters[i].selfieUrl == null
                      ? Text(hunters[i].name[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12))
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hunters[i].name,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Text(
                  '${hunters[i].collectedCount} 💎',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
