import '../models/hunter.dart';

/// Sorts hunters by score descending, with timestamp tiebreak ascending
/// (earlier last capture = higher rank when scores are equal).
List<Hunter> sortHuntersByRank(List<Hunter> hunters) {
  return List.of(hunters)
    ..sort((a, b) {
      if (b.collectedCount != a.collectedCount) {
        return b.collectedCount.compareTo(a.collectedCount);
      }
      // Tiebreak: who captured their last treasure first wins.
      final aTs = a.lastCaptureTimestamp?.millisecondsSinceEpoch ?? 0;
      final bTs = b.lastCaptureTimestamp?.millisecondsSinceEpoch ?? 0;
      if (aTs == 0 && bTs == 0) return 0;
      if (aTs == 0) return 1;
      if (bTs == 0) return -1;
      return aTs.compareTo(bTs);
    });
}
