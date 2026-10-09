import 'package:flutter/material.dart';

class ShimmerPlaceholder extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey.shade300.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

class HotelCardSkeleton extends StatelessWidget {
  const HotelCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerPlaceholder(
            width: double.infinity,
            height: 180,
            borderRadius: 16,
          ),
          const SizedBox(height: 14),
          const ShimmerPlaceholder(
            width: 180,
            height: 18,
            borderRadius: 6,
          ),
          const SizedBox(height: 8),
          const ShimmerPlaceholder(
            width: 120,
            height: 14,
            borderRadius: 4,
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              ShimmerPlaceholder(width: 60, height: 22, borderRadius: 6),
              SizedBox(width: 8),
              ShimmerPlaceholder(width: 80, height: 22, borderRadius: 6),
              SizedBox(width: 8),
              ShimmerPlaceholder(width: 70, height: 22, borderRadius: 6),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerPlaceholder(width: 90, height: 20, borderRadius: 6),
              ShimmerPlaceholder(width: 100, height: 32, borderRadius: 10),
            ],
          ),
        ],
      ),
    );
  }
}
