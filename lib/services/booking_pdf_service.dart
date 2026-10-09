import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/hotel_model.dart';

class BookingPdfService {
  static String _formatCurrency(double amount) {
    return 'PHP ${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  static Future<Uint8List> generateReservationsReportPdf(List<Booking> bookings) async {
    final pdf = pw.Document();

    final now = DateTime.now();
    final dateFormatted = '${now.month}/${now.day}/${now.year}';
    final timeFormatted = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final totalBookings = bookings.length;
    final completedBookings = bookings.where((b) => b.status == 'Completed').length;
    final confirmedBookings = bookings.where((b) => b.status == 'Confirmed').length;
    final cancelledBookings = bookings.where((b) => b.status == 'Cancelled').length;
    final totalRevenue = bookings
        .where((b) => b.status != 'Cancelled')
        .fold<double>(0.0, (sum, b) => sum + b.totalPrice);

    final fontBold = await PdfGoogleFonts.poppinsBold();
    final fontSemiBold = await PdfGoogleFonts.poppinsSemiBold();
    final fontRegular = await PdfGoogleFonts.poppinsRegular();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        header: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 1.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'STAYEASE HOTELS',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 22,
                        color: const PdfColor.fromInt(0xFF1E3A8A),
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Executive Reservations & Revenue Report',
                      style: pw.TextStyle(
                        font: fontSemiBold,
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Generated: $dateFormatted $timeFormatted',
                      style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey600),
                    ),
                    pw.Text(
                      'Confidential • Super Admin Portal',
                      style: pw.TextStyle(font: fontSemiBold, fontSize: 9, color: PdfColors.grey500),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 14),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 1),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'StayEase Mobile App Management Report',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(font: fontSemiBold, fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
        build: (context) {
          return [
            // KPI Summary Cards
            pw.Row(
              children: [
                _buildKpiCard(
                  title: 'TOTAL REVENUE',
                  value: _formatCurrency(totalRevenue),
                  fontBold: fontBold,
                  color: const PdfColor.fromInt(0xFF1E3A8A),
                  bgColor: const PdfColor.fromInt(0xFFEFF6FF),
                ),
                pw.SizedBox(width: 10),
                _buildKpiCard(
                  title: 'RESERVATIONS',
                  value: '$totalBookings Total',
                  fontBold: fontBold,
                  color: const PdfColor.fromInt(0xFF0F766E),
                  bgColor: const PdfColor.fromInt(0xFFF0FDFA),
                ),
                pw.SizedBox(width: 10),
                _buildKpiCard(
                  title: 'STATUS BREAKDOWN',
                  value: '$completedBookings Done • $confirmedBookings Conf • $cancelledBookings Canc',
                  fontBold: fontBold,
                  color: const PdfColor.fromInt(0xFF047857),
                  bgColor: const PdfColor.fromInt(0xFFECFDF5),
                  isSmallValue: true,
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Reservations Table
            pw.Text(
              'Detailed Bookings Log',
              style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.grey800),
            ),
            pw.SizedBox(height: 8),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.8),
              columnWidths: const {
                0: pw.FlexColumnWidth(2.8), // Hotel & Ref
                1: pw.FlexColumnWidth(2.8), // Guest Email
                2: pw.FlexColumnWidth(2.0), // Dates
                3: pw.FlexColumnWidth(1.8), // Amount
                4: pw.FlexColumnWidth(1.4), // Status
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1F5F9)),
                  children: [
                    _buildTableHeader('Hotel & ID', fontBold),
                    _buildTableHeader('Guest Account', fontBold),
                    _buildTableHeader('Stay Duration', fontBold),
                    _buildTableHeader('Amount', fontBold),
                    _buildTableHeader('Status', fontBold),
                  ],
                ),
                // Data Rows
                ...bookings.asMap().entries.map((entry) {
                  final index = entry.key;
                  final b = entry.value;
                  final isEven = index % 2 == 0;
                  final checkIn = '${b.checkInDate.month}/${b.checkInDate.day}';
                  final checkOut = '${b.checkOutDate.month}/${b.checkOutDate.day}/${b.checkOutDate.year}';

                  PdfColor statusBg;
                  PdfColor statusFg;
                  if (b.status == 'Cancelled') {
                    statusBg = const PdfColor.fromInt(0xFFFEE2E2);
                    statusFg = const PdfColor.fromInt(0xFFB91C1C);
                  } else {
                    // Both Completed and Confirmed are green
                    statusBg = const PdfColor.fromInt(0xFFDCFCE7);
                    statusFg = const PdfColor.fromInt(0xFF15803D);
                  }

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isEven ? PdfColors.white : const PdfColor.fromInt(0xFFF8FAFC),
                    ),
                    children: [
                      // Hotel
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              b.hotel.name,
                              style: pw.TextStyle(font: fontSemiBold, fontSize: 9.5, color: PdfColors.grey900),
                            ),
                            pw.SizedBox(height: 1),
                            pw.Text(
                              'Ref: #${b.id}',
                              style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.grey500),
                            ),
                          ],
                        ),
                      ),
                      // Guest Email
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              b.userEmail.isNotEmpty ? b.userEmail : 'Guest User',
                              style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.grey800),
                            ),
                            pw.Text(
                              '${b.paymentMethod} (${b.paymentStatus})',
                              style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.grey500),
                            ),
                          ],
                        ),
                      ),
                      // Dates
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              '$checkIn - $checkOut',
                              style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.grey800),
                            ),
                            pw.Text(
                              '${b.totalNights} nights • ${b.guests} guests',
                              style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.grey500),
                            ),
                          ],
                        ),
                      ),
                      // Amount
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                        child: pw.Text(
                          _formatCurrency(b.totalPrice),
                          style: pw.TextStyle(font: fontBold, fontSize: 9, color: const PdfColor.fromInt(0xFF1E3A8A)),
                        ),
                      ),
                      // Status Badge
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: statusBg,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                          ),
                          child: pw.Text(
                            b.status,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 7.5,
                              color: statusFg,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildKpiCard({
    required String title,
    required String value,
    required pw.Font fontBold,
    required PdfColor color,
    required PdfColor bgColor,
    bool isSmallValue = false,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: color, width: 0.6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(font: fontBold, fontSize: 8, color: color),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: isSmallValue ? 8.5 : 12,
                color: PdfColors.grey900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTableHeader(String text, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: fontBold,
          fontSize: 8.5,
          color: PdfColors.grey800,
        ),
      ),
    );
  }

  static Future<void> openPdfPreview(BuildContext context, List<Booking> bookings) async {
    if (bookings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No bookings available to generate report.')),
      );
      return;
    }

    // Show quick progress dialog while generating
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 18),
                Text('Generating PDF Report...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final pdfBytes = await generateReservationsReportPdf(bookings);

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Reservations PDF Report'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_rounded),
                  tooltip: 'Share PDF',
                  onPressed: () async {
                    await Printing.sharePdf(
                      bytes: pdfBytes,
                      filename: 'stayease_reservations_${DateTime.now().millisecondsSinceEpoch}.pdf',
                    );
                  },
                ),
              ],
            ),
            body: PdfPreview(
              build: (format) => pdfBytes,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              dynamicLayout: false,
              pdfFileName: 'stayease_reservations_${DateTime.now().millisecondsSinceEpoch}.pdf',
            ),
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    }
  }
}
