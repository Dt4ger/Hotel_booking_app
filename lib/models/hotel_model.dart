class Hotel {
  final String id;
  final String name;
  final String location;
  final double rating;
  final int reviewsCount;
  final double pricePerNight;
  final String imageUrl;
  final String description;
  final List<String> amenities;
  final String category;

  const Hotel({
    required this.id,
    required this.name,
    required this.location,
    required this.rating,
    required this.reviewsCount,
    required this.pricePerNight,
    required this.imageUrl,
    required this.description,
    required this.amenities,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'pricePerNight': pricePerNight,
      'imageUrl': imageUrl,
      'description': description,
      'amenities': amenities,
      'category': category,
    };
  }

  factory Hotel.fromMap(Map<String, dynamic> map, String id) {
    return Hotel(
      id: id,
      name: map['name'] as String? ?? 'Unnamed Hotel',
      location: map['location'] as String? ?? 'Philippines',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      reviewsCount: map['reviewsCount'] as int? ?? 50,
      pricePerNight: (map['pricePerNight'] as num?)?.toDouble() ?? 3000.0,
      imageUrl: map['imageUrl'] as String? ?? '',
      description: map['description'] as String? ?? '',
      amenities: List<String>.from(map['amenities'] ?? []),
      category: map['category'] as String? ?? 'Resort',
    );
  }

  Hotel copyWith({
    String? id,
    String? name,
    String? location,
    double? rating,
    int? reviewsCount,
    double? pricePerNight,
    String? imageUrl,
    String? description,
    List<String>? amenities,
    String? category,
  }) {
    return Hotel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      amenities: amenities ?? this.amenities,
      category: category ?? this.category,
    );
  }
}

class Booking {
  final String id;
  final Hotel hotel;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guests;
  final double totalPrice;
  final DateTime bookingDate;
  final String status;
  final String userId;
  final String userEmail;
  final String paymentMethod;
  final String paymentStatus;

  Booking({
    required this.id,
    required this.hotel,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guests,
    required this.totalPrice,
    required this.bookingDate,
    this.status = 'Confirmed',
    this.userId = '',
    this.userEmail = '',
    this.paymentMethod = 'GCash',
    this.paymentStatus = 'Paid',
  });

  int get totalNights {
    final diff = checkOutDate.difference(checkInDate).inDays;
    return diff <= 0 ? 1 : diff;
  }
}

class HotelReview {
  final String id;
  final String hotelId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  HotelReview({
    required this.id,
    required this.hotelId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'hotelId': hotelId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HotelReview.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedDate;
    if (map['createdAt'] is String) {
      parsedDate = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return HotelReview(
      id: id,
      hotelId: map['hotelId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? 'Verified Guest',
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      comment: map['comment'] as String? ?? '',
      createdAt: parsedDate,
    );
  }
}

// Curated sample reviews for hotels
final List<HotelReview> sampleReviews = [
  // h1: Shangri-La Ocean Resort
  HotelReview(
    id: 'rev_1',
    hotelId: 'h1',
    userId: 'u1',
    userName: 'Samantha Reyes',
    rating: 5.0,
    comment:
        'Absolutely breathtaking beachfront views! The sunset at the private cove was unforgettable. Staff went above and beyond for our anniversary.',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  HotelReview(
    id: 'rev_2',
    hotelId: 'h1',
    userId: 'u2',
    userName: 'Marc Anthony Tan',
    rating: 4.8,
    comment:
        'The infinity pool and breakfast buffet spread are top-notch. Clean rooms and seamless airport speedboat transfers.',
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
  HotelReview(
    id: 'rev_3',
    hotelId: 'h1',
    userId: 'u3',
    userName: 'Elena Rostova',
    rating: 5.0,
    comment:
        'Paradise on earth! Quiet, secluded from the crowded beach stations, and the spa treatment was heavenly.',
    createdAt: DateTime.now().subtract(const Duration(days: 9)),
  ),

  // h2: Grand Horizon Skyline
  HotelReview(
    id: 'rev_4',
    hotelId: 'h2',
    userId: 'u4',
    userName: 'Carlos Miguel Gomez',
    rating: 5.0,
    comment:
        'Best city staycation in BGC! Rooftop bar drinks are excellent and high-speed Wi-Fi was flawless for remote work.',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  HotelReview(
    id: 'rev_5',
    hotelId: 'h2',
    userId: 'u5',
    userName: 'Beatriz Lim',
    rating: 4.6,
    comment:
        'Very clean, modern design, and walking distance to High Street shops and restaurants. The gym is well-equipped.',
    createdAt: DateTime.now().subtract(const Duration(days: 6)),
  ),

  // h3: El Nido Haven Villas
  HotelReview(
    id: 'rev_6',
    hotelId: 'h3',
    userId: 'u6',
    userName: 'Liam Cooper',
    rating: 5.0,
    comment:
        'Waking up right beside limestone cliffs was surreal. The private island-hopping tour arranged by the concierge was the highlight of our trip!',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
  HotelReview(
    id: 'rev_7',
    hotelId: 'h3',
    userId: 'u7',
    userName: 'Kristine Joy Dizon',
    rating: 4.9,
    comment:
        'Eco-luxury at its finest. Fresh coconuts on arrival, pristine kayak rentals, and extremely respectful hospitality.',
    createdAt: DateTime.now().subtract(const Duration(days: 8)),
  ),

  // h4: Pine Crest Mountain Lodge
  HotelReview(
    id: 'rev_8',
    hotelId: 'h4',
    userId: 'u8',
    userName: 'Ramon Castillo',
    rating: 4.7,
    comment:
        'The fireplace at night with complimentary hot chocolate was super cozy. Perfect mountain escape from the Manila heat.',
    createdAt: DateTime.now().subtract(const Duration(days: 4)),
  ),
  HotelReview(
    id: 'rev_9',
    hotelId: 'h4',
    userId: 'u9',
    userName: 'Hannah Patricia Lee',
    rating: 4.5,
    comment:
        'Rustic Baguio charm with comfortable pine wood interiors. Great breakfast strawberries and coffee.',
    createdAt: DateTime.now().subtract(const Duration(days: 11)),
  ),

  // h5: Cebu Waterfront Suite
  HotelReview(
    id: 'rev_10',
    hotelId: 'h5',
    userId: 'u10',
    userName: 'David Vance',
    rating: 4.8,
    comment:
        'Great family resort! Kids loved the water slide and lagoon pool, while we enjoyed the poolside cocktails and lechon dinner.',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  ),

  // h6: Siargao Palms Surf Resort
  HotelReview(
    id: 'rev_11',
    hotelId: 'h6',
    userId: 'u11',
    userName: 'Chloe Bennett',
    rating: 5.0,
    comment:
        'Incredible vibes! Morning yoga overlooking the waves, great surf instructors, and the best acai bowls in General Luna.',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),

  // h7: Tagaytay Ridge View Hotel
  HotelReview(
    id: 'rev_12',
    hotelId: 'h7',
    userId: 'u12',
    userName: 'Paolo & Denise Mendoza',
    rating: 4.9,
    comment:
        'Unmatched panorama of Taal Volcano right from our balcony bed. Heated infinity pool makes the chilly evening magical.',
    createdAt: DateTime.now().subtract(const Duration(days: 4)),
  ),

  // h8: The Bellevue Urban Hotel
  HotelReview(
    id: 'rev_13',
    hotelId: 'h8',
    userId: 'u13',
    userName: 'Kenneth Ong',
    rating: 4.7,
    comment:
        'Super convenient spot in Makati. Clean comfortable bed, quiet room, and fast check-in. Excellent value for money.',
    createdAt: DateTime.now().subtract(const Duration(days: 7)),
  ),

  // h9: Amanpulo Private Island Sanctuary
  HotelReview(
    id: 'rev_14',
    hotelId: 'h9',
    userId: 'u14',
    userName: 'Julian & Victoria Sterling',
    rating: 5.0,
    comment:
        'Utter perfection. Powder-soft white sand, turquoise water clarity, and our private butler made us feel like royalty. Worth every cent.',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

// Mock Hotel Listings across popular destinations in the Philippines
final List<Hotel> sampleHotels = [
  const Hotel(
    id: 'h1',
    name: 'Shangri-La Ocean Resort',
    location: 'Boracay, Aklan',
    rating: 4.9,
    reviewsCount: 320,
    pricePerNight: 9500.0,
    category: 'Resort',
    imageUrl:
        'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=800&q=80',
    description:
        'Experience luxury island living with private beach access, infinity pools, and world-class dining overlooking pristine white sands.',
    amenities: ['Free Wi-Fi', 'Swimming Pool', 'Ocean View', 'Spa', 'Breakfast Included', 'Airport Shuttle'],
  ),
  const Hotel(
    id: 'h2',
    name: 'Grand Horizon Skyline',
    location: 'Bonifacio Global City, Taguig',
    rating: 4.8,
    reviewsCount: 245,
    pricePerNight: 6800.0,
    category: 'Luxury',
    imageUrl:
        'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?auto=format&fit=crop&w=800&q=80',
    description:
        'A chic metropolitan hotel located in the heart of the business district, featuring rooftop cocktails, a modern gym, and panoramic city vistas.',
    amenities: ['Free Wi-Fi', 'Rooftop Bar', 'Fitness Gym', 'Room Service', 'Valet Parking'],
  ),
  const Hotel(
    id: 'h3',
    name: 'El Nido Haven Villas',
    location: 'El Nido, Palawan',
    rating: 4.95,
    reviewsCount: 410,
    pricePerNight: 11200.0,
    category: 'Beachfront',
    imageUrl:
        'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?auto=format&fit=crop&w=800&q=80',
    description:
        'Eco-luxury villas set between towering limestone cliffs and turquoise lagoons. Direct access to island-hopping tours and diving excursions.',
    amenities: ['Private Beach', 'Eco Tours', 'Free Breakfast', 'Kayak Rental', 'Free Wi-Fi'],
  ),
  const Hotel(
    id: 'h4',
    name: 'Pine Crest Mountain Lodge',
    location: 'Baguio City, Benguet',
    rating: 4.6,
    reviewsCount: 189,
    pricePerNight: 3500.0,
    category: 'Budget',
    imageUrl:
        'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=800&q=80',
    description:
        'Cozy, pine-scented retreat with a working stone fireplace, complimentary hot chocolate, and lush mountain-view terraces.',
    amenities: ['Fireplace Lounge', 'Free Breakfast', 'Free Wi-Fi', 'Coffee Shop', 'Heating'],
  ),
  const Hotel(
    id: 'h5',
    name: 'Cebu Waterfront Suite',
    location: 'Mactan, Cebu',
    rating: 4.7,
    reviewsCount: 278,
    pricePerNight: 5400.0,
    category: 'Resort',
    imageUrl:
        'https://images.unsplash.com/photo-1571896349842-33c89424de2d?auto=format&fit=crop&w=800&q=80',
    description:
        'Perfect tropical getaway for families and couples, offering water sports, lagoon swimming pools, and signature Filipino hospitality.',
    amenities: ['Water Sports', 'Kids Club', 'Outdoor Pool', 'Restaurant', 'Free Wi-Fi'],
  ),
  const Hotel(
    id: 'h6',
    name: 'Siargao Palms Surf Resort',
    location: 'General Luna, Siargao',
    rating: 4.85,
    reviewsCount: 194,
    pricePerNight: 4200.0,
    category: 'Beachfront',
    imageUrl:
        'https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=800&q=80',
    description:
        'Laidback beachfront sanctuary steps away from Cloud 9. Includes surfboard rentals, sunset yoga sessions, and organic smoothie bowls.',
    amenities: ['Surfboard Rental', 'Beach Access', 'Yoga Deck', 'Free Wi-Fi', 'Cafe & Bar'],
  ),
  const Hotel(
    id: 'h7',
    name: 'Tagaytay Ridge View Hotel',
    location: 'Tagaytay, Cavite',
    rating: 4.75,
    reviewsCount: 312,
    pricePerNight: 4900.0,
    category: 'Resort',
    imageUrl:
        'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=800&q=80',
    description:
        'Breathtaking unobstructed view of Taal Lake and Volcano with a heated infinity pool, cool mountain breeze, and farm-to-table dining.',
    amenities: ['Taal Lake View', 'Heated Pool', 'Free Breakfast', 'Spa', 'Free Wi-Fi'],
  ),
  const Hotel(
    id: 'h8',
    name: 'The Bellevue Urban Hotel',
    location: 'Makati, Metro Manila',
    rating: 4.65,
    reviewsCount: 165,
    pricePerNight: 3900.0,
    category: 'Budget',
    imageUrl:
        'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=800&q=80',
    description:
        'Modern, smart, and budget-friendly city hotel near Greenbelt and Ayala Center. Ideal for business travelers and weekend staycationers.',
    amenities: ['Free Wi-Fi', 'Fitness Gym', 'Co-working Space', 'Coffee Bar', '24/7 Concierge'],
  ),
  const Hotel(
    id: 'h9',
    name: 'Amanpulo Private Island Sanctuary',
    location: 'Pamalican Island, Palawan',
    rating: 4.98,
    reviewsCount: 520,
    pricePerNight: 24500.0,
    category: 'Luxury',
    imageUrl:
        'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?auto=format&fit=crop&w=800&q=80',
    description:
        'The ultimate secluded paradise surrounded by coral reefs and white sand beaches, with personal casitas, private butler service, and chartered seaplane access.',
    amenities: ['Private Beach', 'Butler Service', 'Spa', 'Breakfast Included', 'Swimming Pool', 'Free Wi-Fi'],
  ),
  const Hotel(
    id: 'h10',
    name: 'Henann Crystal Sands Resort',
    location: 'Station 2, Boracay',
    rating: 4.88,
    reviewsCount: 432,
    pricePerNight: 8200.0,
    category: 'Resort',
    imageUrl:
        'https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?auto=format&fit=crop&w=800&q=80',
    description:
        'Iconic beachfront property with direct access to White Beach Station 2, featuring crystal-clear upper deck pools and sunset swim-up bars.',
    amenities: ['Free Wi-Fi', 'Swimming Pool', 'Breakfast Included', 'Fitness Gym', 'Spa', 'Private Beach'],
  ),
  const Hotel(
    id: 'h11',
    name: 'Bohol South Palms Resort',
    location: 'Panglao Island, Bohol',
    rating: 4.82,
    reviewsCount: 290,
    pricePerNight: 7500.0,
    category: 'Beachfront',
    imageUrl:
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
    description:
        'Sprawling white-sand beachfront haven lined with coconut palms. Enjoy paddleboarding, dolphin watching tours, and fresh seafood by the shore.',
    amenities: ['Free Wi-Fi', 'Swimming Pool', 'Breakfast Included', 'Private Beach', 'Spa'],
  ),
  const Hotel(
    id: 'h12',
    name: 'Crimson Mactan Island Haven',
    location: 'Lapu-Lapu City, Cebu',
    rating: 4.78,
    reviewsCount: 360,
    pricePerNight: 9800.0,
    category: 'Luxury',
    imageUrl:
        'https://images.unsplash.com/photo-1584132967334-10e028bd69f7?auto=format&fit=crop&w=800&q=80',
    description:
        'Premier 5-star seaside retreat offering infinity cascade pools, world-acclaimed Aum Spa treatments, and international gastronomic dining.',
    amenities: ['Free Wi-Fi', 'Swimming Pool', 'Breakfast Included', 'Fitness Gym', 'Spa'],
  ),
  const Hotel(
    id: 'h13',
    name: 'Z Hostel & Rooftop Manila',
    location: 'Poblacion, Makati',
    rating: 4.62,
    reviewsCount: 415,
    pricePerNight: 3200.0,
    category: 'Budget',
    imageUrl:
        'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?auto=format&fit=crop&w=800&q=80',
    description:
        'Vibrant, design-forward urban social hub in Makati. Enjoy rooftop DJ sets, co-working lounges, super-fast Wi-Fi, and delicious artisan brews.',
    amenities: ['Free Wi-Fi', 'Breakfast Included', 'Fitness Gym'],
  ),
  const Hotel(
    id: 'h14',
    name: 'Coron Westown Lagoon Resort',
    location: 'Coron, Palawan',
    rating: 4.84,
    reviewsCount: 285,
    pricePerNight: 6200.0,
    category: 'Resort',
    imageUrl:
        'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=800&q=80',
    description:
        'Surrounded by turquoise lagoons and dramatic peaks. Featuring multiple expansive lagoon pools, dive equipment rentals, and tour concierge.',
    amenities: ['Free Wi-Fi', 'Swimming Pool', 'Breakfast Included', 'Spa'],
  ),
  const Hotel(
    id: 'h15',
    name: 'Seda BGC Metro Executive',
    location: 'Bonifacio Global City, Taguig',
    rating: 4.86,
    reviewsCount: 370,
    pricePerNight: 7900.0,
    category: 'Luxury',
    imageUrl:
        'https://images.unsplash.com/photo-1568084680786-a84f91d1153c?auto=format&fit=crop&w=800&q=80',
    description:
        'Sleek and polished executive hotel right next to High Street BGC. Boasts a rooftop bar with skyline views, 24/7 fitness facility, and club lounge access.',
    amenities: ['Free Wi-Fi', 'Swimming Pool', 'Breakfast Included', 'Fitness Gym', 'Spa'],
  ),
];
