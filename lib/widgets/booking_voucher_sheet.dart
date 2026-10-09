import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import '../models/hotel_model.dart';
import 'app_image.dart';

class BookingVoucherSheet extends StatefulWidget {
  final Booking booking;

  const BookingVoucherSheet({super.key, required this.booking});

  static void show(BuildContext context, Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookingVoucherSheet(booking: booking),
    );
  }

  @override
  State<BookingVoucherSheet> createState() => _BookingVoucherSheetState();
}

class _BookingVoucherSheetState extends State<BookingVoucherSheet> {
  final GlobalKey _ticketRepaintKey = GlobalKey();
  bool _isSaving = false;
  bool _isSharing = false;

  String _formatFriendlyDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String get _displayRef {
    final raw = widget.booking.id;
    if (raw.length <= 10) return raw.toUpperCase();
    return raw.substring(0, 10).toUpperCase();
  }

  String _generateTicketText() {
    final b = widget.booking;
    return '''
==============================
   STAYEASE HOTEL E-VOUCHER   
==============================
Hotel: ${b.hotel.name}
Location: ${b.hotel.location}
Booking Reference: #$_displayRef
Status: ${b.status}

Primary Guest: ${b.userEmail.isNotEmpty ? b.userEmail : 'Valued Guest'}
Guests: ${b.guests} Guest(s) (Deluxe Room)
Total Stay: ${b.totalNights} Night(s)

Check-in: ${_formatFriendlyDate(b.checkInDate)} (From 2:00 PM)
Check-out: ${_formatFriendlyDate(b.checkOutDate)} (Until 12:00 PM)

Payment Method: ${b.paymentMethod}
Payment Status: ${b.paymentStatus}
Total Amount Paid: ₱${b.totalPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}

* Show your Booking Reference or QR code at front desk upon check-in.
==============================''';
  }

  Future<void> _handleSaveVoucher() async {
    setState(() => _isSaving = true);
    try {
      // 1. Try capturing widget as PNG image
      RenderRepaintBoundary? boundary =
          _ticketRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary != null) {
        final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final pngBytes = byteData.buffer.asUint8List();
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/StayEase_Voucher_$_displayRef.png');
          await file.writeAsBytes(pngBytes);

          // Save directly to the phone's Gallery / Photos
          try {
            await Gal.putImage(file.path, album: 'StayEase');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.photo_library_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Voucher saved to your Phone Gallery! 📸',
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF0F766E),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
              return;
            }
          } catch (galError) {
            debugPrint('Gallery save error: $galError');
          }
        }
      }

      // If gallery plugin failed or permission denied, save file and notify
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save to gallery. Please check storage permissions.'),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Save voucher error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save voucher: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleShareTicket() async {
    setState(() => _isSharing = true);
    try {
      final textToShare = _generateTicketText();
      final box = context.findRenderObject() as RenderBox?;

      // Check if we can share image + text
      RenderRepaintBoundary? boundary =
          _ticketRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary != null) {
        try {
          final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
          final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            final pngBytes = byteData.buffer.asUint8List();
            final tempDir = await getTemporaryDirectory();
            final filePath = '${tempDir.path}/voucher_$_displayRef.png';
            final file = File(filePath);
            await file.writeAsBytes(pngBytes);

            // ignore: deprecated_member_use
            await Share.shareXFiles(
              [XFile(filePath, mimeType: 'image/png')],
              text: 'StayEase Hotel Booking: ${widget.booking.hotel.name}\nRef: #$_displayRef\nCheck-in: ${_formatFriendlyDate(widget.booking.checkInDate)}',
              subject: 'StayEase Hotel Booking Voucher #$_displayRef',
              sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
            );
            return;
          }
        } catch (imgShareErr) {
          debugPrint('Error preparing image for share: $imgShareErr');
        }
      }

      // Fallback text share
      // ignore: deprecated_member_use
      await Share.share(
        textToShare,
        subject: 'StayEase Hotel Voucher #$_displayRef',
        sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );
    } catch (e) {
      debugPrint('Share error: $e');
      // If native share sheet failed, inform user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open share sheet: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final booking = widget.booking;

    final isConfirmed = booking.status.toLowerCase() == 'confirmed';
    final isCompleted = booking.status.toLowerCase() == 'completed';
    final isCancelled = booking.status.toLowerCase() == 'cancelled';
    final statusColor = isCancelled
        ? const Color(0xFFEF4444)
        : ((isConfirmed || isCompleted) ? const Color(0xFF10B981) : const Color(0xFF3B82F6));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'E-Ticket & Voucher',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          booking.status.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Official Confirmation & Check-in Pass',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                splashRadius: 20,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Scrollable Voucher Body
          Flexible(
            child: SingleChildScrollView(
              child: RepaintBoundary(
                key: _ticketRepaintKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(22),
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
                    children: [
                      // Top Brand Header Strip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.hotel_rounded, size: 16, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  'STAYEASE CONFIRMATION',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'VERIFIED',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Hotel Info Header
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AppImage(
                                imageUrl: booking.hotel.imageUrl,
                                width: 72,
                                height: 72,
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
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_rounded, size: 13, color: primary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          booking.hotel.location,
                                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      // Booking Reference Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'BOOKING REF: #$_displayRef',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: primary,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(Icons.copy_rounded, size: 14, color: Colors.grey.shade600),
                                        tooltip: 'Copy Reference',
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: booking.id));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Booking reference copied!'),
                                              duration: Duration(seconds: 1),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Dashed Cutout Divider (Ticket Effect)
                      Row(
                        children: [
                          Container(
                            width: 14,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.horizontal(right: Radius.circular(14)),
                            ),
                          ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Flex(
                                  direction: Axis.horizontal,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: List.generate(
                                    (constraints.constrainWidth() / 10).floor(),
                                    (_) => const SizedBox(
                                      width: 5,
                                      height: 1.5,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(color: Color(0xFFCBD5E1)),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Container(
                            width: 14,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.horizontal(left: Radius.circular(14)),
                            ),
                          ),
                        ],
                      ),

                      // Booking Details Grid
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Check-in & Check-out row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildDetailCol('CHECK-IN', _formatFriendlyDate(booking.checkInDate), 'From 2:00 PM'),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.nightlight_round, size: 12, color: Colors.indigo),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${booking.totalNights} Night(s)',
                                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildDetailCol('CHECK-OUT', _formatFriendlyDate(booking.checkOutDate), 'Until 12:00 PM'),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Guest & Room Info
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildDetailCol(
                                  'GUEST / HOLDER',
                                  booking.userEmail.isNotEmpty ? booking.userEmail.split('@').first : 'Valued Guest',
                                  '${booking.guests} Guest(s) • Deluxe Room',
                                ),
                                _buildDetailCol(
                                  'TOTAL PAYMENT',
                                  '₱${booking.totalPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                  '${booking.paymentMethod} • ${booking.paymentStatus}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Important Policies (Standard on Agoda/Booking.com)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 18, color: Colors.grey.shade700),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Cancellation Policy: Free cancellation up to 48 hours prior to check-in. Valid government photo ID required at front desk.',
                                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade700, height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Working Action Buttons (Save Voucher & Share Ticket)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_rounded, size: 18),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save Voucher',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSaving ? null : _handleSaveVoucher,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: _isSharing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.share_rounded, size: 18),
                  label: Text(
                    _isSharing ? 'Sharing...' : 'Share Ticket',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSharing ? null : _handleShareTicket,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCol(String label, String value, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        Text(
          sub,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
