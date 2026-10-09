import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'models/hotel_model.dart';
import 'widgets/hotel_card.dart';
import 'widgets/shimmer_placeholder.dart';
import 'screens/hotel_detail_screen.dart';
import 'screens/my_bookings_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/wishlist_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'services/booking_service.dart';
import 'services/auth_service.dart';
import 'services/hotel_service.dart';
import 'services/favorite_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize notification service
  await NotificationService().initialize();
  // Seed sample hotels in Firestore on startup if empty
  await HotelService().seedDefaultHotelsIfNeeded();
  runApp(const HotelBookingApp());
}

class HotelBookingApp extends StatelessWidget {
  const HotelBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StayEase Hotel Booking',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routes: {
        '/admin': (ctx) {
          final user = AuthService().currentUser;
          if (user != null && AuthService.isAdminUser(user)) {
            return AdminDashboardScreen(
              user: user,
              onSwitchToCustomerView: () => Navigator.pop(ctx),
            );
          }
          return const Scaffold(
            body: Center(child: Text('Access Denied: Admin only')),
          );
        },
      },
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _adminCustomerPreview = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;
        final isAdmin = AuthService.isAdminUser(user);

        // If the logged in user is the admin and hasn't toggled preview, show Admin Portal
        if (isAdmin && !_adminCustomerPreview) {
          return AdminDashboardScreen(
            user: user!,
            onSwitchToCustomerView: () {
              setState(() {
                _adminCustomerPreview = true;
              });
            },
          );
        }

        // Everyone else (including visitors/guests with user == null) sees the MainNavigationScreen
        return MainNavigationScreen(
          user: user,
          isAdminPreview: isAdmin && _adminCustomerPreview,
          onReturnToAdmin: () {
            setState(() {
              _adminCustomerPreview = false;
            });
          },
        );
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final User? user;
  final bool isAdminPreview;
  final VoidCallback? onReturnToAdmin;

  const MainNavigationScreen({
    super.key,
    required this.user,
    this.isAdminPreview = false,
    this.onReturnToAdmin,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final BookingService _bookingService = BookingService();

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _handleBookConfirmed(Booking booking) async {
    await _bookingService.addBooking(
      hotel: booking.hotel,
      checkInDate: booking.checkInDate,
      checkOutDate: booking.checkOutDate,
      guests: booking.guests,
      totalPrice: booking.totalPrice,
      userId: widget.user?.uid ?? '',
      userEmail: widget.user?.email ?? 'Guest',
      paymentMethod: booking.paymentMethod,
      paymentStatus: booking.paymentStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVisitor = widget.user == null;
    final userId = widget.user?.uid ?? '';

    return StreamBuilder<List<Booking>>(
      stream: isVisitor
          ? Stream.value(<Booking>[])
          : _bookingService.getBookingsStream(userId: userId),
      builder: (context, snapshot) {
        final bookings = snapshot.data ?? [];

        final screens = [
          ExploreScreen(
            user: widget.user,
            onSignInRequested: _openLogin,
            onBookConfirmed: _handleBookConfirmed,
          ),
          WishlistScreen(
            onSignInRequested: _openLogin,
            onBookConfirmed: _handleBookConfirmed,
          ),
          MyBookingsScreen(
            bookings: bookings,
            isVisitor: isVisitor,
            isLoading: snapshot.connectionState == ConnectionState.waiting,
            onSignInRequested: _openLogin,
            onCancelBooking: (bookingId) async {
              await _bookingService.cancelBooking(bookingId);
            },
          ),
          ProfileScreen(
            onSignInRequested: _openLogin,
          ),
        ];

        return Scaffold(
          appBar: widget.isAdminPreview
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(40),
                  child: Container(
                    color: Colors.purple.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Viewing as Customer (Preview Mode)',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                          InkWell(
                            onTap: widget.onReturnToAdmin,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Return to Admin',
                                style: TextStyle(
                                  color: Colors.purple.shade800,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : null,
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (idx) {
              setState(() {
                _currentIndex = idx;
              });
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: 'Explore',
              ),
              const NavigationDestination(
                icon: Icon(Icons.favorite_border_rounded),
                selectedIcon: Icon(Icons.favorite_rounded),
                label: 'Wishlist',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: bookings.isNotEmpty,
                  label: Text('${bookings.length}'),
                  child: const Icon(Icons.bookmark_border_rounded),
                ),
                selectedIcon: Badge(
                  isLabelVisible: bookings.isNotEmpty,
                  label: Text('${bookings.length}'),
                  child: const Icon(Icons.bookmark_rounded),
                ),
                label: 'My Bookings',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}

class ExploreScreen extends StatefulWidget {
  final User? user;
  final VoidCallback? onSignInRequested;
  final Function(Booking) onBookConfirmed;

  const ExploreScreen({
    super.key,
    this.user,
    this.onSignInRequested,
    required this.onBookConfirmed,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String selectedCategory = 'All';
  String searchQuery = '';
  final categories = ['All', 'Resort', 'Luxury', 'Beachfront', 'Budget'];
  final HotelService _hotelService = HotelService();
  final FavoriteService _favoriteService = FavoriteService();

  // Advanced Filter & Sort states
  double _maxPrice = 30000;
  double _minRating = 0;
  String _sortBy = 'Recommended'; // 'Recommended', 'Price: Low to High', 'Price: High to Low', 'Top Rated'
  List<String> _selectedAmenities = [];

  final List<String> _availableAmenities = [
    'Free Wi-Fi',
    'Swimming Pool',
    'Breakfast Included',
    'Fitness Gym',
    'Spa',
    'Private Beach',
  ];

  void _showFilterModal() {
    double tempMaxPrice = _maxPrice;
    double tempMinRating = _minRating;
    String tempSortBy = _sortBy;
    List<String> tempAmenities = List.from(_selectedAmenities);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            return Padding(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.tune_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Filter & Sort Hotels',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Find stays tailored to your taste',
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempMaxPrice = 30000;
                              tempMinRating = 0;
                              tempSortBy = 'Recommended';
                              tempAmenities.clear();
                            });
                          },
                          child: Text('Reset', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Sort By
                    Text(
                      'Sort by',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Recommended',
                        'Price: Low to High',
                        'Price: High to Low',
                        'Top Rated'
                      ].map((sortOption) {
                        final isSelected = tempSortBy == sortOption;
                        return ChoiceChip(
                          label: Text(
                            sortOption,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: theme.colorScheme.primary,
                          backgroundColor: const Color(0xFFF1F5F9),
                          checkmarkColor: Colors.white,
                          side: BorderSide(
                            color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setModalState(() => tempSortBy = sortOption);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Price Range
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Max Price per Night',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Text(
                          'Up to ₱${tempMaxPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: tempMaxPrice,
                      min: 3000,
                      max: 30000,
                      divisions: 27,
                      label: '₱${tempMaxPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                      onChanged: (val) {
                        setModalState(() => tempMaxPrice = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Minimum Rating
                    Text(
                      'Minimum Rating',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [0.0, 4.0, 4.5, 4.8].map((ratingVal) {
                        final isSelected = tempMinRating == ratingVal;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (ratingVal > 0)
                                  Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: isSelected ? Colors.amberAccent : Colors.amber,
                                  ),
                                Text(
                                  ratingVal == 0 ? 'Any' : ' $ratingVal+',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            selected: isSelected,
                            selectedColor: theme.colorScheme.primary,
                            backgroundColor: const Color(0xFFF1F5F9),
                            checkmarkColor: Colors.white,
                            side: BorderSide(
                              color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setModalState(() => tempMinRating = ratingVal);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Amenities Filter
                    Text(
                      'Amenities',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableAmenities.map((amenity) {
                        final isSelected = tempAmenities.contains(amenity);
                        return FilterChip(
                          label: Text(
                            amenity,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: theme.colorScheme.primary,
                          backgroundColor: const Color(0xFFF1F5F9),
                          checkmarkColor: Colors.white,
                          side: BorderSide(
                            color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
                          ),
                          onSelected: (val) {
                            setModalState(() {
                              if (val) {
                                tempAmenities.add(amenity);
                              } else {
                                tempAmenities.remove(amenity);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons Row (Clear & Apply)
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () {
                                setModalState(() {
                                  tempMaxPrice = 30000;
                                  tempMinRating = 0;
                                  tempSortBy = 'Recommended';
                                  tempAmenities.clear();
                                });
                              },
                              child: Text('Reset', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _maxPrice = tempMaxPrice;
                                  _minRating = tempMinRating;
                                  _sortBy = tempSortBy;
                                  _selectedAmenities = tempAmenities;
                                });
                                Navigator.pop(ctx);
                              },
                              child: Text('Apply Filters',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVisitor = widget.user == null;

    final hasActiveFilter = _maxPrice < 30000 ||
        _minRating > 0 ||
        _sortBy != 'Recommended' ||
        _selectedAmenities.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            children: [
              const TextSpan(text: 'Stay'),
              TextSpan(
                text: 'Ease',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (isVisitor)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: widget.onSignInRequested,
                icon: const Icon(Icons.login_rounded, size: 16),
                label: Text(
                  'Sign In',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder<List<Hotel>>(
        stream: _hotelService.getHotelsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: const [
                HotelCardSkeleton(),
                HotelCardSkeleton(),
              ],
            );
          }
          final allHotels = snapshot.data ?? sampleHotels;
          var filteredHotels = allHotels.where((hotel) {
            final matchesCat = selectedCategory == 'All' || hotel.category == selectedCategory;
            final matchesSearch = hotel.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                hotel.location.toLowerCase().contains(searchQuery.toLowerCase());
            final matchesPrice = hotel.pricePerNight <= _maxPrice;
            final matchesRating = hotel.rating >= _minRating;
            final matchesAmenities = _selectedAmenities.isEmpty ||
                _selectedAmenities.every((a) => hotel.amenities.any((ha) =>
                    ha.toLowerCase().contains(a.toLowerCase()) ||
                    a.toLowerCase().contains(ha.toLowerCase())));

            return matchesCat && matchesSearch && matchesPrice && matchesRating && matchesAmenities;
          }).toList();

          // Apply Sorting
          if (_sortBy == 'Price: Low to High') {
            filteredHotels.sort((a, b) => a.pricePerNight.compareTo(b.pricePerNight));
          } else if (_sortBy == 'Price: High to Low') {
            filteredHotels.sort((a, b) => b.pricePerNight.compareTo(a.pricePerNight));
          } else if (_sortBy == 'Top Rated') {
            filteredHotels.sort((a, b) => b.rating.compareTo(a.rating));
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Search Field + Filter Button Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search hotel or location...',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
                          prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.8),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            searchQuery = val;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: _showFilterModal,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: hasActiveFilter
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasActiveFilter
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade200,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: hasActiveFilter ? Colors.white : Colors.black87,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Popular Destinations Quick Chips
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 8),
                      child: Text(
                        'Popular:',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                    ...['Boracay', 'Siargao', 'Palawan', 'Cebu', 'Tagaytay', 'Baguio', 'Bohol'].map((dest) {
                      final isSelected = searchQuery.toLowerCase() == dest.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              searchQuery = isSelected ? '' : dest;
                            });
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.place_rounded,
                                  size: 13,
                                  color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  dest,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              // Removable Active Filter Pills Row
              if (hasActiveFilter) ...[
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (_maxPrice < 30000)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Chip(
                            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                            side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                            label: Text(
                              '≤ ₱${_maxPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                            ),
                            deleteIcon: Icon(Icons.close_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                            onDeleted: () {
                              setState(() {
                                _maxPrice = 30000;
                              });
                            },
                          ),
                        ),
                      if (_minRating > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Chip(
                            backgroundColor: Colors.amber.shade50,
                            side: BorderSide(color: Colors.amber.shade300),
                            label: Text(
                              '⭐ ${_minRating.toStringAsFixed(1)}+',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                            ),
                            deleteIcon: Icon(Icons.close_rounded, size: 14, color: Colors.amber.shade900),
                            onDeleted: () {
                              setState(() {
                                _minRating = 0;
                              });
                            },
                          ),
                        ),
                      if (_sortBy != 'Recommended')
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Chip(
                            backgroundColor: const Color(0xFFF1F5F9),
                            side: BorderSide(color: Colors.grey.shade300),
                            label: Text(
                              _sortBy,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                            deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Colors.black87),
                            onDeleted: () {
                              setState(() {
                                _sortBy = 'Recommended';
                              });
                            },
                          ),
                        ),
                      ..._selectedAmenities.map((amenity) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Chip(
                            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                            side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                            label: Text(
                              amenity,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
                            ),
                            deleteIcon: Icon(Icons.close_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                            onDeleted: () {
                              setState(() {
                                _selectedAmenities.remove(amenity);
                              });
                            },
                          ),
                        );
                      }),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _maxPrice = 30000;
                            _minRating = 0;
                            _sortBy = 'Recommended';
                            _selectedAmenities.clear();
                          });
                        },
                        child: Text(
                          'Reset all',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Featured / Special Deals Carousel
              if (searchQuery.isEmpty && selectedCategory == 'All') ...[
                SizedBox(
                  height: 145,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildPromoCard(
                        title: 'Boracay White Sands',
                        subtitle: 'Up to 25% Off Luxury Resorts',
                        badge: 'LIMITED OFFER',
                        badgeColor: Colors.amber.shade700,
                        gradientColors: [const Color(0xFF1E56A0), const Color(0xFF163E75)],
                        icon: Icons.beach_access_rounded,
                        imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=800&q=80',
                        onTap: () {
                          setState(() {
                            selectedCategory = 'Resort';
                          });
                        },
                      ),
                      const SizedBox(width: 14),
                      _buildPromoCard(
                        title: 'Siargao Wave Escape',
                        subtitle: 'Surf retreats & yoga packages',
                        badge: 'TRENDING NOW',
                        badgeColor: Colors.teal.shade700,
                        gradientColors: [const Color(0xFF0D9488), const Color(0xFF0F766E)],
                        icon: Icons.surfing_rounded,
                        imageUrl: 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=800&q=80',
                        onTap: () {
                          setState(() {
                            selectedCategory = 'Beachfront';
                          });
                        },
                      ),
                      const SizedBox(width: 14),
                      _buildPromoCard(
                        title: 'Tagaytay Mountain View',
                        subtitle: 'Cozy weekend ridge getaways',
                        badge: 'TOP PICK',
                        badgeColor: Colors.deepOrange.shade600,
                        gradientColors: [const Color(0xFFC2410C), const Color(0xFF9A3412)],
                        icon: Icons.landscape_rounded,
                        imageUrl: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=800&q=80',
                        onTap: () {
                          setState(() {
                            searchQuery = 'Tagaytay';
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Categories Chips
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = cat == selectedCategory;
                    return ChoiceChip(
                      label: Text(
                        cat,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: theme.colorScheme.primary,
                      backgroundColor: const Color(0xFFF1F5F9),
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            selectedCategory = cat;
                          });
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Hotels (${filteredHotels.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (hasActiveFilter)
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () {
                        setState(() {
                          _maxPrice = 30000;
                          _minRating = 0;
                          _sortBy = 'Recommended';
                          _selectedAmenities.clear();
                        });
                      },
                      child: const Text('Clear Filters', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              if (hasActiveFilter || selectedCategory != 'All' || searchQuery.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (selectedCategory != 'All')
                      _buildActiveFilterChip('Category: $selectedCategory', () {
                        setState(() => selectedCategory = 'All');
                      }),
                    if (_sortBy != 'Recommended')
                      _buildActiveFilterChip('Sort: $_sortBy', () {
                        setState(() => _sortBy = 'Recommended');
                      }),
                    if (_minRating > 0)
                      _buildActiveFilterChip('$_minRating+ Stars', () {
                        setState(() => _minRating = 0);
                      }),
                    if (_maxPrice < 30000)
                      _buildActiveFilterChip('Max ₱${_maxPrice.toInt()}', () {
                        setState(() => _maxPrice = 30000);
                      }),
                    ..._selectedAmenities.map((a) => _buildActiveFilterChip(a, () {
                          setState(() => _selectedAmenities.remove(a));
                        })),
                    if (searchQuery.isNotEmpty)
                      _buildActiveFilterChip('Search: "$searchQuery"', () {
                        setState(() => searchQuery = '');
                      }),
                  ],
                ),
              ],
              const SizedBox(height: 12),

              // Hotel List
              if (filteredHotels.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 54, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'No hotels match current filters',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Try relaxing your filter criteria or price limits to view more stays.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          setState(() {
                            selectedCategory = 'All';
                            searchQuery = '';
                            _maxPrice = 30000;
                            _minRating = 0;
                            _sortBy = 'Recommended';
                            _selectedAmenities.clear();
                          });
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text('Reset All Filters', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ],
                  ),
                )
              else
                StreamBuilder<List<String>>(
                  stream: _favoriteService.getFavoriteHotelIds(widget.user?.uid ?? ''),
                  builder: (favContext, favSnapshot) {
                    final favIds = favSnapshot.data ?? [];

                    return Column(
                      children: filteredHotels.map((hotel) {
                        final isFav = favIds.contains(hotel.id);

                        return HotelCard(
                          hotel: hotel,
                          isFavorite: isFav,
                          onFavoriteToggle: () async {
                            if (widget.user == null) {
                              widget.onSignInRequested?.call();
                              return;
                            }
                            await _favoriteService.toggleFavorite(widget.user!.uid, hotel.id);
                            if (favContext.mounted) {
                              ScaffoldMessenger.of(favContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isFav
                                        ? 'Removed from your wishlist'
                                        : 'Added to your wishlist! ❤️',
                                  ),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HotelDetailScreen(
                                  hotel: hotel,
                                  onBookConfirmed: widget.onBookConfirmed,
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPromoCard({
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required List<Color> gradientColors,
    required IconData icon,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            // Luxury Dark Gradient Overlay for high text contrast
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      gradientColors.first.withValues(alpha: 0.65),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Content
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              shadows: const [
                                Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 1)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 11,
                              shadows: const [
                                Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
