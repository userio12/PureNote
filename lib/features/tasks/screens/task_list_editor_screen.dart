import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;
import 'package:purenote/core/database/database.dart';
import 'package:purenote/core/error/result.dart';
import 'package:purenote/core/providers/database_provider.dart';

class TaskListEditorScreen extends ConsumerStatefulWidget {
  final String? noteId;
  const TaskListEditorScreen({super.key, this.noteId});

  @override
  ConsumerState<TaskListEditorScreen> createState() => _TaskListEditorScreenState();
}

class _TaskListEditorScreenState extends ConsumerState<TaskListEditorScreen> {
  late TextEditingController _titleController;
  final _itemControllers = <String, TextEditingController>{};
  final _itemFocusNodes = <String, FocusNode>{};
  bool _isNew = true;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _isNew = widget.noteId == null;
    if (!_isNew) _loadTaskList();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _titleController.dispose();
    for (final c in _itemControllers.values) { c.dispose(); }
    for (final f in _itemFocusNodes.values) { f.dispose(); }
    super.dispose();
  }

  Future<void> _loadTaskList() async {
    final dao = ref.read(noteDaoProvider);
    final note = await dao.getById(widget.noteId!);
    if (note != null && mounted) {
      _titleController.text = note.title;
      final taskDao = ref.read(taskDaoProvider);
      final items = await taskDao.watchByNoteId(widget.noteId!).first;
      if (mounted) {
        setState(() {
          for (final item in items) {
        _itemControllers[item.id] = TextEditingController(text: item.content);
        _itemFocusNodes[item.id] = FocusNode();
      }
        });
      }
    }
  }

  void _addItem() {
    final id = const Uuid().v4();
    setState(() {
      _itemControllers[id] = TextEditingController();
      _itemFocusNodes[id] = FocusNode();
    });
    _debounceSave();
    Future.microtask(() => _itemFocusNodes[id]?.requestFocus());
  }

  void _removeItem(String id) {
    _itemControllers[id]?.dispose();
    _itemFocusNodes[id]?.dispose();
    setState(() {
      _itemControllers.remove(id);
      _itemFocusNodes.remove(id);
    });
    _debounceSave();
  }

  void _debounceSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), _save);
  }

  Future<void> _save() async {
    try {
      final noteDao = ref.read(noteDaoProvider);
      final taskDao = ref.read(taskDaoProvider);
      final id = widget.noteId ?? const Uuid().v4();
      final now = DateTime.now().millisecondsSinceEpoch;

      if (_isNew) {
        final result = await noteDao.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
        );
        if (result is Ok && mounted) {
          await noteDao.updateFields(NotesCompanion(
            id: Value(id),
            title: Value(_titleController.text),
            type: const Value(1),
          ));
        }
        _isNew = false;
      } else {
        await noteDao.updateFields(NotesCompanion(
          id: Value(widget.noteId!),
          title: Value(_titleController.text),
          updatedAt: Value(now),
        ));
        await taskDao.deleteByNoteId(id);
      }

      double orderIndex = 0;
      for (final entry in _itemControllers.entries) {
        if (entry.value.text.isNotEmpty) {
          await taskDao.insert(TaskItemsCompanion(
            id: Value(entry.key),
            noteId: Value(id),
            content: Value(entry.value.text),
            isChecked: const Value(false),
            orderIndex: Value(orderIndex),
          ));
          orderIndex += 1.0;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save task list')),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    final hasContent = _titleController.text.isNotEmpty ||
        _itemControllers.values.any((c) => c.text.isNotEmpty);
    if (!hasContent && _isNew) return true;
    await _save();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canPop = await _onWillPop();
        if (canPop && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isNew ? 'New Task List' : 'Edit Task List'),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () async {
                await _save();
                if (context.mounted) context.pop();
              },
              tooltip: 'Save',
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _titleController,
                onChanged: (_) => _debounceSave(),
                decoration: const InputDecoration(
                  hintText: 'Task list title',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _itemControllers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.playlist_add, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No items yet',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.tonalIcon(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add),
                            label: const Text('Add item'),
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _itemControllers.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          final entries = _itemControllers.entries.toList();
                          final item = entries.removeAt(oldIndex);
                          entries.insert(newIndex, item);
                          _itemControllers
                            ..clear()
                            ..addEntries(entries);
                        });
                        _debounceSave();
                      },
                      itemBuilder: (context, index) {
                        final entry = _itemControllers.entries.elementAt(index);
                        return _TaskItemTile(
                          key: ValueKey(entry.key),
                          controller: entry.value,
                          focusNode: _itemFocusNodes[entry.key]!,
                          onDelete: () => _removeItem(entry.key),
                          onChanged: () => _debounceSave(),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addItem,
          tooltip: 'Add item',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _TaskItemTile extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const _TaskItemTile({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: 0,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.drag_handle, color: Colors.grey),
            ),
          ),
          Checkbox(
            value: false,
            onChanged: (_) {},
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: (_) => onChanged(),
              decoration: const InputDecoration(
                hintText: 'Task item',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onDelete,
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}
