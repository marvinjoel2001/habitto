import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/step_progress_indicator.dart';
import '../../../../shared/theme/app_theme.dart';
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
  double _budgetMin = 1000000;
  double _budgetMax = 5000000;

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

  bool _isLoading = false;
  bool _isLoadingData = true;

  // Property types
  List<Map<String, dynamic>> get _propertyTypes => [
    {'id': 'casa', 'name': S.of(context).houseType, 'icon': Icons.home},
    {'id': 'departamento', 'name': S.of(context).apartmentType, 'icon': Icons.apartment},
    {'id': 'habitacion', 'name': S.of(context).roomType, 'icon': Icons.bedroom_parent},
  ];

  // Common amenities
  List<Map<String, dynamic>> get _amenities => [
    {'id': 'wifi', 'name': S.of(context).wifiAmenity, 'icon': Icons.wifi},
    {'id': 'parking', 'name': S.of(context).parkingAmenity, 'icon': Icons.local_parking},
    {
      'id': 'laundry',
      'name': S.of(context).laundryAmenity,
      'icon': Icons.local_laundry_service
    },
    {'id': 'gym', 'name': S.of(context).gymAmenity, 'icon': Icons.fitness_center},
    {'id': 'pool', 'name': S.of(context).poolAmenity, 'icon': Icons.pool},
    {'id': 'garden', 'name': S.of(context).gardenAmenity, 'icon': Icons.park},
  ];

  // Lifestyle tags
  List<String> get _lifestyleTags => [
    S.of(context).lifestyleQuiet,
    S.of(context).lifestyleSocial,
    S.of(context).lifestyleActive,
    S.of(context).lifestyleReading,
    S.of(context).lifestyleMusic,
    S.of(context).lifestyleMovies,
    S.of(context).lifestyleCooking,
    S.of(context).lifestyleTravel,
    S.of(context).lifestyleTech,
    S.of(context).lifestyleArt,
    S.of(context).lifestyleNature,
    S.of(context).lifestyleStudy
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
    MapboxOptions.setAccessToken("pk.eyJ1IjoibWFydmluMjAwMSIsImEiOiJjbWdpaDRicTQwOTc3Mm9wcmd3OW5lNzExIn0.ISPECxmLq_6xhipoygxtFg");
    _initializePage();
    _budgetMin = 10;
    _budgetMax = 5000000;
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
      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
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
    if (_currentStep < 3) {
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
    if (_currentStep < 3) {
      _nextStep();
    }
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
      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
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
        'budget_min': _budgetMin.round(),
        'budget_max': _budgetMax.round(),
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
            content: Text(
                S.of(context).searchProfileCreatedMessage),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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
    switch (_currentStep) {
      case 0:
        if (_latitudeController.text.isEmpty ||
            _longitudeController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(S.of(context).selectLocationError)),
          );
          return false;
        }
        break;
      case 1:
        if (_selectedPropertyTypes.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(S.of(context).selectPropertyTypeError)),
          );
          return false;
        }
        break;
    }
    return true;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: _isLoadingData
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              )
            : Column(
                children: [
                  _buildHeader(),
                  _buildStepIndicator(),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStep1(),
                        _buildStep2(),
                        _buildStep3(),
                        _buildStep4(),
                      ],
                    ),
                  ),
                  _buildBottomButtons(),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 80 + MediaQuery.of(context).padding.top,
      decoration: const BoxDecoration(color: Colors.white),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  S.of(context).createSearchProfileTitle,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (_currentStep >= 2)
                TextButton(
                  onPressed: _skipStep,
                  child: Text(
                    S.of(context).skipButton,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                )
              else
                const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: StepProgressIndicator(
        currentStep: _currentStep,
        totalSteps: 4,
        stepTitles: [
          S.of(context).locationStep,
          S.of(context).propertyStep,
          S.of(context).cohabitationStep,
          S.of(context).lifestyleStep
        ],
      ),
    );
  }

  // Step 1: Location and Budget
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).step1Title,
            style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
          ),
          const SizedBox(height: 32),

          // Map for location selection
          Text(
            S.of(context).locationStep,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          Container(
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
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
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon:
                            const Icon(Icons.my_location, color: Colors.white),
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
                                _latitudeController.text = _currentPosition!
                                    .latitude
                                    .toStringAsFixed(6);
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
          Text(
            S.of(context).budgetRangeLabel,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      S.of(context).dragToAdjustLabel,
                      style: const TextStyle(color: Colors.black),
                    ),
                    Text(
                      'Bs. ${_budgetMax.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                RangeSlider(
                  values: RangeValues(_budgetMin, _budgetMax),
                  min: 1,
                  max: 10000000,
                  divisions: 100,
                  activeColor: AppTheme.primaryColor,
                  inactiveColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                  labels: RangeLabels(
                    'Bs. ${_budgetMin.toStringAsFixed(0)}',
                    'Bs. ${_budgetMax.toStringAsFixed(0)}',
                  ),
                  onChanged: (values) {
                    setState(() {
                      _budgetMin = values.start;
                      _budgetMax = values.end;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 2: Property Requirements
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).step2Title,
            style: const TextStyle(fontSize: 16, color: Colors.black, height: 1.5),
          ),
          const SizedBox(height: 32),

          // Property types
          Text(
            S.of(context).propertyTypeLabel,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _propertyTypes.map((type) {
              final isSelected = _selectedPropertyTypes.contains(type['id']);
              return Container(
                decoration: isSelected
                    ? AppTheme.getMintButtonDecoration()
                    : AppTheme.getGlassCard(),
                child: FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(type['icon'], size: 16, color: AppTheme.darkGrayBase),
                      const SizedBox(width: 4),
                      Text(
                        type['name'],
                        style: const TextStyle(color: AppTheme.darkGrayBase),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isSelected ? AppTheme.secondaryColor : Colors.grey,
                        size: 18,
                      ),
                    ],
                  ),
                  selected: isSelected,
                  backgroundColor: Colors.white,
                  selectedColor: Colors.white,
                  checkmarkColor: AppTheme.darkGrayBase,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedPropertyTypes.add(type['id']);
                      } else {
                        _selectedPropertyTypes.remove(type['id']);
                      }
                    });
                  },
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Bedrooms range
          Text(
            S.of(context).bedroomsLabel,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
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
                RangeSlider(
                  values: RangeValues(
                      _bedroomsMin.toDouble(), _bedroomsMax.toDouble()),
                  min: 1,
                  max: 6,
                  divisions: 5,
                  activeColor: AppTheme.primaryColor,
                  inactiveColor: AppTheme.primaryColor.withValues(alpha: 0.3),
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
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Amenities
          Text(
            S.of(context).amenitiesLabel,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _amenities.map((amenity) {
              final isSelected = _selectedAmenities.contains(amenity['id']);
              return Container(
                decoration: isSelected
                    ? AppTheme.getMintButtonDecoration()
                    : AppTheme.getGlassCard(),
                child: FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(amenity['icon'], size: 16, color: AppTheme.darkGrayBase),
                      const SizedBox(width: 4),
                      Text(
                        amenity['name'],
                        style: const TextStyle(color: AppTheme.darkGrayBase),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isSelected ? AppTheme.secondaryColor : Colors.grey,
                        size: 18,
                      ),
                    ],
                  ),
                  selected: isSelected,
                  backgroundColor: Colors.white,
                  selectedColor: Colors.white,
                  checkmarkColor: AppTheme.darkGrayBase,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedAmenities.add(amenity['id']);
                      } else {
                        _selectedAmenities.remove(amenity['id']);
                      }
                    });
                  },
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Switches
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      S.of(context).remoteWorkSpaceLabel,
                      style: const TextStyle(fontSize: 16, color: Colors.black),
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
                    Text(
                      S.of(context).petAllowedLabel,
                      style: const TextStyle(fontSize: 16, color: Colors.black),
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
      ),
    );
  }

  // Step 3: Cohabitation and Family
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).step3Title,
            style: const TextStyle(fontSize: 16, color: Colors.black, height: 1.5),
          ),
          const SizedBox(height: 32),

          // Roommate preference
          Text(
            S.of(context).roommatePreferenceLabel,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildRadioOption(S.of(context).noRoommateOption, 'no'),
                const SizedBox(height: 12),
                _buildRadioOption(S.of(context).openRoommateOption, 'open'),
                const SizedBox(height: 12),
                _buildRadioOption(S.of(context).yesRoommateOption, 'yes'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Family size
          Text(
            S.of(context).familySizeLabel,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          _buildCounterField(
            value: _familySize,
            onChanged: (value) {
              setState(() {
                _familySize = value;
              });
            },
            min: 1,
            max: 10,
          ),

          const SizedBox(height: 24),

          // Children count
          Text(
            S.of(context).childrenCountLabel,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          _buildCounterField(
            value: _childrenCount,
            onChanged: (value) {
              setState(() {
                _childrenCount = value;
              });
            },
            min: 0,
            max: 10,
          ),
        ],
      ),
    );
  }

  // Step 4: Lifestyle and Vibes
  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).step4Title,
            style: const TextStyle(fontSize: 16, color: Colors.black, height: 1.5),
          ),
          const SizedBox(height: 32),

          // Lifestyle tags
          Text(
            S.of(context).lifestyleLabel,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          Text(
            S.of(context).selectTagsLabel(_selectedLifestyleTags.length),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _lifestyleTags.map((tag) {
              final isSelected = _selectedLifestyleTags.contains(tag);
              return Container(
                decoration: isSelected
                    ? AppTheme.getMintButtonDecoration()
                    : AppTheme.getGlassCard(),
                child: FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tag, style: const TextStyle(color: AppTheme.darkGrayBase)),
                      const SizedBox(width: 8),
                      Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isSelected ? AppTheme.secondaryColor : Colors.grey,
                        size: 18,
                      ),
                    ],
                  ),
                  selected: isSelected,
                  backgroundColor: Colors.white,
                  selectedColor: Colors.white,
                  checkmarkColor: AppTheme.darkGrayBase,
                  onSelected: (selected) {
                    setState(() {
                      if (selected && _selectedLifestyleTags.length < 5) {
                        _selectedLifestyleTags.add(tag);
                      } else if (!selected) {
                        _selectedLifestyleTags.remove(tag);
                      }
                    });
                  },
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Smoker switch
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  S.of(context).smokerLabel,
                  style: const TextStyle(fontSize: 16, color: Colors.black),
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
          Text(
            S.of(context).languagesLabel,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _languages.map((language) {
              final isSelected = _selectedLanguages.contains(language);
              return Container(
                decoration: isSelected
                    ? AppTheme.getMintButtonDecoration()
                    : AppTheme.getGlassCard(),
                child: FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(language, style: const TextStyle(color: AppTheme.darkGrayBase)),
                      const SizedBox(width: 8),
                      Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isSelected ? AppTheme.secondaryColor : Colors.grey,
                        size: 18,
                      ),
                    ],
                  ),
                  selected: isSelected,
                  backgroundColor: Colors.white,
                  selectedColor: Colors.white,
                  checkmarkColor: AppTheme.darkGrayBase,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedLanguages.add(language);
                      } else {
                        _selectedLanguages.remove(language);
                      }
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String label, String value) {
    final isSelected = _roommatePreference == value;
    return Container(
      decoration: isSelected
          ? AppTheme.getMintButtonDecoration()
          : AppTheme.getGlassCard(),
      child: RadioListTile<String>(
        title: Text(label, style: const TextStyle(color: Colors.black)),
        value: value,
        groupValue: _roommatePreference,
        onChanged: (value) {
          setState(() {
            _roommatePreference = value!;
          });
        },
        activeColor: AppTheme.primaryColor,
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
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.darkGrayBase.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 3)),
              ],
            ),
            child: IconButton(
              onPressed: value > min ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove, color: Colors.black),
            ),
          ),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.darkGrayBase.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 3)),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppTheme.darkGrayBase.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: Container(
                decoration: AppTheme.getGlassCard(),
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: BorderSide(
                        color: AppTheme.whiteColor.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    S.of(context).previousButton,
                    style: const TextStyle(
                      color: AppTheme.whiteColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: Container(
              decoration: AppTheme.getMintButtonDecoration(),
              child: CustomButton(
                text: _currentStep == 3 ? S.of(context).finishButton : S.of(context).nextButton,
                onPressed: _isLoading ? null : _nextStep,
                backgroundColor: Colors.transparent,
                textColor: AppTheme.darkGrayBase,
                isLoading: _isLoading,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
