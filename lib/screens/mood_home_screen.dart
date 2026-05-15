import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/mood_repository.dart';
import '../models/mood_entry.dart';
import '../models/mood_kind.dart';
import '../widgets/mood_face_painter.dart';

class MoodHomeScreen extends StatefulWidget {
  const MoodHomeScreen({super.key});

  @override
  State<MoodHomeScreen> createState() => _MoodHomeScreenState();
}

class _MoodHomeScreenState extends State<MoodHomeScreen> {
  final _repo = MoodRepository();
  List<MoodEntry> _entries = [];
  bool _loading = true;
  String? _newEntryId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _repo.loadEntries();
    if (!mounted) return;
    setState(() {
      _entries = entries.reversed.take(7).toList();
      _loading = false;
    });
  }

  Future<void> _logMood(MoodKind mood) async {
    HapticFeedback.mediumImpact();
    final entry = MoodEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      mood: mood,
      timestamp: DateTime.now(),
    );
    await _repo.addEntry(entry);
    if (!mounted) return;
    setState(() {
      _newEntryId = entry.id;
      if (_entries.length >= 7) _entries.removeLast();
      _entries.insert(0, entry);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged: ${mood.label}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Mood Tracker'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LoggerCard(onMoodSelected: _logMood),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Recent entries',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(child: _buildTimeline()),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sentiment_neutral_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No moods logged yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap a face above to get started',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _entries.length,
      itemBuilder: (context, i) => _TimelineCard(
        key: ValueKey(_entries[i].id),
        entry: _entries[i],
        isFirst: i == 0,
        isLast: i == _entries.length - 1,
        isNew: _entries[i].id == _newEntryId,
      ),
    );
  }
}

class _LoggerCard extends StatelessWidget {
  final ValueChanged<MoodKind> onMoodSelected;

  const _LoggerCard({required this.onMoodSelected});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(
              'How are you feeling?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: MoodKind.values
                  .map((m) => _MoodButton(mood: m, onTap: () => onMoodSelected(m)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  final MoodKind mood;
  final VoidCallback onTap;

  const _MoodButton({required this.mood, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            CustomPaint(
              size: const Size(48, 48),
              painter: MoodFacePainter(mood),
            ),
            const SizedBox(height: 4),
            Text(mood.label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _TimelineCard extends StatefulWidget {
  final MoodEntry entry;
  final bool isFirst;
  final bool isLast;
  final bool isNew;

  const _TimelineCard({
    super.key,
    required this.entry,
    required this.isFirst,
    required this.isLast,
    this.isNew = false,
  });

  @override
  State<_TimelineCard> createState() => _TimelineCardState();
}

class _TimelineCardState extends State<_TimelineCard>
    with TickerProviderStateMixin {
  late final AnimationController _tapController;
  late final AnimationController _appearController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _exprAnim;
  late final CurvedAnimation _fadeAnim;
  late final CurvedAnimation _slideCurve;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.30), weight: 25),
      TweenSequenceItem(
        tween: Tween(begin: 1.30, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 75,
      ),
    ]).animate(_tapController);
    _exprAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 75),
    ]).animate(_tapController);

    _appearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _appearController, curve: Curves.easeOut);
    _slideCurve = CurvedAnimation(parent: _appearController, curve: Curves.easeOutCubic);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.25),
      end: Offset.zero,
    ).animate(_slideCurve);

    if (widget.isNew) {
      _appearController.forward();
    } else {
      _appearController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _fadeAnim.dispose();
    _slideCurve.dispose();
    _tapController.dispose();
    _appearController.dispose();
    super.dispose();
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';

    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(dt.year, dt.month, dt.day);
    final diffDays = today.difference(entryDay).inDays;

    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    final timeStr = '$h:$m $period';

    if (diffDays == 0) return 'Today · $timeStr';
    if (diffDays == 1) return 'Yesterday · $timeStr';
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day} · $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final lineColor = Theme.of(context).dividerColor;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline spine
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: 2,
                      height: 25,
                      color: widget.isFirst ? Colors.transparent : lineColor,
                    ),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: widget.entry.mood.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 2,
                          color: widget.isLast ? Colors.transparent : lineColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Card
              Expanded(
                child: Card(
                  margin: EdgeInsets.only(bottom: widget.isLast ? 0 : 8),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _tapController.forward(from: 0),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: AnimatedBuilder(
                        animation: _tapController,
                        child: Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.entry.mood.label,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatTimestamp(widget.entry.timestamp),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        builder: (context, child) => Row(
                          children: [
                            Transform.scale(
                              scale: _scaleAnim.value,
                              child: CustomPaint(
                                size: const Size(40, 40),
                                painter: MoodFacePainter(
                                  widget.entry.mood,
                                  animT: _exprAnim.value,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            child!,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
