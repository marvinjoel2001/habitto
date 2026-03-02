import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart' as picker;
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/step_progress_indicator.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/custom_choice_chip.dart';
import '../../data/services/profile_service.dart';
import '../../../../generated/l10n.dart';

class CreateSearchProfilePage extends StatefulWidget {
  const CreateSearchProfilePage({super.key});

  @override
  State<CreateSearchProfilePage> createState() =>
      _CreateSearchProfilePageState();
}

class _CreateSearchProfilePageState extends State<CreateSearchProfilePage> {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  final ProfileService _profileService = ProfileService();

  // Step 1: Location and Budget
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  double _budget = 1000;

  // Step 2: Property Requirements
  final List<String> _selectedPropertyTypes = [];
  int _bedroomsMin = 1;
  int _bedroomsMax = 3;
  final List<String> _selectedAmenities = [];
  bool _remoteWorkSpace = false;
  bool _petAllowed = false;

  // Step 3: Cohabitation and Family
  String _roommatePreference = 'open'; // 'no', 'open', 'yes'
  int _familySize = 1;
  int _childrenCount = 0;

  // Step 4: Lifestyle and Vibes
  final List<String> _selectedLifestyleTags = [];
  bool _smoker = false;
  final List<String> _selectedLanguages = [];

  // Map and location
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  Uint8List? _markerImage;
  geo.Position? _currentPosition;
  bool _isMapReady = false;

  // Photo and Verification
  File? _profileImage;
  bool _isVerified = false;
  final picker.ImagePicker _imagePicker = picker.ImagePicker();
  CameraController? _cameraController;
  final bool _cameraReady = false;
  final List<CameraDescription> _cameras = const [];

  bool _isLoading = false;
  bool _isLoadingData = true;
  static const double _budgetPivot = 10000;
  static const double _budgetMaxValue = 100000;

  // Property types
  List<Map<String, dynamic>> get _propertyTypes => [
        {'id': 'casa', 'name': S.of(context).houseType, 'icon': Icons.home},
        {
          'id': 'departamento',
          'name': S.of(context).apartmentType,
          'icon': Icons.apartment
        },
        {
          'id': 'habitacion',
          'name': S.of(context).roomType,
          'icon': Icons.bedroom_parent
        },
      ];

  // Common amenities
  List<Map<String, dynamic>> get _amenities => [
        {'id': 'wifi', 'name': S.of(context).wifiAmenity, 'icon': Icons.wifi},
        {
          'id': 'parking',
          'name': S.of(context).parkingAmenity,
          'icon': Icons.local_parking
        },
        {
          'id': 'laundry',
          'name': S.of(context).laundryAmenity,
          'icon': Icons.local_laundry_service
        },
        {
          'id': 'gym',
          'name': S.of(context).gymAmenity,
          'icon': Icons.fitness_center
        },
        {'id': 'pool', 'name': S.of(context).poolAmenity, 'icon': Icons.pool},
        {
          'id': 'garden',
          'name': S.of(context).gardenAmenity,
          'icon': Icons.park
        },
      ];

  // Lifestyle tags
  List<Map<String, dynamic>> get _lifestyleTags => [
        {
          'id': 'quiet',
          'name': S.of(context).lifestyleQuiet,
          'icon': Icons.self_improvement
        },
        {
          'id': 'social',
          'name': S.of(context).lifestyleSocial,
          'icon': Icons.people_outline
        },
        {
          'id': 'active',
          'name': S.of(context).lifestyleActive,
          'icon': Icons.fitness_center
        },
        {
          'id': 'reading',
          'name': S.of(context).lifestyleReading,
          'icon': Icons.menu_book
        },
        {
          'id': 'music',
          'name': S.of(context).lifestyleMusic,
          'icon': Icons.music_note
        },
        {
          'id': 'movies',
          'name': S.of(context).lifestyleMovies,
          'icon': Icons.movie_filter
        },
        {
          'id': 'cooking',
          'name': S.of(context).lifestyleCooking,
          'icon': Icons.restaurant
        },
        {
          'id': 'travel',
          'name': S.of(context).lifestyleTravel,
          'icon': Icons.flight_takeoff
        },
        {
          'id': 'tech',
          'name': S.of(context).lifestyleTech,
          'icon': Icons.computer
        },
        {
          'id': 'art',
          'name': S.of(context).lifestyleArt,
          'icon': Icons.palette_outlined
        },
        {
          'id': 'nature',
          'name': S.of(context).lifestyleNature,
          'icon': Icons.forest_outlined
        },
        {
          'id': 'study',
          'name': S.of(context).lifestyleStudy,
          'icon': Icons.school_outlined
        },
      ];

  // Languages
  List<String> get _languages => [
        S.of(context).langSpanish,
        S.of(context).langEnglish,
        S.of(context).langPortuguese,
        S.of(context).langFrench,
        S.of(context).langGerman,
        S.of(context).langItalian
      ];

  @override
  void initState() {
    super.initState();
    MapboxOptions.setAccessToken(dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? "");
    _initializePage();
    _budget = 1000;
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      geo.LocationPermission permission =
          await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }
      if (permission == geo.LocationPermission.whileInUse ||
          permission == geo.LocationPermission.always) {
        _currentPosition = await geo.Geolocator.getCurrentPosition(
            desiredAccuracy: geo.LocationAccuracy.high);

        if (_currentPosition != null) {
          setState(() {
            _latitudeController.text =
                _currentPosition!.latitude.toStringAsFixed(6);
            _longitudeController.text =
                _currentPosition!.longitude.toStringAsFixed(6);
          });

          // Update marker if map is ready
          if (_isMapReady) {
            _updateLocationMarker();
          }
        }
      } else {
        print('Location permission denied');
        // Use default location if permission denied
        setState(() {
          _latitudeController.text = '-16.500000';
          _longitudeController.text = '-68.150000';
        });
      }
    } catch (e) {
      print('Error al obtener la ubicación: $e');
      // Use default location on error
      setState(() {
        _latitudeController.text = '-16.500000';
        _longitudeController.text = '-68.150000';
      });
    }
  }

  // Load marker image
  Future<void> _loadMarkerImage() async {
    try {
      final ByteData markerBytes =
          await rootBundle.load('assets/images/house_pointer.png');
      _markerImage = markerBytes.buffer.asUint8List();
    } catch (e) {
      print('Error cargando imagen de marcador: $e');
      // If image loading fails, generate a default marker like in search page
      _markerImage = await _generateDefaultMarker();
    }
  }

  // Generate default marker
  Future<Uint8List> _generateDefaultMarker() async {
    const double size = 64.0;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final bgPaint = Paint()..color = const Color(0x00000000);
    canvas.drawRect(const Rect.fromLTWH(0, 0, size, size), bgPaint);

    final circlePaint = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.95)
      ..style = ui.PaintingStyle.fill;
    const center = Offset(size / 2, size / 2);
    canvas.drawCircle(center, size * 0.36, circlePaint);

    final borderPaint = Paint()
      ..color = AppTheme.whiteColor.withValues(alpha: 0.8)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, size * 0.36, borderPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveSearchProfile();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipStep() {
    if (_currentStep < 4) {
      _nextStep();
    }
  }

  double _budgetToSliderValue(double budget) {
    if (budget <= _budgetPivot) {
      return (budget / _budgetPivot) * 0.6;
    }
    return 0.6 +
        ((budget - _budgetPivot) / (_budgetMaxValue - _budgetPivot)) * 0.4;
  }

  double _sliderValueToBudget(double value) {
    if (value <= 0.0) return 100.0; // Mínimo inicial
    if (value <= 0.6) {
      final raw = (value / 0.6) * _budgetPivot;
      final budget = (raw / 100).round() * 100.0;
      return budget < 100 ? 100 : budget;
    }
    final normalized = (value - 0.6) / 0.4;
    final raw = _budgetPivot + normalized * (_budgetMaxValue - _budgetPivot);
    return (raw / 1000).round() * 1000.0;
  }

  void _showEditBudgetDialog() {
    final controller = TextEditingController(text: _budget.round().toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).budgetRangeLabel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: 'Bs ',
                labelText: S.of(context).budgetRangeLabel,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context).cancelButton),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val == null) {
                Navigator.pop(context);
                return;
              }
              setState(() {
                _budget = val.clamp(100, _budgetMaxValue);
              });
              Navigator.pop(context);
            },
            child: Text(S.of(context).saveChangesButton),
          ),
        ],
      ),
    );
  }

  void _showEditBedroomsDialog() {
    final minController = TextEditingController(text: _bedroomsMin.toString());
    final maxController = TextEditingController(text: _bedroomsMax.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).bedroomsLabel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: S.of(context).minLabel(''),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: maxController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: S.of(context).maxLabel(''),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context).cancelButton),
          ),
          ElevatedButton(
            onPressed: () {
              final minVal = int.tryParse(minController.text);
              final maxVal = int.tryParse(maxController.text);
              if (minVal == null || maxVal == null) {
                Navigator.pop(context);
                return;
              }
              int nextMin = minVal.clamp(1, 10);
              int nextMax = maxVal.clamp(1, 10);
              if (nextMin > nextMax) {
                final temp = nextMin;
                nextMin = nextMax;
                nextMax = temp;
              }
              setState(() {
                _bedroomsMin = nextMin;
                _bedroomsMax = nextMax;
              });
              Navigator.pop(context);
            },
            child: Text(S.of(context).saveChangesButton),
          ),
        ],
      ),
    );
  }

  Future<void> _initializePage() async {
    setState(() {
      _isLoadingData = true;
    });
    await _loadMarkerImage();
    await _ensureLocationPermission();
    await _getCurrentLocation();
    setState(() {
      _isLoadingData = false;
    });
  }

  Future<void> _ensureLocationPermission() async {
    try {
      final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }
      geo.LocationPermission permission =
          await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }
      if (permission == geo.LocationPermission.deniedForever) {
        return;
      }
    } catch (_) {}
  }

  Future<void> _saveSearchProfile() async {
    if (!_validateCurrentStep()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare search profile data according to API documentation
      final searchProfileData = <String, dynamic>{
        'latitude': _latitudeController.text.isNotEmpty
            ? double.parse(_latitudeController.text)
            : -16.500000,
        'longitude': _longitudeController.text.isNotEmpty
            ? double.parse(_longitudeController.text)
            : -68.150000,
        'budget_min': _budget.round(),
        'budget_max': (_budget * 1.5).round(), // Default range based on budget
        'desired_types': _selectedPropertyTypes,
        'bedrooms_min': _bedroomsMin,
        'bedrooms_max': _bedroomsMax,
        'amenities': _selectedAmenities,
        'remote_work_space': _remoteWorkSpace,
        'pet_allowed': _petAllowed,
        'roommate_preference': _roommatePreference,
        'family_size': _familySize,
        'children_count': _childrenCount,
        'lifestyle_tags': _selectedLifestyleTags,
        'smoker': _smoker,
        'languages': _selectedLanguages,
      };

      final response =
          await _profileService.createSearchProfile(searchProfileData);

      if (response['success']) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(S.of(context).searchProfileCreatedTitle),
            content: Text(S.of(context).searchProfileCreatedMessage),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/home', (route) => false);
                },
                child: Text(S.of(context).continueButton),
              ),
            ],
          ),
        );
      } else {
        throw Exception(
            response['error'] ?? S.of(context).errorCreatingSearchProfile);
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

  bool _validateCurrentStep() {
    return true; // We allow skipping all fields per user request
  }

  // Map creation handler
  void _onMapCreated(MapboxMap mapboxMap) async {
    try {
      _mapboxMap = mapboxMap;
      _mapboxMap!.location
          .updateSettings(LocationComponentSettings(enabled: true));
      _pointAnnotationManager =
          await mapboxMap.annotations.createPointAnnotationManager();

      setState(() {
        _isMapReady = true;
      });

      _updateLocationMarker();
    } catch (e) {
      print('Error creating map: $e');
      setState(() {
        _isMapReady = false;
      });
    }
  }

  // Update location marker
  void _updateLocationMarker() async {
    if (_pointAnnotationManager == null || _markerImage == null) {
      print('Cannot update marker: manager or image is null');
      return;
    }

    try {
      await _pointAnnotationManager!.deleteAll();

      double lat = 0.0;
      double lng = 0.0;

      try {
        lat = double.parse(_latitudeController.text);
        lng = double.parse(_longitudeController.text);
      } catch (e) {
        if (_currentPosition != null) {
          lat = _currentPosition!.latitude;
          lng = _currentPosition!.longitude;
          _latitudeController.text = lat.toStringAsFixed(6);
          _longitudeController.text = lng.toStringAsFixed(6);
        } else {
          lat = -16.5000;
          lng = -68.1500;
        }
      }

      final options = <PointAnnotationOptions>[
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(lng, lat)),
          image: _markerImage!,
          iconSize: 0.5,
        )
      ];

      await _pointAnnotationManager!.createMulti(options);
    } catch (e) {
      print('Error updating location marker: $e');
    }
  }

  Widget _buildProgressHeader() {
    const int totalSteps = 5;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: List.generate(totalSteps, (i) {
                  final active = i <= _currentStep;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                      height: 6, // Más ancha
                      margin:
                          EdgeInsets.only(right: i == totalSteps - 1 ? 0 : 8),
                      decoration: BoxDecoration(
                        color: active
                            ? AppTheme.primaryColor
                            : Colors.black.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      'Paso ${_currentStep + 1} de $totalSteps',
                      key: ValueKey(_currentStep),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _stepTitle(),
                      key: ValueKey(_currentStep),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryColor.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
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

  String _stepTitle() {
    switch (_currentStep) {
      case 0:
        return S.of(context).locationStep;
      case 1:
        return S.of(context).propertyStep;
      case 2:
        return S.of(context).cohabitationStep;
      case 3:
        return S.of(context).lifestyleStep;
      default:
        return 'Finalizar Perfil';
    }
  }

  Widget _buildCardContainer({required Widget child}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 92, bottom: 96),
      child: child,
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
          onPressed: () {
            if (_currentStep > 0) {
              _previousStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (_currentStep < 4)
            TextButton(
              onPressed: _skipStep,
              child: Text(
                S.of(context).skipButton,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const SizedBox(width: 48),
        ],
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
          child: _isLoadingData
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                )
              : Stack(
                  children: [
                    Positioned.fill(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildCardContainer(child: _buildStep1()),
                          _buildCardContainer(child: _buildStep2()),
                          _buildCardContainer(child: _buildStep3()),
                          _buildCardContainer(child: _buildStep4()),
                          _buildCardContainer(child: _buildStep5()),
                        ],
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
                      bottom: 8,
                      child: _buildBottomButtons(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // Step 1: Location and Budget
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).step1Title,
                style: const TextStyle(
                    fontSize: 16, color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'Elige una zona ideal y define tu presupuesto para mostrarte opciones reales.',
                style:
                    TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Map for location selection
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            S.of(context).locationStep,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 250,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Stack(
                  children: [
                    MapWidget(
                      onMapCreated: _onMapCreated,
                      styleUri: MapboxStyles.OUTDOORS,
                      cameraOptions: CameraOptions(
                        center: Point(
                          coordinates: Position(
                            _currentPosition?.longitude ?? -68.1500,
                            _currentPosition?.latitude ?? -16.5000,
                          ),
                        ),
                        zoom: 14,
                      ),
                      onTapListener: (gestureContext) {
                        final coordinates = gestureContext.point.coordinates;
                        setState(() {
                          _longitudeController.text =
                              coordinates.lng.toStringAsFixed(6);
                          _latitudeController.text =
                              coordinates.lat.toStringAsFixed(6);
                        });
                        _updateLocationMarker();
                      },
                    ),
                    if (!_isMapReady)
                      Container(
                        color: Colors.white.withValues(alpha: 0.8),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),

                // Current location button
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.my_location, color: Colors.white),
                      onPressed: () {
                        if (_currentPosition != null &&
                            _mapboxMap != null &&
                            _isMapReady) {
                          try {
                            _mapboxMap!.flyTo(
                              CameraOptions(
                                center: Point(
                                  coordinates: Position(
                                    _currentPosition!.longitude,
                                    _currentPosition!.latitude,
                                  ),
                                ),
                                zoom: 15,
                              ),
                              MapAnimationOptions(duration: 1000),
                            );

                            setState(() {
                              _latitudeController.text =
                                  _currentPosition!.latitude.toStringAsFixed(6);
                              _longitudeController.text = _currentPosition!
                                  .longitude
                                  .toStringAsFixed(6);
                            });

                            _updateLocationMarker();
                          } catch (e) {
                            print('Error flying to current location: $e');
                          }
                        } else {
                          print(
                              'Map not ready or current position not available');
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Budget range slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            S.of(context).budgetRangeLabel,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.getGlassCard(),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.of(context).dragToAdjustLabel,
                        style: const TextStyle(color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bs ${_budget.round()}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: Colors.black),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit,
                        size: 18, color: AppTheme.primaryColor),
                    onPressed: _showEditBudgetDialog,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  valueIndicatorColor:
                      AppTheme.primaryColor.withValues(alpha: 0.9),
                  valueIndicatorTextStyle:
                      const TextStyle(color: Colors.white, fontSize: 12),
                  overlayColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                  activeTrackColor: AppTheme.primaryColor,
                  inactiveTrackColor:
                      AppTheme.primaryColor.withValues(alpha: 0.25),
                  thumbColor: AppTheme.primaryColor,
                ),
                child: Slider(
                  value: _budgetToSliderValue(_budget),
                  min: 0,
                  max: 1,
                  divisions: 200,
                  label: 'Bs ${_budget.round()}',
                  onChanged: (value) {
                    setState(() {
                      _budget = _sliderValueToBudget(value);
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Step 2: Property Requirements
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).step2Title,
                style: const TextStyle(
                    fontSize: 16, color: Colors.black, height: 1.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cuéntanos el tipo de lugar y las comodidades que realmente te importan.',
                style:
                    TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Property types
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            S.of(context).propertyTypeLabel,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _propertyTypes.map((type) {
              final isSelected = _selectedPropertyTypes.contains(type['id']);
              return CustomChoiceChip(
                label: type['name'],
                icon: type['icon'],
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedPropertyTypes.add(type['id']);
                    } else {
                      _selectedPropertyTypes.remove(type['id']);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 24),

        // Bedrooms range
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                S.of(context).bedroomsLabel,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black),
              ),
              IconButton(
                icon: const Icon(Icons.edit,
                    size: 18, color: AppTheme.primaryColor),
                onPressed: _showEditBedroomsDialog,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.getGlassCard(),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(S.of(context).minLabel(_bedroomsMin),
                      style: const TextStyle(color: Colors.black)),
                  Text(S.of(context).maxLabel(_bedroomsMax),
                      style: const TextStyle(color: Colors.black)),
                ],
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  valueIndicatorColor:
                      AppTheme.primaryColor.withValues(alpha: 0.9),
                  valueIndicatorTextStyle:
                      const TextStyle(color: Colors.white, fontSize: 12),
                  overlayColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                  activeTrackColor: AppTheme.primaryColor,
                  inactiveTrackColor:
                      AppTheme.primaryColor.withValues(alpha: 0.25),
                  thumbColor: AppTheme.primaryColor,
                ),
                child: RangeSlider(
                  values: RangeValues(
                      _bedroomsMin.toDouble(), _bedroomsMax.toDouble()),
                  min: 1,
                  max: 6,
                  divisions: 5,
                  labels: RangeLabels(
                    '$_bedroomsMin',
                    '$_bedroomsMax',
                  ),
                  onChanged: (values) {
                    setState(() {
                      _bedroomsMin = values.start.round();
                      _bedroomsMax = values.end.round();
                    });
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Amenities
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            S.of(context).amenitiesLabel,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _amenities.map((amenity) {
              final isSelected = _selectedAmenities.contains(amenity['id']);
              return CustomChoiceChip(
                label: amenity['name'],
                icon: amenity['icon'],
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedAmenities.add(amenity['id']);
                    } else {
                      _selectedAmenities.remove(amenity['id']);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 24),

        // Switches
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.getGlassCard(),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      S.of(context).remoteWorkSpaceLabel,
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                  Switch(
                    value: _remoteWorkSpace,
                    onChanged: (value) {
                      setState(() {
                        _remoteWorkSpace = value;
                      });
                    },
                    activeThumbColor: AppTheme.primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      S.of(context).petAllowedLabel,
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                  Switch(
                    value: _petAllowed,
                    onChanged: (value) {
                      setState(() {
                        _petAllowed = value;
                      });
                    },
                    activeThumbColor: AppTheme.primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Step 3: Cohabitation and Family
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.people_alt_rounded,
                      color: AppTheme.primaryColor, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Preferencias de Convivencia',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: -0.5),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                '¿Buscas a alguien para compartir los gastos del alquiler y servicios?',
                style:
                    TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
              ),
              SizedBox(height: 4),
              Text(
                'Un "roomie" es un compañero de casa con el que compartes un lugar más grande y cómodo dividiendo los costos.',
                style:
                    TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Roommate preference options
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              _buildRadioOption(
                'No, busco un lugar solo',
                'no',
                icon: Icons.person_outline,
                subtitle: 'Prefiero tener mi propio espacio privado.',
              ),
              const SizedBox(height: 12),
              _buildRadioOption(
                'Abierto a compartir',
                'open',
                icon: Icons.sync_alt,
                subtitle: 'Me da igual, busco la mejor opción disponible.',
              ),
              const SizedBox(height: 12),
              _buildRadioOption(
                'Sí, busco un roomie',
                'yes',
                icon: Icons.group_outlined,
                subtitle:
                    'Quiero alquilar algo mejor compartiendo gastos con alguien compatible.',
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Family size
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            S.of(context).familySizeLabel,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildCounterField(
            value: _familySize,
            onChanged: (value) {
              setState(() {
                _familySize = value;
              });
            },
            min: 1,
            max: 10,
          ),
        ),

        const SizedBox(height: 24),

        // Children count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            S.of(context).childrenCountLabel,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildCounterField(
            value: _childrenCount,
            onChanged: (value) {
              setState(() {
                _childrenCount = value;
              });
            },
            min: 0,
            max: 10,
          ),
        ),
      ],
    );
  }

  // Step 4: Lifestyle and Vibes
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).step4Title,
                style: const TextStyle(
                    fontSize: 16, color: Colors.black, height: 1.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'Selecciona hábitos y preferencias para mejorar el match.',
                style:
                    TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Lifestyle tags
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            S.of(context).lifestyleLabel,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            S.of(context).selectTagsLabel(_selectedLifestyleTags.length),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _lifestyleTags.map((tag) {
              final isSelected = _selectedLifestyleTags.contains(tag['id']);
              return CustomChoiceChip(
                label: tag['name'],
                icon: tag['icon'],
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected && _selectedLifestyleTags.length < 5) {
                      _selectedLifestyleTags.add(tag['id']);
                    } else if (!selected) {
                      _selectedLifestyleTags.remove(tag['id']);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 24),

        // Smoker switch
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.getGlassCard(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  S.of(context).smokerLabel,
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
              Switch(
                value: _smoker,
                onChanged: (value) {
                  setState(() {
                    _smoker = value;
                  });
                },
                activeThumbColor: AppTheme.primaryColor,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Languages
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            S.of(context).languagesLabel,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _languages.map((language) {
              final isSelected = _selectedLanguages.contains(language);
              return CustomChoiceChip(
                label: language,
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedLanguages.add(language);
                    } else {
                      _selectedLanguages.remove(language);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStep5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_user_rounded,
                      color: AppTheme.primaryColor, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Verifica tu Perfil',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: -0.5),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'Sube una foto real para que otros usuarios confíen en ti. Los perfiles verificados tienen 3 veces más matches.',
                style:
                    TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: _pickProfileImage,
            child: Container(
              width: 180,
              height: 240,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _profileImage != null
                      ? AppTheme.primaryColor
                      : Colors.white.withValues(alpha: 0.8),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: _profileImage != null
                    ? Image.file(_profileImage!, fit: BoxFit.cover)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded,
                              size: 48,
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.6)),
                          const SizedBox(height: 12),
                          const Text(
                            'Subir Foto',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.getGlassCard(),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: Colors.blue[700], size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verificación de Identidad',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Opcional: Verifica tu identidad para obtener el check azul.',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isVerified,
                  onChanged: (v) {
                    setState(() => _isVerified = v);
                  },
                  activeThumbColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickProfileImage() async {
    try {
      final picker.XFile? image = await _imagePicker.pickImage(
        source: picker.ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Widget _buildRadioOption(String label, String value,
      {String? subtitle, IconData? icon}) {
    final isSelected = _roommatePreference == value;
    return Container(
      decoration: isSelected
          ? BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
            )
          : BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
      child: RadioListTile<String>(
        secondary: icon != null
            ? Icon(
                icon,
                color: isSelected ? AppTheme.primaryColor : Colors.black45,
                size: 28,
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : Colors.black,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: isSelected ? Colors.black87 : Colors.black54,
                  fontSize: 13,
                  height: 1.3,
                ),
              )
            : null,
        value: value,
        groupValue: _roommatePreference,
        onChanged: (value) {
          setState(() {
            _roommatePreference = value!;
          });
        },
        activeColor: AppTheme.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildCounterField({
    required int value,
    required Function(int) onChanged,
    required int min,
    required int max,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.getGlassCard(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppTheme.darkGrayBase.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: IconButton(
              onPressed: value > min ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove, color: Colors.black),
            ),
          ),
          Text(
            value.toString(),
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppTheme.darkGrayBase.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: IconButton(
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousStep,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.6)),
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(S.of(context).previousButton,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: _currentStep == 3
                      ? S.of(context).finishButton
                      : S.of(context).nextButton,
                  onPressed: _isLoading ? null : _nextStep,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  textColor: Colors.white,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
