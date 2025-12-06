import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class SocialLoginButton extends StatelessWidget {
  final IconData? icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? imageAsset;
  final bool showGlow;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.imageAsset,
    this.showGlow = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Usamos el color primario del tema en lugar del verde menta fijo
    final theme = Theme.of(context);
    final glowColor = theme.colorScheme.primary;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (showGlow)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ClipOval(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: glowColor.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: Material(
                color: (backgroundColor ?? Colors.white).withValues(alpha: 0.15),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onPressed,
                  customBorder: const CircleBorder(),
                  child: isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : (imageAsset != null
                          ? Image.asset(
                              imageAsset!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Icon(
                                icon,
                                color: iconColor ?? Colors.white,
                                size: 24,
                              ),
                            )),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
