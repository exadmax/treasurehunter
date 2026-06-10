import 'package:flutter/material.dart';

/// Duration to show QR scan result feedback before closing the scanner.
const Duration _kScannerFeedbackDuration = Duration(seconds: 2);
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../models/hunt.dart';
import '../../models/hunter.dart';
import '../../models/treasure.dart';
import '../../services/hunt_service.dart';

class HunterMainScreen extends StatefulWidget {
  final String huntId;
  final String hunterId;

  const HunterMainScreen({
    super.key,
    required this.huntId,
    required this.hunterId,
  });

  @override
  State<HunterMainScreen> createState() => _HunterMainScreenState();
}

class _HunterMainScreenState extends State<HunterMainScreen> {
  bool _scannerOpen = false;

  @override
  Widget build(BuildContext context) {
    final service = context.read<HuntService>();

    return StreamBuilder<Hunt?>(
      stream: service.watchHunt(widget.huntId),
      builder: (context, huntSnap) {
        final hunt = huntSnap.data;

        // Auto-redirect on game finish
        if (hunt?.status == HuntStatus.finished) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/hunt/${widget.huntId}/podium');
            }
          });
        }

        return StreamBuilder<List<Hunter>>(
          stream: service.watchHunters(widget.huntId),
          builder: (context, huntersSnap) {
            final hunters = huntersSnap.data ?? [];
            final me = hunters
                .where((h) => h.id == widget.hunterId)
                .firstOrNull;

            return StreamBuilder<List<Treasure>>(
              stream: service.watchTreasures(widget.huntId),
              builder: (context, treasuresSnap) {
                final allTreasures = treasuresSnap.data ?? [];
                final collected = me?.collectedTreasures ?? [];
                final collectedTreasures = allTreasures
                    .where((t) => collected.contains(t.id))
                    .toList();

                return Scaffold(
                  appBar: AppBar(
                    title: Text(me?.name ?? 'Caçador'),
                    leading: CircleAvatar(
                      backgroundImage: me?.selfieUrl != null
                          ? NetworkImage(me!.selfieUrl!)
                          : null,
                      backgroundColor: const Color(0xFFFFB703),
                      child: me?.selfieUrl == null
                          ? Text(
                              me?.name[0].toUpperCase() ?? '?',
                              style:
                                  const TextStyle(color: Colors.white),
                            )
                          : null,
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.leaderboard),
                        tooltip: 'Placar',
                        onPressed: () => context
                            .go('/hunt/${widget.huntId}/leaderboard'),
                      ),
                    ],
                  ),
                  body: Column(
                    children: [
                      // Score banner
                      _ScoreBanner(
                        collected: me?.collectedCount ?? 0,
                        total: allTreasures.length,
                      ),
                      // Treasure grid
                      Expanded(
                        child: _TreasureGrid(
                          allTreasures: allTreasures,
                          collectedIds: collected,
                        ),
                      ),
                    ],
                  ),
                  floatingActionButton:
                      FloatingActionButton.extended(
                    onPressed: () =>
                        _openScanner(context, hunt, service),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Ler QR Code'),
                    backgroundColor: const Color(0xFFFFB703),
                    foregroundColor: const Color(0xFF023047),
                  ),
                  floatingActionButtonLocation:
                      FloatingActionButtonLocation.centerFloat,
                );
              },
            );
          },
        );
      },
    );
  }

  void _openScanner(
      BuildContext context, Hunt? hunt, HuntService service) {
    if (hunt == null) return;
    setState(() => _scannerOpen = true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _QrScannerSheet(
        huntId: widget.huntId,
        hunterId: widget.hunterId,
        hunt: hunt,
        service: service,
      ),
    ).whenComplete(() => setState(() => _scannerOpen = false));
  }
}

class _ScoreBanner extends StatelessWidget {
  final int collected;
  final int total;

  const _ScoreBanner({required this.collected, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: const Color(0xFFFFB703).withOpacity(0.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.diamond, color: Color(0xFFFFB703)),
          const SizedBox(width: 8),
          Text(
            '$collected / $total tesouros encontrados',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _TreasureGrid extends StatelessWidget {
  final List<Treasure> allTreasures;
  final List<String> collectedIds;

  const _TreasureGrid({
    required this.allTreasures,
    required this.collectedIds,
  });

  @override
  Widget build(BuildContext context) {
    if (allTreasures.isEmpty) {
      return const Center(child: Text('Nenhum tesouro cadastrado.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: allTreasures.length,
      itemBuilder: (_, i) {
        final treasure = allTreasures[i];
        final isCollected = collectedIds.contains(treasure.id);
        return _TreasureCard(
            treasure: treasure, isCollected: isCollected);
      },
    );
  }
}

/// ITU-R BT.709 luminance-based grayscale color matrix.
/// Used to desaturate uncollected treasure images.
const List<double> _kGrayscaleMatrix = [
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0,      0,      0,      1, 0,
];

class _TreasureCard extends StatelessWidget {
  final Treasure treasure;
  final bool isCollected;

  const _TreasureCard(
      {required this.treasure, required this.isCollected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isCollected
            ? const Color(0xFFFFB703).withOpacity(0.2)
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isCollected ? const Color(0xFFFFB703) : Colors.grey[300]!,
          width: isCollected ? 2 : 1,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: treasure.imageUrl != null
                ? ColorFiltered(
                    colorFilter: isCollected
                        ? const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.multiply)
                        : const ColorFilter.matrix(_kGrayscaleMatrix),
                    child: Image.network(
                      treasure.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                    ),
                  )
                : Icon(
                    Icons.diamond,
                    size: 36,
                    color: isCollected
                        ? const Color(0xFFFFB703)
                        : Colors.grey,
                  ),
          ),
          if (isCollected)
            const Positioned(
              top: 4,
              right: 4,
              child: Icon(Icons.check_circle,
                  color: Colors.green, size: 20),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 4, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(11)),
              ),
              child: Text(
                treasure.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrScannerSheet extends StatefulWidget {
  final String huntId;
  final String hunterId;
  final Hunt hunt;
  final HuntService service;

  const _QrScannerSheet({
    required this.huntId,
    required this.hunterId,
    required this.hunt,
    required this.service,
  });

  @override
  State<_QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<_QrScannerSheet> {
  bool _processing = false;
  String? _feedback;
  bool _success = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final treasureId = barcode!.rawValue!;
    setState(() => _processing = true);

    try {
      final ok = await widget.service.collectTreasure(
        huntId: widget.huntId,
        hunterId: widget.hunterId,
        treasureId: treasureId,
        mode: widget.hunt.mode,
      );

      if (!mounted) return;

      if (ok) {
        // Check if game is now finished
        await widget.service.checkAndFinishHunt(
            widget.huntId, widget.hunt.mode);

        setState(() {
          _success = true;
          _feedback = '✅ Tesouro encontrado!';
        });
      } else {
        setState(() {
          _success = false;
          _feedback = widget.hunt.mode == GameMode.differential
              ? '❌ Tesouro já coletado por outro caçador!'
              : '❌ Você já coletou este tesouro!';
        });
      }

      await Future.delayed(_kScannerFeedbackDuration);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _success = false;
          _feedback = 'Erro: $e';
          _processing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aponte para o QR Code do Tesouro!',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: Stack(
                children: [
                  MobileScanner(
                    onDetect: _onDetect,
                  ),
                  if (_feedback != null)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      color: _success
                          ? Colors.green.withOpacity(0.8)
                          : Colors.red.withOpacity(0.8),
                      alignment: Alignment.center,
                      child: Text(
                        _feedback!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
