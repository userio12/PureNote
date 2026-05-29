import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purenote/core/database/database.dart';
import 'package:purenote/core/providers/database_provider.dart';
import 'package:purenote/core/providers/settings_provider.dart';
import 'package:purenote/features/notes/providers/notes_provider.dart';
import 'package:purenote/features/notes/widgets/note_card.dart';

class NotesListScreen extends ConsumerWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesStreamProvider);
    final settings = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: Icon(
              settings.viewMode == 0 ? Icons.grid_view : Icons.list,
            ),
            onPressed: () {
              ref.read(settingsNotifierProvider.notifier).update(
                settings.copyWith(viewMode: settings.viewMode == 0 ? 1 : 0),
              );
            },
            tooltip: settings.viewMode == 0 ? 'Grid view' : 'List view',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
            tooltip: 'Search notes',
          ),
        ],
      ),
      body: notesAsync.when(
        data: (notes) {
          final pinned = notes.where((n) => n.isPinned).toList();
          final unpinned = notes.where((n) => !n.isPinned).toList();

          if (notes.isEmpty) {
            return const _EmptyState();
          }

          if (settings.viewMode == 1) {
            return _GridNotesView(
              pinned: pinned,
              unpinned: unpinned,
              onTap: (note) => context.push('/note/${note.id}'),
              onPin: (note) => _togglePin(ref, note),
              onDelete: (note) => _deleteNote(ref, note),
            );
          }

          return _ListNotesView(
            pinned: pinned,
            unpinned: unpinned,
            onTap: (note) => context.push('/note/${note.id}'),
            onPin: (note) => _togglePin(ref, note),
            onDelete: (note) => _deleteNote(ref, note),
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          itemBuilder: (_, _) => const NoteCardSkeleton(),
        ),
        error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(notesStreamProvider)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/note/new'),
        tooltip: 'New note',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _togglePin(WidgetRef ref, Note note) async {
    final dao = ref.read(noteDaoProvider);
    await dao.togglePin(note.id);
  }

  Future<void> _deleteNote(WidgetRef ref, Note note) async {
    final dao = ref.read(noteDaoProvider);
    await dao.delete(note.id);
  }
}

class _ListNotesView extends StatelessWidget {
  final List<Note> pinned;
  final List<Note> unpinned;
  final void Function(Note) onTap;
  final void Function(Note) onPin;
  final void Function(Note) onDelete;

  const _ListNotesView({
    required this.pinned,
    required this.unpinned,
    required this.onTap,
    required this.onPin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: pinned.length + unpinned.length + (pinned.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (pinned.isNotEmpty && index == pinned.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              'Others',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          );
        }

        final note = index < pinned.length
            ? pinned[index]
            : unpinned[index - pinned.length - (pinned.isNotEmpty ? 1 : 0)];

        return NoteCard(
          note: note,
          onTap: () => onTap(note),
          onPin: () => onPin(note),
          onDelete: () => onDelete(note),
        );
      },
    );
  }
}

class _GridNotesView extends StatelessWidget {
  final List<Note> pinned;
  final List<Note> unpinned;
  final void Function(Note) onTap;
  final void Function(Note) onPin;
  final void Function(Note) onDelete;

  const _GridNotesView({
    required this.pinned,
    required this.unpinned,
    required this.onTap,
    required this.onPin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final all = [...pinned, ...unpinned];
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: all.length,
      itemBuilder: (context, index) {
        final note = all[index];
        return NoteCard(
          note: note,
          onTap: () => onTap(note),
          onPin: () => onPin(note),
          onDelete: () => onDelete(note),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.note_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No notes yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first note',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey.shade500),
          const SizedBox(height: 16),
          Text(
            'Could not load notes',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
