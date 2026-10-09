import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/favorite_service.dart';
import '../services/booking_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../widgets/app_image.dart';
import '../models/hotel_model.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onSignInRequested;

  const ProfileScreen({super.key, this.onSignInRequested});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FavoriteService _favoriteService = FavoriteService();
  final BookingService _bookingService = BookingService();
  final NotificationService _notificationService = NotificationService();
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final enabled = await _notificationService.areBookingNotificationsEnabled();
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
      });
    }
  }

  void _showEditProfileDialog(User user, String initialAvatar) {
    final nameController = TextEditingController(text: user.displayName ?? '');
    String currentAvatar = initialAvatar;
    bool isPickingAvatar = false;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> pickAvatar() async {
            setDialogState(() => isPickingAvatar = true);
            try {
              final picked = await StorageService.pickImage();
              if (picked != null) {
                final filename = 'avatar_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                final uploadedUrl = await StorageService.uploadImage(
                  file: picked,
                  folderPath: 'profile_avatars',
                  filename: filename,
                );
                if (uploadedUrl != null) {
                  setDialogState(() {
                    currentAvatar = uploadedUrl;
                  });
                }
              }
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Failed to pick avatar: $e')),
                );
              }
            } finally {
              if (ctx.mounted) {
                setDialogState(() => isPickingAvatar = false);
              }
            }
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Modal Header with Close Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 16, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.manage_accounts_rounded, color: theme.colorScheme.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Profile',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Personalize your account details',
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
                          splashRadius: 20,
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),

                  // Modal Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar Container with Camera Badge & Tap Action
                          GestureDetector(
                            onTap: isPickingAvatar ? null : pickAvatar,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                      width: 2.5,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 48,
                                    backgroundColor: const Color(0xFFE2E8F0),
                                    backgroundImage: getAppImageProvider(currentAvatar),
                                    child: (currentAvatar.isEmpty)
                                        ? Icon(Icons.person_rounded, size: 52, color: theme.colorScheme.primary)
                                        : null,
                                  ),
                                ),
                                if (isPickingAvatar)
                                  Container(
                                    width: 104,
                                    height: 104,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                    ),
                                  ),
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Pick from files button
                          OutlinedButton.icon(
                            onPressed: isPickingAvatar ? null : pickAvatar,
                            icon: const Icon(Icons.folder_open_rounded, size: 16),
                            label: Text(
                              isPickingAvatar ? 'Reading photo...' : 'Choose Picture from Files',
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.primary,
                              side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Full Name input field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Full Name',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: nameController,
                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  hintText: 'Enter your name',
                                  prefixIcon: Icon(Icons.person_outline_rounded, color: theme.colorScheme.primary, size: 20),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Modal Actions (Footer)
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                      border: Border(top: BorderSide(color: Colors.grey.shade100)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              try {
                                final newName = nameController.text.trim();
                                await user.updateDisplayName(newName);

                                // Save to Firestore users doc
                                await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                                  'displayName': newName,
                                  'photoURL': currentAvatar,
                                  'email': user.email ?? '',
                                  'updatedAt': FieldValue.serverTimestamp(),
                                }, SetOptions(merge: true));

                                // Only update Firebase Auth's photoURL if it is an HTTP link (<= 2048 chars)
                                if (currentAvatar.isNotEmpty && !currentAvatar.startsWith('data:')) {
                                  try {
                                    await user.updatePhotoURL(currentAvatar);
                                  } catch (_) {}
                                }

                                await user.reload();
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  setState(() {});
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text('Profile updated successfully!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Failed to update: $e')),
                                  );
                                }
                              }
                            },
                            child: Text(
                              'Save Changes',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
    final user = _authService.currentUser;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final isVisitor = user == null;
    final isGuest = user?.isAnonymous ?? false;

    return StreamBuilder<DocumentSnapshot>(
      stream: !isVisitor && !isGuest
          ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
          : null,
      builder: (context, userDocSnapshot) {
        final userData = userDocSnapshot.data?.data() as Map<String, dynamic>?;
        final firestoreAvatar = userData?['photoURL'] as String?;
        final firestoreName = userData?['displayName'] as String?;

        final effectiveAvatar = (firestoreAvatar != null && firestoreAvatar.isNotEmpty)
            ? firestoreAvatar
            : user?.photoURL;

        final displayName = isVisitor
            ? 'Welcome, Traveler'
            : ((firestoreName != null && firestoreName.isNotEmpty)
                ? firestoreName
                : (user.displayName != null && user.displayName!.isNotEmpty
                    ? user.displayName!
                    : (isGuest ? 'Guest Traveler' : 'Valued Guest')));

        final email = isVisitor
            ? 'Sign in to access your profile & reservations'
            : (user.email ?? (isGuest ? 'Anonymous User' : 'No email'));

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'My Profile',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            actions: [
              if (!isVisitor && !isGuest)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Profile',
                  onPressed: () => _showEditProfileDialog(user, effectiveAvatar ?? ''),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // Profile Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: primaryColor.withValues(alpha: 0.12),
                      backgroundImage: getAppImageProvider(effectiveAvatar),
                      child: (effectiveAvatar == null || effectiveAvatar.isEmpty)
                          ? Icon(
                              isGuest ? Icons.person_outline_rounded : Icons.person_rounded,
                              size: 40,
                              color: primaryColor,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isVisitor
                                  ? Colors.grey.shade100
                                  : (isGuest ? Colors.orange.shade50 : Colors.blue.shade50),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isVisitor ? 'Visitor' : (isGuest ? 'Guest Account' : 'Member'),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isVisitor
                                  ? Colors.grey.shade700
                                  : (isGuest ? Colors.orange.shade800 : primaryColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

          // Traveler Stats Row
          if (!isVisitor) ...[
            StreamBuilder<List<Booking>>(
              stream: _bookingService.getBookingsStream(userId: user.uid),
              builder: (context, bookingSnap) {
                final bookingsCount = (bookingSnap.data ?? []).length;

                return StreamBuilder<List<String>>(
                  stream: _favoriteService.getFavoriteHotelIds(user.uid),
                  builder: (context, favSnap) {
                    final favCount = (favSnap.data ?? []).length;

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            icon: Icons.flight_takeoff_rounded,
                            iconColor: primaryColor,
                            value: '$bookingsCount',
                            label: 'Total Trips',
                          ),
                          Container(width: 1, height: 36, color: Colors.grey.shade200),
                          _buildStatItem(
                            icon: Icons.favorite_rounded,
                            iconColor: Colors.redAccent,
                            value: '$favCount',
                            label: 'Wishlisted',
                          ),
                          Container(width: 1, height: 36, color: Colors.grey.shade200),
                          _buildStatItem(
                            icon: Icons.workspace_premium_rounded,
                            iconColor: Colors.amber.shade700,
                            value: bookingsCount >= 3 ? 'Gold' : (bookingsCount >= 1 ? 'Silver' : 'Explorer'),
                            label: 'Tier Level',
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
          ],

          // Account Options
          Text(
            'Account Settings',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),

          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                if (_authService.isAdmin) ...[
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings, color: Colors.purple),
                    title: Text('Admin Management Portal',
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.bold, color: Colors.purple)),
                    subtitle: Text('Manage hotels, bookings, and revenue',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                    trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.purple),
                    onTap: () {
                      Navigator.pushNamed(context, '/admin');
                    },
                  ),
                  Divider(height: 1, color: Colors.grey.shade100),
                ],
                if (!isVisitor && !isGuest) ...[
                  ListTile(
                    leading: Icon(Icons.badge_outlined, color: primaryColor),
                    title: Text('Edit Personal Info', style: GoogleFonts.poppins(fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                    onTap: () => _showEditProfileDialog(user, effectiveAvatar ?? ''),
                  ),
                  Divider(height: 1, color: Colors.grey.shade100),
                ],
                ListTile(
                  leading: Icon(Icons.email_outlined, color: primaryColor),
                  title: Text('Account Email', style: GoogleFonts.poppins(fontSize: 14)),
                  subtitle: Text(email, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                ),
                Divider(height: 1, color: Colors.grey.shade100),
                ListTile(
                  leading: Icon(Icons.security_outlined, color: primaryColor),
                  title: Text('Security & Password', style: GoogleFonts.poppins(fontSize: 14)),
                  subtitle: const Text('Send password reset instructions to email', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                  onTap: () {
                    if (user?.email != null) {
                      _authService.sendPasswordResetEmail(user!.email!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.green.shade700,
                          content: Text('Password reset instructions sent to ${user.email}'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No email registered for this account.')),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.notifications_active_outlined, color: primaryColor),
                  title: Text('Booking Notifications', style: GoogleFonts.poppins(fontSize: 14)),
                  subtitle: Text('Receive booking vouchers and trip updates', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  trailing: Switch(
                    value: _notificationsEnabled,
                    activeThumbColor: primaryColor,
                    onChanged: (val) async {
                      setState(() {
                        _notificationsEnabled = val;
                      });
                      await _notificationService.setBookingNotificationsEnabled(val);
                      if (val) {
                        await _notificationService.requestPermissions();
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(val ? 'Notifications enabled!' : 'Notifications muted.'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade100),
                ListTile(
                  leading: Icon(Icons.info_outline, color: primaryColor),
                  title: Text('About StayEase', style: GoogleFonts.poppins(fontSize: 14)),
                  subtitle: Text('Version 1.2.0 • Philippines', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

          if (isVisitor) ...[
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: widget.onSignInRequested,
                icon: const Icon(Icons.login_rounded, size: 20),
                label: Text(
                  'Sign In / Register',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Logout Button
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  backgroundColor: Colors.red.shade50.withValues(alpha: 0.5),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
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
                            child: Icon(Icons.logout_rounded, color: Colors.red.shade600, size: 30),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Log Out of StayEase?',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You will need to sign in again to manage your reservations and profile.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                          ),
                        ],
                      ),
                      actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text('Log Out', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await _authService.signOut();
                  }
                },
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: Text(
                  'Log Out',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  },
);
}

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
