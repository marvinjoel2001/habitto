// Clase: SearchPage

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../../shared/theme/app_theme.dart';



class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Nuevas variables para mapbox_maps_flutter
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;

  // CAMBIO: Múltiples imágenes de marcadores
  Uint8List? _houseMarkerImage;
  Uint8List? _edificioMarkerImage;
  Uint8List? _loteMarkerImage;
  Uint8List? _userLocationImage;

  // Estado de la UI
  geo.Position? _currentPosition;
  PropertyInfo? _selectedProperty;
  bool _isLoading = true;

  // Datos hardcodeados de propiedades en Santa Cruz - COORDENADAS CORREGIDAS Y SEPARADAS
  final List<PropertyData> _properties = [
    PropertyData(
      id: '1',
      title: 'Apartamento en Equipetrol',
      price: 'Bs. 3,500 / mes',
      description: 'Moderno apartamento de 3 habitaciones con vista panorámica en el corazón de Equipetrol. Incluye gimnasio y piscina.',
      location: Point(coordinates: Position(-63.1821, -17.7833)), // Centro Equipetrol
      type: PropertyType.house,
      imageUrl: 'assets/images/casa1.jpg',
    ),
    PropertyData(
      id: '2',
      title: 'Casa en Las Palmas',
      price: 'Bs. 4,200 / mes',
      description: 'Hermosa casa de 4 habitaciones con jardín privado y garaje para 2 vehículos en zona residencial exclusiva.',
      location: Point(coordinates: Position(-63.1500, -17.7700)), // Las Palmas (más al este)
      type: PropertyType.house,
      imageUrl: 'assets/images/casa2.jpg',
    ),
    PropertyData(
      id: '3',
      title: 'Departamento en Plan 3000',
      price: 'Bs. 2,800 / mes',
      description: 'Acogedor departamento de 2 habitaciones en zona norte de la ciudad.',
      location: Point(coordinates: Position(-63.1650, -17.7500)), // Plan 3000 (norte)
      type: PropertyType.apartment,
      imageUrl: 'assets/images/casa3.jpg',
    ),
    PropertyData(
      id: '4',
      title: 'Casa en Urubó',
      price: 'Bs. 5,800 / mes',
      description: 'Lujosa casa de 5 habitaciones con piscina, quincho y amplio jardín en condominio cerrado.',
      location: Point(coordinates: Position(-63.1200, -17.7400)), // Urubó (noreste)
      type: PropertyType.house,
      imageUrl: 'assets/images/casa4.jpg',
    ),
    PropertyData(
      id: '5',
      title: 'Apartamento en Manzana 40',
      price: 'Bs. 2,200 / mes',
      description: 'Departamento económico de 2 habitaciones en zona popular, ideal para estudiantes.',
      location: Point(coordinates: Position(-63.2000, -17.8000)), // Manzana 40 (suroeste)
      type: PropertyType.apartment,
      imageUrl: 'assets/images/casa1.jpg',
    ),
    PropertyData(
      id: '6',
      title: 'Casa en Cristo Redentor',
      price: 'Bs. 3,800 / mes',
      description: 'Casa familiar de 3 habitaciones cerca del Cristo Redentor con vista panorámica.',
      location: Point(coordinates: Position(-63.1900, -17.7600)), // Cristo Redentor (oeste)
      type: PropertyType.house,
      imageUrl: 'assets/images/casa2.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Inicializar el token de Mapbox - igual que en add_property_page.dart
    MapboxOptions.setAccessToken("pk.eyJ1IjoibWFydmluMjAwMSIsImEiOiJjbWdpaDRicTQwOTc3Mm9wcmd3OW5lNzExIn0.ISPECxmLq_6xhipoygxtFg");
    _getCurrentLocation();
    _loadMarkerImages();
  }

  // CAMBIO: Carga las imágenes específicas de marcadores desde assets
  Future<void> _loadMarkerImages() async {
    try {
      // Cargar las tres imágenes de pointers desde assets
      final ByteData houseBytes = await rootBundle.load('assets/images/house_pointer.png');
      _houseMarkerImage = houseBytes.buffer.asUint8List();

      final ByteData edificioBytes = await rootBundle.load('assets/images/edificio_pointer.png');
      _edificioMarkerImage = edificioBytes.buffer.asUint8List();

      final ByteData loteBytes = await rootBundle.load('assets/images/lote_pointer.png');
      _loteMarkerImage = loteBytes.buffer.asUint8List();

    } catch (e) {
      debugPrint('Error cargando imágenes de marcadores: $e');
      // Si falla, genera marcadores por defecto
      _houseMarkerImage = await _generateDefaultMarker();
      _edificioMarkerImage = await _generateDefaultMarker();
      _loteMarkerImage = await _generateDefaultMarker();
    }

    // Genera avatar para ubicación del usuario
    _userLocationImage = await _generateUserLocationMarker();

    // Si el manager de anotaciones ya existe (map ya creado), crea los marcadores
    if (_pointAnnotationManager != null) {
      await _createMarkers();
    }
  }

  // CAMBIO: Función para seleccionar imagen de marcador aleatoriamente
  Uint8List? _getRandomMarkerImage() {
    final images = [_houseMarkerImage, _edificioMarkerImage, _loteMarkerImage];
    final availableImages = images.where((img) => img != null).toList();

    if (availableImages.isEmpty) return null;

    // Selecciona una imagen aleatoria
    final randomIndex = DateTime.now().millisecondsSinceEpoch % availableImages.length;
    return availableImages[randomIndex];
  }

  // Genera una imagen PNG simple para el marcador de propiedades
  Future<Uint8List> _generateDefaultMarker() async {
    const double size = 64.0;

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    // Fondo transparente
    final bgPaint = Paint()..color = const Color(0x00000000);
    canvas.drawRect(const Rect.fromLTWH(0, 0, size, size), bgPaint);

    // Círculo principal del marcador (amarillo como el tema)
    final circlePaint = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;
    const center = Offset(size / 2, size / 2);
    canvas.drawCircle(center, size * 0.36, circlePaint);

    // Borde sutil
    final borderPaint = Paint()
      ..color = AppTheme.whiteColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, size * 0.36, borderPaint);

    // Renderiza imagen y devuelve PNG en bytes
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // Genera avatar para la ubicación del usuario
  Future<Uint8List> _generateUserLocationMarker() async {
    const double size = 80.0;

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    // Fondo transparente
    final bgPaint = Paint()..color = const Color(0x00000000);
    canvas.drawRect(const Rect.fromLTWH(0, 0, size, size), bgPaint);

    const center = Offset(size / 2, size / 2);

    // Círculo exterior (azul)
    final outerCirclePaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size * 0.45, outerCirclePaint);

    // Círculo medio (azul más intenso)
    final middleCirclePaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size * 0.3, middleCirclePaint);

    // Círculo interior (azul sólido)
    final innerCirclePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size * 0.2, innerCirclePaint);

    // Borde blanco
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, size * 0.2, borderPaint);

    // Renderiza imagen y devuelve PNG en bytes
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  @override
  void dispose() {
    super.dispose();
  }

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
      }
    } catch (e) {
      // Usar ubicación por defecto si hay un error o no hay permiso
    } finally {
      if (mounted) {
        setState(() {
          _currentPosition ??= geo.Position(
              latitude: -17.7833,
              longitude: -63.1821,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              altitudeAccuracy: 0.0,
              headingAccuracy: 0.0);
          _isLoading = false;
        });
      }
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    // Habilita el punto azul de la ubicación del usuario
    _mapboxMap!.location
        .updateSettings(LocationComponentSettings(enabled: true));

    // Crea el gestor de marcadores (annotations)
    _pointAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();

    // Conectar el listener de tap en anotaciones
    _pointAnnotationManager?.tapEvents(onTap: (annotation) {
      _onMarkerTapped(annotation);
    });

    // Opcional: long press en anotaciones
    _pointAnnotationManager?.longPressEvents(onLongPress: (annotation) {
      _onMarkerLongPressed(annotation);
    });

    // Ahora que el mapa está listo, crea los marcadores
    _createMarkers();
  }

  Future<void> _createMarkers() async {
    // Espera a que el gestor de marcadores y las imágenes estén listos
    if (_pointAnnotationManager == null || _userLocationImage == null) return;

    // Verifica que al menos una imagen de marcador esté disponible
    if (_houseMarkerImage == null && _edificioMarkerImage == null && _loteMarkerImage == null) return;

    // Limpia marcadores anteriores
    await _pointAnnotationManager!.deleteAll();

    // Crea una lista de opciones para todos los marcadores de propiedades
    final options = <PointAnnotationOptions>[];

    // CAMBIO: Marcadores de propiedades con imágenes aleatorias
    for (final property in _properties) {
      final markerImage = _getRandomMarkerImage();
      if (markerImage != null) {
        options.add(PointAnnotationOptions(
          geometry: property.location,
          image: markerImage,
          iconSize: 0.4, // Tamaño más pequeño
          // textField removido - sin números
        ));
      }
    }

    // Marcador de ubicación del usuario (sin cambios)
    if (_currentPosition != null) {
      options.add(PointAnnotationOptions(
        geometry: Point(coordinates: Position(
          _currentPosition!.longitude,
          _currentPosition!.latitude,
        )),
        image: _userLocationImage,
        iconSize: 0.8, // También más pequeño
        // textField removido
      ));
    }

    // Crea todos los marcadores en una sola operación (más eficiente)
    await _pointAnnotationManager!.createMulti(options);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.primary,
      extendBody: true,
      body: RefreshIndicator(
        onRefresh: _reloadMapData,
        color: cs.primary,
        backgroundColor: AppTheme.darkGrayBase,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Stack(
                children: [
          // Mapa ocupa TODA la pantalla sin márgenes
          Positioned.fill(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : MapWidget(
                    onMapCreated: _onMapCreated,
                    styleUri: MapboxStyles.OUTDOORS,
                    cameraOptions: CameraOptions(
                      center: Point(
                        coordinates: Position(
                          _currentPosition!.longitude,
                          _currentPosition!.latitude,
                        ),
                      ),
                      zoom: 13, // Zoom más alejado para ver todos los marcadores
                      pitch: 45,
                      bearing: 0,
                    ),
                    onTapListener: (context) =>
                        setState(() => _selectedProperty = null),
                  ),
          ),

          // TOP overlays: barra de búsqueda y chips con SafeArea
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 10),
                    _buildFilters(),
                  ],
                ),
              ),
            ),
          ),

          // Columna de acciones a la derecha - ajustada para bottom bar
          Positioned(
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom +
                    (_selectedProperty != null ? 240 : 100),
            child: _buildMapActions(),
          ),

          // Card inferior cuando hay selección - MEJORADO
          if (_selectedProperty != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 90, // Más arriba del bottom bar
              child: _buildPropertyCard(),
            ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reloadMapData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await _loadMarkerImages();
      await _getCurrentLocation();
      await _createMarkers();
    } catch (_) {} finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Manejo de tap en marcador - CORREGIDO para ignorar el marcador del usuario
  void _onMarkerTapped(PointAnnotation annotation) {
    // Ignorar si es el marcador de ubicación del usuario
    if (annotation.textField == 'user_location') return;

    // Buscar la propiedad correspondiente al marcador tocado
    final property = _properties.firstWhere(
      (prop) => prop.id == annotation.textField,
      orElse: () => _properties.first,
    );

    setState(() {
      _selectedProperty = PropertyInfo(
        title: property.title,
        price: property.price,
        description: property.description,
        imageUrl: property.imageUrl,
      );
    });
  }

  // Opcional: manejo de long-press en marcador
  void _onMarkerLongPressed(PointAnnotation annotation) {
    debugPrint("Long press en marcador: ${annotation.textField}");
  }

  // --- Widgets de UI extraídos para mayor claridad ---

  Widget _buildSearchBar() {

    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.whiteColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppTheme.whiteColor.withValues(alpha: 0.5)),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por zona, precio o tipo',
              border: InputBorder.none,
              icon: Icon(Icons.search, color: AppTheme.blackColor.withValues(alpha: 0.7)),
              hintStyle: TextStyle(color: AppTheme.blackColor.withValues(alpha: 0.6)),
            ),
            style: const TextStyle(color: AppTheme.blackColor),
          ),
        ),
      ),
    );
  }

  // Chips de filtro con glass (horizontal)
  Widget _buildFilters() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('Zona', true),
          const SizedBox(width: 8),
          _buildFilterChip('Precio', false),
          const SizedBox(width: 8),
          _buildFilterChip('Tipo', false),
          const SizedBox(width: 8),
          _buildFilterChip('Amenities', false),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    final primary = Theme.of(context).colorScheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Chip(
          label: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.blackColor : AppTheme.blackColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          backgroundColor:
              isSelected ? primary.withValues(alpha: 0.85) : AppTheme.whiteColor.withValues(alpha: 0.85),
          shape: StadiumBorder(
            side: BorderSide(
              color: isSelected
                  ? primary.withValues(alpha: 0.9)
                  : AppTheme.whiteColor.withValues(alpha: 0.9),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // Columna de acciones del mapa (glass) - mejorada para 3D
  Widget _buildMapActions() {

    Widget glassIcon(IconData icon, VoidCallback onTap) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.whiteColor.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.whiteColor.withValues(alpha: 0.55)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.blackColor.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(icon, color: AppTheme.blackColor),
                onPressed: onTap,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Zoom in con animación 3D - ZOOM MÁS GRADUAL
        glassIcon(Icons.add, () async {
          if (_mapboxMap != null) {
            // Obtener el zoom actual
            final currentCamera = await _mapboxMap!.getCameraState();
            final currentZoom = currentCamera.zoom;

            // Incrementar zoom de manera gradual (+1.5 niveles)
            _mapboxMap!.flyTo(
              CameraOptions(
                zoom: currentZoom + 1.5,
                pitch: 60,
              ),
              MapAnimationOptions(duration: 800, startDelay: 0),
            );
          }
        }),
        // Zoom out - ZOOM MÁS GRADUAL
        glassIcon(Icons.remove, () async {
          if (_mapboxMap != null) {
            // Obtener el zoom actual
            final currentCamera = await _mapboxMap!.getCameraState();
            final currentZoom = currentCamera.zoom;

            // Decrementar zoom de manera gradual (-1.5 niveles)
            _mapboxMap!.flyTo(
              CameraOptions(
                zoom: currentZoom - 1.5,
                pitch: 30,
              ),
              MapAnimationOptions(duration: 800, startDelay: 0),
            );
          }
        }),
        // Vista 3D/2D toggle
        glassIcon(Icons.threed_rotation, () {
          if (_mapboxMap != null) {
            _mapboxMap!.flyTo(
              CameraOptions(
                pitch: 0,
                bearing: 0,
              ),
              MapAnimationOptions(duration: 1000, startDelay: 0),
            );
          }
        }),
        // Centrar en ubicación actual
        glassIcon(Icons.my_location, () {
          if (_currentPosition != null && _mapboxMap != null) {
            _mapboxMap!.flyTo(
              CameraOptions(
                center: Point(
                  coordinates: Position(
                    _currentPosition!.longitude,
                    _currentPosition!.latitude,
                  ),
                ),
                zoom: 16,
                pitch: 45,
              ),
              MapAnimationOptions(duration: 1500, startDelay: 0),
            );
          }
        }),
      ],
    );
  }

  // Card inferior MEJORADO con mejor glassmorphism y colores más visibles
  Widget _buildPropertyCard() {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.whiteColor.withValues(alpha: 0.45), // Más translúcido para efecto cristal
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.whiteColor.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.blackColor.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con botón cerrar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _selectedProperty!.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.blackColor.withValues(alpha: 0.87), // Más visible
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _selectedProperty = null),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.blackColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.close, color: AppTheme.blackColor.withValues(alpha: 0.87), size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Precio destacado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _selectedProperty!.price,
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppTheme.blackColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Imagen de la propiedad
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  _selectedProperty!.imageUrl,
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(
                        width: double.infinity,
                        height: 120,
                        color: AppTheme.grayColor.withValues(alpha: 0.3),
                        child: const Icon(Icons.home, size: 40, color: AppTheme.grayColor),
                      ),
                ),
              ),
              const SizedBox(height: 16),

              // Descripción con mejor contraste
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.whiteColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.whiteColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _selectedProperty!.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.blackColor.withValues(alpha: 0.87), // Más visible
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Botón Ver Más mejorado
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {/* Navegar a detalles de la propiedad */},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: AppTheme.blackColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Ver Más Detalles',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
}

// --- Modelos de Datos Actualizados ---

class PropertyData {
  final String id;
  final String title;
  final String price;
  final String description;
  final Point location;
  final PropertyType type;
  final String imageUrl;

  const PropertyData({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.location,
    required this.type,
    required this.imageUrl,
  });
}

class PropertyInfo {
  final String title;
  final String price;
  final String description;
  final String imageUrl;
  const PropertyInfo({
    required this.title,
    required this.price,
    required this.description,
    required this.imageUrl,
  });
}

enum PropertyType { house, apartment }
