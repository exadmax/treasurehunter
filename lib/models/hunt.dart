import 'package:cloud_firestore/cloud_firestore.dart';

enum GameMode { cumulative, differential }

enum HuntStatus { waiting, active, finished }

class Hunt {
  final String id;
  final String name;
  final String? coverImageUrl;
  final GameMode mode;
  final HuntStatus status;
  final int totalTreasures;

  const Hunt({
    required this.id,
    required this.name,
    this.coverImageUrl,
    required this.mode,
    required this.status,
    required this.totalTreasures,
  });

  factory Hunt.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Hunt(
      id: doc.id,
      name: data['name'] as String? ?? '',
      coverImageUrl: data['coverImageUrl'] as String?,
      mode: data['mode'] == 'differential'
          ? GameMode.differential
          : GameMode.cumulative,
      status: _parseStatus(data['status'] as String?),
      totalTreasures: data['totalTreasures'] as int? ?? 0,
    );
  }

  static HuntStatus _parseStatus(String? status) {
    switch (status) {
      case 'active':
        return HuntStatus.active;
      case 'finished':
        return HuntStatus.finished;
      default:
        return HuntStatus.waiting;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'coverImageUrl': coverImageUrl,
      'mode': mode == GameMode.differential ? 'differential' : 'cumulative',
      'status': status.name,
      'totalTreasures': totalTreasures,
    };
  }

  Hunt copyWith({
    String? id,
    String? name,
    String? coverImageUrl,
    GameMode? mode,
    HuntStatus? status,
    int? totalTreasures,
  }) {
    return Hunt(
      id: id ?? this.id,
      name: name ?? this.name,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      totalTreasures: totalTreasures ?? this.totalTreasures,
    );
  }
}
