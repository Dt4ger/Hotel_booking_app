import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/hotel_model.dart';
import '../../services/hotel_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_image.dart';

class AdminHotelFormDialog extends StatefulWidget {
  final Hotel? hotelToEdit;

  const AdminHotelFormDialog({super.key, this.hotelToEdit});

  @override
  State<AdminHotelFormDialog> createState() => _AdminHotelFormDialogState();
}

class _AdminHotelFormDialogState extends State<AdminHotelFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  late TextEditingController _ratingController;
  late TextEditingController _imageUrlController;
  late TextEditingController _descriptionController;
  late TextEditingController _amenitiesController;

  String _selectedCategory = 'Resort';
  final List<String> _categories = ['Resort', 'Luxury', 'Beachfront', 'Budget', 'Boutique'];
  bool _isSaving = false;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    final h = widget.hotelToEdit;
    _nameController = TextEditingController(text: h?.name ?? '');
    _locationController = TextEditingController(text: h?.location ?? '');
    _priceController = TextEditingController(text: h != null ? h.pricePerNight.toStringAsFixed(0) : '');
    _ratingController = TextEditingController(text: h != null ? h.rating.toString() : '4.8');
    _imageUrlController = TextEditingController(text: h?.imageUrl ?? '');
    _descriptionController = TextEditingController(text: h?.description ?? '');
    _amenitiesController = TextEditingController(text: h != null ? h.amenities.join(', ') : 'Free Wi-Fi, Pool, Breakfast');
    if (h != null && _categories.contains(h.category)) {
      _selectedCategory = h.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _ratingController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    _amenitiesController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromDevice() async {
    setState(() => _isPickingImage = true);
    try {
      final picked = await StorageService.pickImage();
      if (picked != null) {
        final filename = 'hotel_${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
        final uploadedUrl = await StorageService.uploadImage(
          file: picked,
          folderPath: 'hotels',
          filename: filename,
        );

        if (uploadedUrl != null && mounted) {
          setState(() {
            _imageUrlController.text = uploadedUrl;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo selected and attached successfully!'),
              backgroundColor: Color(0xFF1E56A0),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick photo: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final amenitiesList = _amenitiesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final price = double.tryParse(_priceController.text) ?? 3500.0;
    final rating = double.tryParse(_ratingController.text) ?? 4.8;
    final defaultImage = _imageUrlController.text.trim().isNotEmpty
        ? _imageUrlController.text.trim()
        : 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=800&q=80';

    final hotelService = HotelService();

    try {
      if (widget.hotelToEdit != null) {
        final updatedHotel = widget.hotelToEdit!.copyWith(
          name: _nameController.text.trim(),
          location: _locationController.text.trim(),
          pricePerNight: price,
          rating: rating,
          imageUrl: defaultImage,
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          amenities: amenitiesList,
        );
        await hotelService.updateHotel(updatedHotel);
      } else {
        final newHotel = Hotel(
          id: '',
          name: _nameController.text.trim(),
          location: _locationController.text.trim(),
          rating: rating,
          reviewsCount: 1,
          pricePerNight: price,
          imageUrl: defaultImage,
          description: _descriptionController.text.trim(),
          amenities: amenitiesList,
          category: _selectedCategory,
        );
        await hotelService.addHotel(newHotel);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.hotelToEdit != null
                ? 'Hotel updated successfully!'
                : 'Hotel added successfully!'),
            backgroundColor: const Color(0xFF1E56A0),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save hotel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.hotelToEdit != null;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 12,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: screenHeight * 0.90,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(22, 20, 16, 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF2F4F7), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit_note_rounded : Icons.add_business_rounded,
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit Hotel Listing' : 'Add New Property',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1D2939),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Configure property details, pricing & media',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF667085),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      splashRadius: 20,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF98A2B3)),
                    ),
                  ],
                ),
              ),

              // Scrollable Form Body
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
                  children: [
                    // SECTION: MEDIA / COVER PHOTO
                    _buildSectionHeader('Cover Photo', Icons.photo_library_outlined, primaryColor),
                    const SizedBox(height: 10),

                    // Media Card
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFEAECF0)),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_imageUrlController.text.trim().isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Stack(
                                children: [
                                  AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: AppImage(
                                      imageUrl: _imageUrlController.text.trim(),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Material(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      shape: const CircleBorder(),
                                      child: InkWell(
                                        customBorder: const CircleBorder(),
                                        onTap: () => setState(() => _imageUrlController.clear()),
                                        child: const Padding(
                                          padding: EdgeInsets.all(6),
                                          child: Icon(Icons.close_rounded, color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    left: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.65),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 12),
                                          const SizedBox(width: 5),
                                          Text(
                                            'Cover Attached',
                                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Upload Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isPickingImage ? null : _pickImageFromDevice,
                              icon: _isPickingImage
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.cloud_upload_outlined, size: 19),
                              label: Text(
                                _isPickingImage
                                    ? 'Uploading Image...'
                                    : (_imageUrlController.text.trim().isNotEmpty
                                        ? 'Replace Photo from Device'
                                        : 'Choose Photo from Device'),
                                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // SECTION: PROPERTY BASICS
                    _buildSectionHeader('Basic Information', Icons.info_outline_rounded, primaryColor),
                    const SizedBox(height: 10),

                    // Hotel Name
                    TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1D2939)),
                      decoration: _buildInputDecoration(
                        label: 'Hotel Name *',
                        hint: 'e.g. Shangri-La Boracay Resort',
                        icon: Icons.apartment_rounded,
                        primaryColor: primaryColor,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter hotel name' : null,
                    ),
                    const SizedBox(height: 12),

                    // Location
                    TextFormField(
                      controller: _locationController,
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1D2939)),
                      decoration: _buildInputDecoration(
                        label: 'Location (Destination) *',
                        hint: 'e.g. Boracay, Aklan',
                        icon: Icons.location_on_outlined,
                        primaryColor: primaryColor,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter location' : null,
                    ),
                    const SizedBox(height: 12),

                    // Category & Rating Row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
                            style: GoogleFonts.poppins(fontSize: 13.5, color: const Color(0xFF1D2939), fontWeight: FontWeight.w500),
                            decoration: _buildInputDecoration(
                              label: 'Category',
                              icon: Icons.category_outlined,
                              primaryColor: primaryColor,
                            ),
                            items: _categories.map((c) {
                              return DropdownMenuItem(value: c, child: Text(c));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCategory = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _ratingController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1D2939)),
                            decoration: InputDecoration(
                              labelText: 'Rating',
                              labelStyle: GoogleFonts.poppins(color: const Color(0xFF667085), fontSize: 13),
                              prefixIcon: const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEAECF0))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEAECF0))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Price Per Night
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1D2939)),
                      decoration: InputDecoration(
                        labelText: 'Price Per Night (PHP) *',
                        labelStyle: GoogleFonts.poppins(color: const Color(0xFF667085), fontSize: 13),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 14, right: 8),
                          child: Text(
                            '₱',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18, color: primaryColor),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEAECF0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEAECF0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter price per night' : null,
                    ),

                    const SizedBox(height: 20),

                    // SECTION: DETAILS
                    _buildSectionHeader('Details & Amenities', Icons.tune_rounded, primaryColor),
                    const SizedBox(height: 10),

                    // Amenities
                    TextFormField(
                      controller: _amenitiesController,
                      style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1D2939)),
                      decoration: _buildInputDecoration(
                        label: 'Amenities (comma separated)',
                        hint: 'Free Wi-Fi, Pool, Breakfast, Ocean View',
                        icon: Icons.room_service_outlined,
                        primaryColor: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      style: GoogleFonts.poppins(fontSize: 13, height: 1.45, color: const Color(0xFF1D2939)),
                      decoration: InputDecoration(
                        labelText: 'Property Description',
                        labelStyle: GoogleFonts.poppins(color: const Color(0xFF667085), fontSize: 13),
                        hintText: 'Describe highlights, room experiences, location perks...',
                        hintStyle: GoogleFonts.poppins(color: const Color(0xFF98A2B3), fontSize: 12),
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEAECF0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEAECF0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Actions
              Container(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFF2F4F7), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(color: Color(0xFFD0D5DD)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: Colors.white,
                        ),
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: const Color(0xFF344054),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isSaving ? null : _handleSave,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_circle_rounded, size: 18),
                        label: Text(
                          isEditing ? 'Save Changes' : 'Create Hotel',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF344054),
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    String? hint,
    required IconData icon,
    required Color primaryColor,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: const Color(0xFF667085), fontSize: 13),
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: const Color(0xFF98A2B3), fontSize: 12),
      prefixIcon: Icon(icon, color: const Color(0xFF667085), size: 20),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEAECF0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEAECF0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primaryColor, width: 1.5)),
    );
  }
}
