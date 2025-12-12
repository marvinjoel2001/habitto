import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../data/services/profile_service.dart';
import '../../domain/entities/profile.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../../../generated/l10n.dart';

class EditProfilePage extends StatefulWidget {
  final Profile profile;
  final User user;

  const EditProfilePage({
    super.key,
    required this.profile,
    required this.user,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();
  final _imagePicker = ImagePicker();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _userTypeController;
  late TextEditingController _emailController;

  File? _selectedImage;
  bool _isLoading = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _phoneController = TextEditingController(text: widget.profile.phone);
    _userTypeController = TextEditingController(text: widget.profile.userType);
    _emailController = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _userTypeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final profileData = {
        'phone': _phoneController.text.trim(),
        'user_type': _userTypeController.text,
      };

      final profileResult = await _profileService.updateCurrentProfile(
        profileData,
        profileImage: _selectedImage,
      );

      if (!profileResult['success']) {
        throw Exception(profileResult['error']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).profileUpdatedSuccess)),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(S.of(context).profileUpdateError(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Gradient
          Container(
            height: 300,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF8E2DE2), // Purple
                  Color(0xFFFF0080), // Pink/Magenta
                  Color(0xFFFF6600), // Orange
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  S.of(context).editProfileTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // 2. White Container with Rounded Corners
          Container(
            margin: const EdgeInsets.only(top: 180),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMinimalTextField(
                            controller: _firstNameController,
                            label: S.of(context).firstNameLabel,
                            enabled: false,
                          ),
                          const SizedBox(height: 24),
                          _buildMinimalTextField(
                            controller: _lastNameController,
                            label: S.of(context).lastNameLabel,
                            enabled: false,
                          ),
                          const SizedBox(height: 24),
                          _buildMinimalTextField(
                            controller: _emailController,
                            label: S.of(context).emailLabel,
                            enabled: false,
                          ),
                          const SizedBox(height: 24),
                          _buildMinimalTextField(
                            controller: _phoneController,
                            label: S.of(context).phoneLabel,
                            icon: Icons.phone,
                            enabled: true,
                            isEditable: true,
                          ),
                          const SizedBox(height: 32),
                          _buildActionRow(S.of(context).changePasswordLabel,
                              hasArrow: true),
                          const SizedBox(height: 24),
                          _buildNotificationSwitch(),
                          const SizedBox(height: 40),
                          _buildButtons(),
                        ],
                      ),
                    ),
                  ),
          ),

          // 3. Avatar & Label (Overlapping)
          Positioned(
            top: 110,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                height: 140,
                width: 300, // Wide enough to hold label + avatar
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Label (User Type) - Behind Avatar
                    Positioned(
                      left: 10, // Adjust to position to the left of avatar
                      child: Container(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right:
                              50, // Extra padding on right to slide under avatar
                          top: 8,
                          bottom: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFF8E2DE2).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getModeIcon(_userTypeController.text),
                              color: const Color(0xFF8E2DE2),
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userTypeController.text.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF8E2DE2),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Avatar
                    Container(
                      width: 130,
                      height: 130,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8E2DE2), Color(0xFFFF0080)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: _selectedImage != null
                              ? Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                )
                              : widget.profile.profileImage != null &&
                                      widget.profile.profileImage!.isNotEmpty
                                  ? Image.network(
                                      widget.profile.profileImage!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Image.asset(
                                          'assets/images/unnamed.png',
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    )
                                  : Image.asset(
                                      'assets/images/unnamed.png',
                                      fit: BoxFit.cover,
                                    ),
                        ),
                      ),
                    ),

                    // Edit Icon (Pencil)
                    Positioned(
                      bottom: 5,
                      right:
                          90, // Positioned relative to the stack center/width
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Color(0xFF8E2DE2),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: 50,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool enabled = true,
    bool isEditable = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.grey[400], size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: TextFormField(
                controller: controller,
                enabled: enabled,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w400,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                ),
              ),
            ),
            if (isEditable) Icon(Icons.edit, color: Colors.grey[400], size: 18),
          ],
        ),
        const SizedBox(height: 8),
        Divider(color: Colors.grey[300], thickness: 1),
      ],
    );
  }

  Widget _buildActionRow(String title, {bool hasArrow = false}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
              ),
            ),
            if (hasArrow)
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
        const SizedBox(height: 12),
        Divider(color: Colors.grey[300], thickness: 1),
      ],
    );
  }

  Widget _buildNotificationSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          S.of(context).notificationsLabel,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w400,
          ),
        ),
        Switch(
          value: _notificationsEnabled,
          onChanged: (value) {
            setState(() {
              _notificationsEnabled = value;
            });
          },
          activeThumbColor: const Color(0xFF8E2DE2),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: const LinearGradient(
                colors: [Color(0xFF8E2DE2), Color(0xFFFF0080)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF0080).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                S.of(context).saveChangesButton,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[400]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                S.of(context).cancelButtonCaps,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getModeIcon(String mode) {
    switch (mode.toLowerCase()) {
      case 'inquilino':
        return Icons.person_outline;
      case 'propietario':
        return Icons.home_work_outlined;
      case 'agente':
        return Icons.verified_user_outlined;
      default:
        return Icons.person_outline;
    }
  }
}
