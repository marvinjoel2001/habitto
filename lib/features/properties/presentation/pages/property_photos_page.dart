import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/widgets/custom_network_image.dart';
import '../../../../core/services/api_service.dart';
import '../../../../config/app_config.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../data/services/photo_service.dart';
import '../../domain/entities/photo.dart';
import '../../domain/entities/property.dart';
import '../../../../../generated/l10n.dart';

class PropertyPhotosPage extends StatefulWidget {
  final Property property;

  const PropertyPhotosPage({
    super.key,
    required this.property,
  });

  @override
  State<PropertyPhotosPage> createState() => _PropertyPhotosPageState();
}

class _PropertyPhotosPageState extends State<PropertyPhotosPage> {
  late PhotoService _photoService;
  final ImagePicker _imagePicker = ImagePicker();

  List<Photo> _photos = [];
  bool _isLoading = true;
  bool _isUploading = false;
  int _uploadedCount = 0;

  @override
  void initState() {
    super.initState();
    _photoService = PhotoService(ApiService());
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _photoService.getPropertyPhotos(widget.property.id);

    if (result['success']) {
      setState(() {
        _photos = result['data']['photos'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(result['error'] ?? S.of(context).loadPhotosErrorGeneric),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadImage(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).pickImageError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      if (widget.property.id <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).invalidPropertyIdError),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadImage(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).takePhotoError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickMultipleAndUpload() async {
    try {
      if (widget.property.id <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).invalidPropertyIdError),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _isUploading = true;
          _uploadedCount = 0;
        });

        for (final img in images) {
          final result = await _photoService.uploadPropertyPhoto(
            propertyId: widget.property.id,
            imageFile: File(img.path),
            caption: 'Foto de ${widget.property.address}',
          );

          if (result['success']) {
            _uploadedCount++;
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      result['error'] ?? S.of(context).uploadPhotoErrorGeneric),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }

        if (mounted) {
          setState(() {
            _isUploading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  S.of(context).photosUploadedCount(_uploadedCount.toString())),
              backgroundColor: Colors.green,
            ),
          );
        }

        await _loadPhotos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).pickImagesError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    setState(() {
      _isUploading = true;
    });

    if (widget.property.id <= 0) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).invalidPropertyIdErrorDetail),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final result = await _photoService.uploadPropertyPhoto(
      propertyId: widget.property.id,
      imageFile: imageFile,
      caption: 'Foto de ${widget.property.address}',
    );

    setState(() {
      _isUploading = false;
    });

    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(result['message'] ?? S.of(context).photoUploadedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Recargar las fotos
      await _loadPhotos();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(result['error'] ?? S.of(context).uploadPhotoErrorGeneric),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePhoto(Photo photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).deletePhotoTitle),
        content: Text(S.of(context).deletePhotoConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.of(context).cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(S.of(context).deleteButton),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _photoService.deletePhoto(photo.id);

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(result['message'] ?? S.of(context).photoDeletedSuccess),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Recargar las fotos
        await _loadPhotos();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  result['error'] ?? S.of(context).deletePhotoErrorGeneric),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          S.of(context).photosOfProperty(widget.property.address),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Encabezado informativo
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.home_outlined,
                          color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.property.type,
                                style: AppTheme.headlineSmall),
                            Text(
                                'ID: ${widget.property.id} · ${widget.property.address}',
                                style: AppTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Botón para agregar fotos
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  (_isUploading || widget.property.id <= 0)
                                      ? null
                                      : _pickAndUploadImage,
                              icon: _isUploading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.photo_library_outlined),
                              label: Text(_isUploading
                                  ? S.of(context).uploadingStatus
                                  : S.of(context).galleryOption),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  (_isUploading || widget.property.id <= 0)
                                      ? null
                                      : _pickFromCamera,
                              icon: const Icon(Icons.photo_camera_outlined),
                              label: Text(S.of(context).cameraOption),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black87,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: (_isUploading || widget.property.id <= 0)
                              ? null
                              : _pickMultipleAndUpload,
                          icon: const Icon(Icons.collections_outlined),
                          label: Text(S.of(context).selectMultiplePhotos),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side:
                                const BorderSide(color: AppTheme.primaryColor),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          S.of(context).uploadMultipleHint,
                          style: AppTheme.bodyMedium
                              .copyWith(color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                ),

                // Lista de fotos
                Expanded(
                  child:
                      _photos.isEmpty ? _buildEmptyState() : _buildPhotoGrid(),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            S.of(context).noPhotosYet,
            style: AppTheme.headlineSmall.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            S.of(context).addPhotosHint,
            style: AppTheme.bodyMedium.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final photo = _photos[index];
        return _buildPhotoCard(photo);
      },
    );
  }

  Widget _buildPhotoCard(Photo photo) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen
            CustomNetworkImage(
              imageUrl: AppConfig.sanitizeUrl(photo.image),
              fit: BoxFit.cover,
              placeholder: Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: Container(
                color: Colors.grey[200],
                child: const Icon(
                  Icons.broken_image,
                  size: 50,
                  color: Colors.grey,
                ),
              ),
            ),

            // Overlay con botones
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: () => _deletePhoto(photo),
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ),
            ),

            // Caption si existe
            if (photo.caption != null && photo.caption!.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    photo.caption!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
