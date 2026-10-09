import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hotel_model.dart';

class ReviewService {
  final CollectionReference _reviewsRef =
      FirebaseFirestore.instance.collection('reviews');

  Stream<List<HotelReview>> getReviewsForHotel(String hotelId) {
    final defaultForHotel = sampleReviews.where((r) => r.hotelId == hotelId).toList();

    return _reviewsRef
        .where('hotelId', isEqualTo: hotelId)
        .snapshots()
        .map((snapshot) {
      final firestoreReviews = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return HotelReview.fromMap(data, doc.id);
      }).toList();

      final combined = [...firestoreReviews, ...defaultForHotel];
      combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return combined;
    }).handleError((_) => defaultForHotel);
  }

  Future<void> addReview({
    required String hotelId,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
  }) async {
    await _reviewsRef.add({
      'hotelId': hotelId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}
