import 'package:flutter/material.dart';

class LoadingTile extends StatefulWidget {
  final bool showDivider;
  final EdgeInsets? padding;
  final double? height;
  
  const LoadingTile({
    super.key,
    this.showDivider = true,
    this.padding,
    this.height,
  });

  @override
  State<LoadingTile> createState() => _LoadingTileState();
}

class _LoadingTileState extends State<LoadingTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            height: widget.height,
            padding: widget.padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [
                  (_animation.value - 1).clamp(0.0, 1.0),
                  _animation.value.clamp(0.0, 1.0),
                  (_animation.value + 1).clamp(0.0, 1.0),
                ],
                colors: [
                  Colors.grey[300]!,
                  Colors.grey[100]!,
                  Colors.grey[300]!,
                ],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar placeholder
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title placeholder
                          Container(
                            height: 16,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Subtitle placeholder
                          Container(
                            height: 14,
                            width: MediaQuery.of(context).size.width * 0.6,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Arrow placeholder
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
                if (widget.showDivider) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  // Status and payment placeholders
                  Row(
                    children: [
                      // Status placeholder
                      Container(
                        height: 14,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Spacer(),
                      // Payment placeholder
                      Container(
                        height: 14,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// Specialized loading tiles for different use cases
class DeliveryLoadingTile extends StatelessWidget {
  const DeliveryLoadingTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoadingTile(
      showDivider: true,
      padding: EdgeInsets.all(16),
    );
  }
}

class SimpleLoadingTile extends StatelessWidget {
  final double? height;
  
  const SimpleLoadingTile({
    super.key,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return LoadingTile(
      showDivider: false,
      height: height ?? 80,
      padding: const EdgeInsets.all(12),
    );
  }
}

// Loading list widget for multiple tiles
class LoadingTileList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index)? itemBuilder;
  final EdgeInsets? padding;
  final double? itemHeight;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const LoadingTileList({
    super.key,
    this.itemCount = 5,
    this.itemBuilder,
    this.padding,
    this.itemHeight,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding ?? const EdgeInsets.all(16),
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: itemBuilder ?? (context, index) {
        return LoadingTile(
          height: itemHeight,
          showDivider: true,
        );
      },
    );
  }
}

// Skeleton row widget for custom layouts
class SkeletonRow extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? color;

  const SkeletonRow({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
    );
  }
}

// Skeleton circle for avatars
class SkeletonCircle extends StatelessWidget {
  final double size;
  final Color? color;

  const SkeletonCircle({
    super.key,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }
}

// Enhanced shimmer container for custom use
class ShimmerContainer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final List<Color>? colors;

  const ShimmerContainer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.colors,
  });

  @override
  State<ShimmerContainer> createState() => _ShimmerContainerState();
}

class _ShimmerContainerState extends State<ShimmerContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors ?? [
      Colors.grey[300]!,
      Colors.grey[100]!,
      Colors.grey[300]!,
    ];

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
              colors: colors,
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

// Utility extension for easy shimmer wrapping
extension ShimmerExtension on Widget {
  Widget shimmer({
    Duration duration = const Duration(milliseconds: 1500),
    List<Color>? colors,
  }) {
    return ShimmerContainer(
      duration: duration,
      colors: colors,
      child: this,
    );
  }
}
