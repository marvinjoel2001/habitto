import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../../config/app_config.dart';

class CustomNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool showLoading;

  const CustomNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.placeholder,
    this.errorWidget,
    this.showLoading = true,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildErrorWidget(context);
    }

    final sanitizedUrl = AppConfig.sanitizeUrl(imageUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: sanitizedUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) =>
            placeholder ??
            (showLoading
                ? Container(
                    width: width,
                    height: height,
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor),
                      ),
                    ),
                  )
                : Container(color: Colors.grey[200])),
        errorWidget: (context, url, error) => _buildErrorWidget(context),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported,
                  color: Colors.grey[500], size: (width ?? 50) * 0.4),
            ],
          ),
        );
  }
}
