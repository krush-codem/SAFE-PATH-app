import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/journey_provider.dart';
import '../providers/repository_providers.dart';

class LocationPickerScreen extends ConsumerStatefulWidget {
  final bool isOrigin;
  
  const LocationPickerScreen({super.key, this.isOrigin = false});

  @override
  ConsumerState<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredPlaces = [];
  bool _isLoading = false;
  late bool _isOriginSelected;

  @override
  void initState() {
    super.initState();
    _isOriginSelected = widget.isOrigin;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() async {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      if (mounted) setState(() { _filteredPlaces = []; });
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final results = await ref.read(placeRepositoryProvider).getAutocomplete(query);
      if (mounted) {
        setState(() {
          _filteredPlaces = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final journeyState = ref.watch(journeyProvider);
    final String currentOrigin = journeyState.origin ?? 'Current Location';
    final String currentDest = journeyState.destination ?? 'Where to?';

    return Scaffold(
      backgroundColor: const Color(0xFF0F1724),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Plan your trip', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Row(
                children: [
                   _RoundChip(icon: Icons.access_time, label: 'Pick-up now'),
                   SizedBox(width: 12),
                   _RoundChip(icon: Icons.person, label: 'For me'),
                ],
              ),
              const SizedBox(height: 24),
              
              // Input fields with switching logic
              Row(
                children: [
                   Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2633),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05), 
                          width: 1
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          _buildSearchField(
                            isActive: _isOriginSelected, 
                            label: 'Starting point', 
                            value: currentOrigin, 
                            icon: Icons.my_location,
                            color: Colors.white,
                            onTap: () {
                              if (!_isOriginSelected) {
                                setState(() {
                                  _isOriginSelected = true;
                                  _searchController.clear();
                                });
                              }
                            }
                          ),
                          const Divider(height: 1, color: Colors.white12),
                          _buildSearchField(
                            isActive: !_isOriginSelected, 
                            label: 'Where to?', 
                            value: currentDest, 
                            icon: Icons.stop_circle_outlined,
                            color: Colors.blueAccent,
                            onTap: () {
                              if (_isOriginSelected) {
                                setState(() {
                                  _isOriginSelected = false;
                                  _searchController.clear();
                                });
                              }
                            }
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const CircleAvatar(
                    backgroundColor: Color(0xFF1E2633), 
                    child: Icon(Icons.add, color: Colors.white)
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // List of dynamic places
              Expanded(
                child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                : _filteredPlaces.isEmpty && _searchController.text.isNotEmpty
                ? _buildEmptyState()
                : ListView.builder(
                  itemCount: _filteredPlaces.length,
                  itemBuilder: (context, index) {
                    final place = _filteredPlaces[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on_outlined, color: Colors.white38),
                      title: Text(place['title'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      subtitle: Text(place['subtitle'], style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      onTap: () {
                         final notifier = ref.read(journeyProvider.notifier);
                         if (_isOriginSelected) {
                           notifier.setRouting(place['title'], journeyState.destination ?? '');
                         } else {
                           notifier.setRouting(journeyState.origin ?? 'Current Location', place['title']);
                         }
                         
                         if (ref.read(journeyProvider).origin != null && ref.read(journeyProvider).destination != null) {
                            context.pop();
                         }
                      },
                    );
                  },
                ),
              ),
              
              const Divider(color: Colors.white12),
              ListTile(
                leading: const Icon(Icons.map_outlined, color: Colors.blueAccent),
                title: const Text('Set location on map', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                onTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Map selection coming soon...')));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 40.0),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.white10),
            const SizedBox(height: 16),
            const Text(
              'No results found',
              style: TextStyle(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try searching for "Bhubaneswar", "AIIMS", or "SUM"',
              style: TextStyle(color: Colors.white12, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField({
    required bool isActive,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? color : Colors.white38),
            const SizedBox(width: 16),
            Expanded(
              child: isActive 
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: label, 
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 14), 
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  )
                : Text(
                    value, 
                    style: TextStyle(
                      color: value == label ? Colors.white24 : Colors.white70, 
                      fontSize: 14
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RoundChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF1E2633), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white38),
        ],
      ),
    );
  }
}
