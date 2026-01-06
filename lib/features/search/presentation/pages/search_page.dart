// Clase: SearchPage

import 'dart:math';
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
import '../../data/services/zone_service.dart';
import 'package:habitto/features/properties/presentation/pages/property_detail_page.dart';
import 'package:habitto/config/app_config.dart';
import '../../../../../generated/l10n.dart';

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
  late final ZoneService _zoneService;

  // Estado de zonas
  bool _showingZones = false;
  final String _zoneSourceId = "zones-source";
  final String _zoneFillLayerId = "zones-fill-layer";
  final String _zoneLineLayerId = "zones-line-layer";

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _propertyService = PropertyService(apiService: _apiService);
    _zoneService = ZoneService(apiService: _apiService);
    // Inicializar el token de Mapbox - igual que en add_property_page.dart
    MapboxOptions.setAccessToken(
        "pk.eyJ1IjoibWFydmluMjAwMSIsImEiOiJjbWdpaDRicTQwOTc3Mm9wcmd3OW5lNzExIn0.ISPECxmLq_6xhipoygxtFg");
    _getCurrentLocation();
    _loadMarkerImages();
    _loadPropertiesFromApi();
  }

  // CAMBIO: Carga las imágenes específicas de marcadores (Ahora generados programáticamente en Amarillo)
  Future<void> _loadMarkerImages() async {
    try {
      // Generamos marcadores específicos con íconos para cada tipo
      // Usando el color amarillo (accentMint)
      _houseMarkerImage = await _generateMarkerWithIcon(Icons.home);
      _edificioMarkerImage = await _generateMarkerWithIcon(Icons.apartment);
      _loteMarkerImage = await _generateMarkerWithIcon(Icons.landscape);
    } catch (e) {
      debugPrint('Error generando marcadores: $e');
      // Fallback
      final defaultMarker = await _generateMarkerWithIcon(Icons.place);
      _houseMarkerImage = defaultMarker;
      _edificioMarkerImage = defaultMarker;
      _loteMarkerImage = defaultMarker;
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

    // Selecciona una imagen aleatoria para simular variedad
    final randomIndex =
        DateTime.now().millisecondsSinceEpoch % availableImages.length;
    return availableImages[randomIndex];
  }

  // Genera un marcador tipo "Pin" (Gota invertida) con círculo blanco y un ícono dentro
  Future<Uint8List> _generateMarkerWithIcon(IconData iconData) async {
    const double width = 96.0;
    const double height = 110.0;

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    // 1. Pincel del Cuerpo (Amarillo)
    final paint = Paint()
      ..color = AppTheme.accentMint
      ..style = PaintingStyle.fill;

    // 2. Pincel del Círculo Interior (Blanco)
    final whiteCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 3. Sombra
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Definir la forma del Pin (Gota invertida)
    final path = Path();
    const double radius = width / 2;
    const double centerX = width / 2;
    const double centerY = radius;

    // Empezar desde la punta inferior
    path.moveTo(centerX, height);
    // Curva suave hacia la izquierda
    path.quadraticBezierTo(centerX - 10, height - 25, 0, centerY);
    // Arco superior
    path.arcTo(
        Rect.fromCircle(center: const Offset(centerX, centerY), radius: radius),
        pi,
        pi,
        false);
    // Curva suave hacia la derecha y regreso a la punta
    path.lineTo(width, centerY);
    path.quadraticBezierTo(centerX + 10, height - 25, centerX, height);
    path.close();

    // Dibujar sombra
    canvas.drawPath(path.shift(const Offset(0, 5)), shadowPaint);

    // Dibujar cuerpo amarillo
    canvas.drawPath(path, paint);

    // Dibujar círculo blanco interior
    canvas.drawCircle(
        const Offset(centerX, centerY), radius * 0.65, whiteCirclePaint);

    // Dibujar Ícono en el centro del círculo blanco
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: 36.0,
        fontFamily: iconData.fontFamily,
        color: AppTheme.primaryColor,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        centerX - textPainter.width / 2,
        centerY - textPainter.height / 2,
      ),
    );

    // Renderizar imagen
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // Mantenemos este método por si acaso, aunque ya no se use directamente
  Future<Uint8List> _generateDefaultMarker() async {
    return _generateMarkerWithIcon(Icons.place);
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
      backgroundColor: Colors.white,
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
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
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
        propertyId: int.tryParse(property.id),
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
                  title: p.address.isNotEmpty
                      ? p.address
                      : S.of(context).propertyTitleFallback,
                  price: p.price > 0
                      ? S.of(context).rentPerMonth(p.price.toStringAsFixed(0))
                      : '—',
                  description: p.description,
                  location:
                      Point(coordinates: Position(p.longitude!, p.latitude!)),
                  type: PropertyType.house,
                  imageUrl: (p.mainPhoto != null && p.mainPhoto!.isNotEmpty)
                      ? AppConfig.sanitizeUrl(p.mainPhoto!)
                      : 'assets/images/casa1.jpg',
                  address: p.address,
                  features: [
                    S.of(context).bedroomsShort(p.bedrooms.toString()),
                    S.of(context).bathroomsShort(p.bathrooms.toString()),
                    S.of(context).sizeShort(p.size.toStringAsFixed(0))
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: S.of(context).searchPlaceholder,
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search,
              color: AppTheme.blackColor.withValues(alpha: 0.7)),
          hintStyle:
              TextStyle(color: AppTheme.blackColor.withValues(alpha: 0.6)),
        ),
        style: const TextStyle(color: AppTheme.blackColor),
        controller: _searchController,
        onChanged: (v) => _onSearchChanged(v),
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
          _buildFilterChip(
            S.of(context).filterZone,
            _showingZones,
            onTap: _toggleZones,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(S.of(context).filterPrice, false),
          const SizedBox(width: 8),
          _buildFilterChip(S.of(context).filterType, false),
          const SizedBox(width: 8),
          _buildFilterChip(S.of(context).filterAmenities, false),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected,
      {VoidCallback? onTap}) {
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Chip(
            label: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.blackColor,
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
      ),
    );
  }

  Future<void> _toggleZones() async {
    if (_mapboxMap == null) return;

    setState(() {
      _showingZones = !_showingZones;
    });

    if (_showingZones) {
      await _loadAndShowZones();
    } else {
      await _hideZones();
    }
  }

  Future<void> _loadAndShowZones() async {
    try {
      final response = await _zoneService.getZonesGeoJson();
      if (response['success'] == true && response['data'] != null) {
        final geoJsonData = response['data'];

        // Lista de puntos para calcular los límites y centrar el mapa
        final List<Point> allPoints = [];

        // Procesar GeoJSON para asignar colores si no tienen
        if (geoJsonData['features'] != null) {
          final List features = geoJsonData['features'];
          final colors = [
            '#FF5733', // Rojo anaranjado
            '#33FF57', // Verde
            '#3357FF', // Azul
            '#FF33F6', // Magenta
            '#33FFF6', // Cian
            '#F6FF33', // Amarillo
            '#FF8333', // Naranja
            '#8333FF', // Violeta
          ];

          for (int i = 0; i < features.length; i++) {
            final feature = features[i];
            if (feature['properties'] == null) {
              feature['properties'] = {};
            }
            // Asignar color basado en índice o ID
            final color = colors[i % colors.length];
            feature['properties']['fill_color'] = color;

            // Recolectar puntos para el bounding box
            try {
              if (feature['geometry'] != null &&
                  feature['geometry']['coordinates'] != null) {
                final geometry = feature['geometry'];
                if (geometry['type'] == 'Polygon') {
                  final coordinates = geometry['coordinates'] as List;
                  for (final ring in coordinates) {
                    for (final point in ring) {
                      if (point is List && point.length >= 2) {
                        allPoints.add(Point(
                            coordinates: Position(
                          (point[0] as num).toDouble(),
                          (point[1] as num).toDouble(),
                        )));
                      }
                    }
                  }
                }
              }
            } catch (e) {
              debugPrint('Error parseando coordenadas de zona: $e');
            }
          }
          debugPrint('Cargando zonas GeoJSON: ${features.length} features');
        }

        final String geoJsonString = jsonEncode(geoJsonData);

        // Eliminar capas anteriores si existen
        await _removeZonesLayerImpl();

        // Añadir fuente
        await _mapboxMap!.style
            .addSource(GeoJsonSource(id: _zoneSourceId, data: geoJsonString));

        // Añadir capa de relleno (Fill Layer) - Efecto "Humito"
        await _mapboxMap!.style.addStyleLayer(
          jsonEncode({
            "id": _zoneFillLayerId,
            "type": "fill",
            "source": _zoneSourceId,
            "paint": {
              "fill-color": ['get', 'fill_color'],
              "fill-opacity": 0.45,
              "fill-outline-color": ['get', 'fill_color']
            }
          }),
          null,
        );

        // Añadir capa de línea (Line Layer) para bordes definidos
        await _mapboxMap!.style.addStyleLayer(
          jsonEncode({
            "id": _zoneLineLayerId,
            "type": "line",
            "source": _zoneSourceId,
            "paint": {
              "line-color": ['get', 'fill_color'],
              "line-width": 3.0,
              "line-opacity": 0.8
            }
          }),
          null,
        );

        // Hacer zoom a las zonas si hay puntos
        if (allPoints.isNotEmpty) {
          final camera = await _mapboxMap!.cameraForCoordinates(
            allPoints,
            MbxEdgeInsets(top: 50, left: 50, bottom: 50, right: 50),
            null, // bearing
            null, // pitch
          );

          await _mapboxMap!.flyTo(
            camera,
            MapAnimationOptions(duration: 1500, startDelay: 0),
          );
        }
      }
    } catch (e) {
      debugPrint('Error mostrando zonas: $e');
      // Revertir estado si falla
      setState(() {
        _showingZones = false;
      });
    }
  }

  Future<void> _hideZones() async {
    await _removeZonesLayerImpl();
  }

  Future<void> _removeZonesLayerImpl() async {
    if (_mapboxMap == null) return;

    try {
      if (await _mapboxMap!.style.styleLayerExists(_zoneLineLayerId)) {
        await _mapboxMap!.style.removeStyleLayer(_zoneLineLayerId);
      }
      if (await _mapboxMap!.style.styleLayerExists(_zoneFillLayerId)) {
        await _mapboxMap!.style.removeStyleLayer(_zoneFillLayerId);
      }
      if (await _mapboxMap!.style.styleSourceExists(_zoneSourceId)) {
        await _mapboxMap!.style.removeStyleSource(_zoneSourceId);
      }
    } catch (e) {
      debugPrint('Error removiendo capas de zonas: $e');
    }
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
                child: SizedBox(
                  width: double.infinity,
                  height: 120,
                  child: _buildPropertyImage(_selectedProperty!.imageUrl),
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
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.85),
                          ))
                      .toList(),
                ),
              const SizedBox(height: 16),

              // Botón Ver Más mejorado
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final pid = _selectedProperty?.propertyId;
                    if (pid != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PropertyDetailPage(propertyId: pid),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: AppTheme.blackColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    S.of(context).viewMoreDetails,
                    style: const TextStyle(
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

  Widget _buildPropertyImage(String urlRaw) {
    final url = AppConfig.sanitizeUrl(urlRaw);
    final placeholder = Container(
      color: AppTheme.grayColor.withValues(alpha: 0.3),
      alignment: Alignment.center,
      child: const Icon(Icons.home, size: 40, color: AppTheme.grayColor),
    );

    if (url.isEmpty) return placeholder;
    final isNetwork = url.startsWith('http://') || url.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stack) => placeholder,
      );
    }
    return Image.asset(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => placeholder,
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
  final int? propertyId;
  const PropertyInfo({
    required this.title,
    required this.price,
    required this.description,
    required this.imageUrl,
    this.address,
    this.features = const [],
    this.propertyId,
  });
}

enum PropertyType { house, apartment }

class _Suggestion {
  final String label;
  final double lon;
  final double lat;
  _Suggestion({required this.label, required this.lon, required this.lat});
}
