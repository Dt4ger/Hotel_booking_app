import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hotel_model.dart';

class BookingService {
  final CollectionReference _bookingsRef =
      FirebaseFirestore.instance.collection('bookings');

  // Stream of bookings optionally ordered and filtered by userId
  Stream<List<Booking>> getBookingsStream({String? userId}) {
    Query query = _bookingsRef;
    if (userId != null && userId.isNotEmpty) {
      query = query.where('userId', isEqualTo: userId);
    }

    return query
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Find matching hotel from sampleHotels or construct fallback
        final hotelId = data['hotelId'] as String? ?? '';
        final matchedHotel = sampleHotels.firstWhere(
          (h) => h.id == hotelId,
          orElse: () => Hotel(
            id: hotelId,
            name: data['hotelName'] as String? ?? 'Hotel',
            location: data['hotelLocation'] as String? ?? 'Philippines',
            rating: (data['hotelRating'] as num?)?.toDouble() ?? 4.5,
            reviewsCount: 100,
            pricePerNight: (data['pricePerNight'] as num?)?.toDouble() ?? 3000.0,
            imageUrl: data['hotelImageUrl'] as String? ?? '',
            description: '',
            amenities: const [],
            category: 'Resort',
          ),
        );

        return Booking(
          id: doc.id,
          hotel: matchedHotel,
          checkInDate: (data['checkInDate'] as Timestamp).toDate(),
          checkOutDate: (data['checkOutDate'] as Timestamp).toDate(),
          guests: data['guests'] as int? ?? 1,
          totalPrice: (data['totalPrice'] as num).toDouble(),
          bookingDate: (data['bookingDate'] as Timestamp).toDate(),
          status: data['status'] as String? ?? 'Confirmed',
          userId: data['userId'] as String? ?? '',
          userEmail: data['userEmail'] as String? ?? '',
          paymentMethod: data['paymentMethod'] as String? ?? 'GCash',
          paymentStatus: data['paymentStatus'] as String? ?? 'Paid',
        );
      }).toList();

      // Sort client-side by bookingDate descending so composite Firestore indexes are not required
      list.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
      return list;
    });
  }

  // Stream of ALL bookings for Admin
  Stream<List<Booking>> getAllBookingsStream() {
    return getBookingsStream(userId: null);
  }

  // Update booking status (Admin: Confirmed, Completed, Cancelled)
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    await _bookingsRef.doc(bookingId).update({'status': newStatus});
  }

  // Create a new booking in Firestore
  Future<String> addBooking({
    required Hotel hotel,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int guests,
    required double totalPrice,
    String? userId,
    String? userEmail,
    String paymentMethod = 'GCash',
    String paymentStatus = 'Paid',
  }) async {
    final doc = await _bookingsRef.add({
      'hotelId': hotel.id,
      'hotelName': hotel.name,
      'hotelLocation': hotel.location,
      'hotelRating': hotel.rating,
      'pricePerNight': hotel.pricePerNight,
      'hotelImageUrl': hotel.imageUrl,
      'checkInDate': Timestamp.fromDate(checkInDate),
      'checkOutDate': Timestamp.fromDate(checkOutDate),
      'guests': guests,
      'totalPrice': totalPrice,
      'bookingDate': Timestamp.now(),
      'status': 'Confirmed',
      'userId': userId ?? '',
      'userEmail': userEmail ?? '',
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
    });
    return doc.id;
  }

  // Cancel/Delete booking from Firestore
  Future<void> cancelBooking(String bookingId) async {
    await _bookingsRef.doc(bookingId).delete();
  }
}
