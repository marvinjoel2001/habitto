import 'package:flutter/material.dart';
import 'package:habitto/core/services/api_service.dart';
import 'package:habitto/features/properties/data/services/property_service.dart';
import 'package:habitto/features/properties/data/services/photo_service.dart';
import 'package:habitto/features/properties/domain/entities/property.dart'
    as domain;
import 'package:habitto/features/properties/domain/entities/photo.dart'
    as domain_photo;
import 'package:habitto/config/app_config.dart';
import 'package:habitto/shared/theme/app_theme.dart';

class PropertyDetailPage extends StatefulWidget {
  final int propertyId;
  const PropertyDetailPage({super.key, required this.propertyId});
  @override
  State<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage> {
  late final ApiService _api;
  late final PropertyService _propertyService;
  late final PhotoService _photoService;
  domain.Property? _property;
  List<String> _photos = [];
  int _page = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _api = ApiService();
    _propertyService = PropertyService(apiService: _api);
    _photoService = PhotoService(_api);
    _load();
  }

  Future<void> _load() async {
    final res = await _propertyService.getPropertyById(widget.propertyId);
    if (res['success'] == true && res['data'] != null) {
      _property = res['data'] as domain.Property;
    }
    final pres = await _photoService.getPropertyPhotos(widget.propertyId);
    if (pres['success'] == true && pres['data'] != null) {
      final photos = (pres['data']['photos'] as List<domain_photo.Photo>?);
      _photos = List<String>.from((photos ?? [])
          .map((p) => AppConfig.sanitizeUrl(p.image))
          .where((u) => u.isNotEmpty)
          .toSet()
          .toList());
    }
    final mp = _property?.mainPhoto;
    if (mp != null && mp.isNotEmpty) {
      final s = AppConfig.sanitizeUrl(mp);
      if (!_photos.contains(s)) _photos.insert(0, s);
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _property == null
                ? const Center(child: Text('Propiedad no encontrada'))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: AppTheme.whiteColor),
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.share_outlined,
                                color: AppTheme.whiteColor),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.favorite_outline,
                                color: AppTheme.whiteColor),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 220,
                          child: PageView.builder(
                            itemCount: _photos.isNotEmpty ? _photos.length : 1,
                            onPageChanged: (i) => setState(() => _page = i),
                            itemBuilder: (_, i) {
                              if (_photos.isEmpty) {
                                return _placeholderImage();
                              }
                              return _networkImage(_photos[i]);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 54,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (_, i) {
                            final active = i == _page;
                            return Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: active
                                      ? cs.primary
                                      : Colors.grey.shade300,
                                  width: active ? 2 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: _photos.isEmpty
                                    ? _placeholderImage()
                                    : _networkImage(_photos[i],
                                        fit: BoxFit.cover),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemCount: _photos.isNotEmpty ? _photos.length : 5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _property!.address.isNotEmpty
                            ? _property!.address
                            : 'Propiedad',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.whiteColor),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _property!.price > 0
                            ? 'Bs. ${_property!.price.toStringAsFixed(0)}/mes'
                            : '—',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.whiteColor),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _tag('${_property!.bedrooms} Dorm.'),
                          const SizedBox(width: 8),
                          _tag('${_property!.bathrooms} Baños'),
                          const SizedBox(width: 8),
                          _tag('${_property!.size.toStringAsFixed(0)} m²'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 8)),
                          ],
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Comodidades',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: _property!.amenities
                                  .map((_) => _amenityChip())
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                              child: _primaryButton('Swipe para Match',
                                  cs.primary, Colors.black, () {})),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                              child:
                                  _secondaryButton('Solicitar Roomie', () {})),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _secondaryButton('Agendar Vista', () {})),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('Reseñas',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      _reviewTile('Juan Perez',
                          '¡El departamento es increíble! Muy bien ubicado y con todas las comodidades. 100% recomendado.'),
                      const SizedBox(height: 10),
                      _reviewTile('María García',
                          'Buena ubicación, aunque un poco ruidoso por la noche. El anfitrión fue muy amable.'),
                    ],
                  ),
      ),
    );
  }

  Widget _networkImage(String url, {BoxFit fit = BoxFit.cover}) {
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stack) => _placeholderImage(),
    );
  }

  Widget _placeholderImage() {
    return Container(
        color: Colors.grey.shade300,
        alignment: Alignment.center,
        child: const Icon(Icons.image, size: 36));
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  Widget _amenityChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: const Row(children: [
        Icon(Icons.check_circle, size: 16),
        SizedBox(width: 6),
        Text('Amenidad')
      ]),
    );
  }

  Widget _primaryButton(String label, Color bg, Color fg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: bg.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 8))
          ],
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _secondaryButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: const TextStyle(
                color: AppTheme.blackColor, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _reviewTile(String name, String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 6))
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 18, backgroundColor: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Row(children: [
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  Icon(Icons.star_half, size: 16, color: Colors.amber)
                ]),
                const SizedBox(height: 6),
                Text(text,
                    style: TextStyle(color: Colors.black.withOpacity(0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
