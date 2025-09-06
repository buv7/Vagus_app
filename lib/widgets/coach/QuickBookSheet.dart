import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/coach/calendar_quick_book_service.dart';
import '../../services/coach/calendar_peek_service.dart';
import '../../services/coach/quickbook_autoconfirm_service.dart';

class QuickBookSheet extends StatefulWidget {
  final String coachId;
  final String clientId;
  final String? conversationId;
  final String? mode; // 'reschedule' | null
  final QuickBookSlot? prefillSlot; // Pre-filled slot from parsing
  final void Function(QuickBookSlot slot)? onProposed;
  final void Function(QuickBookSlot slot)? onBooked;

  const QuickBookSheet({
    super.key,
    required this.coachId,
    required this.clientId,
    this.conversationId,
    this.mode,
    this.prefillSlot,
    this.onProposed,
    this.onBooked,
  });

  @override
  State<QuickBookSheet> createState() => _QuickBookSheetState();
}

class _QuickBookSheetState extends State<QuickBookSheet> {
  final _svc = CalendarQuickBookService();
  final _peek = CalendarPeekService();
  List<QuickBookSlot> _slots = [];
  List<PeekEvent> _events = [];
  List<PeekBlock> _free = [];
  bool _busy = true;
  String? _coachTz;
  String? _clientTz;
  
  // Guard rails for tap throttling and past-time slots
  DateTime? _lastTapTime;
  static const Duration _tapThrottle = Duration(seconds: 1);
  static const Duration _pastTimeThreshold = Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final tzCoach = await _svc.coachTimeZone(widget.coachId);
      final tzClient = await _svc.clientTimeZone(widget.clientId);
      final slots = await _svc.suggestSlots(
        coachId: widget.coachId,
        clientId: widget.clientId,
      );
      
      // Load calendar events and compute free blocks
      final now = DateTime.now();
      final events = await _peek.upcomingCoachEvents(
        coachId: widget.coachId,
        hours: 48,
      );
      final free = _peek.computeFreeBlocks(
        events: events,
        anchor: now,
        hours: 48,
      );
      
      if (!mounted) return;
      
      setState(() {
        _coachTz = tzCoach;
        _clientTz = tzClient;
        _slots = slots;
        _events = events;
        _free = free;
        _busy = false;
      });
    } catch (e) {
      print('QuickBookSheet: Error loading data - $e');
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  widget.mode == 'reschedule' ? 'Reschedule' : 'Quick Book',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            // Timezone info
            if (_coachTz != null && _clientTz != null) ...[
              Text(
                'Coach TZ: $_coachTz • Client TZ: $_clientTz',
                style: TextStyle(
                  fontSize: 12,
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.65),
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            // Loading indicator
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(12),
                child: LinearProgressIndicator(),
              ),
            
            // Content
            if (!_busy) ...[
              // Prefill slot display
              if (widget.prefillSlot != null) ...[
                _buildPrefillSlotCard(context),
                const SizedBox(height: 16),
              ],
              
              // Calendar peek strip
              if (_events.isNotEmpty || _free.isNotEmpty) ...[
                _buildPeekStrip(context),
                const SizedBox(height: 16),
              ],
              
              // Suggested slots
              if (_slots.isNotEmpty) ...[
                Text(
                  'Suggested Times',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _slots.map((slot) => _buildSlotChip(context, slot)).toList(),
                ),
                const SizedBox(height: 16),
              ],
              
              // Custom time picker
              _buildCustomPicker(context),
              
              const SizedBox(height: 8),
              
              // Tip
              Text(
                'Tip: propose 2 options for faster confirmation.',
                style: TextStyle(
                  fontSize: 12,
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.65),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSlotChip(BuildContext context, QuickBookSlot slot) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final isPastTime = slot.start.isBefore(now.add(_pastTimeThreshold));
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatSlotTime(slot.start),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: 'Propose call at ${_formatTimeForAccessibility(slot.start)}',
                hint: 'Double tap to propose this time slot to the client',
                button: true,
                child: FilledButton.tonal(
                  onPressed: isPastTime ? null : () => _proposeSlot(slot),
                  child: const Text('Propose'),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                label: 'Book and notify client for ${_formatTimeForAccessibility(slot.start)}',
                hint: 'Double tap to book this time slot and notify the client',
                button: true,
                child: FilledButton(
                  onPressed: isPastTime ? null : () => _bookSlot(slot),
                  child: const Text('Book & notify'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return StatefulBuilder(
      builder: (ctx, setLocalState) {
        DateTime chosen = DateTime.now().add(const Duration(days: 1, hours: 10));
        Duration duration = const Duration(minutes: 15);
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Custom Time',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                        initialDate: chosen,
                      );
                      if (date == null) return;
                      
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: chosen.hour, minute: chosen.minute),
                      );
                      if (time == null) return;
                      
                      setLocalState(() {
                        chosen = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    },
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(_formatSlotTime(chosen)),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: duration.inMinutes,
                    items: const [15, 20, 30, 45, 60]
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text('$m min'),
                            ))
                        .toList(),
                    onChanged: (v) => setLocalState(() {
                      duration = Duration(minutes: v ?? 15);
                    }),
                  ),
                  const Spacer(),
                  Semantics(
                    label: 'Propose call at ${_formatTimeForAccessibility(chosen)}',
                    hint: 'Double tap to propose this custom time slot to the client',
                    button: true,
                    child: FilledButton.tonal(
                      onPressed: () => _proposeCustomSlot(chosen, duration),
                      child: const Text('Propose'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatSlotTime(DateTime dt) {
    final dow = _getDayOfWeek(dt.weekday);
    final year = dt.year;
    final month = _pad(dt.month);
    final day = _pad(dt.day);
    final hour = _pad(dt.hour);
    final minute = _pad(dt.minute);
    
    return '$dow $year-$month-$day $hour:$minute';
  }

  String _getDayOfWeek(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _pad(int x) => x < 10 ? '0$x' : '$x';

  /// Formats a DateTime for accessibility labels
  String _formatTimeForAccessibility(DateTime dateTime) {
    return DateFormat('EEEE, MMMM d at h:mm a').format(dateTime);
  }

  Future<void> _proposeSlot(QuickBookSlot slot) async {
    // Guard rail: tap throttling
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!) < _tapThrottle) {
      return; // Ignore rapid taps
    }
    _lastTapTime = now;
    
    // Guard rail: past time check
    if (slot.start.isBefore(now.add(_pastTimeThreshold))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That time just passed — pick another.')),
        );
      }
      return;
    }
    
    try {
      final result = await _svc.sendProposalMessage(
        clientId: widget.clientId,
        slot: slot,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
        
        if (result.ok) {
          // Track the proposal for auto-confirmation
          if (widget.conversationId != null) {
            QuickBookAutoConfirmService.instance.trackProposal(
              ProposedSlot(
                conversationId: widget.conversationId!,
                clientId: widget.clientId,
                coachId: widget.coachId,
                start: slot.start,
                duration: slot.duration,
                sentAt: DateTime.now(),
              ),
            );
          }
          
          if (widget.onProposed != null) {
            widget.onProposed!(slot);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send proposal: $e')),
        );
      }
    }
  }

  Future<void> _bookSlot(QuickBookSlot slot) async {
    // Guard rail: tap throttling
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!) < _tapThrottle) {
      return; // Ignore rapid taps
    }
    _lastTapTime = now;
    
    // Guard rail: past time check
    if (slot.start.isBefore(now.add(_pastTimeThreshold))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That time just passed — pick another.')),
        );
      }
      return;
    }
    
    try {
      final result = await _svc.createHoldEvent(
        clientId: widget.clientId,
        slot: slot,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
        
        if (result.ok && widget.onBooked != null) {
          widget.onBooked!(slot);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to book slot: $e')),
        );
      }
    }
  }

  Future<void> _proposeCustomSlot(DateTime chosen, Duration duration) async {
    final slot = QuickBookSlot(chosen, duration);
    
    // Validate the slot
    final validation = _svc.validateSlot(slot);
    if (!validation.ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(validation.message)),
        );
      }
      return;
    }
    
    await _proposeSlot(slot);
  }

  Widget _buildPrefillSlotCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slot = widget.prefillSlot!;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule_outlined,
                size: 16,
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Parsed Time',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatSlotTime(slot.start),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Duration: ${slot.duration.inMinutes} minutes',
            style: TextStyle(
              fontSize: 12,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Semantics(
                label: 'Propose call at ${_formatTimeForAccessibility(slot.start)}',
                hint: 'Double tap to propose this time slot to the client',
                button: true,
                child: FilledButton.tonal(
                  onPressed: () => _proposeSlot(slot),
                  child: const Text('Propose'),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                label: 'Book and notify client for ${_formatTimeForAccessibility(slot.start)}',
                hint: 'Double tap to book this time slot and notify the client',
                button: true,
                child: FilledButton(
                  onPressed: () => _bookSlot(slot),
                  child: const Text('Book & notify'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeekStrip(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next 48h availability',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          _buildPeekTimeline(context, now),
          const SizedBox(height: 8),
          _buildFreeBlockChips(context),
        ],
      ),
    );
  }

  Widget _buildPeekTimeline(BuildContext context, DateTime anchor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final end = anchor.add(const Duration(hours: 48));
    final totalMs = end.millisecondsSinceEpoch - anchor.millisecondsSinceEpoch;

    return SizedBox(
      height: 16,
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final width = constraints.maxWidth;
          final children = <Widget>[
            // Base bar
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                  ),
                ),
              ),
            ),
          ];

          // Add event overlays
          for (final event in _events) {
            final start = event.start.isBefore(anchor) ? anchor : event.start;
            final end = event.end.isAfter(anchor.add(const Duration(hours: 48))) ? anchor.add(const Duration(hours: 48)) : event.end;
            if (!end.isAfter(start)) continue;

            final left = ((start.millisecondsSinceEpoch - anchor.millisecondsSinceEpoch) / totalMs) * width;
            final right = ((end.millisecondsSinceEpoch - anchor.millisecondsSinceEpoch) / totalMs) * width;
            
            children.add(
              Positioned(
                left: left,
                width: (right - left).clamp(2.0, width),
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.35),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            );
          }

          return Stack(children: children);
        },
      ),
    );
  }

  Widget _buildFreeBlockChips(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_free.isEmpty) {
      return Text(
        'No free blocks detected in the next 48h.',
        style: TextStyle(
          fontSize: 12,
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.65),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _free.map((block) {
        final minutes = block.end.difference(block.start).inMinutes;
        final formattedTime = _peek.formatCompactTime(block.start);
        
        return ActionChip(
          label: Text('$formattedTime • ${minutes}m'),
          onPressed: () => _proposeFreeBlock(block),
        );
      }).toList(),
    );
  }

  Future<void> _proposeFreeBlock(PeekBlock block) async {
    try {
      final slot = QuickBookSlot(block.start, const Duration(minutes: 15));
      final result = await _svc.sendProposalMessage(
        clientId: widget.clientId,
        slot: slot,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
        
        if (result.ok) {
          // Track the proposal for auto-confirmation
          if (widget.conversationId != null) {
            QuickBookAutoConfirmService.instance.trackProposal(
              ProposedSlot(
                conversationId: widget.conversationId!,
                clientId: widget.clientId,
                coachId: widget.coachId,
                start: slot.start,
                duration: slot.duration,
                sentAt: DateTime.now(),
              ),
            );
          }
          
          if (widget.onProposed != null) {
            widget.onProposed!(slot);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send proposal: $e')),
        );
      }
    }
  }
}
