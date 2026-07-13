import 'package:flutter/material.dart';

import 'cached_cover_image.dart';

class AppDetailCover extends StatelessWidget {
  const AppDetailCover({
    super.key,
    required this.url,
    this.icon = Icons.podcasts,
    this.borderRadius = 10,
    this.maxContentWidth = 520,
    this.horizontalPadding = 48,
    this.heightFactor = 0.32,
  });

  final String? url;
  final IconData icon;
  final double borderRadius;
  final double maxContentWidth;
  final double horizontalPadding;
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final maxHeight = (screenSize.height * heightFactor).clamp(150.0, 280.0);
    final maxWidth = (screenSize.width - horizontalPadding).clamp(
      0.0,
      maxContentWidth,
    );
    final placeholderHeight = maxHeight.clamp(140.0, maxWidth * 0.62);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: CachedCoverImage(
            url: url,
            fit: BoxFit.contain,
            decodeLogicalSize: Size(maxWidth, maxHeight),
            placeholderBuilder: (context) => SizedBox(
              width: maxWidth,
              height: placeholderHeight,
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(icon, size: 56),
              ),
            ),
            errorBuilder: (context) => SizedBox(
              width: maxWidth,
              height: placeholderHeight,
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(icon, size: 56),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
