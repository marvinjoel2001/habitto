import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../../generated/l10n.dart';

class SocialAreasPage extends StatelessWidget {
  const SocialAreasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(S.of(context).socialAreasTitle),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Text(
          S.of(context).socialAreasComingSoon,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}
