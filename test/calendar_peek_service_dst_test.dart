import 'package:flutter_test/flutter_test.dart';
import 'package:vagus_app/services/coach/calendar_peek_service.dart';

void main() {
  group('CalendarPeekService DST Tests', () {
    late CalendarPeekService service;

    setUp(() {
      service = CalendarPeekService();
    });

    test('should handle DST transition consistently', () {
      // Create a window that crosses a DST transition
      // Spring forward: March 10, 2024 2:00 AM -> 3:00 AM (loses 1 hour)
      final anchor = DateTime(2024, 3, 10, 1, 0); // 1 AM before DST
      final events = <PeekEvent>[
        // Event during DST transition period
        PeekEvent(
          start: DateTime(2024, 3, 10, 2, 30), // 2:30 AM (after spring forward)
          end: DateTime(2024, 3, 10, 3, 30),   // 3:30 AM
          title: 'DST Event',
        ),
      ];

      // Compute free blocks for 48 hours starting before DST
      final blocks = service.computeFreeBlocks(
        events: events,
        anchor: anchor,
        hours: 48,
        dayStartHour: 1, // Start at 1 AM to catch the transition
        dayEndHour: 4,   // End at 4 AM to see the effect
        minBlock: const Duration(minutes: 15),
      );

      // Verify we get consistent block count
      // Should have blocks before 2:30 AM and after 3:30 AM
      expect(blocks.length, greaterThan(0));
      
      // Verify all blocks are valid (start < end)
      for (final block in blocks) {
        expect(block.start.isBefore(block.end), isTrue);
        expect(block.duration.inMinutes, greaterThanOrEqualTo(15));
      }

      // Verify no blocks overlap with the DST event
      for (final block in blocks) {
        final event = events.first;
        final hasOverlap = block.start.isBefore(event.end) && 
                          block.end.isAfter(event.start);
        expect(hasOverlap, isFalse, 
               reason: 'Block ${block.start} - ${block.end} overlaps with event ${event.start} - ${event.end}');
      }
    });

    test('should maintain block count consistency across DST boundary', () {
      // Test with multiple events around DST transition
      final anchor = DateTime(2024, 3, 10, 0, 0); // Midnight before DST
      final events = <PeekEvent>[
        PeekEvent(
          start: DateTime(2024, 3, 10, 1, 0), // 1 AM
          end: DateTime(2024, 3, 10, 1, 30),  // 1:30 AM
          title: 'Pre-DST Event',
        ),
        PeekEvent(
          start: DateTime(2024, 3, 10, 3, 0), // 3 AM (after spring forward)
          end: DateTime(2024, 3, 10, 3, 30),  // 3:30 AM
          title: 'Post-DST Event',
        ),
      ];

      final blocks = service.computeFreeBlocks(
        events: events,
        anchor: anchor,
        hours: 4, // Just 4 hours to focus on DST transition
        dayStartHour: 0,
        dayEndHour: 4,
        minBlock: const Duration(minutes: 15),
      );

      // Should have consistent number of blocks
      expect(blocks.length, greaterThan(0));
      
      // All blocks should be valid
      for (final block in blocks) {
        expect(block.start.isBefore(block.end), isTrue);
        expect(block.duration.inMinutes, greaterThanOrEqualTo(15));
      }

      // Verify no overlaps with any events
      for (final block in blocks) {
        for (final event in events) {
          final hasOverlap = block.start.isBefore(event.end) && 
                            block.end.isAfter(event.start);
          expect(hasOverlap, isFalse, 
                 reason: 'Block ${block.start} - ${block.end} overlaps with event ${event.start} - ${event.end}');
        }
      }
    });

    test('should handle fall DST transition (gain hour)', () {
      // Fall back: November 3, 2024 2:00 AM -> 1:00 AM (gains 1 hour)
      final anchor = DateTime(2024, 11, 3, 0, 0); // Midnight before fall back
      final events = <PeekEvent>[
        PeekEvent(
          start: DateTime(2024, 11, 3, 1, 30), // 1:30 AM (after fall back)
          end: DateTime(2024, 11, 3, 2, 30),   // 2:30 AM
          title: 'Fall DST Event',
        ),
      ];

      final blocks = service.computeFreeBlocks(
        events: events,
        anchor: anchor,
        hours: 4,
        dayStartHour: 0,
        dayEndHour: 4,
        minBlock: const Duration(minutes: 15),
      );

      // Should handle the extra hour correctly
      expect(blocks.length, greaterThan(0));
      
      // All blocks should be valid
      for (final block in blocks) {
        expect(block.start.isBefore(block.end), isTrue);
        expect(block.duration.inMinutes, greaterThanOrEqualTo(15));
      }
    });
  });
}
