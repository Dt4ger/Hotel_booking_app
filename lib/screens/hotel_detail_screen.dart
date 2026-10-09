import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/hotel_model.dart';
import '../services/auth_service.dart';
import '../services/favorite_service.dart';
import '../services/review_service.dart';
import '../services/notification_service.dart';
import '../widgets/booking_voucher_sheet.dart';
import '../widgets/app_image.dart';
import 'login_screen.dart';

class HotelDetailScreen extends StatefulWidget {
  final Hotel hotel;
  final Function(Booking) onBookConfirmed;

  const HotelDetailScreen({
    super.key,
    required this.hotel,
    required this.onBookConfirmed,
  });

  @override
  State<HotelDetailScreen> createState() => _HotelDetailScreenState();
}

class _HotelDetailScreenState extends State<HotelDetailScreen> {
  final FavoriteService _favoriteService = FavoriteService();
  final ReviewService _reviewService = ReviewService();
  final AuthService _authService = AuthService();

  DateTime? checkInDate;
  DateTime? checkOutDate;
  int guests = 1;
  String selectedPaymentMethod = 'GCash';
  int _currentImageIndex = 0;
  late final PageController _imagePageController;

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  List<String> get _hotelGallery {
    final base = widget.hotel.imageUrl;
    return [
      base,
      'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=800&q=80',
    ];
  }

  int get nights {
    if (checkInDate == null || checkOutDate == null) return 0;
    final diff = checkOutDate!.difference(checkInDate!).inDays;
    return diff <= 0 ? 1 : diff;
  }

  double get totalPrice => nights * widget.hotel.pricePerNight;

  Future<void> _showBookingSheet() async {
    if (_authService.currentUser == null) {
      final signedIn = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );

      if (signedIn != true && _authService.currentUser == null) {
        return;
      }
    }

    if (!mounted) return;

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
            final hasDates = checkInDate != null && checkOutDate != null;
            final modalNights = hasDates
                ? (checkOutDate!.difference(checkInDate!).inDays <= 0
                    ? 1
                    : checkOutDate!.difference(checkInDate!).inDays)
                : 0;
            final modalTotalPrice = modalNights * widget.hotel.pricePerNight;

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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.bookmark_add_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Book Reservation',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                widget.hotel.name,
                                style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Dates Selection Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: checkInDate ??
                                    DateTime.now().add(const Duration(days: 1)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  checkInDate = picked;
                                  if (checkOutDate != null &&
                                      !checkOutDate!.isAfter(checkInDate!)) {
                                    checkOutDate = null;
                                  }
                                });
                                setState(() {});
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: checkInDate != null
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey.shade300,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Check-in',
                                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Text(
                                    checkInDate != null
                                        ? '${checkInDate!.month}/${checkInDate!.day}/${checkInDate!.year}'
                                        : 'Select date',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: checkInDate != null
                                          ? Colors.black87
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              if (checkInDate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Please select a check-in date first.')),
                                );
                                return;
                              }
                              final firstAvailable =
                                  checkInDate!.add(const Duration(days: 1));
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: (checkOutDate != null &&
                                        checkOutDate!.isAfter(checkInDate!))
                                    ? checkOutDate!
                                    : firstAvailable,
                                firstDate: firstAvailable,
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  checkOutDate = picked;
                                });
                                setState(() {});
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: checkOutDate != null
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey.shade300,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Check-out',
                                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Text(
                                    checkOutDate != null
                                        ? '${checkOutDate!.month}/${checkOutDate!.day}/${checkOutDate!.year}'
                                        : 'Select date',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: checkOutDate != null
                                          ? Colors.black87
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Guests Counter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Number of Guests',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        Row(
                          children: [
                            IconButton.outlined(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: guests > 1
                                  ? () {
                                      setModalState(() => guests--);
                                      setState(() {});
                                    }
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '$guests',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton.outlined(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: guests < 10
                                  ? () {
                                      setModalState(() => guests++);
                                      setState(() {});
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Payment Method Selection
                    Text(
                      'Payment Method',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPaymentOption(
                            title: 'GCash',
                            icon: Icons.account_balance_wallet,
                            color: Colors.blue.shade700,
                            selected: selectedPaymentMethod == 'GCash',
                            onTap: () {
                              setModalState(() => selectedPaymentMethod = 'GCash');
                              setState(() {});
                            },
                          ),
                          const SizedBox(width: 10),
                          _buildPaymentOption(
                            title: 'Maya',
                            icon: Icons.wallet_rounded,
                            color: Colors.green.shade700,
                            selected: selectedPaymentMethod == 'Maya',
                            onTap: () {
                              setModalState(() => selectedPaymentMethod = 'Maya');
                              setState(() {});
                            },
                          ),
                          const SizedBox(width: 10),
                          _buildPaymentOption(
                            title: 'Card',
                            icon: Icons.credit_card,
                            color: Colors.indigo.shade700,
                            selected: selectedPaymentMethod == 'Card',
                            onTap: () {
                              setModalState(() => selectedPaymentMethod = 'Card');
                              setState(() {});
                            },
                          ),
                          const SizedBox(width: 10),
                          _buildPaymentOption(
                            title: 'Pay at Hotel',
                            icon: Icons.payments_outlined,
                            color: Colors.amber.shade800,
                            selected: selectedPaymentMethod == 'Pay at Hotel',
                            onTap: () {
                              setModalState(() => selectedPaymentMethod = 'Pay at Hotel');
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Pricing Calculation
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                hasDates
                                    ? '₱${widget.hotel.pricePerNight.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} x $modalNights night(s)'
                                    : 'Select dates to calculate',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              Text(
                                hasDates
                                    ? '₱${modalTotalPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}'
                                    : '₱0',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Taxes & Fees',
                                  style: TextStyle(color: Colors.grey.shade700)),
                              const Text('Included',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600, color: Colors.green)),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Amount',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '₱${modalTotalPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Confirm Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasDates
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          if (checkInDate == null || checkOutDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select both Check-in and Check-out dates first.'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          final auth = _authService;
                          final newBooking = Booking(
                            id: 'BK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                            hotel: widget.hotel,
                            checkInDate: checkInDate!,
                            checkOutDate: checkOutDate!,
                            guests: guests,
                            totalPrice: modalTotalPrice,
                            bookingDate: DateTime.now(),
                            userId: auth.currentUser?.uid ?? '',
                            userEmail: auth.currentUser?.email ?? 'Guest',
                            paymentMethod: selectedPaymentMethod,
                            paymentStatus: selectedPaymentMethod == 'Pay at Hotel' ? 'Pending' : 'Paid',
                          );

                          widget.onBookConfirmed(newBooking);
                          NotificationService().showBookingConfirmationNotification(newBooking);
                          Navigator.pop(ctx);
                          _showSuccessDialog(newBooking);
                        },
                        child: Text(
                          hasDates ? 'Confirm & Pay (Simulated)' : 'Please Select Dates',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
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

  Widget _buildPaymentOption({
    required String title,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.grey.shade100,
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? color : Colors.black87,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close_rounded, size: 22, color: Colors.grey),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981).withValues(alpha: 0.15),
                      const Color(0xFF10B981).withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 54),
              ),
              const SizedBox(height: 16),
              Text(
                'Booking Confirmed!',
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              Text(
                'Reservation Code',
                style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 12),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Text(
                  booking.id,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: const Color(0xFF047857),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Payment: ${booking.paymentMethod} • ${booking.paymentStatus}',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF059669),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Your reservation is registered. Track status and receipts in the My Bookings tab.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    BookingVoucherSheet.show(context, booking);
                  },
                  icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                  label: Text('View E-Ticket Voucher', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddReviewDialog() {
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to leave a review.')),
      );
      return;
    }

    double userRating = 5.0;
    final commentController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Guest Review',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              widget.hotel.name,
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('How was your overall experience?',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starNumber = index + 1;
                      return IconButton(
                        icon: Icon(
                          starNumber <= userRating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber.shade700,
                          size: 34,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            userRating = starNumber.toDouble();
                          });
                        },
                      );
                    }),
                  ),
                  Center(
                    child: Text(
                      '$userRating / 5.0 Rating',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Share highlights of your stay, amenities, or staff...',
                      hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
                      filled: true,
                      fillColor: const Color(0xFFF4F7F6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  if (commentController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a brief comment.')),
                    );
                    return;
                  }

                  await _reviewService.addReview(
                    hotelId: widget.hotel.id,
                    userId: user.uid,
                    userName: user.displayName ?? (user.isAnonymous ? 'Guest' : 'Traveler'),
                    rating: userRating,
                    comment: commentController.text.trim(),
                  );

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thank you! Your review has been submitted.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: Text('Submit Review', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getAmenityIcon(String amenity) {
    final lower = amenity.toLowerCase();
    if (lower.contains('wi-fi')) return Icons.wifi;
    if (lower.contains('pool')) return Icons.pool;
    if (lower.contains('gym') || lower.contains('fitness')) return Icons.fitness_center;
    if (lower.contains('breakfast') || lower.contains('coffee')) return Icons.restaurant;
    if (lower.contains('beach') || lower.contains('ocean')) return Icons.beach_access;
    if (lower.contains('spa')) return Icons.spa;
    if (lower.contains('shuttle')) return Icons.airport_shuttle;
    return Icons.check_circle_outline;
  }

  Widget _buildScoreItem(String label, String score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            score,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, double pct, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$stars',
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                ),
                const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 5,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text(
              '${(pct * 100).toInt()}%',
              textAlign: TextAlign.end,
              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _authService.currentUser;
    final userId = user?.uid ?? '';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            leading: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.85),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              StreamBuilder<List<String>>(
                stream: _favoriteService.getFavoriteHotelIds(userId),
                builder: (context, snapshot) {
                  final isFav = (snapshot.data ?? []).contains(widget.hotel.id);
                  return CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.85),
                    child: IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : Colors.black,
                      ),
                      onPressed: () async {
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sign in to save hotels to your wishlist.')),
                          );
                          return;
                        }
                        await _favoriteService.toggleFavorite(userId, widget.hotel.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isFav
                                  ? 'Removed from your Wishlist'
                                  : 'Saved to your Wishlist!'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _imagePageController,
                    itemCount: _hotelGallery.length,
                    onPageChanged: (idx) {
                      setState(() {
                        _currentImageIndex = idx;
                      });
                    },
                    itemBuilder: (context, index) {
                      return AppImage(
                        imageUrl: _hotelGallery[index],
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library_outlined, size: 14, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            '${_currentImageIndex + 1} / ${_hotelGallery.length}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.hotel.category,
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            widget.hotel.rating.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            ' (${widget.hotel.reviewsCount} reviews)',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.hotel.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        widget.hotel.location,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    'About this hotel',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.hotel.description,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.5,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Amenities & Perks',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: widget.hotel.amenities.map((amenity) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getAmenityIcon(amenity), size: 18, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(amenity, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Reviews & Ratings Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Guest Reviews',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showAddReviewDialog,
                        icon: const Icon(Icons.rate_review_outlined, size: 18),
                        label: const Text('Leave a Review'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Rating Scorecard Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.08),
                          Colors.white,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.hotel.rating.toString(),
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                    ],
                                  ),
                                  Text(
                                    widget.hotel.rating >= 4.8
                                        ? 'Exceptional'
                                        : widget.hotel.rating >= 4.5
                                            ? 'Wonderful'
                                            : 'Very Good',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${widget.hotel.reviewsCount} verified traveler ratings',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildRatingBar(5, 0.85, const Color(0xFF10B981)),
                                  _buildRatingBar(4, 0.12, theme.colorScheme.primary),
                                  _buildRatingBar(3, 0.03, Colors.amber.shade700),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildScoreItem('Cleanliness', '4.9'),
                              const SizedBox(width: 6),
                              _buildScoreItem('Location', '4.8'),
                              const SizedBox(width: 6),
                              _buildScoreItem('Service', '4.9'),
                              const SizedBox(width: 6),
                              _buildScoreItem('Comfort', '4.8'),
                              const SizedBox(width: 6),
                              _buildScoreItem('Value', '4.7'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  StreamBuilder<List<HotelReview>>(
                    stream: _reviewService.getReviewsForHotel(widget.hotel.id),
                    builder: (context, snapshot) {
                      final reviews = snapshot.data ?? [];
                      if (reviews.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.reviews_outlined, color: Colors.grey.shade400, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'No customer reviews yet. Be the first to review this hotel!',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: reviews.map((rev) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                                          child: Text(
                                            rev.userName.isNotEmpty ? rev.userName[0].toUpperCase() : 'U',
                                            style: GoogleFonts.poppins(
                                              color: theme.colorScheme.primary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              rev.userName,
                                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                                            ),
                                            Row(
                                              children: [
                                                Icon(Icons.verified_rounded, size: 12, color: theme.colorScheme.primary),
                                                const SizedBox(width: 3),
                                                Text(
                                                  'Verified Guest',
                                                  style: GoogleFonts.poppins(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.star_rounded, color: Colors.amber.shade800, size: 15),
                                          const SizedBox(width: 3),
                                          Text(
                                            rev.rating.toStringAsFixed(1),
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber.shade900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  rev.comment,
                                  style: GoogleFonts.poppins(color: Colors.black87, fontSize: 13, height: 1.45),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '${rev.createdAt.month}/${rev.createdAt.day}/${rev.createdAt.year}',
                                    style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Price per night', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Row(
                    children: [
                      Text(
                        '₱${widget.hotel.pricePerNight.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Text(' / night', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _showBookingSheet,
                child: const Text('Book Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
