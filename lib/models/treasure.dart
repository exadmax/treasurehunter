import 'package:cloud_firestore/cloud_firestore.dart';

class Treasure {
  final String id;
  final String name;
  final String? imageUrl;
  final bool isAvailable;

  const Treasure({
    required this.id,
    required this.name,
    this.imageUrl,
    this.isAvailable = true,
  });

  factory Treasure.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Treasure(
      id: doc.id,
      name: data['name'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      isAvailable: data['isAvailable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
    };
  }

  Treasure copyWith({
    String? id,
    String? name,
    String? imageUrl,
    bool? isAvailable,
  }) {
    return Treasure(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
