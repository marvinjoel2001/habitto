import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';

class SocialAreasPage extends StatelessWidget {
  const SocialAreasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Áreas Sociales'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text(
          'Áreas Sociales - Próximamente',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}
