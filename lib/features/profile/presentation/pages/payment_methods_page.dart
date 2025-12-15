import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../properties/data/services/property_service.dart';
import '../../../properties/domain/entities/payment_method.dart';
import '../../../../../generated/l10n.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  final PropertyService _propertyService = PropertyService();
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = true;
  bool _isCreating = false;

  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _propertyService.getPaymentMethods();

      if (result['success']) {
        final paymentMethodsData = result['payment_methods'] as List;
        setState(() {
          _paymentMethods = paymentMethodsData
              .map((data) => PaymentMethod.fromJson(data))
              .toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(S.of(context).paymentMethodsLoadError(result['error']))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(S.of(context).paymentMethodsLoadError(e.toString()))),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createPaymentMethod() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).enterPaymentMethodNameError)),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      // La API espera un Map<String, dynamic> con los datos del método de pago
      final payload = {
        'name': _nameController.text.trim(),
      };
      final result = await _propertyService.createPaymentMethod(payload);

      if (result['success']) {
        _nameController.clear();
        Navigator.of(context).pop(); // Cerrar el diálogo
        _loadPaymentMethods(); // Recargar la lista
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).paymentMethodCreatedSuccess)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  S.of(context).paymentMethodCreateError(result['error']))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(S.of(context).paymentMethodCreateError(e.toString()))),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  void _showCreatePaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(S.of(context).createPaymentMethodTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: S.of(context).paymentMethodNameLabel,
                      hintText: S.of(context).paymentMethodNameHint,
                      border: const OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isCreating
                      ? null
                      : () {
                          _nameController.clear();
                          Navigator.of(context).pop();
                        },
                  child: Text(S.of(context).cancelButton),
                ),
                ElevatedButton(
                  onPressed: _isCreating ? null : _createPaymentMethod,
                  child: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(S.of(context).createButton),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).paymentMethodsTitle),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: AppTheme.getProfileBackground(),
          ),
          // Blur & Dark Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
          // Content
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                )
              : _buildPaymentMethodsList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePaymentMethodDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPaymentMethodsList() {
    if (_paymentMethods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payment,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context).noPaymentMethods,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context).createFirstPaymentMethodHint,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: S.of(context).createPaymentMethodTitle,
              onPressed: _showCreatePaymentMethodDialog,
              backgroundColor: AppTheme.primaryColor,
              textColor: Colors.white,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _paymentMethods.length,
      itemBuilder: (context, index) {
        final paymentMethod = _paymentMethods[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.payment,
                color: AppTheme.primaryColor,
              ),
            ),
            title: Text(
              paymentMethod.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              S.of(context).idLabel(paymentMethod.id),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (String value) {
                switch (value) {
                  case 'edit':
                    // TODO: Implementar edición
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(S.of(context).editFeatureComingSoon)),
                    );
                    break;
                  case 'delete':
                    // TODO: Implementar eliminación
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(S.of(context).deleteFeatureComingSoon)),
                    );
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(
                    leading: const Icon(Icons.edit, size: 20),
                    title: Text(S.of(context).editButton),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
                    leading:
                        const Icon(Icons.delete, color: Colors.red, size: 20),
                    title: Text(S.of(context).deleteButton),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
