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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _entries.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) => _EntryTile(entry: _entries[i]),
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

class _EntryTile extends StatelessWidget {
  final MoodEntry entry;

  const _EntryTile({required this.entry});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CustomPaint(
            size: const Size(36, 36),
            painter: MoodFacePainter(entry.mood),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.mood.label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            _timeAgo(entry.timestamp),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
