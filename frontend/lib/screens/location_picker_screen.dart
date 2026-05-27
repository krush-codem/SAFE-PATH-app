import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/journey_provider.dart';
import '../providers/repository_providers.dart';
import '../routing/app_router.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journeyState = ref.watch(journeyProvider);
    final String currentOrigin = journeyState.origin ?? 'Current Location';
    final String currentDest = journeyState.destination ?? 'Where to?';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Plan your trip', style: theme.textTheme.titleLarge),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                children: [
                   _RoundChip(icon: Icons.access_time, label: 'Pick-up now', color: colorScheme.primary),
                   const SizedBox(width: 12),
                   _RoundChip(icon: Icons.person, label: 'For me', color: colorScheme.onSurface.withValues(alpha: 0.5)),
                ],
              ),
              const SizedBox(height: 24),
              
              // Input fields with switching logic
              Row(
                children: [
                   Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            _buildSearchField(
                              context,
                              isActive: _isOriginSelected, 
                              label: 'Starting point', 
                              value: currentOrigin, 
                              icon: Icons.my_location,
                              color: colorScheme.onSurface,
                              onTap: () {
                                if (!_isOriginSelected) {
                                  setState(() {
                                    _isOriginSelected = true;
                                    _searchController.clear();
                                  });
                                }
                              }
                            ),
                            const Divider(),
                            _buildSearchField(
                              context,
                              isActive: !_isOriginSelected, 
                              label: 'Where to?', 
                              value: currentDest, 
                              icon: Icons.stop_circle_outlined,
                              color: AppColors.primaryBlue,
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
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // List of dynamic places
              Expanded(
                child: _isLoading 
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : _filteredPlaces.isEmpty && _searchController.text.isNotEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                  itemCount: _filteredPlaces.length,
                  itemBuilder: (context, index) {
                    final place = _filteredPlaces[index];
                    return ListTile(
                      leading: Icon(Icons.location_on_outlined, color: colorScheme.onSurface.withValues(alpha: 0.38)),
                      title: Text(place['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(place['subtitle'], style: theme.textTheme.bodySmall),
                      onTap: () {
                         final notifier = ref.read(journeyProvider.notifier);
                         if (_isOriginSelected) {
                           notifier.setRouting(place['title'], journeyState.destination ?? '');
                         } else {
                           notifier.setRouting(journeyState.origin ?? 'Current Location', place['title']);
                         }
                         
                         if (ref.read(journeyProvider).origin != null && ref.read(journeyProvider).destination != null) {
                            context.go(AppRoutes.home);
                         }
                      },
                    );
                  },
                ),
              ),
              
              const Divider(),
              ListTile(
                leading: Icon(Icons.map_outlined, color: colorScheme.primary),
                title: Text('Set location on map', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
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

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40.0),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching for "Bhubaneswar", "AIIMS", or "SUM"',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.12), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(
    BuildContext context, {
    required bool isActive,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? color : theme.colorScheme.onSurface.withValues(alpha: 0.38)),
            const SizedBox(width: 16),
            Expanded(
              child: isActive 
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: label, 
                      hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.24), fontSize: 14), 
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                  )
                : Text(
                    value, 
                    style: TextStyle(
                      color: value == label ? theme.colorScheme.onSurface.withValues(alpha: 0.24) : theme.colorScheme.onSurface.withValues(alpha: 0.7), 
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
  final Color? color;

  const _RoundChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? theme.colorScheme.onSurface),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.38)),
        ],
      ),
    );
  }
}
