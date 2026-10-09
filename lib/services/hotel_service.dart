import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hotel_model.dart';

class HotelService {
  final CollectionReference _hotelsRef =
      FirebaseFirestore.instance.collection('hotels');

  // Stream of hotels from Firestore
  Stream<List<Hotel>> getHotelsStream() {
    return _hotelsRef.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return sampleHotels;
      }
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Hotel.fromMap(data, doc.id);
      }).toList();
    });
  }

  // Seed default hotels to Firestore ensuring all sampleHotels exist
  Future<void> seedDefaultHotelsIfNeeded() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final hotel in sampleHotels) {
        final docRef = _hotelsRef.doc(hotel.id);
        batch.set(docRef, hotel.toMap(), SetOptions(merge: true));
      }
      await batch.commit();
    } catch (e) {
      // Continue with offline/local fallback if permissions pending
    }
  }

  // Add a new hotel
  Future<String> addHotel(Hotel hotel) async {
    final docRef = await _hotelsRef.add(hotel.toMap());
    return docRef.id;
  }

  // Update existing hotel
  Future<void> updateHotel(Hotel hotel) async {
    await _hotelsRef.doc(hotel.id).update(hotel.toMap());
  }

  // Delete a hotel
  Future<void> deleteHotel(String hotelId) async {
    await _hotelsRef.doc(hotelId).delete();
  }
}
