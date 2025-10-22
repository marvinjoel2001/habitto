import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
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
  const AddPropertyPage({Key? key}) : super(key: key);

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

  bool _isLoading = false;
  bool _isLoadingData = true;

  String _selectedPropertyType = 'casa';
  int _bedrooms = 3;
  int _bathrooms = 2;
  List<int> _selectedAmenityIds = [];
  List<int> _selectedPaymentMethodIds = [];
  
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
    _loadInitialData();
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
      backgroundColor: Colors.white,
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(),
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
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 80 + MediaQuery.of(context).padding.top,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.85),
            Theme.of(context).colorScheme.primary,
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
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  'Detalles de la Propiedad',
                  style: TextStyle(
                    color: Colors.white,
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
                    color: Colors.white,
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
            style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 32),
          const Text(
            'Tipo de Propiedad',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.whiteColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.whiteColor.withOpacity(0.3), width: 1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPropertyType,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                    dropdownColor: Colors.white,
                    items: _propertyTypeMapping.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.value, // API value (casa, departamento, etc.)
                        child: Text(
                          entry.key, // Display value (Casa, Departamento, etc.)
                          style: const TextStyle(color: Colors.black),
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
          const SizedBox(height: 24),
          const Text(
            'Habitaciones',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (_bedrooms > 1) {
                    setState(() {
                      _bedrooms--;
                      _bedroomsController.text = _bedrooms.toString();
                    });
                  }
                },
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.grey,
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F8F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _bedrooms.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _bedrooms++;
                    _bedroomsController.text = _bedrooms.toString();
                  });
                },
                icon: const Icon(Icons.add_circle_outline),
                color: const Color(0xFFA8E6CE),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Baños',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (_bathrooms > 1) {
                    setState(() {
                      _bathrooms--;
                      _bathroomsController.text = _bathrooms.toString();
                    });
                  }
                },
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.grey,
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: Text(
                        _bathrooms.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _bathrooms++;
                    _bathroomsController.text = _bathrooms.toString();
                  });
                },
                icon: const Icon(Icons.add_circle_outline),
                color: Theme.of(context).colorScheme.primary,
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
          const Text(
            'Detalles adicionales de la propiedad',
            style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 32),
          const Text(
            'Precio de Alquiler (COP)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _priceController,
            hintText: 'Ej: 1500000',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          const Text(
            'Garantía (COP)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableAmenities.map((amenity) {
              final isSelected = _selectedAmenityIds.contains(amenity.id);
              return FilterChip(
                label: Text(amenity.name),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedAmenityIds.add(amenity.id);
                    } else {
                      _selectedAmenityIds.remove(amenity.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Métodos de Pago Aceptados',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availablePaymentMethods.map((method) {
              final isSelected = _selectedPaymentMethodIds.contains(method.id);
              return FilterChip(
                label: Text(method.name),
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

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ubicación y disponibilidad de la propiedad',
            style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 32),
          const Text(
            'Dirección *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _addressController,
            hintText: 'Ej: Calle Principal 123, Zona Sur, La Paz',
          ),
          const SizedBox(height: 24),
          const Text(
            'Latitud',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _latitudeController,
            hintText: 'Ej: -16.5000 (opcional)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          const Text(
            'Longitud',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _longitudeController,
            hintText: 'Ej: -68.1500 (opcional)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          const Text(
            'Fecha de Disponibilidad',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
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
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFA8E6CE)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Anterior',
                  style: TextStyle(
                    color: Color(0xFFA8E6CE),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: CustomButton(
              text: _currentStep == 2 ? 'Finalizar' : 'Siguiente',
              onPressed: _isLoading ? null : _nextStep,
              backgroundColor: const Color(0xFF00FF00),
              textColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
