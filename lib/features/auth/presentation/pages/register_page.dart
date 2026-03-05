import 'package:flutter/material.dart';
import 'package:habitto/shared/theme/app_theme.dart';
import '../../data/services/auth_service.dart';
import '../../domain/entities/user.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../generated/l10n.dart';
import '../../../profile/presentation/pages/create_search_profile_page.dart';

import 'dart:ui' as ui;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _selectedUserType = 'inquilino';
  int _step = 0;
  static const int _totalSteps = 3;
  Color get _glassFieldColor => Colors.white.withValues(alpha: 0.7);

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError(S.of(context).passwordsDoNotMatch);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = User(
        id: 0, // Se asignará por el backend
        username: _usernameController.text,
        email: _emailController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        dateJoined: DateTime.now(),
      );

      final profile = Profile(
        id: 0, // Se asignará por el backend
        user: user, // Se asignará después de crear el usuario
        userType: _selectedUserType,
        phone: _phoneController.text,
        isVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        favorites: [],
      );

      final response = await _authService.register(
        user,
        profile,
        _passwordController.text,
      );
      if (!mounted) return;

      if (response['success']) {
        // Después del registro exitoso, hacer login automático
        final loginResponse = await _authService.login(
          _usernameController.text,
          _passwordController.text,
        );
        if (!mounted) return;

        if (loginResponse['success']) {
          if (_selectedUserType == 'inquilino') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateSearchProfilePage(),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(S.of(context).registrationSuccess)));
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context).registrationSuccessLogin)));
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        _showError(_friendlyRegisterError(response['error']));
      }
    } catch (e) {
      if (!mounted) return;
      _showError(S.of(context).errorMessage(e.toString()));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _friendlyRegisterError(dynamic error) {
    if (error == null) return S.of(context).registrationError;
    if (error is Map) {
      if (error.containsKey('username')) {
        return 'El nombre de usuario no está disponible';
      }
      if (error.containsKey('email')) {
        return 'Este correo ya está registrado';
      }
      if (error.containsKey('phone')) {
        return 'Este teléfono ya está registrado';
      }
      final msg = error.values.join(' ').toString();
      if (msg.isNotEmpty) return msg;
    }
    final raw = error.toString();
    final lower = raw.toLowerCase();
    if (lower.contains('username') && lower.contains('exist')) {
      return 'El nombre de usuario no está disponible';
    }
    if (lower.contains('usuario') && lower.contains('existe')) {
      return 'El nombre de usuario no está disponible';
    }
    if (lower.contains('email') && lower.contains('exist')) {
      return 'Este correo ya está registrado';
    }
    if (lower.contains('correo') && lower.contains('existe')) {
      return 'Este correo ya está registrado';
    }
    if (lower.contains('phone') && lower.contains('exist')) {
      return 'Este teléfono ya está registrado';
    }
    if (lower.contains('telefono') && lower.contains('existe')) {
      return 'Este teléfono ya está registrado';
    }
    return raw.isNotEmpty ? raw : S.of(context).registrationError;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _validateCurrentStep() {
    if (_step == 0) {
      if (_firstNameController.text.isEmpty ||
          _lastNameController.text.isEmpty) {
        _showError(S.of(context).requiredField);
        return false;
      }
      return true;
    }
    if (_step == 1 || _step == 2) {
      return _formKey.currentState!.validate();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF6F6F8),
              Color(0xFFEDEFF5),
              Color(0xFFF8F9FB),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: _buildCardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStepHeader(),
                      const SizedBox(height: 16),
                      _buildStepBody(),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                top: 8,
                child: _buildProgressHeader(),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          if (_step > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    if (_step > 0) _step--;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.6)),
                                  foregroundColor: Colors.white,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.08),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                ),
                                child: Text(S.of(context).backButton,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                          if (_step > 0) const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              text: _step < 2
                                  ? S.of(context).continueButton
                                  : S.of(context).registerButton,
                              onPressed: _step < 2
                                  ? () {
                                      if (!_validateCurrentStep()) return;
                                      setState(() => _step++);
                                    }
                                  : _register,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              textColor: Colors.white,
                              isLoading: _isLoading,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    final progress = (_step + 1) / _totalSteps;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  value: progress,
                  backgroundColor: Colors.black.withValues(alpha: 0.08),
                  valueColor:
                      const AlwaysStoppedAnimation(AppTheme.primaryColor),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Paso ${_step + 1}/$_totalSteps',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _stepTitle(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _stepTitle(),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _stepSubtitle(),
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  String _stepTitle() {
    switch (_step) {
      case 0:
        return S.of(context).yourNameTitle;
      case 1:
        return S.of(context).contactTitle;
      default:
        return S.of(context).accountTitle;
    }
  }

  String _stepSubtitle() {
    switch (_step) {
      case 0:
        return 'Usa tu nombre real para personalizar tu perfil';
      case 1:
        return 'Tu contacto será privado y solo visible en matches';
      default:
        return 'Crea tus credenciales para ingresar a Habitto';
    }
  }

  Widget _buildCardContainer({required Widget child}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildStepBody() {
    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(
                controller: _firstNameController,
                hintText: S.of(context).firstNamePlaceholder,
                fillColor: _glassFieldColor,
                validator: (v) => (v == null || v.isEmpty)
                    ? S.of(context).requiredField
                    : null),
            const SizedBox(height: 16),
            CustomTextField(
                controller: _lastNameController,
                hintText: S.of(context).lastNamePlaceholder,
                fillColor: _glassFieldColor,
                validator: (v) => (v == null || v.isEmpty)
                    ? S.of(context).requiredField
                    : null),
            const SizedBox(height: 12),
          ],
        );
      case 1:
        return Form(
          key: _formKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            CustomTextField(
                controller: _emailController,
                hintText: S.of(context).emailPlaceholder,
                fillColor: _glassFieldColor,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return S.of(context).enterEmailError;
                  }
                  if (!v.contains('@')) {
                    return S.of(context).enterValidEmailError;
                  }
                  return null;
                }),
            const SizedBox(height: 16),
            CustomTextField(
                controller: _phoneController,
                hintText: S.of(context).phonePlaceholder,
                fillColor: _glassFieldColor,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return S.of(context).enterPhoneError;
                  }
                  return null;
                }),
            const SizedBox(height: 16),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                    color: _glassFieldColor,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.5))),
                child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                  value: _selectedUserType,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black),
                  items: [
                    DropdownMenuItem(
                        value: 'inquilino',
                        child: Text(S.of(context).tenantRole)),
                    DropdownMenuItem(
                        value: 'propietario',
                        child: Text(S.of(context).landlordRole)),
                    DropdownMenuItem(
                        value: 'agente', child: Text(S.of(context).agentRole))
                  ],
                  onChanged: (v) {
                    setState(() => _selectedUserType = v!);
                  },
                ))),
            const SizedBox(height: 8),
          ]),
        );
      default:
        return Form(
            key: _formKey,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                      controller: _usernameController,
                      hintText: S.of(context).usernamePlaceholder,
                      fillColor: _glassFieldColor,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return S.of(context).enterUsernameError;
                        }
                        return null;
                      }),
                  const SizedBox(height: 16),
                  CustomTextField(
                      controller: _passwordController,
                      hintText: S.of(context).passwordPlaceholder,
                      fillColor: _glassFieldColor,
                      isPassword: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return S.of(context).enterPasswordError;
                        }
                        if (v.length < 6) {
                          return S.of(context).passwordLengthError;
                        }
                        return null;
                      }),
                  const SizedBox(height: 16),
                  CustomTextField(
                      controller: _confirmPasswordController,
                      hintText: S.of(context).confirmPasswordPlaceholder,
                      fillColor: _glassFieldColor,
                      isPassword: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return S.of(context).confirmPasswordError;
                        }
                        return null;
                      }),
                  const SizedBox(height: 24),
                ]));
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
