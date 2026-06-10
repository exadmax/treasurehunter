import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/hunter.dart';
import '../../utils/rank_utils.dart';
import '../../models/treasure.dart';
import '../../services/hunt_service.dart';

class LeaderboardScreen extends StatelessWidget {
  final String huntId;
  const LeaderboardScreen({super.key, required this.huntId});

  @override
  Widget build(BuildContext context) {
    final service = context.read<HuntService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Placar 🏆'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<List<Hunter>>(
        stream: service.watchHunters(huntId),
        builder: (context, huntersSnap) {
          return StreamBuilder<List<Treasure>>(
            stream: service.watchTreasures(huntId),
            builder: (context, treasuresSnap) {
              final hunters = sortHuntersByRank(huntersSnap.data ?? []);
              final allTreasures = treasuresSnap.data ?? [];

              if (hunters.isEmpty) {
                return const Center(
                    child: Text('Nenhum caçador registrado.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: hunters.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _LeaderboardTile(
                  rank: i + 1,
                  hunter: hunters[i],
                  allTreasures: allTreasures,
                ),
              );
            },
          );
        },
      ),
    );
  }
        // Tiebreak by last capture timestamp (earlier = better)
        final aTs = a.lastCaptureTimestamp?.millisecondsSinceEpoch ?? 0;
        final bTs = b.lastCaptureTimestamp?.millisecondsSinceEpoch ?? 0;
        if (aTs == 0 && bTs == 0) return 0;
        if (aTs == 0) return 1;
        if (bTs == 0) return -1;
        return aTs.compareTo(bTs);
      });
  }
}

class _LeaderboardTile extends StatelessWidget {
  final int rank;
  final Hunter hunter;
  final List<Treasure> allTreasures;

  const _LeaderboardTile({
    required this.rank,
    required this.hunter,
    required this.allTreasures,
  });

  @override
  Widget build(BuildContext context) {
    final collectedTreasures = allTreasures
        .where((t) => hunter.collectedTreasures.contains(t.id))
        .toList();

    final rankColors = {
      1: const Color(0xFFFFD700),
      2: const Color(0xFFC0C0C0),
      3: const Color(0xFFCD7F32),
    };

    final rankEmoji = {1: '🥇', 2: '🥈', 3: '🥉'};

    return Card(
      color: rank <= 3
          ? rankColors[rank]!.withOpacity(0.1)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Rank badge
            SizedBox(
              width: 40,
              child: Text(
                rankEmoji[rank] ?? '#$rank',
                style: TextStyle(
                  fontSize: rank <= 3 ? 24 : 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 8),

            // Selfie
            CircleAvatar(
              radius: 24,
              backgroundImage: hunter.selfieUrl != null
                  ? NetworkImage(hunter.selfieUrl!)
                  : null,
              backgroundColor: const Color(0xFFFFB703),
              child: hunter.selfieUrl == null
                  ? Text(hunter.name[0].toUpperCase(),
                      style:
                          const TextStyle(color: Colors.white))
                  : null,
            ),
            const SizedBox(width: 12),

            // Name and score
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hunter.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  Text(
                    '${hunter.collectedCount} tesouro${hunter.collectedCount != 1 ? 's' : ''} encontrado${hunter.collectedCount != 1 ? 's' : ''}',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Collected treasures thumbnails
            SizedBox(
              height: 40,
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: collectedTreasures.length.clamp(0, 5),
                itemBuilder: (_, i) {
                  final t = collectedTreasures[i];
                  return Padding(
                    padding:
                        const EdgeInsets.only(left: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: t.imageUrl != null
                          ? Image.network(t.imageUrl!,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover)
                          : Container(
                              width: 36,
                              height: 36,
                              color: Colors.amber[100],
                              child: const Icon(Icons.diamond,
                                  size: 20,
                                  color:
                                      Color(0xFFFFB703))),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
