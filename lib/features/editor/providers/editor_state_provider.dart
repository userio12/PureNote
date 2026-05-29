import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'editor_state_provider.g.dart';

enum SaveStatus { idle, saving, saved, unsaved }

@Riverpod(keepAlive: true)
class EditorState extends _$EditorState {
  @override
  EditorStateData build() => const EditorStateData();

  void markDirty() {
    state = state.copyWith(saveStatus: SaveStatus.unsaved);
  }

  void markSaving() {
    state = state.copyWith(saveStatus: SaveStatus.saving);
  }

  void markSaved() {
    state = state.copyWith(saveStatus: SaveStatus.saved);
  }

  void markIdle() {
    state = state.copyWith(saveStatus: SaveStatus.idle);
  }

  void setColor(int? color) {
    state = state.copyWith(selectedColor: color);
  }

  void reset() {
    state = const EditorStateData();
  }
}

class EditorStateData {
  final SaveStatus saveStatus;
  final int? selectedColor;

  const EditorStateData({
    this.saveStatus = SaveStatus.idle,
    this.selectedColor,
  });

  EditorStateData copyWith({
    SaveStatus? saveStatus,
    int? selectedColor,
  }) {
    return EditorStateData(
      saveStatus: saveStatus ?? this.saveStatus,
      selectedColor: selectedColor ?? this.selectedColor,
    );
  }
}
