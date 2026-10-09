import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/hotel_model.dart';
import '../services/auth_service.dart';
import '../services/favorite_service.dart';
import '../services/hotel_service.dart';
import '../widgets/hotel_card.dart';
import 'hotel_detail_screen.dart';

class WishlistScreen extends StatelessWidget {
  final VoidCallback? onSignInRequested;
  final Function(Booking)? onBookConfirmed;

  const WishlistScreen({
    super.key,
    this.onSignInRequested,
    this.onBookConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final isVisitor = user == null;
    final favoriteService = FavoriteService();
    final hotelService = HotelService();

    if (isVisitor) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'My Wishlist',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.favorite_border_rounded, size: 54, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 20),
                Text(
                  'Save Your Dream Stays',
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to save and sync your favorite resorts and boutique hotels across devices.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: onSignInRequested,
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: Text('Sign In Now', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Wishlist',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: StreamBuilder<List<String>>(
        stream: favoriteService.getFavoriteHotelIds(user.uid),
        builder: (context, favSnapshot) {
          if (favSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final favoriteIds = favSnapshot.data ?? [];
          if (favoriteIds.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.favorite_outline_rounded, size: 54, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'No saved hotels yet',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the heart icon on any hotel detail screen to bookmark your favorite places.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            );
          }

          return StreamBuilder<List<Hotel>>(
            stream: hotelService.getHotelsStream(),
            builder: (context, hotelSnapshot) {
              final allHotels = hotelSnapshot.data ?? sampleHotels;
              final favoriteHotels = allHotels.where((h) => favoriteIds.contains(h.id)).toList();

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: favoriteHotels.length,
                itemBuilder: (context, index) {
                  final hotel = favoriteHotels[index];
                  return HotelCard(
                    hotel: hotel,
                    isFavorite: true,
                    onFavoriteToggle: () async {
                      await favoriteService.toggleFavorite(user.uid, hotel.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Removed from wishlist'),
                            duration: Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HotelDetailScreen(
                            hotel: hotel,
                            onBookConfirmed: onBookConfirmed ?? (_) {},
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
