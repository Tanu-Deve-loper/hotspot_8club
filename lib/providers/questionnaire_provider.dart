import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuestionnaireState {
  final String answerText;
  final String? audioFilePath;
  final String? videoFilePath;
  final bool isRecordingAudio;
  final bool isRecordingVideo;
  final int audioDuration;
  final bool showAudioConfirmation;
  final double audioAmplitude; // NEW: For waveform animation

  QuestionnaireState({
    this.answerText = '',
    this.audioFilePath,
    this.videoFilePath,
    this.isRecordingAudio = false,
    this.isRecordingVideo = false,
    this.audioDuration = 0,
    this.showAudioConfirmation = false,
    this.audioAmplitude = 0.0, // NEW
  });

  QuestionnaireState copyWith({
    String? answerText,
    String? audioFilePath,
    String? videoFilePath,
    bool? isRecordingAudio,
    bool? isRecordingVideo,
    int? audioDuration,
    bool? showAudioConfirmation,
    double? audioAmplitude, // NEW
  }) {
    return QuestionnaireState(
      answerText: answerText ?? this.answerText,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      videoFilePath: videoFilePath ?? this.videoFilePath,
      isRecordingAudio: isRecordingAudio ?? this.isRecordingAudio,
      isRecordingVideo: isRecordingVideo ?? this.isRecordingVideo,
      audioDuration: audioDuration ?? this.audioDuration,
      showAudioConfirmation: showAudioConfirmation ?? this.showAudioConfirmation,
      audioAmplitude: audioAmplitude ?? this.audioAmplitude, // NEW
    );
  }

  bool get hasAudio => audioFilePath != null && audioFilePath!.isNotEmpty;
  bool get hasVideo => videoFilePath != null && videoFilePath!.isNotEmpty;

  String get formattedDuration {
    final minutes = (audioDuration ~/ 60).toString().padLeft(2, '0');
    final seconds = (audioDuration % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class QuestionnaireNotifier extends StateNotifier<QuestionnaireState> {
  QuestionnaireNotifier() : super(QuestionnaireState());

  void updateAnswerText(String text) {
    state = state.copyWith(answerText: text);
  }

  void startAudioRecording() {
    state = state.copyWith(
      isRecordingAudio: true,
      audioDuration: 0,
      showAudioConfirmation: false,
      audioAmplitude: 0.0, // NEW
    );
  }

  void updateAudioDuration(int duration) {
    state = state.copyWith(audioDuration: duration);
  }

  // NEW: Update amplitude for waveform
  void updateAudioAmplitude(double amplitude) {
    state = state.copyWith(audioAmplitude: amplitude);
  }

  void stopAudioRecording() {
    state = state.copyWith(
      isRecordingAudio: false,
      showAudioConfirmation: true,
      audioAmplitude: 0.0, // Reset
    );
  }

  void confirmAudioRecording(String filePath) {
    state = state.copyWith(
      audioFilePath: filePath,
      showAudioConfirmation: false,
    );
  }

  void cancelAudioRecording() {
    state = state.copyWith(
      isRecordingAudio: false,
      showAudioConfirmation: false,
      audioDuration: 0,
      audioAmplitude: 0.0, // Reset
    );
  }

  void deleteAudio() {
    state = QuestionnaireState(
      answerText: state.answerText,
      videoFilePath: state.videoFilePath,
      isRecordingVideo: state.isRecordingVideo,
    );
  }

  void startVideoRecording() {
    state = state.copyWith(isRecordingVideo: true);
  }

  void stopVideoRecording(String filePath) {
    state = state.copyWith(
      isRecordingVideo: false,
      videoFilePath: filePath,
    );
  }

  void cancelVideoRecording() {
    state = state.copyWith(isRecordingVideo: false);
  }

  void deleteVideo() {
    state = QuestionnaireState(
      answerText: state.answerText,
      audioFilePath: state.audioFilePath,
      isRecordingAudio: state.isRecordingAudio,
      audioDuration: state.audioDuration,
      showAudioConfirmation: state.showAudioConfirmation,
    );
  }

  void reset() {
    state = QuestionnaireState();
  }
}

final questionnaireProvider =
    StateNotifierProvider<QuestionnaireNotifier, QuestionnaireState>((ref) {
  return QuestionnaireNotifier();
});
