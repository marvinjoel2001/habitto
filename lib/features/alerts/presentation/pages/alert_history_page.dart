import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../../generated/l10n.dart';

class AlertHistoryPage extends StatelessWidget {
  const AlertHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(S.of(context).alertHistoryTitle),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Text(
          S.of(context).alertHistoryComingSoon,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}