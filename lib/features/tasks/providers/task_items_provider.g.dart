// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_items_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$taskItemsByNoteHash() => r'956926876a9374e65e9b001ed7e240d40e9c5a0d';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [taskItemsByNote].
@ProviderFor(taskItemsByNote)
const taskItemsByNoteProvider = TaskItemsByNoteFamily();

/// See also [taskItemsByNote].
class TaskItemsByNoteFamily extends Family<AsyncValue<List<TaskItem>>> {
  /// See also [taskItemsByNote].
  const TaskItemsByNoteFamily();

  /// See also [taskItemsByNote].
  TaskItemsByNoteProvider call(String noteId) {
    return TaskItemsByNoteProvider(noteId);
  }

  @override
  TaskItemsByNoteProvider getProviderOverride(
    covariant TaskItemsByNoteProvider provider,
  ) {
    return call(provider.noteId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'taskItemsByNoteProvider';
}

/// See also [taskItemsByNote].
class TaskItemsByNoteProvider extends StreamProvider<List<TaskItem>> {
  /// See also [taskItemsByNote].
  TaskItemsByNoteProvider(String noteId)
    : this._internal(
        (ref) => taskItemsByNote(ref as TaskItemsByNoteRef, noteId),
        from: taskItemsByNoteProvider,
        name: r'taskItemsByNoteProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$taskItemsByNoteHash,
        dependencies: TaskItemsByNoteFamily._dependencies,
        allTransitiveDependencies:
            TaskItemsByNoteFamily._allTransitiveDependencies,
        noteId: noteId,
      );

  TaskItemsByNoteProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.noteId,
  }) : super.internal();

  final String noteId;

  @override
  Override overrideWith(
    Stream<List<TaskItem>> Function(TaskItemsByNoteRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TaskItemsByNoteProvider._internal(
        (ref) => create(ref as TaskItemsByNoteRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        noteId: noteId,
      ),
    );
  }

  @override
  StreamProviderElement<List<TaskItem>> createElement() {
    return _TaskItemsByNoteProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TaskItemsByNoteProvider && other.noteId == noteId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, noteId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TaskItemsByNoteRef on StreamProviderRef<List<TaskItem>> {
  /// The parameter `noteId` of this provider.
  String get noteId;
}

class _TaskItemsByNoteProviderElement
    extends StreamProviderElement<List<TaskItem>>
    with TaskItemsByNoteRef {
  _TaskItemsByNoteProviderElement(super.provider);

  @override
  String get noteId => (origin as TaskItemsByNoteProvider).noteId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
