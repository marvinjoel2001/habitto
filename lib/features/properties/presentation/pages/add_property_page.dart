import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../domain/entities/amenity.dart';
import '../../domain/entities/payment_method.dart';
import '../../data/services/property_service.dart';
import '../../../profile/data/services/profile_service.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_choice_chip.dart';
import '../../../../shared/widgets/step_progress_indicator.dart';
import '../../../../shared/theme/app_theme.dart';
import 'edit_property_page.dart';
import 'payment_methods_page.dart';
import '../../../../../generated/l10n.dart';

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

  final FocusNode _descriptionFocusNode = FocusNode();
  bool _hasWarnedDescription = false;
  bool _hasWarnedAmenities = false;

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

  Map<String, String> get _propertyTypeDisplayMapping => {
        'casa': S.of(context).propertyTypeHouse,
        'departamento': S.of(context).propertyTypeApartment,
        'habitacion': S.of(context).propertyTypeRoom,
        'anticretico': S.of(context).propertyTypeAnticretico,
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
  List<Map<String, dynamic>> get _canonicalAmenities => [
        {'id': 'wifi', 'name': S.of(context).amenityWifi, 'icon': Icons.wifi},
        {
          'id': 'parking',
          'name': S.of(context).amenityParking,
          'icon': Icons.local_parking
        },
        {
          'id': 'laundry',
          'name': S.of(context).amenityLaundry,
          'icon': Icons.local_laundry_service
        },
        {
          'id': 'gym',
          'name': S.of(context).amenityGym,
          'icon': Icons.fitness_center
        },
        {'id': 'pool', 'name': S.of(context).amenityPool, 'icon': Icons.pool},
        {
          'id': 'garden',
          'name': S.of(context).amenityGarden,
          'icon': Icons.park
        },
      ];

  // Scroll controller to detect scroll position for transparency
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

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

    // Listener para el scroll
    _scrollController.addListener(() {
      if (_scrollController.offset > 10 && !_isScrolled) {
        setState(() {
          _isScrolled = true;
        });
      } else if (_scrollController.offset <= 10 && _isScrolled) {
        setState(() {
          _isScrolled = false;
        });
      }
    });
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
    _descriptionFocusNode.dispose();
    _pageController.dispose();
    _scrollController.dispose();
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
      ..color = AppTheme.accentMint.withValues(alpha: 0.95)
      ..style = ui.PaintingStyle.fill;
    const center = Offset(size / 2, size / 2);
    canvas.drawCircle(center, size * 0.36, circlePaint);

    // Borde sutil
    final borderPaint = Paint()
      ..color = AppTheme.whiteColor.withValues(alpha: 0.8)
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
        SnackBar(content: Text(S.of(context).loadDataError(e.toString()))),
      );
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_validateStep1()) return;
    } else if (_currentStep == 1) {
      if (!_validateStep2()) return;
    }

    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      // Reset scroll for next step
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
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
      // Reset scroll for previous step
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
  }

  // Validación suave con foco para Paso 1
  bool _validateStep1() {
    // Área es importante pero técnicamente opcional en la API (aunque aquí se valida)
    // Si está vacío, hacemos foco y mostramos snackbar
    if (_areaController.text.isEmpty && _sizeController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).enterAreaError)),
      );
      // No hay un FocusNode explícito en _buildProfileStyledField, pero podríamos
      // implementarlo si fuera crítico. Por ahora, el mensaje es suficiente
      // o podríamos permitir avanzar si el usuario insiste (segundo clic)
      // Para este requerimiento, bloquearemos si falta algo "esencial"
      return false; 
    }
    return true;
  }

  // Validación suave con foco para Paso 2
  bool _validateStep2() {
    // 1. Validar precio (bloqueante)
    if (_priceController.text.isEmpty || _priceController.text == '0') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).enterPriceError)),
      );
      return false;
    }

    // 2. Validar Descripción (Suave - Una vez)
    if (_descriptionController.text.trim().isEmpty) {
      if (!_hasWarnedDescription) {
        _descriptionFocusNode.requestFocus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Te recomendamos poner una descripción para una mejor notoriedad de la propiedad'),
            duration: Duration(seconds: 4),
          ),
        );
        setState(() {
          _hasWarnedDescription = true;
        });
        return false; // Detener para que el usuario llene o decida continuar
      }
      // Si ya se advirtió, dejamos pasar
    }

    // 3. Validar Comodidades (Suave - Una vez)
    if (_selectedAmenityNames.isEmpty) {
      if (!_hasWarnedAmenities) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Te recomendamos seleccionar algunas comodidades'),
            duration: Duration(seconds: 4),
          ),
        );
        setState(() {
          _hasWarnedAmenities = true;
        });
        // Intentar scroll hacia comodidades podría ser complejo sin un key específico,
        // pero el mensaje ya alerta.
        return false; // Detener para que el usuario seleccione o decida continuar
      }
      // Si ya se advirtió, dejamos pasar
    }

    return true;
  }

  Future<void> _reloadPaymentMethods() async {
    try {
      final paymentMethodsResponse = await _propertyService.getPaymentMethods();
      if (paymentMethodsResponse['success']) {
        setState(() {
          _availablePaymentMethods =
              (paymentMethodsResponse['payment_methods'] as List)
                  .map<PaymentMethod>((pm) => PaymentMethod.fromJson(pm))
                  .toList();
        });
      }
    } catch (e) {
      print('Error recargando métodos de pago: $e');
    }
  }

  Future<void> _saveProperty() async {
    if (!_validateForm()) return;

    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).userFetchError)),
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
            title: Text(S.of(context).propertyCreatedTitle),
            content: Text(S.of(context).propertyCreatedMessage),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cerrar diálogo
                  Navigator.of(context).pop(); // Volver a la página anterior
                },
                child: Text(S.of(context).laterButton),
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
                child: Text(S.of(context).addPhotosButton),
              ),
            ],
          ),
        );
      } else {
        throw Exception(response['error'] ?? 'Error al crear propiedad');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).genericError(e.toString()))),
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
        SnackBar(content: Text(S.of(context).enterAddressError)),
      );
      return false;
    }

    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).enterPriceError)),
      );
      return false;
    }

    if (_guaranteeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).enterGuaranteeError)),
      );
      return false;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).enterDescriptionError)),
      );
      return false;
    }

    if (_areaController.text.isEmpty && _sizeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).enterAreaError)),
      );
      return false;
    }

    // Validate numeric fields
    if (double.tryParse(_priceController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).invalidPriceError)),
      );
      return false;
    }

    if (double.tryParse(_guaranteeController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).invalidGuaranteeError)),
      );
      return false;
    }

    final areaText = _areaController.text.isNotEmpty
        ? _areaController.text
        : _sizeController.text;
    if (double.tryParse(areaText) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).invalidAreaError)),
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
            : Stack(
                children: [
                  Column(
                    children: [
                      _buildHeader(),
                      // Eliminamos el SizedBox fijo y usamos padding en el contenido
                      // para que el scroll fluya detrás del indicador
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
                  Positioned(
                    top: 80 + MediaQuery.of(context).padding.top,
                    left: 0,
                    right: 0,
                    child: _buildStepIndicator(),
                  ),
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
                  S.of(context).propertyDetailsTitle,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // Espacio para equilibrar el botón de retroceso
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      color: _isScrolled
          ? Colors.white.withOpacity(0.6) // Fondo semitransparente
          : Colors.white, // Fondo sólido
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isScrolled ? 0.6 : 1.0, // Opacidad también al contenido
        child: StepProgressIndicator(
          currentStep: _currentStep,
          totalSteps: 3,
          stepTitles: [
            S.of(context).stepBasic,
            S.of(context).stepDetails,
            S.of(context).stepLocation
          ],
        ),
      ),
    );
  }

  // Funciones auxiliares para sliders no lineales
  // Convierte valor real (precio) a posición del slider (0.0 - 1.0)
  double _priceToSliderValue(double price) {
    if (price <= 10000) {
      // De 0 a 10,000 mapea a 0.0 - 0.5 del slider
      return (price / 10000) * 0.5;
    } else {
      // De 10,000 a 100,000 mapea a 0.5 - 1.0 del slider
      // Normalizamos el rango restante (90,000) al 0.5 restante del slider
      return 0.5 + ((price - 10000) / 90000) * 0.5;
    }
  }

  // Convierte posición del slider (0.0 - 1.0) a valor real (precio)
  double _sliderValueToPrice(double value) {
    if (value <= 0.5) {
      // Mapear 0.0 - 0.5 a 0 - 10,000 (pasos de 50)
      double rawPrice = (value / 0.5) * 10000;
      return (rawPrice / 50).round() * 50.0;
    } else {
      // Mapear 0.5 - 1.0 a 10,000 - 100,000 (pasos de 1,000)
      double normalizedValue = (value - 0.5) / 0.5;
      double rawPrice = 10000 + (normalizedValue * 90000);
      return (rawPrice / 1000).round() * 1000.0;
    }
  }

  void _showEditPriceDialog(
      String title, TextEditingController controller, Function(double) onSave) {
    final tempController = TextEditingController(text: controller.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: tempController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: 'Bs ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context).cancelButton),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(tempController.text);
              if (val != null) {
                onSave(val);
                Navigator.pop(context);
              }
            },
            child: Text(S.of(context).saveChangesButton),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      controller: _scrollController,
      // Padding superior ajustado para dejar espacio al indicador flotante
      padding: const EdgeInsets.only(top: 100, left: 24, right: 24, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).stepBasicDescription,
            style: const TextStyle(
                fontSize: 16, color: Colors.black87, height: 1.5),
          ),
          const SizedBox(height: 32),
          _buildPropertyTypeDropdown(),
          const SizedBox(height: 24),
          Text(
            S.of(context).bedroomsLabel,
            style: const TextStyle(
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
                        color: AppTheme.darkGrayBase.withValues(alpha: 0.3),
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
          Text(
            S.of(context).bathroomsLabel,
            style: const TextStyle(
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
                        color: AppTheme.darkGrayBase.withValues(alpha: 0.3),
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
          Text(
            S.of(context).areaLabel,
            style: const TextStyle(
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
      controller: _scrollController,
      // Padding superior ajustado para dejar espacio al indicador flotante
      padding: const EdgeInsets.only(top: 100, left: 24, right: 24, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).stepDetailsDescription,
            style: const TextStyle(
                fontSize: 16, color: Colors.black87, height: 1.5),
          ),
          const SizedBox(height: 32),
          Text(
            S.of(context).rentPriceLabel,
            style: const TextStyle(
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
                    Row(
                      children: [
                        const Icon(Icons.attach_money,
                            color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(S.of(context).adjustPriceLabel,
                            style: const TextStyle(color: Colors.black87)),
                      ],
                    ),
                    Row(
                      children: [
                        Text('BS ${_priceValue.round()}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, color: Colors.black)),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18, color: AppTheme.primaryColor),
                          onPressed: () {
                            _showEditPriceDialog(
                              S.of(context).rentPriceLabel,
                              _priceController,
                              (val) {
                                setState(() {
                                  _priceValue = val;
                                  _priceController.text = val.round().toString();
                                });
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _priceToSliderValue(_priceValue),
                  min: 0.0,
                  max: 1.0,
                  divisions: 100, // divisiones aproximadas
                  label: _priceValue.round().toString(),
                  activeColor: AppTheme.primaryColor,
                  onChanged: (v) {
                    setState(() {
                      _priceValue = _sliderValueToPrice(v);
                      _priceController.text = _priceValue.round().toString();
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            S.of(context).guaranteeLabel,
            style: const TextStyle(
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
                    Row(
                      children: [
                        const Icon(Icons.lock_outline,
                            color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(S.of(context).adjustGuaranteeLabel,
                            style: const TextStyle(color: Colors.black87)),
                      ],
                    ),
                    Row(
                      children: [
                        Text('BS ${_guaranteeValue.round()}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, color: Colors.black)),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18, color: AppTheme.primaryColor),
                          onPressed: () {
                            _showEditPriceDialog(
                              S.of(context).guaranteeLabel,
                              _guaranteeController,
                              (val) {
                                setState(() {
                                  _guaranteeValue = val;
                                  _guaranteeController.text = val.round().toString();
                                });
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _priceToSliderValue(_guaranteeValue),
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  label: _guaranteeValue.round().toString(),
                  activeColor: AppTheme.secondaryColor,
                  onChanged: (v) {
                    setState(() {
                      _guaranteeValue = _sliderValueToPrice(v);
                      _guaranteeController.text =
                          _guaranteeValue.round().toString();
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            S.of(context).descriptionLabel,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          _buildProfileStyledField(
            controller: _descriptionController,
            hintText: S.of(context).propertyDescriptionHint,
            icon: Icons.description,
            maxLines: 3,
            focusNode: _descriptionFocusNode, // Asignar FocusNode
          ),
          const SizedBox(height: 24),
          Text(
            S.of(context).amenitiesLabel,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _canonicalAmenities.map((amenity) {
              final String name = amenity['name'] as String;
              final bool isSelected = _selectedAmenityNames.contains(name);
              return CustomChoiceChip(
                label: name,
                icon: amenity['icon'] as IconData,
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedAmenityNames.add(name);
                    } else {
                      _selectedAmenityNames.remove(name);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            S.of(context).acceptedPaymentMethodsLabel,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          if (_availablePaymentMethods.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.credit_card_off,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'No tienes métodos de pago configurados o creados',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PaymentMethodsPage(),
                        ),
                      ).then((_) => _reloadPaymentMethods());
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Crear un método de pago'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availablePaymentMethods.map((method) {
                final isSelected =
                    _selectedPaymentMethodIds.contains(method.id);
                return CustomChoiceChip(
                  label: method.name,
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedPaymentMethodIds.add(method.id);
                      } else {
                        _selectedPaymentMethodIds.remove(method.id);
                      }
                    });
                  },
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
        iconSize: 0.35,
      )
    ];

    // Crear todos los marcadores en una sola operación (más eficiente)
    await _pointAnnotationManager!.createMulti(options);
  }

  // Actualizar dirección basada en coordenadas (Reverse Geocoding)
  Future<void> _updateAddressFromCoordinates(double lat, double lng) async {
    try {
      List<geocoding.Placemark> placemarks =
          await geocoding.placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        geocoding.Placemark place = placemarks[0];
        // Construir dirección: Calle + Número (o Calle sola)
        String street = place.thoroughfare ?? '';
        String number = place.subThoroughfare ?? '';
        String locality = place.locality ?? '';
        
        String fullAddress = street;
        if (number.isNotEmpty) fullAddress += ' $number';
        if (locality.isNotEmpty) fullAddress += ', $locality';
        
        if (fullAddress.trim().isEmpty) {
           fullAddress = place.street ?? '';
        }

        setState(() {
          _addressController.text = fullAddress;
        });
      }
    } catch (e) {
      print('Error en reverse geocoding: $e');
    }
  }

  // Actualizar coordenadas basadas en dirección (Forward Geocoding)
  Future<void> _updateCoordinatesFromAddress(String address) async {
    if (address.trim().isEmpty) return;
    
    try {
      List<geocoding.Location> locations =
          await geocoding.locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        geocoding.Location loc = locations[0];
        setState(() {
          _latitudeController.text = loc.latitude.toStringAsFixed(6);
          _longitudeController.text = loc.longitude.toStringAsFixed(6);
        });
        
        _updatePropertyMarker();
        
        // Mover la cámara del mapa inline si está listo
        if (_mapboxMap != null) {
          _mapboxMap!.flyTo(
            CameraOptions(
              center: Point(coordinates: Position(loc.longitude, loc.latitude)),
              zoom: 15,
            ),
            MapAnimationOptions(duration: 800),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró la dirección')),
      );
    }
  }

  void _openFullScreenMap() {
    // Usar valores iniciales de los controladores, o la ubicación actual si están vacíos
    double initialLat;
    double initialLng;
    try {
      initialLat = double.parse(_latitudeController.text);
      initialLng = double.parse(_longitudeController.text);
    } catch (_) {
      initialLat = _currentPosition?.latitude ?? -16.5000;
      initialLng = _currentPosition?.longitude ?? -68.1500;
    }

    // Variables de estado local para el modal
    // Se inicializan fuera del builder para mantener el estado
    double tempLat = initialLat;
    double tempLng = initialLng;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.black,
      builder: (ctx) {
        PointAnnotationManager? sheetAnnotationManager;
        MapboxMap? sheetMap;

        // Función auxiliar para dibujar marcador en el mapa del modal
        Future<void> drawMarker(double lat, double lng) async {
          if (sheetAnnotationManager == null || _markerImage == null) return;
          await sheetAnnotationManager!.deleteAll();
          await sheetAnnotationManager!.create(PointAnnotationOptions(
            geometry: Point(coordinates: Position(lng, lat)),
            image: _markerImage!,
            iconSize: 0.35,
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
                        
                        // Mover cámara a la ubicación inicial
                        await m.flyTo(
                          CameraOptions(
                            center: Point(coordinates: Position(tempLng, tempLat)),
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
                        // IMPORTANTE: Usar las coordenadas del punto tocado en el mapa
                        final c = gestureContext.point.coordinates;
                        
                        print("Map tapped at: ${c.lat}, ${c.lng}");
                        
                        // Actualizar variables temporales
                        tempLat = c.lat.toDouble();
                        tempLng = c.lng.toDouble();
                        
                        // Redibujar marcador en la nueva posición
                        await drawMarker(tempLat, tempLng);
                        
                        // Reconstruir UI del modal para mostrar nuevas coordenadas
                        setSheetState(() {});
                      },
                    ),
                    // Capa transparente para gestos que permite scroll vertical en los bordes
                    // pero prioriza el mapa en el centro
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      width: 20, // Zona segura izquierda para arrastrar modal
                      child: Container(color: Colors.transparent),
                    ),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 0,
                      width: 20, // Zona segura derecha para arrastrar modal
                      child: Container(color: Colors.transparent),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 60, // Zona segura superior para arrastrar modal
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        child: Container(color: Colors.transparent),
                      ),
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
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: CustomButton(
                                text: S.of(context).confirmLocation,
                                backgroundColor: Colors.transparent,
                                textColor: Colors.white,
                                onPressed: () {
                                  setState(() {
                                    _latitudeController.text =
                                        tempLat.toStringAsFixed(6);
                                    _longitudeController.text =
                                        tempLng.toStringAsFixed(6);
                                  });
                                  
                                  // Actualizar marcador en el mapa pequeño
                                  _updatePropertyMarker();
                                  
                                  // Actualizar dirección
                                  _updateAddressFromCoordinates(tempLat, tempLng);
                                  
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
      controller: _scrollController,
      // Padding superior ajustado para dejar espacio al indicador flotante
      padding: const EdgeInsets.only(top: 100, left: 24, right: 24, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).stepLocationDescription,
            style: const TextStyle(
                fontSize: 16, color: Colors.black87, height: 1.5),
          ),
          const SizedBox(height: 32),
          
          // Mapa para seleccionar ubicación (PRIMERO)
          Text(
            S.of(context).mapLocationLabel,
            style: const TextStyle(
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
                        color: Colors.black.withValues(alpha: 0.05),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.open_in_full,
                                  color: AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              Text(S.of(context).tapToSelectLocation),
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

          // Campo de dirección (DEBAJO DEL MAPA)
          Text(
            S.of(context).addressLabel,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          // Custom field with suffix icon
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextFormField(
              controller: _addressController,
              onEditingComplete: () {
                _updateCoordinatesFromAddress(_addressController.text);
                FocusScope.of(context).unfocus();
              },
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: S.of(context).addressHint,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                labelStyle: const TextStyle(color: Colors.black54),
                prefixIcon: const Icon(Icons.location_on, color: AppTheme.primaryColor),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: AppTheme.primaryColor),
                  onPressed: () {
                    _updateCoordinatesFromAddress(_addressController.text);
                    FocusScope.of(context).unfocus();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.5)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          Text(
            S.of(context).availabilityDateLabel,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          _buildProfileStyledField(
            controller: _availabilityDateController,
            hintText: S.of(context).dateHint,
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
                      colorScheme: const ColorScheme.light(
                        primary: AppTheme.primaryColor,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Colors.black,
                      ),
                      dialogBackgroundColor: Colors.white,
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
    FocusNode? focusNode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: hintText,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          labelStyle: const TextStyle(color: Colors.black54),
          prefixIcon: Icon(icon, color: AppTheme.primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPropertyTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedPropertyType,
        decoration: InputDecoration(
          hintText: S.of(context).propertyTypeLabel,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          labelStyle: const TextStyle(color: Colors.black54),
          prefixIcon: const Icon(Icons.home_work, color: AppTheme.primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dropdownColor: Colors.white,
        style: const TextStyle(color: Colors.black),
        items: _propertyTypeDisplayMapping.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child:
                Text(entry.value, style: const TextStyle(color: Colors.black)),
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
            Colors.white.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white,
                  border: Border.all(color: AppTheme.primaryColor),
                ),
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    S.of(context).previousButton,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
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
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CustomButton(
                text: _currentStep == 2
                    ? S.of(context).finishButton
                    : S.of(context).nextButton,
                onPressed: _isLoading ? null : _nextStep,
                backgroundColor: Colors.transparent,
                textColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
