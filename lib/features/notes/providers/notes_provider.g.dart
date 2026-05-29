// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notesStreamHash() => r'3de0f0f91c06377d154d4deb2b27c6d4b4f561a8';

/// See also [NotesStream].
@ProviderFor(NotesStream)
final notesStreamProvider =
    StreamNotifierProvider<NotesStream, List<Note>>.internal(
      NotesStream.new,
      name: r'notesStreamProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notesStreamHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NotesStream = StreamNotifier<List<Note>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
