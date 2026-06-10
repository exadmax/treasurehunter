import 'package:cloud_firestore/cloud_firestore.dart';

class Hunter {
  final String id;
  final String name;
  final String? selfieUrl;
  final int collectedCount;
  final Timestamp? lastCaptureTimestamp;
  final List<String> collectedTreasures;

  const Hunter({
    required this.id,
    required this.name,
    this.selfieUrl,
    this.collectedCount = 0,
    this.lastCaptureTimestamp,
    this.collectedTreasures = const [],
  });

  factory Hunter.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Hunter(
      id: doc.id,
      name: data['name'] as String? ?? '',
      selfieUrl: data['selfieUrl'] as String?,
      collectedCount: data['collectedCount'] as int? ?? 0,
      lastCaptureTimestamp: data['lastCaptureTimestamp'] as Timestamp?,
      collectedTreasures:
          List<String>.from(data['collectedTreasures'] as List? ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'selfieUrl': selfieUrl,
      'collectedCount': collectedCount,
      'lastCaptureTimestamp': lastCaptureTimestamp,
      'collectedTreasures': collectedTreasures,
    };
  }

  Hunter copyWith({
    String? id,
    String? name,
    String? selfieUrl,
    int? collectedCount,
    Timestamp? lastCaptureTimestamp,
    List<String>? collectedTreasures,
  }) {
    return Hunter(
      id: id ?? this.id,
      name: name ?? this.name,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      collectedCount: collectedCount ?? this.collectedCount,
      lastCaptureTimestamp: lastCaptureTimestamp ?? this.lastCaptureTimestamp,
      collectedTreasures: collectedTreasures ?? this.collectedTreasures,
    );
  }
}
