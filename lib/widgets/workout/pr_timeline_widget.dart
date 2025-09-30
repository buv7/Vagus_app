import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/workout/analytics_models.dart';
import '../../utils/locale_helper.dart';

/// Personal Records timeline widget
///
/// Displays achievement timeline with:
/// - Chronological PR list
/// - PR type badges (weight, volume, reps, 1RM)
/// - Celebration animations
/// - Filterable by exercise or type
class PRTimelineWidget extends StatefulWidget {
  final List<PRRecord> records;
  final Function(PRRecord)? onRecordTap;
  final bool showFilters;

  const PRTimelineWidget({
    Key? key,
    required this.records,
    this.onRecordTap,
    this.showFilters = true,
  }) : super(key: key);

  @override
  State<PRTimelineWidget> createState() => _PRTimelineWidgetState();
}

class _PRTimelineWidgetState extends State<PRTimelineWidget> {
  String? _filterType;
  String? _searchQuery;

  @override
  Widget build(BuildContext context) {
    final filteredRecords = _getFilteredRecords();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocaleHelper.t(context, 'personal_records'),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${filteredRecords.length} ${LocaleHelper.t(context, 'achievements')}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                    Icon(Icons.emoji_events, color: Colors.amber[700], size: 32),
                  ],
                ),

                // Filters
                if (widget.showFilters) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Type filter
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: _filterType,
                          decoration: InputDecoration(
                            labelText: LocaleHelper.t(context, 'filter_by_type'),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(LocaleHelper.t(context, 'all_types')),
                            ),
                            DropdownMenuItem(
                              value: 'weight',
                              child: Text(LocaleHelper.t(context, 'weight_pr')),
                            ),
                            DropdownMenuItem(
                              value: 'volume',
                              child: Text(LocaleHelper.t(context, 'volume_pr')),
                            ),
                            DropdownMenuItem(
                              value: 'reps',
                              child: Text(LocaleHelper.t(context, 'reps_pr')),
                            ),
                            DropdownMenuItem(
                              value: '1rm',
                              child: Text(LocaleHelper.t(context, '1rm_pr')),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filterType = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Search
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: LocaleHelper.t(context, 'search_exercise'),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            suffixIcon: const Icon(Icons.search),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          // Timeline
          if (filteredRecords.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      LocaleHelper.t(context, 'no_records_found'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredRecords.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final record = filteredRecords[index];
                return _buildTimelineItem(record);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(PRRecord record) {
    final typeColor = _getPRTypeColor(record.type);
    final typeIcon = _getPRTypeIcon(record.type);

    return InkWell(
      onTap: widget.onRecordTap != null ? () => widget.onRecordTap!(record) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Date timeline marker
            SizedBox(
              width: 60,
              child: Column(
                children: [
                  Text(
                    DateFormat('MMM').format(record.achievedDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                  ),
                  Text(
                    DateFormat('d').format(record.achievedDate),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                        ),
                  ),
                  Text(
                    DateFormat('y').format(record.achievedDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            ),

            // Timeline line
            Container(
              width: 2,
              height: 60,
              color: Colors.grey[300],
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),

            // PR badge and details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PR type badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: typeColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(typeIcon, size: 14, color: typeColor),
                            const SizedBox(width: 4),
                            Text(
                              record.type.toUpperCase(),
                              style: TextStyle(
                                color: typeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Exercise name
                  Text(
                    record.exerciseName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),

                  // Value
                  Text(
                    record.displayValue,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: typeColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  // Description
                  if (record.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      record.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ],
              ),
            ),

            // Trophy icon
            Icon(Icons.emoji_events, color: Colors.amber[700], size: 28),
          ],
        ),
      ),
    );
  }

  List<PRRecord> _getFilteredRecords() {
    var records = widget.records;

    // Filter by type
    if (_filterType != null) {
      records = records.where((r) => r.type == _filterType).toList();
    }

    // Filter by search query
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      records = records
          .where((r) => r.exerciseName.toLowerCase().contains(_searchQuery!))
          .toList();
    }

    return records;
  }

  Color _getPRTypeColor(String type) {
    switch (type) {
      case 'weight':
        return Colors.blue;
      case 'volume':
        return Colors.purple;
      case 'reps':
        return Colors.green;
      case '1rm':
        return Colors.orange;
      case 'tonnage':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getPRTypeIcon(String type) {
    switch (type) {
      case 'weight':
        return Icons.fitness_center;
      case 'volume':
        return Icons.bar_chart;
      case 'reps':
        return Icons.repeat;
      case '1rm':
        return Icons.trending_up;
      case 'tonnage':
        return Icons.local_shipping;
      default:
        return Icons.star;
    }
  }
}
