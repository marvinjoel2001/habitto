import 'package:flutter/material.dart';
import '../../../properties/data/services/property_service.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../../generated/l10n.dart';

class AgentPortfolioPage extends StatefulWidget {
  const AgentPortfolioPage({super.key});

  @override
  State<AgentPortfolioPage> createState() => _AgentPortfolioPageState();
}

class _AgentPortfolioPageState extends State<AgentPortfolioPage> {
  final PropertyService _service = PropertyService();
  List<Property> _items = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    final resp = await _service.getAgentProperties();
    if (resp['success'] == true && resp['data'] != null) {
      final props = List<Property>.from((resp['data']['properties'] as List));
      setState(() {
        _items = props;
        _loading = false;
      });
    } else {
      setState(() {
        _error = resp['error'] ?? S.of(context).loadPortfolioError;
        _loading = false;
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
        title: Text(S.of(context).portfolioTitle,
            style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh, color: Colors.black))
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Added bottom padding
        child: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/add-property')
              .then((_) => _load()),
          backgroundColor: AppTheme.primaryColor,
          child: const Icon(Icons.add),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Text(_error,
                      style: const TextStyle(color: Colors.black54)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: 120), // Added bottom padding for scroll
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final p = _items[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(p.address),
                          subtitle: Text(S.of(context).portfolioItemSubtitle(
                              p.price.toStringAsFixed(0),
                              p.size.toInt().toString())),
                          trailing: Icon(
                              p.isActive ? Icons.toggle_on : Icons.toggle_off,
                              color: p.isActive ? Colors.green : Colors.grey),
                          onTap: () {},
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
