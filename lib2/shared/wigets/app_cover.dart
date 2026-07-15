import 'package:flutter/material.dart';

import 'cached_cover_image.dart';

class AppCover extends StatelessWidget {
  const AppCover({
    super.key,
    required this.url,
    required this.size,
    required this.icon,
    this.borderRadius = 0,
  });

  final String? url;
  final double size;
  final IconData icon;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox.square(
        dimension: size,
        child: CachedCoverImage(
          url: url,
          decodeLogicalSize: Size.square(size),
          placeholderBuilder: (context) => ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(icon),
          ),
          errorBuilder: (context) => ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(icon),
          ),
        ),
      ),
    );
  }
}
