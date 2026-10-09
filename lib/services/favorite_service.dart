import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteService {
  final CollectionReference _usersRef =
      FirebaseFirestore.instance.collection('users');

  Stream<List<String>> getFavoriteHotelIds(String userId) {
    if (userId.isEmpty) return Stream.value([]);

    return _usersRef.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return <String>[];
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey('favorites')) return <String>[];
      return List<String>.from(data['favorites'] ?? []);
    });
  }

  Future<void> toggleFavorite(String userId, String hotelId) async {
    if (userId.isEmpty) return;

    final docRef = _usersRef.doc(userId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      await docRef.set({
        'favorites': [hotelId],
      }, SetOptions(merge: true));
      return;
    }

    final data = snapshot.data() as Map<String, dynamic>? ?? {};
    final favorites = List<String>.from(data['favorites'] ?? []);

    if (favorites.contains(hotelId)) {
      favorites.remove(hotelId);
    } else {
      favorites.add(hotelId);
    }

    await docRef.set({'favorites': favorites}, SetOptions(merge: true));
  }
}
