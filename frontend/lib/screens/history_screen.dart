import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/journey_provider.dart';
import '../models/journey.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showClearConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Clear History?',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to delete all past journey records? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: GoogleFonts.manrope(color: theme.textTheme.bodySmall?.color)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(journeyProvider.notifier).clearHistory();
            },
            child: Text('CLEAR ALL', style: GoogleFonts.manrope(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final journeysAsync = ref.watch(filteredHistoryProvider);
    final stats = ref.watch(journeyStatsProvider);
    final currentFilter = ref.watch(journeyFilterProvider); // This is ValueNotifier<JourneyType>

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ACTIVITY LOGS Title
                  Text(
                    'ACTIVITY LOGS',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // History subtitle
                  Text(
                    'History',
                    style: GoogleFonts.manrope(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: theme.textTheme.displayLarge?.color,
                    ),
                  ),
                ],
              ),
            ),

            // Search and Filter Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search journeys...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Filter Tabs
                  ValueListenableBuilder<JourneyType>(
                    valueListenable: currentFilter,
                    builder: (context, filterValue, child) {
                      return Row(
                        children: [
                          _buildFilterChip('All', JourneyType.all, currentFilter, stats['total'] ?? 0),
                          const SizedBox(width: 8),
                          _buildFilterChip('Secure', JourneyType.secure, currentFilter, stats['secure'] ?? 0, Colors.green),
                          const SizedBox(width: 8),
                          _buildFilterChip('Alerts', JourneyType.alert, currentFilter, stats['alerts'] ?? 0, Colors.orange),
                          const Spacer(),
                          // Filter icon
                          IconButton(
                            icon: Icon(
                              Icons.filter_list,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                              size: 20,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Journey List with real-time updates
            Expanded(
              child: journeysAsync.when(
                data: (journeys) {
                  // Filter by search text
                  final searchText = _searchController.text.toLowerCase();
                  final filteredJourneys = searchText.isEmpty
                      ? journeys
                      : journeys.where((j) =>
                          j.origin.toLowerCase().contains(searchText) ||
                          j.destination.toLowerCase().contains(searchText)).toList();

                  if (filteredJourneys.isEmpty) {
                    return _buildEmptyState(theme);
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(historyProvider);
                      await ref.read(historyProvider.future);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: filteredJourneys.length + 1, // +1 for summary
                      itemBuilder: (context, index) {
                        if (index == filteredJourneys.length) {
                          // Activity Summary Card at bottom
                          return _buildActivitySummary(theme, stats);
                        }
                        final journey = filteredJourneys[index];
                        return _buildTimelineCard(context, journey, index == filteredJourneys.length - 1);
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.redAccent.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading history',
                        style: GoogleFonts.manrope(color: theme.colorScheme.onSurface.withValues(alpha: 0.38)),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.invalidate(historyProvider),
                        child: Text('Retry', style: GoogleFonts.manrope(color: theme.primaryColor)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, JourneyType type, ValueNotifier<JourneyType> filterNotifier, int count, [Color? accentColor]) {
    final isSelected = filterNotifier.value == type;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        filterNotifier.value = type;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (accentColor?.withValues(alpha: 0.15) ?? theme.primaryColor.withValues(alpha: 0.15))
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected && accentColor != null
                ? accentColor.withValues(alpha: 0.3)
                : theme.dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? (accentColor ?? theme.primaryColor)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.54),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (accentColor?.withValues(alpha: 0.2) ?? theme.primaryColor.withValues(alpha: 0.2))
                      : theme.dividerColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? (accentColor ?? theme.primaryColor)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route_outlined,
            size: 80,
            color: theme.dividerColor.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 20),
          Text(
            'No journeys found',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your journey history will appear here',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context, Journey journey, bool isLast) {
    final theme = Theme.of(context);

    // Determine status styling
    Color statusColor;
    String statusText;
    if (journey.hasAlert) {
      statusColor = Colors.orange;
      statusText = 'ALERT';
    } else if (journey.isSuccessful) {
      statusColor = const Color(0xFF00C853);
      statusText = 'SUCCESSFUL';
    } else {
      statusColor = Colors.blue;
      statusText = journey.status.toUpperCase();
    }

    // Format date
    final now = DateTime.now();
    final isToday = journey.createdAt.year == now.year &&
        journey.createdAt.month == now.month &&
        journey.createdAt.day == now.day;
    final isYesterday = journey.createdAt.year == now.year &&
        journey.createdAt.month == now.month &&
        journey.createdAt.day == now.day - 1;

    String dateText;
    if (isToday) {
      dateText = 'Today, ${DateFormat('HH:mm').format(journey.createdAt)}';
    } else if (isYesterday) {
      dateText = 'Yesterday, ${DateFormat('HH:mm').format(journey.createdAt)}';
    } else {
      dateText = DateFormat('MMM dd, HH:mm').format(journey.createdAt);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          Column(
            children: [
              // Top dot
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              // Line
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          statusColor.withValues(alpha: 0.5),
                          theme.dividerColor.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with date and status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateText,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.54),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // FROM location
                  _buildLocationRow(
                    context,
                    icon: Icons.trip_origin,
                    iconColor: theme.primaryColor,
                    label: 'FROM',
                    location: journey.origin,
                    isFirst: true,
                  ),
                  const SizedBox(height: 12),
                  // TO location
                  _buildLocationRow(
                    context,
                    icon: Icons.location_on,
                    iconColor: const Color(0xFFF25C05),
                    label: 'TO',
                    location: journey.destination,
                    isFirst: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String location,
    required bool isFirst,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                location,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySummary(ThemeData theme, Map<String, dynamic> stats) {
    final arrivalRate = stats['arrivalRate'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(28, 16, 0, 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // Title with icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 18,
                color: theme.primaryColor.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 8),
              Text(
                'Activity Summary',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Big percentage
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.primaryColor.withValues(alpha: 0.3),
                  theme.primaryColor.withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(
                color: theme.primaryColor.withValues(alpha: 0.3),
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                '$arrivalRate%',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ARRIVAL RATE',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn('Total', stats['total']?.toString() ?? '0', theme),
              _buildDivider(theme),
              _buildStatColumn('Secure', stats['secure']?.toString() ?? '0', theme, Colors.green),
              _buildDivider(theme),
              _buildStatColumn('Alerts', stats['alerts']?.toString() ?? '0', theme, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, ThemeData theme, [Color? accentColor]) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: accentColor ?? theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Container(
      height: 30,
      width: 1,
      color: theme.dividerColor.withValues(alpha: 0.2),
    );
  }
}
