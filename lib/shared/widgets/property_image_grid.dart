import 'package:flutter/material.dart';
import 'custom_network_image.dart';

class PropertyImageGrid extends StatelessWidget {
  final List<String> imageUrls;
  final Function(int index)? onImageTap;
  final double height;
  final double gap;
  final double borderRadius;

  const PropertyImageGrid({
    super.key,
    required this.imageUrls,
    this.onImageTap,
    this.height = 250.0,
    this.gap = 2.0,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Limpieza de datos: filtrar URLs vacías o nulas
    final validImages =
        imageUrls.where((url) => url.trim().isNotEmpty).toList();

    if (validImages.isEmpty) {
      return const SizedBox.shrink();
    }

    final count = validImages.length;

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: _buildLayout(validImages, count),
      ),
    );
  }

  Widget _buildLayout(List<String> images, int count) {
    if (count == 1) {
      return _buildSingle(images[0]);
    } else if (count == 2) {
      return _buildTwo(images);
    } else if (count == 3) {
      return _buildThree(images);
    } else {
      return _buildFourOrMore(images, count);
    }
  }

  Widget _buildSingle(String url) {
    return _buildImageItem(url, 0,
        width: double.infinity, height: double.infinity);
  }

  Widget _buildTwo(List<String> images) {
    return Row(
      children: [
        Expanded(child: _buildImageItem(images[0], 0, height: double.infinity)),
        SizedBox(width: gap),
        Expanded(child: _buildImageItem(images[1], 1, height: double.infinity)),
      ],
    );
  }

  Widget _buildThree(List<String> images) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: _buildImageItem(images[0], 0, height: double.infinity),
        ),
        SizedBox(width: gap),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Expanded(
                  child: _buildImageItem(images[1], 1, width: double.infinity)),
              SizedBox(height: gap),
              Expanded(
                  child: _buildImageItem(images[2], 2, width: double.infinity)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFourOrMore(List<String> images, int totalCount) {
    final remaining = totalCount - 4;

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                  child:
                      _buildImageItem(images[0], 0, height: double.infinity)),
              SizedBox(width: gap),
              Expanded(
                  child:
                      _buildImageItem(images[1], 1, height: double.infinity)),
            ],
          ),
        ),
        SizedBox(height: gap),
        Expanded(
          child: Row(
            children: [
              Expanded(
                  child:
                      _buildImageItem(images[2], 2, height: double.infinity)),
              SizedBox(width: gap),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImageItem(images[3], 3, height: double.infinity),
                    if (remaining > 0)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () => onImageTap?.call(3),
                          child: Container(
                            color: Colors.black.withOpacity(0.5),
                            alignment: Alignment.center,
                            child: Text(
                              '+$remaining',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
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
      ],
    );
  }

  Widget _buildImageItem(String url, int index,
      {double? width, double? height}) {
    return GestureDetector(
      onTap: () => onImageTap?.call(index),
      child: CustomNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        borderRadius: 0, // El borde lo maneja el contenedor principal
        showLoading: true,
      ),
    );
  }
}
