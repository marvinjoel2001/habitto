import 'package:flutter/material.dart';
import 'package:habitto/shared/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import '../../data/services/auth_service.dart';
import '../../domain/entities/user.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../../shared/widgets/ai_chat_widget.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../profile/data/services/profile_service.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../generated/l10n.dart';

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
  final ProfileService _profileService = ProfileService();
  bool _isLoading = false;
  String _selectedUserType = 'inquilino';
  File? _selectedImage;
  int _step = 0;
  CameraController? _cameraController;
  bool _cameraReady = false;
  List<CameraDescription> _cameras = const [];
  bool _autoCapture = false;

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
        SnackBar(
            content: Text(S.of(context).imageSelectionError(e.toString()))),
      );
    }
  }

  Widget _buildCameraFull() {
    return Stack(children: [
      Positioned.fill(
        child: _selectedImage != null
            ? Image.file(_selectedImage!, fit: BoxFit.cover)
            : (_cameraReady && _cameraController != null
                ? CameraPreview(_cameraController!)
                : Container(color: Colors.black.withValues(alpha: 0.1))),
      ),
      Positioned.fill(child: CustomPaint(painter: _FaceMaskPainter())),
      if (_selectedImage != null)
        Positioned(
          top: 12,
          left: 12,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: Colors.black.withValues(alpha: 0.1)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () {
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                ),
              ),
            ),
          ),
        ),
      Positioned(
        top: 12,
        right: 12,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.cameraswitch, color: Colors.black),
                  onPressed: () async {
                    final cams = _cameras;
                    if (cams.isNotEmpty) {
                      final current = _cameraController?.description;
                      CameraLensDirection nextDir = CameraLensDirection.back;
                      if (current != null &&
                          current.lensDirection == CameraLensDirection.back) {
                        nextDir = CameraLensDirection.front;
                      }
                      await _cameraController?.dispose();
                      final idx =
                          cams.indexWhere((c) => c.lensDirection == nextDir);
                      final useIdx = idx >= 0 ? idx : 0;
                      _cameraController = CameraController(
                          cams[useIdx], ResolutionPreset.medium,
                          enableAudio: false);
                      await _cameraController!.initialize();
                      setState(() {
                        _cameraReady = true;
                      });
                    }
                  },
                ),
                IconButton(
                  icon: Icon(_autoCapture ? Icons.pause_circle : Icons.timer,
                      color: Colors.black),
                  onPressed: () async {
                    setState(() {
                      _autoCapture = !_autoCapture;
                    });
                    if (_autoCapture) {
                      await Future.delayed(const Duration(seconds: 2));
                      if (mounted && _autoCapture) {
                        _captureSelfie();
                        setState(() {
                          _autoCapture = false;
                        });
                      }
                    }
                  },
                ),
                if (_selectedImage != null)
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.black),
                    onPressed: () {
                      setState(() {
                        _step = 2;
                      });
                    },
                  ),
              ]),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 96,
        left: 12,
        right: 12,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CustomButton(
              text: S.of(context).takePhotoButton,
              onPressed: _captureSelfie,
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            CustomButton(
              text: S.of(context).galleryButton,
              onPressed: _pickImage,
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
            TextButton(
              onPressed: () {
                setState(() => _step = 2);
              },
              child: Text(S.of(context).skipButton,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    ]);
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() {
        _cameraReady = false;
      });
      return;
    }
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        final frontIndex = _cameras
            .indexWhere((c) => c.lensDirection == CameraLensDirection.front);
        final index = frontIndex >= 0 ? frontIndex : 0;
        _cameraController = CameraController(
            _cameras[index], ResolutionPreset.medium,
            enableAudio: false);
        await _cameraController!.initialize();
        setState(() {
          _cameraReady = true;
        });
      }
    } catch (_) {
      setState(() {
        _cameraReady = false;
      });
    }
  }

  Future<void> _captureSelfie() async {
    try {
      if (_cameraController != null && _cameraReady) {
        final xfile = await _cameraController!.takePicture();
        setState(() {
          _selectedImage = File(xfile.path);
        });
      } else {
        final XFile? image = await _imagePicker.pickImage(
            source: ImageSource.camera,
            maxWidth: 800,
            maxHeight: 800,
            imageQuality: 85);
        if (image != null) {
          setState(() {
            _selectedImage = File(image.path);
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).passwordsDoNotMatch)),
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

      final response = await _authService.register(
        user,
        profile,
        _passwordController.text,
      );

      if (response['success']) {
        // Después del registro exitoso, hacer login automático
        final loginResponse = await _authService.login(
          _usernameController.text,
          _passwordController.text,
        );

        if (loginResponse['success']) {
          if (_selectedUserType == 'inquilino') {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.black.withValues(alpha: 0.85),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              builder: (ctx) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(S.of(context).createSearchProfileTitle,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(S.of(context).createSearchProfileDescription,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85))),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor: Colors.black),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _showAiChatProfileCreation();
                                },
                                child: Text(S.of(context).createWithAIButton))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  Navigator.pushReplacementNamed(
                                      context, '/home');
                                },
                                child: Text(S.of(context).skipButton))),
                      ])
                    ],
                  ),
                );
              },
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(response['error'] ?? S.of(context).registrationError)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).errorMessage(e.toString()))),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAiChatProfileCreation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          margin: const EdgeInsets.only(top: 40),
          child: AiChatWidget(
            userName: _firstNameController.text.isNotEmpty
                ? _firstNameController.text
                : _usernameController.text,
            onClose: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
            onProfileCreated: (data) async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(S.of(context).processingProfile),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
              try {
                final result = await _profileService.createSearchProfile(data);
                if (result['success']) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(S.of(context).searchProfileCreatedSuccess),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                    );
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(S.of(context).errorMessage(result['error'])),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(S.of(context).errorMessage(e.toString())),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  Navigator.pushReplacementNamed(context, '/home');
                }
              }
            },
          ),
        ),
      ),
    );
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
        color: Colors.white,
        child: SafeArea(
          child: Stack(
            children: [
              if (_step == 1)
                Positioned.fill(child: _buildCameraFull())
              else
                Center(child: _buildCardContainer(child: _buildStepBody())),
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
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.black.withValues(alpha: 0.08)),
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
                                          Colors.black.withValues(alpha: 0.2)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                ),
                                child: Text(S.of(context).backButton,
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                          if (_step > 0) const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              text: _step < 3
                                  ? S.of(context).continueButton
                                  : S.of(context).registerButton,
                              onPressed: _step < 3
                                  ? () {
                                      setState(() => _step++);
                                      if (_step == 1) _initCamera();
                                    }
                                  : _register,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
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

  Widget _buildProfileImageSection() {
    return const SizedBox.shrink();
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
            Text(S.of(context).yourNameTitle,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                  child: CustomTextField(
                      controller: _firstNameController,
                      hintText: S.of(context).firstNamePlaceholder,
                      validator: (v) => (v == null || v.isEmpty)
                          ? S.of(context).requiredField
                          : null)),
              const SizedBox(width: 12),
              Expanded(
                  child: CustomTextField(
                      controller: _lastNameController,
                      hintText: S.of(context).lastNamePlaceholder,
                      validator: (v) => (v == null || v.isEmpty)
                          ? S.of(context).requiredField
                          : null)),
            ]),
            const SizedBox(height: 12),
          ],
        );
        return const SizedBox.shrink();
      case 2:
        return Form(
          key: _formKey,
          child: Column(children: [
            Text(S.of(context).contactTitle,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
            const SizedBox(height: 24),
            CustomTextField(
                controller: _emailController,
                hintText: S.of(context).emailPlaceholder,
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.black.withValues(alpha: 0.1))),
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
            child: Column(children: [
              Text(S.of(context).accountTitle,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              const SizedBox(height: 24),
              CustomTextField(
                  controller: _usernameController,
                  hintText: S.of(context).usernamePlaceholder,
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
    _cameraController?.dispose();
    super.dispose();
  }
}

class _FaceMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, overlay);

    // Marco ovalado tipo rostro
    final faceWidth = size.width * 0.65;
    final faceHeight = faceWidth * 1.2;
    final faceRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 10),
      width: faceWidth,
      height: faceHeight,
    );

    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;
    canvas.saveLayer(rect, Paint());
    final path = Path()..addOval(faceRect);
    canvas.drawPath(path, clearPaint);
    canvas.restore();

    final border = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawOval(faceRect, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
