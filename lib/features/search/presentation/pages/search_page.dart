// Clase: SearchPage

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:video_player/video_player.dart';

// --- CLASE THEME SIMULADA PARA QUE EL CÓDIGO FUNCIONE ---
// En tu proyecto real, asegúrate de tener este import correcto.
// import '../../../../shared/theme/app_theme.dart';
class AppTheme {
  static const Color primaryColor = Color(0xFFFDB813);
  static const Color grayColor = Colors.grey;
}
// ---------------------------------------------------

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Nuevas variables para mapbox_maps_flutter
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  Uint8List? _markerImage;

  // Estado de la UI
  geo.Position? _currentPosition;
  PropertyInfo? _selectedProperty;  
  bool _isLoading = true;

  // Lógica del video de introducción
  VideoPlayerController? _videoController;
  bool _showVideo = true;
  bool _videoInitialized = false;

  // Datos de ejemplo de propiedades (¡OJO! location ahora es un 'Point')
  final List<PropertyData> _properties = [
    PropertyData(
      id: '1',
      title: 'Depto Centro',
      price: '2.500 BOB / mes',
      description:
          'Amplio departamento de 2 habitaciones en el corazón de la ciudad.',
      // Mapbox usa el formato (LONGITUD, LATITUD)
      location: Point(coordinates: Position(-63.1821, -17.7833)),
      type: PropertyType.apartment,
      imageUrl: 'assets/images/casa1.jpg',
    ),
    PropertyData(
      id: '2',
      title: 'Casa Equipetrol',
      price: '3.200 BOB / mes',
      description: 'Casa moderna con jardín en zona residencial.',
      location: Point(coordinates: Position(-63.1500, -17.7700)),
      type: PropertyType.house,
      imageUrl: 'assets/images/casa2.jpg',
    ),
    PropertyData(
      id: '3',
      title: 'Depto Norte',
      price: '1.800 BOB / mes',
      description: 'Departamento acogedor cerca del centro comercial.',
      location: Point(coordinates: Position(-63.1700, -17.7600)),
      type: PropertyType.apartment,
      imageUrl: 'assets/images/casa3.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // NOTA: Para que este código funcione, debes pasar tu token de Mapbox al ejecutar la app:
    // flutter run --dart-define ACCESS_TOKEN=TU_LLAVE_PUBLICA_AQUI
    MapboxOptions.setAccessToken(const String.fromEnvironment("ACCESS_TOKEN"));

    _initializeVideo();
    _getCurrentLocation();
    _loadMarkerImage();
  }

  // Carga la imagen del marcador una sola vez para mejorar el rendimiento
  Future<void> _loadMarkerImage() async {
    // Asegúrate de tener una imagen en esta ruta y declarada en pubspec.yaml
    final ByteData bytes =
        await rootBundle.load('assets/images/custom_marker.png');
    _markerImage = bytes.buffer.asUint8List();
  }

  Future<void> _initializeVideo() async {
    _videoController =
        VideoPlayerController.asset('assets/videos/Video_Drone_Santa_Cruz.mp4');
    try {
      await _videoController!.initialize();
      setState(() => _videoInitialized = true);
      _videoController!.play();
      _videoController!.addListener(() {
        if (_videoController!.value.position >=
            _videoController!.value.duration) {
          if (mounted) setState(() => _showVideo = false);
        }
      });
    } catch (e) {
      if (mounted) setState(() => _showVideo = false);
    }
  }

  void _skipVideo() {
    if (mounted) setState(() => _showVideo = false);
    _videoController?.pause();
  }

  @override
  void dispose() {
    _videoController?.dispose();
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
    // Asegúrate de crear el manager y guardarlo en el campo correcto
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
    // Espera a que el gestor de marcadores y la imagen estén listos
    if (_pointAnnotationManager == null || _markerImage == null) return;

    // Limpia marcadores anteriores
    await _pointAnnotationManager!.deleteAll();

    // Crea una lista de opciones para todos los marcadores
    final options = <PointAnnotationOptions>[];
    for (final property in _properties) {
      options.add(PointAnnotationOptions(
        geometry: property.location, // Sin toJson, debe ser Point
        image: _markerImage,
        iconSize: 0.8,
        // Usamos el 'textField' para guardar el ID de la propiedad. No se mostrará texto.
        textField: property.id,
      ));
    }

    // Crea todos los marcadores en una sola operación (más eficiente)
    await _pointAnnotationManager!.createMulti(options);
  }

  @override
  Widget build(BuildContext context) {
    if (_showVideo) {
      return Scaffold(/* ... El código del video no cambia ... */);
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header y Filtros (no cambian)
            _buildHeader(),
            _buildFilters(),

            // Mapa refactorizado
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        MapWidget(
                          onMapCreated: _onMapCreated,
                          styleUri: MapboxStyles.MAPBOX_STREETS,
                          cameraOptions: CameraOptions(
                            center: Point(
                              coordinates: Position(
                                _currentPosition!.longitude,
                                _currentPosition!.latitude,
                              ),
                            ),
                            zoom: 14,
                          ),
                          onTapListener: (context) =>
                              setState(() => _selectedProperty = null),
                        ),
                      Positioned(
                        bottom: _selectedProperty != null ? 210 : 20,
                        right: 20,
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: AppTheme.primaryColor,
                          onPressed: () {
                            if (_currentPosition != null &&
                                _mapboxMap != null) {
                              _mapboxMap!.flyTo(
                                CameraOptions(
                                  center: Point(
                                    coordinates: Position(
                                      _currentPosition!.longitude,
                                      _currentPosition!.latitude,
                                    ),
                                  ),
                                  zoom: 14,
                                ),
                                MapAnimationOptions(
                                  duration: 1000,
                                  startDelay: 0,
                                ),
                              );
                            }
                          },
                          child:
                              const Icon(Icons.my_location, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Card de propiedad seleccionada (no cambia)
            if (_selectedProperty != null) _buildPropertyCard(),
          ],
        ),
      ),
    );
  }

  // Manejo de tap en marcador (mover DENTRO de la clase)
  void _onMarkerTapped(PointAnnotation annotation) {
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

  // Opcional: manejo de long-press en marcador (mover DENTRO de la clase)
  void _onMarkerLongPressed(PointAnnotation annotation) {
    // Lógica para long press, por ejemplo mostrar opciones adicionales
    print("Long press en marcador: ${annotation.textField}");
  }

  // --- Widgets de UI extraídos para mayor claridad ---

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.black)),
              const Expanded(
                  child: Text('Búsqueda',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                      textAlign: TextAlign.center)),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(25)),
            child: const TextField(
                decoration: InputDecoration(
                    hintText: 'Busca por zona, precio o tipo',
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.grey))),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('Precio: Todo', true),
          const SizedBox(width: 8),
          _buildFilterChip('Zona: Centro', false),
          const SizedBox(width: 8),
          _buildFilterChip('Tipo: Todos', false),
          const SizedBox(width: 8),
          _buildFilterChip('Amenities: Garaje', false),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(label,
            style: TextStyle(
                color: Colors.black,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
        backgroundColor:
            isSelected ? Colors.white : Colors.white.withOpacity(0.8),
        shape: StadiumBorder(
            side: BorderSide(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                width: 2)),
      ),
    );
  }

  Widget _buildPropertyCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(_selectedProperty!.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.home, size: 30)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selectedProperty!.title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(_selectedProperty!.price,
                        style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              IconButton(
                  onPressed: () => setState(() => _selectedProperty = null),
                  icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 12),
          Text(_selectedProperty!.description,
              style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {/* Navegar a detalles de la propiedad */},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Ver Más',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
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
  final Point location; // <-- Cambiado de LatLng a Point
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
