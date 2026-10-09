import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/hotel_model.dart';

class CalendarService {
  /// Open user's calendar (Google Calendar web/app intent) with pre-filled booking details
  static Future<bool> addBookingToCalendar(Booking booking) async {
    final String title = Uri.encodeComponent('Hotel Stay: ${booking.hotel.name}');
    final String location = Uri.encodeComponent('${booking.hotel.name}, ${booking.hotel.location}');
    final String details = Uri.encodeComponent(
      'Reservation ID: ${booking.id}\n'
      'Guests: ${booking.guests}\n'
      'Total: ₱${booking.totalPrice.toStringAsFixed(0)}\n'
      'Payment: ${booking.paymentMethod} (${booking.paymentStatus})\n'
      'Booked via StayEase Hotel App',
    );

    // Format dates to YYYYMMDDTHHMMSSZ or YYYYMMDD
    final String startIso = _formatCalendarDate(booking.checkInDate, isCheckIn: true);
    final String endIso = _formatCalendarDate(booking.checkOutDate, isCheckIn: false);
    final String dates = '$startIso/$endIso';

    // Google Calendar template URL works cross-platform on web, Android, iOS, Windows
    final Uri calendarUri = Uri.parse(
      'https://calendar.google.com/calendar/render?action=TEMPLATE&text=$title&dates=$dates&details=$details&location=$location',
    );

    try {
      final launched = await launchUrl(
        calendarUri,
        mode: LaunchMode.externalApplication,
      );
      return launched;
    } catch (e) {
      debugPrint('Error launching calendar: $e');
      return false;
    }
  }

  static String _formatCalendarDate(DateTime dt, {required bool isCheckIn}) {
    final int year = dt.year;
    final String month = dt.month.toString().padLeft(2, '0');
    final String day = dt.day.toString().padLeft(2, '0');
    // Standard hotel check-in at 14:00 (2 PM), check-out at 12:00 (12 PM)
    final String time = isCheckIn ? '140000Z' : '120000Z';
    return '$year$month$day' 'T' '$time';
  }
}
