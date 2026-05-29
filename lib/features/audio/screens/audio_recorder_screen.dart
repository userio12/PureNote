import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import 'package:purenote/core/error/result.dart';
import 'package:purenote/core/providers/database_provider.dart';
import 'package:purenote/core/services/attachment_service.dart';

class AudioRecorderScreen extends ConsumerStatefulWidget {
  final String noteId;
  const AudioRecorderScreen({super.key, required this.noteId});

  @override
  ConsumerState<AudioRecorderScreen> createState() => _AudioRecorderScreenState();
}

class _AudioRecorderScreenState extends ConsumerState<AudioRecorderScreen> {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordDuration = 0;
  Timer? _timer;
  String? _recordedPath;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<bool> _hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required')),
        );
      }
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final filePath = p.join(dir.path, 'recordings', '${const Uuid().v4()}.m4a');
    await Directory(p.dirname(filePath)).create(recursive: true);

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: filePath,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordDuration++);
    });

    setState(() {
      _isRecording = true;
      _isPaused = false;
      _recordDuration = 0;
    });
  }

  Future<void> _pauseRecording() async {
    await _recorder.pause();
    _timer?.cancel();
    setState(() => _isPaused = true);
  }

  Future<void> _resumeRecording() async {
    await _recorder.resume();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordDuration++);
    });
    setState(() => _isPaused = false);
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _recordedPath = path;
    });
  }

  Future<void> _saveRecording() async {
    if (_recordedPath == null) return;
    final file = File(_recordedPath!);

    final service = AttachmentService(ref.read(attachmentDaoProvider));
    final result = await service.attachFile(
      noteId: widget.noteId,
      sourceFile: file,
      mimeType: 'audio/m4a',
    );

    if (result is Ok && mounted) {
      context.pop(true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save recording')),
      );
    }
  }

  void _discard() async {
    if (_recordedPath != null) {
      final file = File(_recordedPath!);
      if (await file.exists()) await file.delete();
    }
    if (mounted) context.pop(false);
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Audio'),
        actions: [
          if (_recordedPath != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveRecording,
              tooltip: 'Save',
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isRecording ? Icons.mic : Icons.mic_none,
              size: 80,
              color: _isRecording ? Colors.red : theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              _formatDuration(_recordDuration),
              style: theme.textTheme.displaySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isRecording && _recordedPath == null)
                  FloatingActionButton.large(
                    onPressed: _startRecording,
                    child: const Icon(Icons.mic),
                  ),
                if (_isRecording && !_isPaused)
                  FloatingActionButton.large(
                    onPressed: _pauseRecording,
                    backgroundColor: Colors.orange,
                    child: const Icon(Icons.pause),
                  ),
                if (_isRecording && _isPaused)
                  FloatingActionButton.large(
                    onPressed: _resumeRecording,
                    child: const Icon(Icons.mic),
                  ),
                if (_recordedPath != null && !_isRecording) ...[
                  FloatingActionButton.large(
                    onPressed: _startRecording,
                    child: const Icon(Icons.refresh),
                  ),
                ],
              ],
            ),
            if (_isRecording || _recordedPath != null) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: _isRecording ? _stopRecording : _discard,
                icon: const Icon(Icons.stop, color: Colors.red),
                label: Text(
                  _isRecording ? 'Stop' : 'Discard',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
