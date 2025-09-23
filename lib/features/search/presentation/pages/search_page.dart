import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../shared/theme/app_theme.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  PropertyInfo? _selectedProperty;
  bool _isLoading = true;

  // Datos de ejemplo de propiedades
  final List<PropertyData> _properties = [
    PropertyData(
      id: '1',
      title: 'Depto Centro',
      price: '2.500 BOB / mes',
      description: 'Amplio departamento de 2 habitaciones en el corazón de la ciudad.',
      location: const LatLng(-17.7833, -63.1821),
      type: PropertyType.apartment,
      imageUrl: 'assets/images/casa1.jpg',
    ),
    PropertyData(
      id: '2',
      title: 'Casa Equipetrol',
      price: '3.200 BOB / mes',
      description: 'Casa moderna con jardín en zona residencial.',
      location: const LatLng(-17.7700, -63.1500),
      type: PropertyType.house,
      imageUrl: 'assets/images/casa2.jpg',
    ),
    PropertyData(
      id: '3',
      title: 'Depto Norte',
      price: '1.800 BOB / mes',
      description: 'Departamento acogedor cerca del centro comercial.',
      location: const LatLng(-17.7600, -63.1700),
      type: PropertyType.apartment,
      imageUrl: 'assets/images/casa3.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });
        
        _createMarkers();
      } else {
        // Ubicación por defecto (Santa Cruz, Bolivia)
        setState(() {
          _currentPosition = Position(
            latitude: -17.7833,
            longitude: -63.1821,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
          _isLoading = false;
        });
        _createMarkers();
      }
    } catch (e) {
      setState(() {
        _currentPosition = Position(
          latitude: -17.7833,
          longitude: -63.1821,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        _isLoading = false;
      });
      _createMarkers();
    }
  }

  void _createMarkers() {
    Set<Marker> markers = {};

    // Marcador de ubicación actual
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Mi ubicación'),
        ),
      );
    }

    // Marcadores de propiedades
    for (PropertyData property in _properties) {
      markers.add(
        Marker(
          markerId: MarkerId(property.id),
          position: property.location,
          icon: property.type == PropertyType.house
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          onTap: () => _onMarkerTapped(property),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _onMarkerTapped(PropertyData property) {
    setState(() {
      _selectedProperty = PropertyInfo(
        title: property.title,
        price: property.price,
        description: property.description,
        imageUrl: property.imageUrl,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                      ),
                      const Expanded(
                        child: Text(
                          'Búsqueda',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Barra de búsqueda
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Busca por zona, precio o tipo',
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Filtros
            Container(
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
            ),
            
            // Mapa
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : GoogleMap(
                              onMapCreated: (GoogleMapController controller) {
                                _mapController = controller;
                                // Aplicar estilo verde al mapa
                                _mapController?.setMapStyle(_mapStyle);
                              },
                              initialCameraPosition: CameraPosition(
                                target: _currentPosition != null
                                    ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                                    : const LatLng(-17.7833, -63.1821),
                                zoom: 14,
                              ),
                              markers: _markers,
                              myLocationEnabled: true,
                              myLocationButtonEnabled: false,
                            ),
                      
                      // Botón de ubicación personalizado
                      Positioned(
                        bottom: _selectedProperty != null ? 200 : 20,
                        right: 20,
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: AppTheme.primaryColor,
                          onPressed: () {
                            if (_currentPosition != null && _mapController != null) {
                              _mapController!.animateCamera(
                                CameraUpdate.newLatLng(
                                  LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                ),
                              );
                            }
                          },
                          child: const Icon(Icons.my_location, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Card de propiedad seleccionada
            if (_selectedProperty != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
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
                          child: Container(
                            width: 60,
                            height: 60,
                            color: AppTheme.grayColor,
                            child: Image.asset(
                              _selectedProperty!.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.home, size: 30);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedProperty!.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _selectedProperty!.price,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedProperty = null;
                            });
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedProperty!.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navegar a detalles de la propiedad
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Ver Más',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.black,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  // Estilo del mapa con filtro verde
  static const String _mapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#e8f5e8"
        }
      ]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#2d5a2d"
        }
      ]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [
        {
          "color": "#ffffff"
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#a8e6cf"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#ffffff"
        }
      ]
    }
  ]
  ''';
}

// Modelos de datos
class PropertyData {
  final String id;
  final String title;
  final String price;
  final String description;
  final LatLng location;
  final PropertyType type;
  final String imageUrl;

  PropertyData({
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

  PropertyInfo({
    required this.title,
    required this.price,
    required this.description,
    required this.imageUrl,
  });
}

enum PropertyType { house, apartment }