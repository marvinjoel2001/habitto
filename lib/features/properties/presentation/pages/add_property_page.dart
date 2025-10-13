import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/step_progress_indicator.dart';

class AddPropertyPage extends StatefulWidget {
  const AddPropertyPage({Key? key}) : super(key: key);

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Controladores para los formularios
  final _propertyTypeController = TextEditingController();
  final _bedroomsController = TextEditingController(text: '3');
  final _bathroomsController = TextEditingController(text: '2');
  final _areaController = TextEditingController();

  String _selectedPropertyType = 'Casa';
  int _bedrooms = 3;
  int _bathrooms = 2;

  @override
  void dispose() {
    _propertyTypeController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _areaController.dispose();
    _pageController.dispose();
    super.dispose();
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
      // Guardar propiedad
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

  void _saveProperty() {
    // Aquí iría la lógica para guardar la propiedad
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
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
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPropertyType,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                    items: ['Casa', 'Departamento', 'Oficina', 'Local Comercial'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
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
            'Baños',
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
          // Reemplazar el container central por glass
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
            'Área (m²)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _areaController,
            hintText: 'Ej: 120',
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Paso 2: Detalles adicionales',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Text('Aquí irían más campos como precio, descripción, etc.'),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Paso 3: Ubicación',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Text('Aquí iría el mapa y selección de ubicación'),
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
              onPressed: _nextStep,
              backgroundColor: const Color(0xFF00FF00),
              textColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
