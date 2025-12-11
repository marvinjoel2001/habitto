import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../domain/entities/amenity.dart';
import '../../domain/entities/payment_method.dart';
import '../../data/services/property_service.dart';
import '../../../profile/data/services/profile_service.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/step_progress_indicator.dart';
import '../../../../shared/theme/app_theme.dart';
import 'edit_property_page.dart';

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
  final List<String> _selectedAmenityNames = [];
  final List<int> _selectedPaymentMethodIds = [];

  // Valores numéricos para sliders de precio y garantía
  double _priceValue = 0;
  double _guaranteeValue = 0;

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

  IconData _iconForAmenityName(String name) {
    final key = name.toLowerCase();
    if (key.contains('wifi')) return Icons.wifi;
    if (key.contains('estacion')) return Icons.local_parking;
    if (key.contains('lavander')) return Icons.local_laundry_service;
    if (key.contains('gym') || key.contains('gimnas')) {
      return Icons.fitness_center;
    }
    if (key.contains('piscina') || key.contains('pool')) return Icons.pool;
    if (key.contains('jard') || key.contains('garden')) return Icons.park;
    return Icons.check_circle_outline;
  }

  // Amenidades canónicas iguales a CreateSearchProfilePage
  final List<Map<String, dynamic>> _canonicalAmenities = const [
    {'id': 'wifi', 'name': 'WiFi', 'icon': Icons.wifi},
    {'id': 'parking', 'name': 'Estacionamiento', 'icon': Icons.local_parking},
    {
      'id': 'laundry',
      'name': 'Lavandería',
      'icon': Icons.local_laundry_service
    },
    {'id': 'gym', 'name': 'Gimnasio', 'icon': Icons.fitness_center},
    {'id': 'pool', 'name': 'Piscina', 'icon': Icons.pool},
    {'id': 'garden', 'name': 'Jardín', 'icon': Icons.park},
  ];

  @override
  void initState() {
    super.initState();
    // Inicializar el token de Mapbox - usar el token directamente como en search_page.dart
    MapboxOptions.setAccessToken(
        "pk.eyJ1IjoibWFydmluMjAwMSIsImEiOiJjbWdpaDRicTQwOTc3Mm9wcmd3OW5lNzExIn0.ISPECxmLq_6xhipoygxtFg");
    _loadInitialData();
    _getCurrentLocation();
    _loadMarkerImage();
    _priceController.text = '0';
    _guaranteeController.text = '0';
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
      geo.LocationPermission permission =
          await geo.Geolocator.checkPermission();
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
            _latitudeController.text =
                _currentPosition!.latitude.toStringAsFixed(6);
            _longitudeController.text =
                _currentPosition!.longitude.toStringAsFixed(6);
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
      final ByteData markerBytes =
          await rootBundle.load('assets/images/house_pointer.png');
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
      print('AddPropertyPage: Iniciando carga de datos iniciales');

      // Load amenities, payment methods, and current user profile
      final amenitiesResponse = await _propertyService.getAmenities();
      final paymentMethodsResponse = await _propertyService.getPaymentMethods();
      final profileResponse = await _profileService.getCurrentProfile();

      print(
          'AddPropertyPage: Respuesta de amenities: ${amenitiesResponse['success']}');
      print(
          'AddPropertyPage: Respuesta de payment methods: ${paymentMethodsResponse['success']}');
      print(
          'AddPropertyPage: Respuesta de profile: ${profileResponse['success']}');

      if (amenitiesResponse['success']) {
        _availableAmenities = amenitiesResponse['data'];
        print(
            'AddPropertyPage: ${_availableAmenities.length} amenities cargadas');
      }

      if (paymentMethodsResponse['success']) {
        print(
            'AddPropertyPage: Datos de payment methods: ${paymentMethodsResponse['payment_methods']}');
        _availablePaymentMethods =
            (paymentMethodsResponse['payment_methods'] as List)
                .map<PaymentMethod>((pm) => PaymentMethod.fromJson(pm))
                .toList();
        print(
            'AddPropertyPage: ${_availablePaymentMethods.length} payment methods cargados');
      }

      if (profileResponse['success'] == true &&
          profileResponse['data'] != null) {
        final user = profileResponse['data']['user'];
        if (user != null) {
          _currentUserId = user.id;
          print('AddPropertyPage: Usuario actual ID: $_currentUserId');
        }
      }
    } catch (e) {
      print('AddPropertyPage: Error cargando datos: $e');
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
        const SnackBar(
            content:
                Text('Error: No se pudo obtener la información del usuario')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare property data according to API documentation
      final propertyData = <String, dynamic>{
        'type': _selectedPropertyType,
        'address': _addressController.text.trim(),
        'latitude': _latitudeController.text.isNotEmpty
            ? double.parse(_latitudeController.text).toStringAsFixed(6)
            : "-16.500000",
        'longitude': _longitudeController.text.isNotEmpty
            ? double.parse(_longitudeController.text).toStringAsFixed(6)
            : "-68.150000",
        'price': _priceController.text,
        'guarantee': _guaranteeController.text,
        'description': _descriptionController.text.trim(),
        'size': double.parse(_areaController.text.isNotEmpty
            ? _areaController.text
            : _sizeController.text),
        'bedrooms': _bedrooms,
        'bathrooms': _bathrooms,
        'amenities': _selectedAmenityNames,
        'availability_date': _availabilityDateController.text.isNotEmpty
            ? _availabilityDateController.text
            : DateTime.now()
                .add(const Duration(days: 1))
                .toIso8601String()
                .split('T')[0],
      };

      // Métodos de pago son opcionales: si no hay selección, no enviar la llave
      if (_selectedPaymentMethodIds.isNotEmpty) {
        propertyData['accepted_payment_methods'] = _selectedPaymentMethodIds;
      }

      final response = await _propertyService.createProperty(propertyData);

      if (response['success']) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('¡Propiedad creada!'),
            content: const Text(
                'Tu propiedad ha sido creada exitosamente. ¿Quieres agregar fotos ahora?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cerrar diálogo
                  Navigator.of(context).pop(); // Volver a la página anterior
                },
                child: const Text('Más tarde'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cerrar diálogo
                  // Navegar a la página de fotos (EditPropertyPage inicia en fotos)
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditPropertyPage(
                        property: response['data'],
                      ),
                    ),
                  );
                },
                child: const Text('Agregar fotos'),
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
        const SnackBar(
            content: Text('Por favor ingresa la dirección de la propiedad')),
      );
      return false;
    }

    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor ingresa el precio de alquiler')),
      );
      return false;
    }

    if (_guaranteeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor ingresa el monto de la garantía')),
      );
      return false;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor ingresa una descripción de la propiedad')),
      );
      return false;
    }

    if (_areaController.text.isEmpty && _sizeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor ingresa el área de la propiedad')),
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

    final areaText = _areaController.text.isNotEmpty
        ? _areaController.text
        : _sizeController.text;
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
              const Expanded(
                child: Text(
                  'Detalles de la Propiedad',
                  style: TextStyle(
                    color: Colors.black,
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
                    color: Colors.black,
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
          const Text(
            'Comencemos con lo básico. Proporcione los detalles esenciales de su propiedad.',
            style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
          ),
          const SizedBox(height: 32),
          _buildPropertyTypeDropdown(),
          const SizedBox(height: 24),
          const Text(
            'Habitaciones',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
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
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.black54),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: AppTheme.darkGrayBase.withOpacity(0.3),
                        width: 1),
                    gradient: AppTheme.getCardGradient(),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          _bedrooms.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
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
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppTheme.primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Baños',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
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
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.black54),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: AppTheme.darkGrayBase.withOpacity(0.3),
                        width: 1),
                    gradient: AppTheme.getCardGradient(),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          _bathrooms.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
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
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppTheme.primaryColor),
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
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildProfileStyledField(
            controller: _areaController,
            hintText: 'Ej: 120.5',
            icon: Icons.square_foot,
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
          const Text(
            'Ahora agreguemos los detalles financieros y características especiales.',
            style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
          ),
          const SizedBox(height: 32),
          const Text(
            'Precio de Alquiler (COP) *',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: AppTheme.getGlassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.attach_money, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text('Ajusta el precio',
                            style: TextStyle(color: Colors.black87)),
                      ],
                    ),
                    Text('COP ${_priceValue.round()}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.black)),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _priceValue,
                  min: 0,
                  max: 500,
                  divisions: 500,
                  label: _priceValue.round().toString(),
                  activeColor: AppTheme.primaryColor,
                  onChanged: (v) {
                    setState(() {
                      _priceValue = v;
                      _priceController.text = _priceValue.round().toString();
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Garantía (COP)',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: AppTheme.getGlassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lock_outline, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text('Ajusta la garantía',
                            style: TextStyle(color: Colors.black87)),
                      ],
                    ),
                    Text('COP ${_guaranteeValue.round()}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.black)),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _guaranteeValue,
                  min: 0,
                  max: 500,
                  divisions: 500,
                  label: _guaranteeValue.round().toString(),
                  activeColor: AppTheme.secondaryColor,
                  onChanged: (v) {
                    setState(() {
                      _guaranteeValue = v;
                      _guaranteeController.text =
                          _guaranteeValue.round().toString();
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Descripción',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          _buildProfileStyledField(
            controller: _descriptionController,
            hintText: 'Describe tu propiedad...',
            icon: Icons.description,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          const Text(
            'Comodidades',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _canonicalAmenities.map((amenity) {
              final String name = amenity['name'] as String;
              final bool isSelected = _selectedAmenityNames.contains(name);
              return Container(
                decoration: isSelected
                    ? AppTheme.getMintButtonDecoration()
                    : AppTheme.getGlassCard(),
                child: FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(amenity['icon'] as IconData,
                          size: 16, color: AppTheme.darkGrayBase),
                      const SizedBox(width: 6),
                      Text(
                        name,
                        style: const TextStyle(color: AppTheme.darkGrayBase),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color:
                            isSelected ? AppTheme.secondaryColor : Colors.grey,
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
                        _selectedAmenityNames.add(name);
                      } else {
                        _selectedAmenityNames.remove(name);
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
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
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
                      color: isSelected ? AppTheme.darkGrayBase : Colors.black,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
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
    _mapboxMap!.location
        .updateSettings(LocationComponentSettings(enabled: true));

    // Crear el gestor de marcadores
    _pointAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();

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
        _latitudeController.text = lat.toStringAsFixed(6);
        _longitudeController.text = lng.toStringAsFixed(6);
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

  void _openFullScreenMap() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (ctx) {
        double tempLat;
        double tempLng;
        try {
          tempLat = double.parse(_latitudeController.text);
          tempLng = double.parse(_longitudeController.text);
        } catch (_) {
          tempLat = _currentPosition?.latitude ?? -16.5000;
          tempLng = _currentPosition?.longitude ?? -68.1500;
        }

        PointAnnotationManager? sheetAnnotationManager;
        MapboxMap? sheetMap;

        Future<void> drawMarker(double lat, double lng) async {
          if (sheetAnnotationManager == null || _markerImage == null) return;
          await sheetAnnotationManager!.deleteAll();
          await sheetAnnotationManager!.create(PointAnnotationOptions(
            geometry: Point(coordinates: Position(lng, lat)),
            image: _markerImage!,
            iconSize: 0.6,
          ));
        }

        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Stack(
                  children: [
                    MapWidget(
                      onMapCreated: (m) async {
                        sheetMap = m;
                        await m.location.updateSettings(
                            LocationComponentSettings(enabled: true));
                        sheetAnnotationManager =
                            await m.annotations.createPointAnnotationManager();
                        await m.flyTo(
                          CameraOptions(
                            center:
                                Point(coordinates: Position(tempLng, tempLat)),
                            zoom: 15,
                          ),
                          MapAnimationOptions(duration: 800),
                        );
                        await drawMarker(tempLat, tempLng);
                      },
                      styleUri: MapboxStyles.OUTDOORS,
                      cameraOptions: CameraOptions(
                        center: Point(
                          coordinates: Position(
                            tempLng,
                            tempLat,
                          ),
                        ),
                        zoom: 15,
                      ),
                      onTapListener: (gestureContext) async {
                        final c = gestureContext.point.coordinates;
                        tempLat = c.lat.toDouble();
                        tempLng = c.lng.toDouble();
                        await drawMarker(tempLat, tempLng);
                        setSheetState(() {});
                      },
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        decoration: AppTheme.getGlassCard(),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.black),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 24,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: AppTheme.getMintButtonDecoration(),
                              child: CustomButton(
                                text: 'Confirmar ubicación',
                                backgroundColor: Colors.transparent,
                                textColor: AppTheme.darkGrayBase,
                                onPressed: () {
                                  _latitudeController.text =
                                      tempLat.toStringAsFixed(6);
                                  _longitudeController.text =
                                      tempLng.toStringAsFixed(6);
                                  _updatePropertyMarker();
                                  Navigator.pop(ctx);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 80,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: AppTheme.getGlassCard(),
                        child: Text(
                          'Lat: ${tempLat.toStringAsFixed(6)}   Lng: ${tempLng.toStringAsFixed(6)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ubicación y disponibilidad de la propiedad',
            style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
          ),
          const SizedBox(height: 32),
          const Text(
            'Dirección *',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          _buildProfileStyledField(
            controller: _addressController,
            hintText: 'Ej: Calle Principal 123, Zona Sur, La Paz',
            icon: Icons.location_on,
          ),
          const SizedBox(height: 24),

          // Mapa para seleccionar ubicación
          const Text(
            'Ubicación en el mapa',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _openFullScreenMap,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
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
                        pitch: 45,
                        bearing: 0,
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.05),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.open_in_full,
                                  color: AppTheme.primaryColor),
                              SizedBox(width: 8),
                              Text(
                                  'Toca para seleccionar ubicación en pantalla completa'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Las coordenadas se manejan internamente; no se muestran los campos de lat/long

          const SizedBox(height: 24),
          const Text(
            'Fecha de Disponibilidad',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          _buildProfileStyledField(
            controller: _availabilityDateController,
            hintText: 'YYYY-MM-DD (opcional)',
            icon: Icons.calendar_today,
            readOnly: true,
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
                _availabilityDateController.text =
                    date.toIso8601String().split('T')[0];
              }
            },
          ),
        ],
      ),
    );
  }

  // Campos estilo EditProfile
  Widget _buildProfileStyledField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    VoidCallback? onTap,
    bool readOnly = false,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: AppTheme.darkGrayBase),
        decoration: InputDecoration(
          hintText: hintText,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          labelStyle: const TextStyle(color: AppTheme.darkGrayBase),
          prefixIcon: Icon(icon, color: AppTheme.primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPropertyTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedPropertyType,
        decoration: InputDecoration(
          hintText: 'Tipo de propiedad',
          floatingLabelBehavior: FloatingLabelBehavior.never,
          labelStyle: const TextStyle(color: AppTheme.darkGrayBase),
          prefixIcon: const Icon(Icons.home_work, color: AppTheme.primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dropdownColor: Colors.white,
        style: const TextStyle(color: AppTheme.darkGrayBase),
        items: _propertyTypeMapping.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.value,
            child: Text(entry.key,
                style: const TextStyle(color: AppTheme.darkGrayBase)),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedPropertyType = value;
            });
          }
        },
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
                    side:
                        BorderSide(color: AppTheme.whiteColor.withOpacity(0.3)),
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
