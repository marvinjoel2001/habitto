import 'package:flutter/material.dart';
import 'package:habitto/shared/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../data/services/auth_service.dart';
import '../../domain/entities/user.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';

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
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  String _selectedUserType = 'inquilino';
  File? _selectedImage;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
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

      final response = await _authService.register(user, profile, _passwordController.text, profileImage: _selectedImage);

      if (response['success']) {
        // Después del registro exitoso, hacer login automático
        final loginResponse = await _authService.login(
          _usernameController.text,
          _passwordController.text,
        );

        if (loginResponse['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registro exitoso')),
          );
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registro exitoso. Por favor, inicia sesión.')),
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error'] ?? 'Error en el registro')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        ),
      ),
      body: Stack(
        children: [
          // Fondo
          Image.asset(
            'assets/images/loginboys2.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.10),
                    Colors.black.withOpacity(0.85),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Contenido
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.25)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.10),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Text(
                                'Crear Cuenta',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 8,
                                      color: Colors.black.withOpacity(0.4),
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Foto de perfil
                              _buildProfileImageSection(),
                              const SizedBox(height: 24),

                              // Nombre de usuario
                              CustomTextField(
                                controller: _usernameController,
                                hintText: 'Nombre de usuario',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa un nombre de usuario';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Email
                              CustomTextField(
                                controller: _emailController,
                                hintText: 'Email',
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa tu email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Por favor ingresa un email válido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Nombre y Apellido
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      controller: _firstNameController,
                                      hintText: 'Nombre',
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Requerido';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: _lastNameController,
                                      hintText: 'Apellido',
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Requerido';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Teléfono
                              CustomTextField(
                                controller: _phoneController,
                                hintText: 'Teléfono',
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa tu teléfono';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Tipo de usuario
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedUserType,
                                    isExpanded: true,
                                    dropdownColor: Colors.grey[800],
                                    style: const TextStyle(color: Colors.white),
                                    hint: const Text(
                                      'Tipo de usuario',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'inquilino',
                                        child: Text('Inquilino'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'propietario',
                                        child: Text('Propietario'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'agente',
                                        child: Text('Agente'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedUserType = value!;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Contraseña
                              CustomTextField(
                                controller: _passwordController,
                                hintText: 'Contraseña',
                                isPassword: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa una contraseña';
                                  }
                                  if (value.length < 6) {
                                    return 'La contraseña debe tener al menos 6 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Confirmar contraseña
                              CustomTextField(
                                controller: _confirmPasswordController,
                                hintText: 'Confirmar contraseña',
                                isPassword: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor confirma tu contraseña';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Botón de registro
                              CustomButton(
                                text: 'Registrarse',
                                onPressed: _register,
                                isLoading: _isLoading,
                                backgroundColor: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 16),

                              // Link a login
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '¿Ya tienes una cuenta? ',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(context, '/login');
                                    },
                                    child: Text(
                                      'Inicia sesión',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.secondary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
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
        ],
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: _selectedImage != null
                  ? Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      'assets/images/userempty.png',
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.camera_alt, color: AppTheme.primaryColor, size: 18),
          label: const Text(
            'Agregar foto',
            style: TextStyle(color: AppTheme.primaryColor, fontSize: 14),
          ),
        ),
      ],
    );
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
