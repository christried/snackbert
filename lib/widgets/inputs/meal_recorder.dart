import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:snackbert/providers/audio_recording_provider.dart';

class MealRecorder extends ConsumerStatefulWidget {
  const MealRecorder({super.key, required this.onPickAudio});

  final void Function(File? audioFile) onPickAudio;

  @override
  ConsumerState<MealRecorder> createState() => _MealRecorderState();
}

class _MealRecorderState extends ConsumerState<MealRecorder> {
  late final AudioRecorder _recorder;

  late PlayerController _playerController;

  // Listens to player state so the UI can show play/pause correctly.
  StreamSubscription<PlayerState>? _playerStateSub;

  bool _isRecording = false;
  bool _isPlaying = false;

  String? _audioPath;

  @override
  void initState() {
    super.initState();

    _recorder = AudioRecorder();

    _initPlayerController();
  }

  // Builds a fresh player controller and subscribes to its state.
  void _initPlayerController() {
    _playerController = PlayerController();
    _playerStateSub?.cancel();
    _playerStateSub = _playerController.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
  }

  // re-initialize the whole player on reset because it threw for some reason
  Future<void> _resetPlayerController() async {
    await _playerController.stopPlayer();
    _playerStateSub?.cancel();
    _playerController.dispose();
    _initPlayerController();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      debugPrint('MealRecorder: microphone permission missing.');
      return;
    }

    if (_isPlaying) {
      await _playerController.stopPlayer();
    }

    // Build a unique filename for each recording.
    final dir = await getApplicationDocumentsDirectory();
    final filePath =
        '${dir.path}/meal_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: filePath,
    );

    if (!mounted) return;
    setState(() {
      _isRecording = true;
      _audioPath = null;
    });

    ref.read(audioRecordingProvider.notifier).isRecording();
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    final file = path == null ? null : File(path);
    widget.onPickAudio(file);

    if (path == null) {
      debugPrint('MealRecorder: recording returned no path.');
      if (!mounted) return;
      setState(() {
        _isRecording = false;
      });
      ref.read(audioRecordingProvider.notifier).isNotRecording();
      return;
    }

    await _resetPlayerController();
    await _playerController.preparePlayer(
      path: path,
      shouldExtractWaveform: false,
    );

    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _audioPath = path;
    });

    ref.read(audioRecordingProvider.notifier).isNotRecording();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _togglePlayback() async {
    if (_audioPath == null) return;

    if (_isPlaying) {
      await _playerController.pausePlayer();
      return;
    }

    await _playerController.startPlayer();
  }

  // Deletes the current recording and returns to record mode
  Future<void> _discardRecording() async {
    if (_isPlaying) {
      await _playerController.stopPlayer();
    }

    final path = _audioPath;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }

    if (!mounted) return;
    setState(() {
      _audioPath = null;
      _isPlaying = false;
    });
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _playerController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // STYLING
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bodyLarge = theme.textTheme.bodyLarge!.copyWith(
      color: colors.primary,
    );

    Widget content;
    if (_isRecording) {
      content = TextButton.icon(
        onPressed: _toggleRecording,
        icon: Icon(Icons.stop, size: 40),
        label: Text(_isRecording ? 'Stoppen' : 'Starten', style: bodyLarge),
      );
    } else {
      content = GestureDetector(
        onTap: _toggleRecording,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/snackbert_mascot_mic.png',
              width: 80,
              height: 80,
            ),

            Text("Audio", style: bodyLarge),
          ],
        ),
      );
    }

    // Once we have a recording, show playback + re-record actions.
    if (_audioPath != null) {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton.icon(
            onPressed: _togglePlayback,
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 40),
            label: Text(_isPlaying ? 'Pause' : 'Hören', style: bodyLarge),
          ),
          IconButton(
            onPressed: _discardRecording,
            icon: Icon(Icons.replay, color: colors.primary, size: 25),
            tooltip: 'Neu aufnehmen',
          ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.primaryContainer.withAlpha(155),
        border: Border.all(
          width: 2,
          color: colors.primary.withAlpha(155),
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      height: 200,
      alignment: Alignment.center,
      child: Column(mainAxisSize: MainAxisSize.min, children: [content]),
    );
  }
}
