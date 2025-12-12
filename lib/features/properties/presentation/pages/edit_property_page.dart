import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../core/services/api_service.dart';
import '../../../../config/app_config.dart';
import '../../../../../generated/l10n.dart';
import '../../data/services/property_service.dart';
import '../../data/services/photo_service.dart';
import '../../../matching/data/services/matching_service.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/photo.dart';

class EditPropertyPage extends StatefulWidget {
  final Property property;

  const EditPropertyPage({
    super.key,
    required this.property,
  });

  @override
  State<EditPropertyPage> createState() => _EditPropertyPageState();
}

class _EditPropertyPageState extends State<EditPropertyPage>
    with SingleTickerProviderStateMixin {
  late Property _property;
  late final PropertyService _propertyService;
  late final PhotoService _photoService;
  late final MatchingService _matchingService;
  late final TabController _tabController;

  bool _isLoading = false;
  bool _isLoadingPhotos = true;
  List<Photo> _photos = [];
  List<dynamic> _interestedUsers = [];
  int _matchCount = 0;
  bool _isLoadingMatches = true;
  final ImagePicker _picker = ImagePicker();

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _addressController;
  late TextEditingController _sizeController;
  late TextEditingController _bedroomsController;
  late TextEditingController _bathroomsController;
  late TextEditingController _guaranteeController;

  @override
  void initState() {
    super.initState();
    _property = widget.property;
    _propertyService = PropertyService();
    _photoService = PhotoService(ApiService());
    _matchingService = MatchingService();
    _tabController = TabController(length: 3, vsync: this);

    _initControllers();
    _loadPhotos();
    _loadMatches();
  }

  void _initControllers() {
    _descriptionController = TextEditingController(text: _property.description);
    _priceController = TextEditingController(text: _property.price.toString());
    _addressController = TextEditingController(text: _property.address);
    _sizeController = TextEditingController(text: _property.size.toString());
    _bedroomsController =
        TextEditingController(text: _property.bedrooms.toString());
    _bathroomsController =
        TextEditingController(text: _property.bathrooms.toString());
    _guaranteeController =
        TextEditingController(text: _property.guarantee.toString());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _sizeController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _guaranteeController.dispose();
    super.dispose();
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoadingPhotos = true);
    final result = await _photoService.getPropertyPhotos(_property.id);
    if (result['success']) {
      if (mounted) {
        setState(() {
          _photos = result['data']['photos'] as List<Photo>;
          _isLoadingPhotos = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingPhotos = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(S.of(context).loadPhotosError(result['error']))),
        );
      }
    }
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoadingMatches = true);
    final result = await _matchingService.getPendingMatchRequests();

    if (result['success']) {
      final allRequests = result['data'] as List<dynamic>;
      // Filtrar solicitudes para esta propiedad
      final requestsForThisProperty = allRequests.where((r) {
        final prop = r['property'];
        if (prop == null) return false;
        return prop['id'] == _property.id;
      }).toList();

      if (mounted) {
        setState(() {
          _interestedUsers = requestsForThisProperty;
          _matchCount = requestsForThisProperty.length;
          _isLoadingMatches = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingMatches = false);
        // No mostrar error bloqueante, solo log
        print('Error cargando matches: ${result['error']}');
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> images = await _picker.pickMultiImage();
        if (images.isNotEmpty) {
          await _uploadPhotos(images);
        }
      } else {
        final XFile? image = await _picker.pickImage(source: source);
        if (image != null) {
          await _uploadPhotos([image]);
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).pickImageError(e.toString()))),
      );
    }
  }

  Future<void> _uploadPhotos(List<XFile> images) async {
    setState(() => _isLoading = true);

    int successCount = 0;
    int failCount = 0;

    for (var image in images) {
      final file = File(image.path);
      final result = await _photoService.uploadPropertyPhoto(
        propertyId: _property.id,
        imageFile: file,
      );

      if (result['success']) {
        successCount++;
      } else {
        failCount++;
        print('Error uploading ${image.name}: ${result['error']}');
      }
    }

    await _loadPhotos();

    if (mounted) {
      setState(() => _isLoading = false);
      if (failCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).uploadSummary(successCount, failCount)),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).photosUploadedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deletePhoto(int photoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(context).deletePhotoTitle),
        content: Text(S.of(context).deletePhotoConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.of(context).cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.of(context).deleteButton,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final result = await _photoService.deletePhoto(photoId);

    if (result['success']) {
      await _loadPhotos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).photoDeletedSuccess)),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).genericError(result['error']))),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _savePropertyDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final updateData = {
      'description': _descriptionController.text,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'guarantee': double.tryParse(_guaranteeController.text) ?? 0.0,
      'address': _addressController.text,
      'size': double.tryParse(_sizeController.text) ?? 0.0,
      'bedrooms': int.tryParse(_bedroomsController.text) ?? 0,
      'bathrooms': int.tryParse(_bathroomsController.text) ?? 0,
    };

    final result =
        await _propertyService.updateProperty(_property.id, updateData);

    setState(() => _isLoading = false);

    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).propertyUpdatedSuccess),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _property = Property(
            id: _property.id,
            type: _property.type, // Type is not editable here
            address: updateData['address'] as String,
            price: updateData['price'] as double,
            guarantee: updateData['guarantee'] as double,
            description: updateData['description'] as String,
            size: updateData['size'] as double,
            bedrooms: updateData['bedrooms'] as int,
            bathrooms: updateData['bathrooms'] as int,
            isActive: _property.isActive,
            createdAt: _property.createdAt,
            updatedAt: DateTime.now(),
            owner: _property.owner,
            amenities: _property.amenities,
            acceptedPaymentMethods: _property.acceptedPaymentMethods,
            mainPhoto: _property.mainPhoto,
            latitude: _property.latitude,
            longitude: _property.longitude,
            agent: _property.agent,
            availabilityDate: _property.availabilityDate,
          );
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).updatePropertyError(result['error'])),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildGlassContainer({required Widget child, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Derived title for display
    final displayTitle = "${_property.type} · ${_property.address}";

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          S.of(context).editPropertyTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined, color: Colors.white),
            onPressed: _savePropertyDetails,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: AppTheme.getProfileBackground(),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildDescription(displayTitle),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.primaryColor,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_on_outlined)),
                      Tab(icon: Icon(Icons.edit_note_outlined)),
                      Tab(icon: Icon(Icons.favorite_border)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPhotosGrid(),
                        _buildEditForm(),
                        _buildInterestedList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => _buildImagePickerSheet(ctx),
                );
              },
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add_a_photo, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    final mainPhotoUrl = _photos.isNotEmpty
        ? AppConfig.sanitizeUrl(_photos.first.image)
        : (_property.mainPhoto != null
            ? AppConfig.sanitizeUrl(_property.mainPhoto!)
            : '');

    return Row(
      children: [
        // Property Avatar (Main Image)
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipOval(
            child: mainPhotoUrl.isNotEmpty
                ? Image.network(
                    mainPhotoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey, child: const Icon(Icons.home)),
                  )
                : Container(color: Colors.grey, child: const Icon(Icons.home)),
          ),
        ),
        const SizedBox(width: 20),

        // Stats
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                  S.of(context).priceLabel, '${_property.price.toInt()}'),
              _buildStatItem(
                  S.of(context).bedroomsShortLabel, '${_property.bedrooms}'),
              _buildStatItem(
                  S.of(context).bathroomsLabel, '${_property.bathrooms}'),
              _buildStatItem(S.of(context).matchLabel, '$_matchCount'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _property.address,
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _property.description,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosGrid() {
    if (_isLoadingPhotos) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_library_outlined,
                size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              S.of(context).noPhotosYet,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: S.of(context).uploadPhotosButton,
              onPressed: () => _pickImage(ImageSource.gallery),
              width: 200,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final photo = _photos[index];
        return GestureDetector(
          onLongPress: () => _deletePhoto(photo.id),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                AppConfig.sanitizeUrl(photo.image),
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
              Positioned(
                right: 4,
                top: 4,
                child: GestureDetector(
                  onTap: () => _deletePhoto(photo.id),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInterestedList() {
    if (_isLoadingMatches) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_interestedUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              S.of(context).noInterestsYet,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _interestedUsers.length,
      separatorBuilder: (ctx, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final request = _interestedUsers[index];
        final user = request['interested_user'] ?? {};
        final match = request['match'] ?? {};

        final String name =
            "${user['first_name'] ?? ''} ${user['last_name'] ?? ''}".trim();
        final String displayName =
            name.isNotEmpty ? name : (user['email'] ?? 'Usuario');
        final String? photoUrl = user['profile_image'];

        return _buildGlassContainer(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  image: DecorationImage(
                    image: (photoUrl != null && photoUrl.isNotEmpty)
                        ? NetworkImage(AppConfig.sanitizeUrl(photoUrl))
                        : const AssetImage('assets/images/unnamed.png')
                            as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      S.of(context).matchScore(match['score'] ?? '0'),
                      style: TextStyle(
                        color: AppTheme.primaryColor.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Action Button
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline,
                      color: Colors.white, size: 20),
                  onPressed: () {
                    // TODO: Navigate to chat or accept match
                    // For now just accept
                    _acceptMatch(match['id']);
                  },
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _acceptMatch(dynamic matchId) async {
    if (matchId == null) return;

    // Convert matchId to int if necessary
    final int id =
        (matchId is int) ? matchId : int.tryParse(matchId.toString()) ?? 0;
    if (id == 0) return;

    setState(() => _isLoadingMatches = true);
    final result = await _matchingService.acceptMatchRequest(id);

    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(S.of(context).matchAcceptedMessage),
              backgroundColor: Colors.green),
        );
        _loadMatches(); // Reload list
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingMatches = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).genericError(result['error']))),
        );
      }
    }
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildGlassTextField(
              controller: _priceController,
              label: S.of(context).priceBsLabel,
              icon: Icons.attach_money,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildGlassTextField(
              controller: _guaranteeController,
              label: S.of(context).guaranteeBsLabel,
              icon: Icons.shield_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildGlassTextField(
              controller: _addressController,
              label: S.of(context).addressLabel,
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildGlassTextField(
                    controller: _bedroomsController,
                    label: S.of(context).bedroomsLabel,
                    icon: Icons.bed_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildGlassTextField(
                    controller: _bathroomsController,
                    label: S.of(context).bathroomsLabel,
                    icon: Icons.bathtub_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildGlassTextField(
              controller: _sizeController,
              label: S.of(context).sizeLabel,
              icon: Icons.square_foot,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildGlassTextField(
              controller: _descriptionController,
              label: S.of(context).descriptionLabel,
              icon: Icons.description_outlined,
              maxLines: 4,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: S.of(context).saveChangesButton,
              onPressed: _savePropertyDetails,
              textColor: Colors.white,
            ),
            const SizedBox(height: 40), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return _buildGlassContainer(
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: Colors.white70),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return S.of(context).requiredField;
          }
          return null;
        },
      ),
    );
  }

  Widget _buildImagePickerSheet(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            S.of(context).uploadPhotosTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPickerOption(
                icon: Icons.camera_alt,
                label: S.of(context).cameraOption,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              _buildPickerOption(
                icon: Icons.photo_library,
                label: S.of(context).galleryOption,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}
