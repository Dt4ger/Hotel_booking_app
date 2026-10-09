import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// A smart image widget that renders both standard URLs (http/https),
/// Base64 data URLs (data:image/...;base64,...), and provides a clean fallback.
class AppImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    final url = imageUrl?.trim() ?? '';

    if (url.isEmpty) {
      content = _buildFallback();
    } else if (url.startsWith('data:image')) {
      // Decode Base64 data URI
      try {
        final commaIdx = url.indexOf(',');
        if (commaIdx != -1) {
          final base64Data = url.substring(commaIdx + 1);
          final Uint8List bytes = base64Decode(base64Data);
          content = Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) => _buildFallback(),
          );
        } else {
          content = _buildFallback();
        }
      } catch (e) {
        content = _buildFallback();
      }
    } else {
      // Standard HTTP/HTTPS network image
      content = Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return placeholder ??
              Container(
                width: width,
                height: height,
                color: Colors.grey.shade100,
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
        },
        errorBuilder: (_, _, _) => _buildFallback(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }

    return content;
  }

  Widget _buildFallback() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.apartment_rounded, color: Colors.grey.shade400, size: 36),
                const SizedBox(height: 4),
                Text(
                  'No Image',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
  }
}

/// Helper for CircleAvatar or ImageProvider usage (e.g. Profile avatars)
ImageProvider? getAppImageProvider(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  final clean = url.trim();
  if (clean.startsWith('data:image')) {
    try {
      final commaIdx = clean.indexOf(',');
      if (commaIdx != -1) {
        final base64Data = clean.substring(commaIdx + 1);
        final bytes = base64Decode(base64Data);
        return MemoryImage(bytes);
      }
    } catch (_) {}
  }
  return NetworkImage(clean);
}
