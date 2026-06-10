import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class HuntService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  // ── Hunt ────────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _hunts =>
      _firestore.collection('hunts');

  Stream<Hunt?> watchActiveHunt() {
    return _hunts
        .where('status', whereIn: ['waiting', 'active', 'finished'])
        .orderBy('__name__', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) =>
            snap.docs.isEmpty ? null : Hunt.fromFirestore(snap.docs.first));
  }

  Stream<Hunt?> watchHunt(String huntId) {
    return _hunts
        .doc(huntId)
        .snapshots()
        .map((doc) => doc.exists ? Hunt.fromFirestore(doc) : null);
  }

  Future<String> createHunt({
    required String name,
    required GameMode mode,
    Uint8List? coverImageBytes,
    String? coverImageName,
  }) async {
    String? coverImageUrl;
    if (coverImageBytes != null) {
      coverImageUrl = await _uploadImage(
        bytes: coverImageBytes,
        path: 'hunts/covers/${_uuid.v4()}_$coverImageName',
      );
    }

    final docRef = _hunts.doc();
    await docRef.set({
      'name': name,
      'mode': mode == GameMode.differential ? 'differential' : 'cumulative',
      'status': 'waiting',
      'totalTreasures': 0,
      'coverImageUrl': coverImageUrl,
    });
    return docRef.id;
  }

  Future<void> updateHuntStatus(String huntId, HuntStatus status) async {
    await _hunts.doc(huntId).update({'status': status.name});
  }

  Future<void> updateTotalTreasures(String huntId, int count) async {
    await _hunts.doc(huntId).update({'totalTreasures': count});
  }

  // ── Treasures ────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _treasures(String huntId) =>
      _hunts.doc(huntId).collection('treasures');

  Stream<List<Treasure>> watchTreasures(String huntId) {
    return _treasures(huntId).snapshots().map(
          (snap) => snap.docs.map(Treasure.fromFirestore).toList(),
        );
  }

  Future<String> addTreasure({
    required String huntId,
    required String name,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    String? imageUrl;
    if (imageBytes != null) {
      imageUrl = await _uploadImage(
        bytes: imageBytes,
        path: 'hunts/$huntId/treasures/${_uuid.v4()}_$imageName',
      );
    }

    final docRef = _treasures(huntId).doc();
    await docRef.set({
      'name': name,
      'imageUrl': imageUrl,
      'isAvailable': true,
    });

    // Update total count
    final count = await _treasures(huntId).count().get();
    await updateTotalTreasures(huntId, count.count ?? 0);

    return docRef.id;
  }

  Future<void> deleteTreasure(String huntId, String treasureId) async {
    final doc = await _treasures(huntId).doc(treasureId).get();
    if (doc.exists) {
      final data = doc.data()!;
      if (data['imageUrl'] != null) {
        await _deleteStorageFile(data['imageUrl'] as String);
      }
      await _treasures(huntId).doc(treasureId).delete();
    }
    final count = await _treasures(huntId).count().get();
    await updateTotalTreasures(huntId, count.count ?? 0);
  }

  Future<void> markTreasureUnavailable(
      String huntId, String treasureId) async {
    await _treasures(huntId).doc(treasureId).update({'isAvailable': false});
  }

  // ── Hunters ──────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _hunters(String huntId) =>
      _hunts.doc(huntId).collection('hunters');

  Stream<List<Hunter>> watchHunters(String huntId) {
    return _hunters(huntId).snapshots().map(
          (snap) => snap.docs.map(Hunter.fromFirestore).toList(),
        );
  }

  Future<bool> isNameTaken(String huntId, String name) async {
    final snap = await _hunters(huntId)
        .where('name', isEqualTo: name)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<String> suggestUniqueName(String huntId, String baseName) async {
    if (!await isNameTaken(huntId, baseName)) return baseName;
    int suffix = 2;
    while (await isNameTaken(huntId, '$baseName $suffix')) {
      suffix++;
    }
    return '$baseName $suffix';
  }

  Future<String> registerHunter({
    required String huntId,
    required String name,
    required Uint8List selfieBytes,
    String? selfieName,
  }) async {
    final selfieUrl = await _uploadImage(
      bytes: selfieBytes,
      path: 'hunts/$huntId/selfies/${_uuid.v4()}_${selfieName ?? 'selfie.jpg'}',
    );

    final docRef = _hunters(huntId).doc();
    await docRef.set({
      'name': name,
      'selfieUrl': selfieUrl,
      'collectedCount': 0,
      'lastCaptureTimestamp': null,
      'collectedTreasures': [],
    });
    return docRef.id;
  }

  /// Records a treasure collection event.
  /// Returns true if collection was successful, false if already collected or
  /// unavailable.
  Future<bool> collectTreasure({
    required String huntId,
    required String hunterId,
    required String treasureId,
    required GameMode mode,
  }) async {
    final hunterRef = _hunters(huntId).doc(hunterId);
    final treasureRef = _treasures(huntId).doc(treasureId);

    return _firestore.runTransaction<bool>((tx) async {
      final hunterDoc = await tx.get(hunterRef);
      final treasureDoc = await tx.get(treasureRef);

      if (!hunterDoc.exists || !treasureDoc.exists) return false;

      final hunterData = hunterDoc.data()!;
      final treasureData = treasureDoc.data()!;

      final collected =
          List<String>.from(hunterData['collectedTreasures'] as List? ?? []);
      if (collected.contains(treasureId)) return false;

      if (mode == GameMode.differential &&
          !(treasureData['isAvailable'] as bool? ?? true)) {
        return false;
      }

      collected.add(treasureId);
      final now = Timestamp.now();

      tx.update(hunterRef, {
        'collectedTreasures': collected,
        'collectedCount': collected.length,
        'lastCaptureTimestamp': now,
      });

      if (mode == GameMode.differential) {
        tx.update(treasureRef, {'isAvailable': false});
      }

      return true;
    });
  }

  /// Checks if game is finished (all treasures collected / no more available).
  Future<bool> checkAndFinishHunt(String huntId, GameMode mode) async {
    if (mode == GameMode.differential) {
      final avail = await _treasures(huntId)
          .where('isAvailable', isEqualTo: true)
          .limit(1)
          .get();
      if (avail.docs.isEmpty) {
        await updateHuntStatus(huntId, HuntStatus.finished);
        return true;
      }
    } else {
      // Cumulative: finished when any hunter has collected all treasures
      final totalSnap = await _treasures(huntId).count().get();
      final total = totalSnap.count ?? 0;
      if (total == 0) return false;

      final hunters = await _hunters(huntId).get();
      for (final doc in hunters.docs) {
        final count = doc.data()['collectedCount'] as int? ?? 0;
        if (count >= total) {
          await updateHuntStatus(huntId, HuntStatus.finished);
          return true;
        }
      }
    }
    return false;
  }

  // ── Tear Down ────────────────────────────────────────────────────────────────

  Future<void> clearSession(String huntId) async {
    // Delete all hunter selfies and treasure images from Storage
    final hunters = await _hunters(huntId).get();
    for (final doc in hunters.docs) {
      final url = doc.data()['selfieUrl'] as String?;
      if (url != null) await _deleteStorageFile(url);
      await doc.reference.delete();
    }

    final treasures = await _treasures(huntId).get();
    for (final doc in treasures.docs) {
      final url = doc.data()['imageUrl'] as String?;
      if (url != null) await _deleteStorageFile(url);
      await doc.reference.delete();
    }

    final huntDoc = await _hunts.doc(huntId).get();
    if (huntDoc.exists) {
      final url = huntDoc.data()?['coverImageUrl'] as String?;
      if (url != null) await _deleteStorageFile(url);
      await _hunts.doc(huntId).delete();
    }
  }

  // ── Storage helpers ───────────────────────────────────────────────────────────

  Future<String> _uploadImage({
    required Uint8List bytes,
    required String path,
  }) async {
    final ref = _storage.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<void> _deleteStorageFile(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {
      // File may already be deleted or URL invalid — ignore.
    }
  }
}
