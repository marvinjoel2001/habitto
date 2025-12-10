import 'package:flutter/material.dart';
import '../../../matching/data/services/matching_service.dart';
import '../../../../shared/theme/app_theme.dart';

class AgentLeadsPage extends StatefulWidget {
  const AgentLeadsPage({super.key});

  @override
  State<AgentLeadsPage> createState() => _AgentLeadsPageState();
}

class _AgentLeadsPageState extends State<AgentLeadsPage> {
  final MatchingService _matchingService = MatchingService();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    final resp = await _matchingService.getPendingMatchRequests();
    if (resp['success'] == true && resp['data'] != null) {
      final list = List<Map<String, dynamic>>.from((resp['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map)));
      list.sort((a, b) {
        final sa = ((a['match'] ?? {})['score'] ?? 0).toString();
        final sb = ((b['match'] ?? {})['score'] ?? 0).toString();
        final da = double.tryParse(sa) ?? 0;
        final db = double.tryParse(sb) ?? 0;
        return db.compareTo(da);
      });
      setState(() {
        _items = list;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = resp['error'] ?? 'Error cargando leads';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Removed back button
        title: const Text('Solicitudes',
            style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh, color: Colors.black))
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_search_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error.isNotEmpty
                            ? _error
                            : 'No tienes nuevas solicitudes',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Las nuevas solicitudes aparecerán aquí',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _load,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Actualizar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final it = _items[i];
                      final match =
                          Map<String, dynamic>.from((it['match'] ?? {}) as Map);
                      final prop = Map<String, dynamic>.from(
                          (it['property'] ?? {}) as Map);
                      final score = match['score'] ?? 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                                radius: 20, child: Icon(Icons.person)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${prop['address'] ?? 'Propiedad'}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text('Score: $score%',
                                      style: const TextStyle(
                                          color: Colors.black54)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: Color(0xFF9CA3AF))
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
