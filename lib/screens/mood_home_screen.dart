import 'package:flutter/material.dart';
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
    final entry = MoodEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      mood: mood,
      timestamp: DateTime.now(),
    );
    await _repo.addEntry(entry);
    await _load();
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
      return const Center(child: Text('No moods logged yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _entries.length,
      itemBuilder: (context, i) => _TimelineCard(
        entry: _entries[i],
        isFirst: i == 0,
        isLast: i == _entries.length - 1,
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

class _TimelineCard extends StatelessWidget {
  final MoodEntry entry;
  final bool isFirst;
  final bool isLast;

  const _TimelineCard({
    required this.entry,
    required this.isFirst,
    required this.isLast,
  });

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

    return IntrinsicHeight(
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
                  color: isFirst ? Colors.transparent : lineColor,
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: entry.mood.color,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      width: 2,
                      color: isLast ? Colors.transparent : lineColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Card
          Expanded(
            child: Card(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CustomPaint(
                      size: const Size(40, 40),
                      painter: MoodFacePainter(entry.mood),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.mood.label,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTimestamp(entry.timestamp),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
