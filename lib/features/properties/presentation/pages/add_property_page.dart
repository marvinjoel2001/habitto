import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../../config/app_config.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/amenity.dart';
import '../../domain/entities/payment_method.dart';
import '../../data/services/property_service.dart';
import '../../../profile/data/services/profile_service.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/step_progress_indicator.dart';
import '../../../../shared/theme/app_theme.dart';

class AddPropertyPage extends StatefulWidget {
  const AddPropertyPage({super.key});

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  final PropertyService _propertyService = PropertyService();
  final ProfileService _profileService = ProfileService();

  // Controladores para los formularios
  final _propertyTypeController = TextEditingController();
  final _bedroomsController = TextEditingController(text: '3');
  final _bathroomsController = TextEditingController(text: '2');
  final _areaController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _guaranteeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sizeController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _availabilityDateController = TextEditingController();

  // Variables para el mapa
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  Uint8List? _markerImage;
  geo.Position? _currentPosition;
  bool _isMapReady = false;

  bool _isLoading = false;
  bool _isLoadingData = true;

  String _selectedPropertyType = 'casa';
  int _bedrooms = 3;
  int _bathrooms = 2;
  final List<int> _selectedAmenityIds = [];
  final List<int> _selectedPaymentMethodIds = [];

  List<Amenity> _availableAmenities = [];
  List<PaymentMethod> _availablePaymentMethods = [];
  int? _currentUserId;

  // Property type mapping from display to API values
  final Map<String, String> _propertyTypeMapping = {
    'Casa': 'casa',
    'Departamento': 'departamento',
    'Habitación': 'habitacion',
    'Anticrético': 'anticretico',
  };

  final Map<String, String> _propertyTypeDisplayMapping = {
    'casa': 'Casa',
    'departamento': 'Departamento',
    'habitacion': 'Habitación',
    'anticretico': 'Anticrético',
  };

  @override
  void initState() {
    super.initState();
    // Inicializar el token de Mapbox - usar el token directamente como en search_page.dart
    MapboxOptions.setAccessToken("pk.eyJ1IjoibWFydmluMjAwMSIsImEiOiJjbWdpaDRicTQwOTc3Mm9wcmd3OW5lNzExIn0.ISPECxmLq_6xhipoygxtFg");
    _loadInitialData();
    _getCurrentLocation();
    _loadMarkerImage();
  }

  @override
  void dispose() {
    _propertyTypeController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _areaController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _guaranteeController.dispose();
    _descriptionController.dispose();
    _sizeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _availabilityDateController.dispose();
    _pageController.dispose();
    super.dispose();
  }
  
  // Obtener la ubicación actual del usuario
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
            
        // Actualizar los controladores con la ubicación actual
        if (_currentPosition != null) {
          setState(() {
            _latitudeController.text = _currentPosition!.latitude.toString();
            _longitudeController.text = _currentPosition!.longitude.toString();
          });
        }
      }
    } catch (e) {
      // Usar ubicación por defecto si hay un error o no hay permiso
      print('Error al obtener la ubicación: $e');
    }
  }
  
  // Cargar la imagen del marcador
  Future<void> _loadMarkerImage() async {
    try {
      // Intentar cargar la imagen desde assets
      final ByteData markerBytes = await rootBundle.load('assets/images/house_pointer.png');
      _markerImage = markerBytes.buffer.asUint8List();
    } catch (e) {
      print('Error cargando imagen de marcador: $e');
      // Si falla, generar un marcador por defecto
      _markerImage = await _generateDefaultMarker();
    }
  }
  
  // Generar una imagen PNG simple para el marcador
  Future<Uint8List> _generateDefaultMarker() async {
    const double size = 64.0;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Fondo transparente
    final bgPaint = Paint()..color = const Color(0x00000000);
    canvas.drawRect(const Rect.fromLTWH(0, 0, size, size), bgPaint);

    // Círculo principal del marcador
    final circlePaint = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.95)
      ..style = ui.PaintingStyle.fill;
    const center = Offset(size / 2, size / 2);
    canvas.drawCircle(center, size * 0.36, circlePaint);

    // Borde sutil
    final borderPaint = Paint()
      ..color = AppTheme.whiteColor.withOpacity(0.8)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, size * 0.36, borderPaint);

    // Renderizar imagen y devolver PNG en bytes
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      // Load amenities, payment methods, and current user profile
      final amenitiesResponse = await _propertyService.getAmenities();
      final paymentMethodsResponse = await _propertyService.getPaymentMethods();
      final profileResponse = await _profileService.getCurrentProfile();

      if (amenitiesResponse['success']) {
        _availableAmenities = amenitiesResponse['amenities'];
      }

      if (paymentMethodsResponse['success']) {
        _availablePaymentMethods = paymentMethodsResponse['payment_methods']
            .map<PaymentMethod>((pm) => PaymentMethod.fromJson(pm))
            .toList();
      }

      if (profileResponse['success'] && profileResponse['user'] != null) {
        _currentUserId = profileResponse['user'].id;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando datos: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveProperty();
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

  Future<void> _saveProperty() async {
    if (!_validateForm()) return;

    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo obtener la información del usuario')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare property data according to API documentation
      final propertyData = {
        'owner': _currentUserId!,
        'agent': null, // Can be set if there's an agent
        'type': _selectedPropertyType, // Already in API format (casa, departamento, etc.)
        'address': _addressController.text.trim(),
        'latitude': _latitudeController.text.isNotEmpty
            ? _latitudeController.text
            : "-16.500000",
        'longitude': _longitudeController.text.isNotEmpty
            ? _longitudeController.text
            : "-68.150000",
        'price': _priceController.text,
        'guarantee': _guaranteeController.text,
        'description': _descriptionController.text.trim(),
        'size': double.parse(_areaController.text.isNotEmpty ? _areaController.text : _sizeController.text),
        'bedrooms': _bedrooms,
        'bathrooms': _bathrooms,
        'amenities': _selectedAmenityIds,
        'availability_date': _availabilityDateController.text.isNotEmpty
            ? _availabilityDateController.text
            : DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0],
        'accepted_payment_methods': _selectedPaymentMethodIds,
      };

      final response = await _propertyService.createProperty(propertyData);

      if (response['success']) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('¡Éxito!'),
            content: const Text('Propiedad registrada correctamente'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        throw Exception(response['error'] ?? 'Error al crear propiedad');
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

  bool _validateForm() {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa la dirección de la propiedad')),
      );
      return false;
    }

    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa el precio de alquiler')),
      );
      return false;
    }

    if (_guaranteeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa el monto de la garantía')),
      );
      return false;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa una descripción de la propiedad')),
      );
      return false;
    }

    if (_areaController.text.isEmpty && _sizeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa el área de la propiedad')),
      );
      return false;
    }

    // Validate numeric fields
    if (double.tryParse(_priceController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El precio debe ser un número válido')),
      );
      return false;
    }

    if (double.tryParse(_guaranteeController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La garantía debe ser un número válido')),
      );
      return false;
    }

    final areaText = _areaController.text.isNotEmpty ? _areaController.text : _sizeController.text;
    if (double.tryParse(areaText) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El área debe ser un número válido')),
      );
      return false;
    }

    return true;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.getProfileBackground(),
        child: _isLoadingData
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.9),
            AppTheme.secondaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.darkGrayBase),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  'Detalles de la Propiedad',
                  style: TextStyle(
                    color: AppTheme.darkGrayBase,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Guardar y salir
                },
                child: const Text(
                  'Guardar y salir',
                  style: TextStyle(
                    color: AppTheme.darkGrayBase,
                    fontSize: 14,
                  ),
                ),
              ),
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
        totalSteps: 3,
        stepTitles: const ['Básico', 'Detalles', 'Ubicación'],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comencemos con lo básico. Proporcione los detalles esenciales de su propiedad.',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.whiteColor.withOpacity(0.8),
              height: 1.5
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Tipo de Propiedad',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.whiteColor
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: AppTheme.getGlassCard(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPropertyType,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.whiteColor),
                      dropdownColor: AppTheme.mediumGray,
                      items: _propertyTypeMapping.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.value, // API value (casa, departamento, etc.)
                          child: Text(
                            entry.key, // Display value (Casa, Departamento, etc.)
                            style: const TextStyle(color: AppTheme.whiteColor),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedPropertyType = newValue!;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Habitaciones',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.whiteColor
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                decoration: AppTheme.getGlassCard(),
                child: IconButton(
                  onPressed: () {
                    if (_bedrooms > 1) {
                      setState(() {
                        _bedrooms--;
                        _bedroomsController.text = _bedrooms.toString();
                      });
                    }
                  },
                  icon: Icon(Icons.remove_circle_outline, color: AppTheme.whiteColor.withOpacity(0.7)),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: AppTheme.getGlassCard(),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          _bedrooms.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.whiteColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                decoration: AppTheme.getGlassCard(),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _bedrooms++;
                      _bedroomsController.text = _bedrooms.toString();
                    });
                  },
                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Baños',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.whiteColor
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                decoration: AppTheme.getGlassCard(),
                child: IconButton(
                  onPressed: () {
                    if (_bathrooms > 1) {
                      setState(() {
                        _bathrooms--;
                        _bathroomsController.text = _bathrooms.toString();
                      });
                    }
                  },
                  icon: Icon(Icons.remove_circle_outline, color: AppTheme.whiteColor.withOpacity(0.7)),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: AppTheme.getGlassCard(),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          _bathrooms.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.whiteColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                decoration: AppTheme.getGlassCard(),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _bathrooms++;
                      _bathroomsController.text = _bathrooms.toString();
                    });
                  },
                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Área (m²) *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.whiteColor,
            ),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _areaController,
            hintText: 'Ej: 120.5',
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ahora agreguemos los detalles financieros y características especiales.',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.whiteColor.withOpacity(0.8),
              height: 1.5
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Precio de Alquiler (COP) *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.whiteColor
            ),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _priceController,
            hintText: 'Ej: 2500000',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          const Text(
            'Garantía (COP)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.whiteColor
            ),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _guaranteeController,
            hintText: 'Ej: 3000000',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          const Text(
            'Descripción',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.whiteColor
            ),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _descriptionController,
            hintText: 'Describe tu propiedad...',
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          const Text(
            'Comodidades',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.whiteColor
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableAmenities.map((amenity) {
              final isSelected = _selectedAmenityIds.contains(amenity.id);
              return Container(
                decoration: isSelected
                  ? AppTheme.getMintButtonDecoration()
                  : AppTheme.getGlassCard(),
                child: FilterChip(
                  label: Text(
                    amenity.name,
                    style: TextStyle(
                      color: isSelected ? AppTheme.darkGrayBase : AppTheme.whiteColor,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  backgroundColor: Colors.transparent,
                  selectedColor: Colors.transparent,
                  checkmarkColor: AppTheme.darkGrayBase,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedAmenityIds.add(amenity.id);
                      } else {
                        _selectedAmenityIds.remove(amenity.id);
                      }
                    });
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Métodos de Pago Aceptados',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.whiteColor
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availablePaymentMethods.map((method) {
              final isSelected = _selectedPaymentMethodIds.contains(method.id);
              return Container(
                decoration: isSelected
                  ? AppTheme.getMintButtonDecoration()
                  : AppTheme.getGlassCard(),
                child: FilterChip(
                  label: Text(
                    method.name,
                    style: TextStyle(
                      color: isSelected ? AppTheme.darkGrayBase : AppTheme.whiteColor,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  backgroundColor: Colors.transparent,
                  selectedColor: Colors.transparent,
                  checkmarkColor: AppTheme.darkGrayBase,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedPaymentMethodIds.add(method.id);
                      } else {
                        _selectedPaymentMethodIds.remove(method.id);
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

  // Método para manejar la creación del mapa
  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    
    // Habilitar el punto azul de la ubicación del usuario
    _mapboxMap!.location.updateSettings(LocationComponentSettings(enabled: true));

    // Crear el gestor de marcadores
    _pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    
    setState(() {
      _isMapReady = true;
    });
    
    // Crear el marcador en la ubicación seleccionada o actual
    _updatePropertyMarker();
  }
  
  // Actualizar o crear el marcador de la propiedad
  void _updatePropertyMarker() async {
    if (_pointAnnotationManager == null || _markerImage == null) return;
    
    // Limpiar marcadores anteriores
    await _pointAnnotationManager!.deleteAll();
    
    // Obtener las coordenadas (usar las del formulario o la ubicación actual)
    double lat = 0.0;
    double lng = 0.0;
    
    try {
      lat = double.parse(_latitudeController.text);
      lng = double.parse(_longitudeController.text);
    } catch (e) {
      // Si no hay coordenadas válidas en los campos, usar la ubicación actual
      if (_currentPosition != null) {
        lat = _currentPosition!.latitude;
        lng = _currentPosition!.longitude;
        
        // Actualizar los campos del formulario
        _latitudeController.text = lat.toString();
        _longitudeController.text = lng.toString();
      } else {
        // Ubicación por defecto (La Paz, Bolivia)
        lat = -16.5000;
        lng = -68.1500;
      }
    }
    
    // Crear el marcador usando una lista de opciones y createMulti como en search_page.dart
    final options = <PointAnnotationOptions>[
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(lng, lat)),
        image: _markerImage!,
        iconSize: 0.5,
      )
    ];
    
    // Crear todos los marcadores en una sola operación (más eficiente)
    await _pointAnnotationManager!.createMulti(options);
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ubicación y disponibilidad de la propiedad',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.whiteColor.withOpacity(0.8),
              height: 1.5
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Dirección *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.whiteColor
            ),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _addressController,
            hintText: 'Ej: Calle Principal 123, Zona Sur, La Paz',
          ),
          const SizedBox(height: 24),
          
          // Mapa para seleccionar ubicación
          const Text(
            'Ubicación en el mapa',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.whiteColor
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.whiteColor.withOpacity(0.2)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Mapa
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
                      pitch: 45,
                      bearing: 0,
                    ),
                    onTapListener: (gestureContext) {
                      // Actualizar las coordenadas al tocar el mapa
                      // El gestureContext ya contiene las coordenadas geográficas proyectadas
                      final coordinates = gestureContext.point.coordinates;
                      setState(() {
                        // Acceder a las coordenadas correctamente desde Position
                        // coordinates.latitude es la latitud, coordinates.longitude es la longitud
                         _longitudeController.text = coordinates.lng.toString();
                        _latitudeController.text = coordinates.lat.toString();
                      });
                      _updatePropertyMarker();
                    },
                  ),
                  
                  // Botón para centrar en la ubicación actual
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.darkGrayBase.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.my_location, color: AppTheme.whiteColor),
                        onPressed: () {
                          if (_currentPosition != null && _mapboxMap != null) {
                            // Centrar el mapa en la ubicación actual
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
                            
                            // Actualizar los campos del formulario
                            setState(() {
                              _latitudeController.text = _currentPosition!.latitude.toString();
                              _longitudeController.text = _currentPosition!.longitude.toString();
                            });
                            
                            // Actualizar el marcador
                            _updatePropertyMarker();
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
          
          // Campos de latitud y longitud (ahora se actualizan automáticamente)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Latitud',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.whiteColor
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _latitudeController,
                      hintText: 'Ej: -16.5000',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Longitud',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.whiteColor
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _longitudeController,
                      hintText: 'Ej: -68.1500',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          const Text(
            'Fecha de Disponibilidad',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.whiteColor
            ),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _availabilityDateController,
            hintText: 'YYYY-MM-DD (opcional)',
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppTheme.primaryColor,
                        onPrimary: AppTheme.darkGrayBase,
                        surface: AppTheme.mediumGray,
                        onSurface: AppTheme.whiteColor,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                _availabilityDateController.text = date.toIso8601String().split('T')[0];
              }
            },
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
            AppTheme.darkGrayBase.withOpacity(0.3),
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
                    side: BorderSide(color: AppTheme.whiteColor.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Anterior',
                    style: TextStyle(
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
            flex: _currentStep == 0 ? 1 : 1,
            child: Container(
              decoration: AppTheme.getMintButtonDecoration(),
              child: CustomButton(
                text: _currentStep == 2 ? 'Finalizar' : 'Siguiente',
                onPressed: _isLoading ? null : _nextStep,
                backgroundColor: Colors.transparent,
                textColor: AppTheme.darkGrayBase,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
