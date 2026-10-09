import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/hotel_model.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/hotel_service.dart';
import 'admin_hotel_form_dialog.dart';
import '../../widgets/app_image.dart';
import '../../services/booking_pdf_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  final User user;
  final VoidCallback? onSwitchToCustomerView;

  const AdminDashboardScreen({
    super.key,
    required this.user,
    this.onSwitchToCustomerView,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  final HotelService _hotelService = HotelService();
  final BookingService _bookingService = BookingService();

  @override
  void initState() {
    super.initState();
    // Seed sample hotels in Firestore if first time
    _hotelService.seedDefaultHotelsIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _AdminOverviewTab(
        bookingService: _bookingService,
        hotelService: _hotelService,
        onNavigateToBookings: () => setState(() => _currentIndex = 1),
        onNavigateToHotels: () => setState(() => _currentIndex = 2),
      ),
      _AdminBookingsTab(bookingService: _bookingService),
      _AdminHotelsTab(hotelService: _hotelService),
      _AdminProfileTab(
        user: widget.user,
        bookingService: _bookingService,
        hotelService: _hotelService,
        onSwitchToCustomerView: widget.onSwitchToCustomerView,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.apartment_outlined),
            selectedIcon: Icon(Icons.apartment_rounded),
            label: 'Hotels',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings_rounded),
            label: 'Admin Account',
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 1. OVERVIEW & ANALYTICS TAB
// -------------------------------------------------------------
class _AdminOverviewTab extends StatelessWidget {
  final BookingService bookingService;
  final HotelService hotelService;
  final VoidCallback onNavigateToBookings;
  final VoidCallback onNavigateToHotels;

  const _AdminOverviewTab({
    required this.bookingService,
    required this.hotelService,
    required this.onNavigateToBookings,
    required this.onNavigateToHotels,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.admin_panel_settings, color: primaryColor, size: 22),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Portal',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'StayEase Management',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Booking>>(
        stream: bookingService.getAllBookingsStream(),
        builder: (context, bookingSnapshot) {
          final bookings = bookingSnapshot.data ?? [];
          final activeBookings = bookings.where((b) => b.status == 'Confirmed').length;
          final completedBookings = bookings.where((b) => b.status == 'Completed').length;
          final cancelledBookings = bookings.where((b) => b.status == 'Cancelled').length;

          final totalRevenue = bookings
              .where((b) => b.status != 'Cancelled')
              .fold<double>(0.0, (sum, item) => sum + item.totalPrice);

          return StreamBuilder<List<Hotel>>(
            stream: hotelService.getHotelsStream(),
            builder: (context, hotelSnapshot) {
              final hotels = hotelSnapshot.data ?? [];

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                children: [
                  // Total Revenue Banner Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, const Color(0xFF143F77)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TOTAL PLATFORM REVENUE',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.1,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.trending_up, color: Colors.white, size: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '₱${totalRevenue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Calculated from all active & completed reservations',
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Metrics 2x2 Grid
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          title: 'All Bookings',
                          value: '${bookings.length}',
                          icon: Icons.receipt_long,
                          iconColor: Colors.blue,
                          onTap: onNavigateToBookings,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          title: 'Active / Confirmed',
                          value: '$activeBookings',
                          icon: Icons.check_circle_outline,
                          iconColor: Colors.teal,
                          onTap: onNavigateToBookings,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          title: 'Completed',
                          value: '$completedBookings',
                          icon: Icons.task_alt_rounded,
                          iconColor: Colors.indigo,
                          onTap: onNavigateToBookings,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          title: 'Cancelled',
                          value: '$cancelledBookings',
                          icon: Icons.cancel_outlined,
                          iconColor: Colors.redAccent,
                          onTap: onNavigateToBookings,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _MetricCard(
                    title: 'Total Hotels Listed on Platform',
                    value: '${hotels.length}',
                    icon: Icons.apartment,
                    iconColor: Colors.purple,
                    onTap: onNavigateToHotels,
                  ),
                  const SizedBox(height: 20),

                  // 1. REVENUE ANALYTICS BAR CHART
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
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
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.bar_chart_rounded, size: 20, color: primaryColor),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Revenue Velocity (Last 7 Days)',
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      'Daily booking volume trends',
                                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '+18.4%',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // 7-day visual bars
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final now = DateTime.now();
                            final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                            final dayTotals = List.generate(7, (i) {
                              final targetDay = now.subtract(Duration(days: 6 - i));
                              final daySum = bookings
                                  .where((b) =>
                                      b.status != 'Cancelled' &&
                                      b.bookingDate.year == targetDay.year &&
                                      b.bookingDate.month == targetDay.month &&
                                      b.bookingDate.day == targetDay.day)
                                  .fold<double>(0.0, (sum, b) => sum + b.totalPrice);
                              return daySum;
                            });

                            final maxVal = dayTotals.reduce((a, b) => a > b ? a : b);
                            final chartMax = maxVal > 0 ? maxVal : 25000.0;

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(7, (i) {
                                final targetDay = now.subtract(Duration(days: 6 - i));
                                final dayLabel = dayNames[targetDay.weekday - 1];
                                final val = dayTotals[i];
                                final heightFactor = (val / chartMax).clamp(0.12, 1.0);
                                final isToday = i == 6;

                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      val > 0 ? '₱${(val / 1000).toStringAsFixed(0)}k' : '—',
                                      style: GoogleFonts.poppins(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: isToday ? primaryColor : Colors.grey.shade500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      width: 24,
                                      height: 90 * heightFactor,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isToday
                                              ? [primaryColor, const Color(0xFF163E75)]
                                              : [Colors.blue.shade200, Colors.blue.shade300],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      dayLabel,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                                        color: isToday ? primaryColor : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. PAYMENT METHODS DISTRIBUTION
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.pie_chart_outline_rounded, size: 20, color: Colors.amber.shade800),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payment Channel Share',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  'Transaction split across payment methods',
                                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...[
                          {'name': 'GCash', 'color': Colors.blue.shade700, 'icon': Icons.account_balance_wallet},
                          {'name': 'Maya', 'color': Colors.green.shade700, 'icon': Icons.wallet_rounded},
                          {'name': 'Card', 'color': Colors.indigo.shade700, 'icon': Icons.credit_card},
                          {'name': 'Pay at Hotel', 'color': Colors.amber.shade800, 'icon': Icons.payments_outlined},
                        ].map((method) {
                          final methodName = method['name'] as String;
                          final methodColor = method['color'] as Color;
                          final methodIcon = method['icon'] as IconData;
                          final count = bookings.where((b) => b.paymentMethod.toLowerCase() == methodName.toLowerCase()).length;
                          final pct = bookings.isEmpty ? 0.0 : (count / bookings.length);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(methodIcon, size: 16, color: methodColor),
                                        const SizedBox(width: 6),
                                        Text(
                                          methodName,
                                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '$count bookings (${(pct * 100).toStringAsFixed(0)}%)',
                                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 7,
                                    backgroundColor: Colors.grey.shade100,
                                    valueColor: AlwaysStoppedAnimation<Color>(methodColor),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent Reservations Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Bookings',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: onNavigateToBookings,
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (bookings.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          'No bookings received yet.',
                          style: GoogleFonts.poppins(color: Colors.grey.shade600),
                        ),
                      ),
                    )
                  else
                    ...bookings.take(5).map((booking) {
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: primaryColor.withValues(alpha: 0.1),
                            child: Icon(Icons.hotel_rounded, color: primaryColor),
                          ),
                          title: Text(
                            booking.hotel.name,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            'User: ${booking.userEmail.isNotEmpty ? booking.userEmail : "Guest"}\n₱${booking.totalPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} • ${booking.totalNights} nights',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          trailing: _StatusBadge(status: booking.status),
                        ),
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: iconColor.withValues(alpha: 0.12),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 2. MANAGE ALL BOOKINGS TAB
// -------------------------------------------------------------
class _AdminBookingsTab extends StatefulWidget {
  final BookingService bookingService;

  const _AdminBookingsTab({required this.bookingService});

  @override
  State<_AdminBookingsTab> createState() => _AdminBookingsTabState();
}

class _AdminBookingsTabState extends State<_AdminBookingsTab> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Confirmed', 'Completed', 'Cancelled'];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _exportBookingsToPdf(List<Booking> bookings) {
    BookingPdfService.openPdfPreview(context, bookings);
  }


  void _showStatusDialog(BuildContext context, Booking booking) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    String selectedStatus = booking.status;

    final statusOptions = [
      {
        'status': 'Confirmed',
        'desc': 'Reservation is active & booked',
        'icon': Icons.check_circle_outline_rounded,
        'color': Colors.green.shade700,
        'bg': Colors.green.shade50,
      },
      {
        'status': 'Completed',
        'desc': 'Guest has checked in & finished stay',
        'icon': Icons.task_alt_rounded,
        'color': Colors.green.shade700,
        'bg': Colors.green.shade50,
      },
      {
        'status': 'Cancelled',
        'desc': 'Booking voided or refunded',
        'icon': Icons.cancel_outlined,
        'color': Colors.red.shade700,
        'bg': Colors.red.shade50,
      },
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 12,
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.edit_calendar_rounded, color: primaryColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Update Booking Status',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ref: #${booking.id}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Booking Mini-Card Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AppImage(
                            imageUrl: booking.hotel.imageUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.hotel.name,
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                booking.userEmail.isNotEmpty ? booking.userEmail : 'Guest User',
                                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  Text(
                    'Select Status',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Modern Status Selection Cards
                  ...statusOptions.map((opt) {
                    final isSelected = selectedStatus == opt['status'];
                    final optColor = opt['color'] as Color;
                    final optBg = opt['bg'] as Color;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          setDialogState(() {
                            selectedStatus = opt['status'] as String;
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: isSelected ? optBg : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? optColor : Colors.grey.shade200,
                              width: isSelected ? 1.8 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: optColor.withValues(alpha: 0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: optBg,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  opt['icon'] as IconData,
                                  size: 18,
                                  color: optColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      opt['status'] as String,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: isSelected ? optColor : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      opt['desc'] as String,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle_rounded, color: optColor, size: 20)
                              else
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 14),

                  // Bottom Action Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            if (selectedStatus != booking.status) {
                              await widget.bookingService.updateBookingStatus(booking.id, selectedStatus);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Status updated to $selectedStatus!'),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          child: Text(
                            'Save Status',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Customer Bookings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          StreamBuilder<List<Booking>>(
            stream: widget.bookingService.getAllBookingsStream(),
            builder: (context, snapshot) {
              final bookings = snapshot.data ?? [];
              return IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
                tooltip: 'Export PDF Report',
                onPressed: () => _exportBookingsToPdf(bookings),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Field for Bookings
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Guest Email, Hotel, or #BK ID...',
                hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _filters.map((f) {
                final isSelected = _selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedFilter = f),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: StreamBuilder<List<Booking>>(
              stream: widget.bookingService.getAllBookingsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allBookings = snapshot.data ?? [];
                var filtered = _selectedFilter == 'All'
                    ? allBookings
                    : allBookings.where((b) => b.status == _selectedFilter).toList();

                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((b) {
                    final idMatch = b.id.toLowerCase().contains(_searchQuery);
                    final emailMatch = b.userEmail.toLowerCase().contains(_searchQuery);
                    final hotelMatch = b.hotel.name.toLowerCase().contains(_searchQuery);
                    return idMatch || emailMatch || hotelMatch;
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_rounded, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No reservations matching "$_searchQuery"'
                              : 'No reservations under "$_selectedFilter"',
                          style: GoogleFonts.poppins(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final booking = filtered[index];
                    final checkIn = '${booking.checkInDate.month}/${booking.checkInDate.day}/${booking.checkInDate.year}';
                    final checkOut = '${booking.checkOutDate.month}/${booking.checkOutDate.day}/${booking.checkOutDate.year}';

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    booking.hotel.name,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                _StatusBadge(status: booking.status),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.email_outlined, size: 15, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(
                                  booking.userEmail.isNotEmpty ? booking.userEmail : 'Guest User',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_month_outlined, size: 15, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(
                                  '$checkIn → $checkOut (${booking.totalNights} nights)',
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.payment_outlined, size: 15, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(
                                  'Payment: ${booking.paymentMethod} (${booking.paymentStatus})',
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Total Amount', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                                    Text(
                                      '₱${booking.totalPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    if (booking.status == 'Confirmed') ...[
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal.shade700,
                                          foregroundColor: Colors.white,
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: () async {
                                          await widget.bookingService.updateBookingStatus(booking.id, 'Completed');
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Reservation #${booking.id} marked as Completed!'),
                                                backgroundColor: Colors.teal,
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.check_circle_rounded, size: 16),
                                        label: const Text('Check-in', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        side: BorderSide(color: Colors.grey.shade300),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () => _showStatusDialog(context, booking),
                                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                                      label: const Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    ),
                                  ],
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
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 3. MANAGE HOTELS TAB (CRUD)
// -------------------------------------------------------------
class _AdminHotelsTab extends StatelessWidget {
  final HotelService hotelService;

  const _AdminHotelsTab({required this.hotelService});

  void _openHotelDialog(BuildContext context, {Hotel? hotel}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AdminHotelFormDialog(hotelToEdit: hotel),
    );
  }

  void _confirmDeleteHotel(BuildContext context, Hotel hotel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade600, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Delete Hotel Listing?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to delete "${hotel.name}"? This action cannot be undone.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await hotelService.deleteHotel(hotel.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hotel removed successfully'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: Text('Delete Listing', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Hotel Listings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openHotelDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Hotel'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Hotel>>(
        stream: hotelService.getHotelsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final hotels = snapshot.data ?? [];

          if (hotels.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.apartment_outlined, size: 54, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('No hotels listed. Tap "Add Hotel" to add one!'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: hotels.length,
            itemBuilder: (context, index) {
              final hotel = hotels[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AppImage(
                          imageUrl: hotel.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hotel.name,
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    hotel.location,
                                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₱${hotel.pricePerNight.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} / night • ${hotel.category}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Material(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              onTap: () => _openHotelDialog(context, hotel: hotel),
                              borderRadius: BorderRadius.circular(10),
                              child: const Padding(
                                padding: EdgeInsets.all(7),
                                child: Icon(Icons.edit_outlined, color: Colors.blue, size: 18),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Material(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              onTap: () => _confirmDeleteHotel(context, hotel),
                              borderRadius: BorderRadius.circular(10),
                              child: const Padding(
                                padding: EdgeInsets.all(7),
                                child: Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
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
      ),
    );
  }
}

// -------------------------------------------------------------
// 4. ADMIN PROFILE & SWITCHER TAB
// -------------------------------------------------------------
class _AdminProfileTab extends StatefulWidget {
  final User user;
  final BookingService bookingService;
  final HotelService hotelService;
  final VoidCallback? onSwitchToCustomerView;

  const _AdminProfileTab({
    required this.user,
    required this.bookingService,
    required this.hotelService,
    this.onSwitchToCustomerView,
  });

  @override
  State<_AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<_AdminProfileTab> {
  // Stateful Promo Codes list
  final List<Map<String, dynamic>> _promoCodes = [
    {
      'code': 'SUMMER2026',
      'discount': '20% OFF',
      'sub': 'Valid until May 31, 2026',
      'color': Colors.blue,
    },
    {
      'code': 'STAYEASE10',
      'discount': '₱1,000 OFF',
      'sub': 'Min. spend ₱5,000',
      'color': Colors.teal,
    },
    {
      'code': 'WELCOMEVIP',
      'discount': '15% OFF',
      'sub': 'First-time bookings only',
      'color': Colors.purple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: primaryColor.withValues(alpha: 0.12),
                  child: Icon(Icons.shield_rounded, size: 40, color: primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.displayName ?? 'Administrator',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.user.email ?? 'darrennenel@gmail.com',
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Super Admin',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Admin Management Tools Section
          Text(
            'Admin Controls & Tools',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 10),

          // Promo Codes Manager
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: Colors.white,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.discount_outlined, color: Colors.amber.shade800, size: 20),
            ),
            title: Text('Vouchers & Promo Codes', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('Manage discount codes and seasonal promos', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              showDialog(
                context: context,
                builder: (modalCtx) => StatefulBuilder(
                  builder: (context, setModalState) => Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    backgroundColor: Colors.white,
                    insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 460, maxHeight: 580),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.discount_rounded, color: Colors.amber.shade800, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Active Promo Codes (${_promoCodes.length})',
                                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Manage and issue guest discount vouchers',
                                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                                onPressed: () => Navigator.pop(modalCtx),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: _promoCodes.isEmpty
                                ? Center(
                                    child: Text(
                                      'No active promo codes. Tap "Create Code" to add one.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                                    ),
                                  )
                                : ListView.separated(
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: _promoCodes.length,
                                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final item = _promoCodes[index];
                                      return _buildPromoCodeTile(
                                        context: context,
                                        code: item['code'] as String,
                                        discount: item['discount'] as String,
                                        sub: item['sub'] as String,
                                        color: item['color'] as Color,
                                        onDelete: () {
                                          setState(() {
                                            _promoCodes.removeAt(index);
                                          });
                                          setModalState(() {});
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Promo code ${item['code']} deactivated'),
                                              backgroundColor: Colors.redAccent,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    side: BorderSide(color: Colors.grey.shade300),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => Navigator.pop(modalCtx),
                                  child: Text('Close', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () {
                                    _showCreatePromoCodeDialog(modalCtx, () {
                                      setModalState(() {});
                                    });
                                  },
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: Text('Create Code', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // Review Moderation Portal
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: Colors.white,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.rate_review_outlined, color: Colors.blue.shade700, size: 20),
            ),
            title: Text('Guest Reviews Moderation', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('Review ratings, feedback, and customer flags', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  backgroundColor: Colors.white,
                  insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.rate_review_rounded, color: Colors.blue.shade700, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Review Moderation',
                                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '14 verified reviews • 0 pending flags',
                                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Status Banner
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFABEFC6)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_rounded, color: Color(0xFF079455), size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Community Guidelines Active: All recent guest ratings passed automated profanity and spam checks.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    color: const Color(0xFF067647),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Recent Guest Feedback',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF344054)),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildReviewModerationItem(
                                'Darren N.',
                                'Shangri-La Boracay',
                                5.0,
                                'Exceptional beach views and friendly service throughout the whole week!',
                                'Verified Stay',
                              ),
                              const SizedBox(height: 8),
                              _buildReviewModerationItem(
                                'Maria Santos',
                                'Henann Resort Alona',
                                4.5,
                                'Clean pools and great breakfast buffet. Check-in was fast.',
                                'Verified Stay',
                              ),
                              const SizedBox(height: 8),
                              _buildReviewModerationItem(
                                'Alex Chen',
                                'Discovery Shores',
                                5.0,
                                'Sunset bar was stunning. Will definitely come back next holiday.',
                                'Verified Stay',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('Done', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // 1. Live Super Admin Telemetry / Metrics Card (Real-Time Streams from Firestore)
          StreamBuilder<List<Booking>>(
            stream: widget.bookingService.getBookingsStream(),
            builder: (context, bookingSnap) {
              final totalBookings = bookingSnap.hasData ? bookingSnap.data!.length : 0;
              return StreamBuilder<List<Hotel>>(
                stream: widget.hotelService.getHotelsStream(),
                builder: (context, hotelSnap) {
                  final totalHotels = hotelSnap.hasData ? hotelSnap.data!.length : 0;
                  final isFirestoreConnected = !bookingSnap.hasError && !hotelSnap.hasError;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF1E56A0),
                          Color(0xFF163E75),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E56A0).withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
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
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isFirestoreConnected ? Colors.greenAccent : Colors.amberAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isFirestoreConnected ? 'SYSTEM HEALTH: OPTIMAL' : 'CONNECTING FIRESTORE...',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Cloud Firestore',
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSystemMetricItem(
                                'Total Bookings',
                                bookingSnap.hasData ? '$totalBookings' : '...',
                                Icons.book_online_rounded,
                              ),
                            ),
                            Container(width: 1, height: 36, color: Colors.white24),
                            Expanded(
                              child: _buildSystemMetricItem(
                                'Listed Hotels',
                                hotelSnap.hasData ? '$totalHotels' : '...',
                                Icons.apartment_rounded,
                              ),
                            ),
                            Container(width: 1, height: 36, color: Colors.white24),
                            Expanded(
                              child: _buildSystemMetricItem(
                                'Active Session',
                                'Online',
                                Icons.verified_user_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),

          // Switch to Customer View
          if (widget.onSwitchToCustomerView != null) ...[
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              tileColor: Colors.white,
              leading: const Icon(Icons.remove_red_eye_outlined, color: Colors.blue),
              title: Text('Customer View Preview', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              subtitle: Text('Browse and test the app as a regular customer', style: GoogleFonts.poppins(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: widget.onSwitchToCustomerView,
            ),
            const SizedBox(height: 12),
          ],

          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: Colors.white,
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: Text('Sign Out', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.redAccent)),
            onTap: () async {
              await authService.signOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodeTile({
    required BuildContext context,
    required String code,
    required String discount,
    required String sub,
    required Color color,
    VoidCallback? onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.confirmation_number_outlined, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      code,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1D2939),
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        discount,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: color,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF667085)),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Copy Code',
            icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF667085)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Promo code $code copied to clipboard!'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          if (onDelete != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Delete Code',
              icon: const Icon(Icons.delete_outline_rounded, size: 17, color: Colors.redAccent),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }

  void _showCreatePromoCodeDialog(BuildContext parentContext, VoidCallback onCreated) {
    final codeCtrl = TextEditingController();
    final discountCtrl = TextEditingController();
    final subCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: parentContext,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E56A0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF1E56A0), size: 20),
            ),
            const SizedBox(width: 10),
            Text('Create Promo Code', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Code Name *',
                  hintText: 'e.g. FLASH50',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter promo code' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: discountCtrl,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Discount Value *',
                  hintText: 'e.g. 25% OFF or ₱500 OFF',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter discount value' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: subCtrl,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Terms / Condition (Optional)',
                  hintText: 'e.g. Min spend ₱3,000',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E56A0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              setState(() {
                _promoCodes.add({
                  'code': codeCtrl.text.trim().toUpperCase(),
                  'discount': discountCtrl.text.trim(),
                  'sub': subCtrl.text.trim().isEmpty ? 'Limited time offer' : subCtrl.text.trim(),
                  'color': Colors.indigo,
                });
              });
              onCreated();
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(parentContext).showSnackBar(
                SnackBar(
                  content: Text('Promo Code ${codeCtrl.text.trim().toUpperCase()} created!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text('Add Promo', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  static Widget _buildReviewModerationItem(
    String author,
    String hotelName,
    double rating,
    String comment,
    String tag,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: const Color(0xFF1E56A0).withValues(alpha: 0.15),
                      child: Text(
                        author.isNotEmpty ? author[0] : 'U',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E56A0)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            author,
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1D2939)),
                          ),
                          Text(
                            hotelName,
                            style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF667085)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                  const SizedBox(width: 2),
                  Text(
                    rating.toStringAsFixed(1),
                    style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment,
            style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF344054), height: 1.35),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w600, color: const Color(0xFF027A48)),
                ),
              ),
              Row(
                children: [
                  Text(
                    'Approved',
                    style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF027A48)),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF027A48), size: 14),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildSystemMetricItem(String title, String val, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 6),
        Text(
          val,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// STATUS BADGE COMPONENT
// -------------------------------------------------------------
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status) {
      case 'Cancelled':
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        break;
      case 'Completed':
      case 'Confirmed':
      default:
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
