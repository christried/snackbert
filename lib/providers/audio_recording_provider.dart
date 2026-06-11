import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioRecordingProvider = NotifierProvider<AudioRecordingNotifier, bool>(
  AudioRecordingNotifier.new,
);

class AudioRecordingNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void isRecording() {
    state = true;
  }

  void isNotRecording() {
    state = false;
  }
}
