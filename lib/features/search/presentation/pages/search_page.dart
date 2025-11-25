// Clase: SearchPage

import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../../shared/theme/app_theme.dart';
import 'package:habitto/core/services/api_service.dart';
import 'package:habitto/features/properties/data/services/property_service.dart';
import 'package:habitto/features/properties/domain/entities/property.dart'
    as domain;

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Nuevas variables para mapbox_maps_flutter
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  bool _is3D = true;
  final Map<String, PropertyData> _annotationToProperty = {};
  final Set<String> _userAnnotationIds = {};

  // CAMBIO: Múltiples imágenes de marcadores
  Uint8List? _houseMarkerImage;
  Uint8List? _edificioMarkerImage;
  Uint8List? _loteMarkerImage;
  Uint8List? _userLocationImage;

  // Estado de la UI
  geo.Position? _currentPosition;
  PropertyInfo? _selectedProperty;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<_Suggestion> _suggestions = [];
  bool _showSuggestions = false;

  // Datos hardcodeados de propiedades en Santa Cruz - COORDENADAS CORREGIDAS Y SEPARADAS
  final List<PropertyData> _properties = [];
  late final ApiService _apiService;
  late final PropertyService _propertyService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _propertyService = PropertyService(apiService: _apiService);
    // Inicializar el token de Mapbox - igual que en add_property_page.dart
    MapboxOptions.setAccessToken(
        "pk.eyJ1IjoibWFydmluMjAwMSIsImEiOiJjbWdpaDRicTQwOTc3Mm9wcmd3OW5lNzExIn0.ISPECxmLq_6xhipoygxtFg");
    _getCurrentLocation();
    _loadMarkerImages();
    _loadPropertiesFromApi();
  }

  // CAMBIO: Carga las imágenes específicas de marcadores desde assets
  Future<void> _loadMarkerImages() async {
    try {
      // Cargar las tres imágenes de pointers desde assets
      final ByteData houseBytes =
          await rootBundle.load('assets/images/house_pointer.png');
      _houseMarkerImage = houseBytes.buffer.asUint8List();

      final ByteData edificioBytes =
          await rootBundle.load('assets/images/edificio_pointer.png');
      _edificioMarkerImage = edificioBytes.buffer.asUint8List();

      final ByteData loteBytes =
          await rootBundle.load('assets/images/lote_pointer.png');
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
    final randomIndex =
        DateTime.now().millisecondsSinceEpoch % availableImages.length;
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
    _searchController.dispose();
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

    await _mapboxMap!.gestures.updateSettings(GesturesSettings(
      pinchToZoomEnabled: true,
      rotateEnabled: true,
      pitchEnabled: true,
      scrollEnabled: true,
      quickZoomEnabled: true,
    ));

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
    if (_houseMarkerImage == null &&
        _edificioMarkerImage == null &&
        _loteMarkerImage == null) {
      return;
    }

    // Limpia marcadores anteriores
    await _pointAnnotationManager!.deleteAll();

    _annotationToProperty.clear();
    _userAnnotationIds.clear();

    // Opciones de propiedades
    final propertyOptions = <PointAnnotationOptions>[];
    for (final property in _properties) {
      final markerImage = _getRandomMarkerImage();
      if (markerImage != null) {
        propertyOptions.add(PointAnnotationOptions(
          geometry: property.location,
          image: markerImage,
          iconSize: 0.4,
        ));
      }
    }

    // Crear marcadores de propiedades y mapear ids
    final createdProps =
        await _pointAnnotationManager!.createMulti(propertyOptions);
    for (int i = 0; i < createdProps.length && i < _properties.length; i++) {
      final ann = createdProps[i];
      final id = ann?.id;
      if (id != null) {
        _annotationToProperty[id] = _properties[i];
      }
    }

    // Crear marcador de ubicación del usuario aparte
    if (_currentPosition != null) {
      final userAnn =
          await _pointAnnotationManager!.create(PointAnnotationOptions(
        geometry: Point(
            coordinates: Position(
          _currentPosition!.longitude,
          _currentPosition!.latitude,
        )),
        image: _userLocationImage,
        iconSize: 0.8,
      ));
      final uid = userAnn.id;
      _userAnnotationIds.add(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.primary,
      extendBody: true,
      body: Stack(
        children: [
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
                      zoom: 13,
                      pitch: 45,
                      bearing: 0,
                    ),
                    onTapListener: (context) =>
                        setState(() => _selectedProperty = null),
                  ),
          ),
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
                    if (_showSuggestions)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: _suggestions.map((s) {
                            return ListTile(
                              dense: true,
                              title: Text(s.label,
                                  style: const TextStyle(color: Colors.black)),
                              onTap: () {
                                setState(() {
                                  _showSuggestions = false;
                                  _searchController.text = s.label;
                                });
                                _mapboxMap?.flyTo(
                                  CameraOptions(
                                    center: Point(
                                        coordinates: Position(s.lon, s.lat)),
                                    zoom: 16,
                                    pitch: 45,
                                  ),
                                  MapAnimationOptions(
                                      duration: 800, startDelay: 0),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom +
                (_selectedProperty != null ? 240 : 100),
            child: _buildMapActions(),
          ),
          if (_selectedProperty != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 90,
              child: _buildPropertyCard(),
            ),
        ],
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
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Manejo de tap en marcador con mapeo por id
  void _onMarkerTapped(PointAnnotation annotation) {
    final id = annotation.id;
    if (_userAnnotationIds.contains(id)) return;
    final property = _annotationToProperty[id] ??
        (_properties.isNotEmpty ? _properties.first : null);
    if (property == null) return;
    setState(() {
      _selectedProperty = PropertyInfo(
        title: property.title,
        price: property.price,
        description: property.description,
        imageUrl: property.imageUrl,
        address: property.address,
        features: property.features,
      );
    });
  }

  Future<void> _loadPropertiesFromApi() async {
    try {
      final res = await _propertyService.getProperties(pageSize: 50);
      if (res['success'] == true && res['data'] != null) {
        final List<domain.Property> props =
            List<domain.Property>.from(res['data']['properties'] as List);
        final mapped = props
            .where((p) => p.latitude != null && p.longitude != null)
            .map((p) => PropertyData(
                  id: p.id.toString(),
                  title: p.address.isNotEmpty ? p.address : 'Propiedad',
                  price: p.price > 0
                      ? 'Bs. ${p.price.toStringAsFixed(0)} / mes'
                      : '—',
                  description: p.description,
                  location:
                      Point(coordinates: Position(p.longitude!, p.latitude!)),
                  type: PropertyType.house,
                  imageUrl: p.mainPhoto ?? 'assets/images/casa1.jpg',
                  address: p.address,
                  features: [
                    '${p.bedrooms} hab',
                    '${p.bathrooms} baños',
                    '${p.size.toStringAsFixed(0)} m²'
                  ],
                ))
            .toList();
        setState(() {
          _properties
            ..clear()
            ..addAll(mapped);
        });
        await _createMarkers();
      }
    } catch (_) {}
  }

  // Opcional: manejo de long-press en marcador
  void _onMarkerLongPressed(PointAnnotation annotation) {
    debugPrint("Long press en marcador: ${annotation.id}");
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
            border:
                Border.all(color: AppTheme.whiteColor.withValues(alpha: 0.5)),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por zona, precio o tipo',
              border: InputBorder.none,
              icon: Icon(Icons.search,
                  color: AppTheme.blackColor.withValues(alpha: 0.7)),
              hintStyle:
                  TextStyle(color: AppTheme.blackColor.withValues(alpha: 0.6)),
            ),
            style: const TextStyle(color: AppTheme.blackColor),
            controller: _searchController,
            onChanged: (v) => _onSearchChanged(v),
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
          backgroundColor: isSelected
              ? primary.withValues(alpha: 0.85)
              : AppTheme.whiteColor.withValues(alpha: 0.85),
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
                border: Border.all(
                    color: AppTheme.whiteColor.withValues(alpha: 0.55)),
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
        glassIcon(Icons.threed_rotation, () async {
          if (_mapboxMap != null) {
            final current = await _mapboxMap!.getCameraState();
            final targetPitch = _is3D ? 0.0 : 60.0;
            final targetBearing = _is3D ? 0.0 : 45.0;
            _mapboxMap!.flyTo(
              CameraOptions(
                center: current.center,
                zoom: current.zoom,
                pitch: targetPitch,
                bearing: targetBearing,
              ),
              MapAnimationOptions(duration: 800, startDelay: 0),
            );
            setState(() {
              _is3D = !_is3D;
            });
          }
        }),
        glassIcon(Icons.rotate_left, () async {
          if (_mapboxMap != null) {
            final cam = await _mapboxMap!.getCameraState();
            _mapboxMap!.flyTo(
              CameraOptions(bearing: cam.bearing - 30),
              MapAnimationOptions(duration: 600, startDelay: 0),
            );
          }
        }),
        glassIcon(Icons.rotate_right, () async {
          if (_mapboxMap != null) {
            final cam = await _mapboxMap!.getCameraState();
            _mapboxMap!.flyTo(
              CameraOptions(bearing: cam.bearing + 30),
              MapAnimationOptions(duration: 600, startDelay: 0),
            );
          }
        }),
        // Centrar en ubicación actual
        glassIcon(Icons.my_location, () async {
          if (_mapboxMap != null) {
            if (_currentPosition == null) {
              await _getCurrentLocation();
            }
            if (_currentPosition != null) {
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
                MapAnimationOptions(duration: 1200, startDelay: 0),
              );
            }
          }
        }),
      ],
    );
  }

  Future<void> _onSearchChanged(String q) async {
    if (q.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    final results = await _fetchSuggestions(q.trim());
    setState(() {
      _suggestions = results;
      _showSuggestions = results.isNotEmpty;
    });
  }

  Future<List<_Suggestion>> _fetchSuggestions(String query) async {
    try {
      const token =
          'pk.eyJ1IjoibWFydmluMjAwMSIsImEiOiJjbWdpaDRicTQwOTc3Mm9wcmd3OW5lNzExIn0.ISPECxmLq_6xhipoygxtFg';
      final uri = Uri.parse(
              'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json')
          .replace(queryParameters: {
        'access_token': token,
        'language': 'es',
        'autocomplete': 'true',
        'limit': '5',
      });
      final resp = await http.get(uri);
      if (resp.statusCode != 200) return [];
      final body = resp.body;
      final data = jsonDecode(body) as Map<String, dynamic>;
      final features = (data['features'] as List?) ?? [];
      return features.map<_Suggestion>((f) {
        final label = f['place_name'] as String? ?? '';
        final center = (f['center'] as List?) ?? [];
        final lon = (center.isNotEmpty ? (center[0] as num).toDouble() : 0.0);
        final lat = (center.length > 1 ? (center[1] as num).toDouble() : 0.0);
        return _Suggestion(label: label, lon: lon, lat: lat);
      }).toList();
    } catch (_) {
      return [];
    }
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
            color: AppTheme.whiteColor
                .withValues(alpha: 0.45), // Más translúcido para efecto cristal
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
                        color: AppTheme.blackColor
                            .withValues(alpha: 0.87), // Más visible
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
                      child: Icon(Icons.close,
                          color: AppTheme.blackColor.withValues(alpha: 0.87),
                          size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Precio destacado
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

              if (_selectedProperty!.address != null)
                Row(
                  children: [
                    const Icon(Icons.place_outlined,
                        size: 16, color: AppTheme.blackColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _selectedProperty!.address!,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.blackColor.withValues(alpha: 0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),

              // Imagen de la propiedad
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  _selectedProperty!.imageUrl,
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: double.infinity,
                    height: 120,
                    color: AppTheme.grayColor.withValues(alpha: 0.3),
                    child: const Icon(Icons.home,
                        size: 40, color: AppTheme.grayColor),
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
                  border: Border.all(
                      color: AppTheme.whiteColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _selectedProperty!.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.blackColor
                        .withValues(alpha: 0.87), // Más visible
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_selectedProperty!.features.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedProperty!.features
                      .map((f) => Chip(
                            label: Text(f),
                            backgroundColor: Colors.white.withOpacity(0.85),
                          ))
                      .toList(),
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
  final String address;
  final List<String> features;

  const PropertyData({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.location,
    required this.type,
    required this.imageUrl,
    required this.address,
    this.features = const [],
  });
}

class PropertyInfo {
  final String title;
  final String price;
  final String description;
  final String imageUrl;
  final String? address;
  final List<String> features;
  const PropertyInfo({
    required this.title,
    required this.price,
    required this.description,
    required this.imageUrl,
    this.address,
    this.features = const [],
  });
}

enum PropertyType { house, apartment }

class _Suggestion {
  final String label;
  final double lon;
  final double lat;
  _Suggestion({required this.label, required this.lon, required this.lat});
}
