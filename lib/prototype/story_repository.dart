import 'dart:convert';
import 'package:hive/hive.dart';
import 'story_state.dart';

class StoryRepository {
  static const key = 'storyPrototypeV1';
  final Box<dynamic> box;
  late StoryState state;
  bool _busy = false;
  StoryRepository(this.box) {
    final saved = box.get(key);
    state = saved == null
        ? StoryState.fromLegacy(box.get('progress') as Map?)
        : StoryState.fromMap(saved as Map);
  }

  Future<void> update(DateTime now, void Function(StoryState) command) async {
    if (_busy) throw StateError('A save is already in progress');
    _busy = true;
    try {
      final next = StoryState.fromMap(
        jsonDecode(jsonEncode(state.toMap())) as Map,
      );
      next.settle(now);
      command(next);
      await box.put(key, next.toMap());
      state = next;
    } finally {
      _busy = false;
    }
  }
}
