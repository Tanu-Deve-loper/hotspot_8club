import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'dart:math';
import 'dart:math' as math;
import '../providers/questionnaire_provider.dart';
import '../providers/experience_selection_provider.dart';
import '../services/audio_service.dart';
import '../services/audio_player_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/constants.dart';

class QuestionScreen extends ConsumerStatefulWidget {
  const QuestionScreen({super.key});

  @override
  ConsumerState<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends ConsumerState<QuestionScreen> with SingleTickerProviderStateMixin {
  // ==================== STATE VARIABLES ====================
  final TextEditingController _textController = TextEditingController();
  final AudioService _audioService = AudioService();
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  final FocusNode _focusNode = FocusNode();
  
  // Audio recording state
  String? _tempAudioPath;
  bool _isPlayingAudio = false;
  List<double> _waveformHeights = List.generate(25, (index) => 0.3);
  
  // Video recording state
  CameraController? _cameraController;
  bool _isRecordingVideo = false;
  String? _videoPath;
  VideoPlayerController? _videoPlayerController;
  bool _isPlayingVideo = false;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;

  // Slide animation for recording sheet
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // ==================== LIFECYCLE METHODS ====================
  @override
  void initState() {
    super.initState();
    
    // Initialize slide animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    // Listen to audio player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingAudio = (state == PlayerState.playing);
        });
      }
    });
    
    _initializeCamera();
    
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _audioService.dispose();
    _audioPlayer.dispose();
    _cameraController?.dispose();
    _videoPlayerController?.dispose();
    _slideController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ==================== CAMERA METHODS ====================
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      await _switchCamera(_selectedCameraIndex);
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _switchCamera(int cameraIndex) async {
    if (_cameras.isEmpty) return;
    await _cameraController?.dispose();
    _selectedCameraIndex = cameraIndex;
    _cameraController = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.high,
    );
    await _cameraController?.initialize();
    if (mounted) setState(() {});
  }

  // ==================== AUDIO RECORDING METHODS ====================
  Future<void> _startRecording() async {
    try {
      ref.read(questionnaireProvider.notifier).startAudioRecording();
      _slideController.forward();
      
      await _audioService.startRecording(
        (duration) {
          ref.read(questionnaireProvider.notifier).updateAudioDuration(duration);
        },
        (amplitude) {
          ref.read(questionnaireProvider.notifier).updateAudioAmplitude(amplitude);
          setState(() {
            _waveformHeights.removeAt(0);
            _waveformHeights.add(amplitude);
          });
        },
      );
    } catch (e) {
      _showError('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioService.stopRecording();
      _tempAudioPath = path;
      ref.read(questionnaireProvider.notifier).stopAudioRecording();
    } catch (e) {
      _showError('Failed to stop recording: $e');
    }
  }

  void _confirmRecording() {
    if (_tempAudioPath != null) {
      ref.read(questionnaireProvider.notifier).confirmAudioRecording(_tempAudioPath!);
      _tempAudioPath = null;
    }
  }

  Future<void> _cancelRecording() async {
    await _audioService.cancelRecording();
    ref.read(questionnaireProvider.notifier).cancelAudioRecording();
    _tempAudioPath = null;
    _slideController.reverse();
    setState(() {
      _waveformHeights = List.generate(25, (index) => 0.3);
    });
  }

  void _deleteRecording() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.black75,
        title: Text('Delete Recording?', style: AppTextStyles.heading3.copyWith(color: AppColors.white)),
        content: Text('Are you sure you want to delete this audio recording?', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray50)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.gray50)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _audioPlayer.stop();
              setState(() => _isPlayingAudio = false);
              final audioPath = ref.read(questionnaireProvider).audioFilePath;
              if (audioPath != null) {
                try {
                  File(audioPath).deleteSync();
                } catch (e) {
                  debugPrint('Error deleting file: $e');
                }
              }
              ref.read(questionnaireProvider.notifier).deleteAudio();
              _slideController.reverse();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recording deleted'), backgroundColor: AppColors.red100),
              );
            },
            child: Text('Delete', style: TextStyle(color: AppColors.red100)),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePlayback() async {
    final audioPath = ref.read(questionnaireProvider).audioFilePath;
    if (audioPath == null) return;
    try {
      if (_isPlayingAudio) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(audioPath);
      }
    } catch (e) {
      _showError('Failed to play audio: $e');
    }
  }

  // ==================== VIDEO RECORDING METHODS ====================
  Future<void> _startVideoRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showError('Camera not initialized');
      return;
    }

    try {
      await _cameraController!.startVideoRecording();
      setState(() => _isRecordingVideo = true);
      ref.read(questionnaireProvider.notifier).startVideoRecording();
    } catch (e) {
      _showError('Failed to start video recording: $e');
    }
  }

  Future<void> _stopVideoRecording() async {
    if (_cameraController == null || !_cameraController!.value.isRecordingVideo) {
      return;
    }

    try {
      final file = await _cameraController!.stopVideoRecording();
      setState(() {
        _isRecordingVideo = false;
        _videoPath = file.path;
      });
      ref.read(questionnaireProvider.notifier).stopVideoRecording(file.path);
      
      _videoPlayerController = VideoPlayerController.file(File(file.path));
      await _videoPlayerController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      _showError('Failed to stop video recording: $e');
    }
  }

  Future<void> _toggleVideoPlayback() async {
    if (_videoPlayerController == null) return;
    
    if (_isPlayingVideo) {
      await _videoPlayerController!.pause();
      if (mounted) {
        setState(() {
          _isPlayingVideo = false;
        });
      }
    } else {
      await _videoPlayerController!.play();
      if (mounted) {
        setState(() {
          _isPlayingVideo = true;
        });
      }
    }
  }

  void _deleteVideo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.black75,
        title: Text('Delete Video?', style: AppTextStyles.heading3.copyWith(color: AppColors.white)),
        content: Text('Are you sure you want to delete this video?', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray50)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.gray50)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final videoPath = ref.read(questionnaireProvider).videoFilePath;
              if (videoPath != null) {
                try {
                  File(videoPath).deleteSync();
                } catch (e) {
                  debugPrint('Error deleting video: $e');
                }
              }
              _videoPlayerController?.dispose();
              setState(() {
                _videoPath = null;
                _videoPlayerController = null;
                _isPlayingVideo = false;
              });
              ref.read(questionnaireProvider.notifier).deleteVideo();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video deleted'), backgroundColor: AppColors.red100),
              );
            },
            child: Text('Delete', style: TextStyle(color: AppColors.red100)),
          ),
        ],
      ),
    );
  }

  // ==================== VIDEO RECORDING DIALOG ====================
  void _showVideoRecordingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return Scaffold(
              backgroundColor: AppColors.black100,
              body: Stack(
                children: [
                  // Camera preview or video playback
                  if (_videoPath == null)
                    _cameraController != null && _cameraController!.value.isInitialized
                        ? SizedBox.expand(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _cameraController!.value.previewSize!.height,
                                height: _cameraController!.value.previewSize!.width,
                                child: CameraPreview(_cameraController!),
                              ),
                            ),
                          )
                        : const Center(child: CircularProgressIndicator(color: AppColors.blue75))
                  else
                    StatefulBuilder(
                      builder: (context, setVideoState) {
                        return GestureDetector(
                          onTap: () async {
                            if (_videoPlayerController == null) return;
                            if (_isPlayingVideo) {
                              await _videoPlayerController!.pause();
                              setState(() => _isPlayingVideo = false);
                              setVideoState(() => _isPlayingVideo = false);
                              setDialogState(() {});
                            } else {
                              await _videoPlayerController!.play();
                              setState(() => _isPlayingVideo = true);
                              setVideoState(() => _isPlayingVideo = true);
                              setDialogState(() {});
                              _videoPlayerController!.addListener(() {
                                if (_videoPlayerController!.value.position >= _videoPlayerController!.value.duration) {
                                  if (mounted) {
                                    setState(() => _isPlayingVideo = false);
                                    setVideoState(() => _isPlayingVideo = false);
                                    setDialogState(() {});
                                  }
                                }
                              });
                            }
                          },
                          child: Stack(
                            children: [
                              SizedBox.expand(
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: _videoPlayerController!.value.size.width,
                                    height: _videoPlayerController!.value.size.height,
                                    child: VideoPlayer(_videoPlayerController!),
                                  ),
                                ),
                              ),
                              if (!_isPlayingVideo)
                                Center(
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                                    child: Center(child: _buildCustomIcon(CustomIconType.play, size: 40)),
                                  ),
                                ),
                              Positioned(
                                bottom: 80,
                                left: 20,
                                right: 20,
                                child: Column(
                                  children: [
                                    VideoProgressIndicator(
                                      _videoPlayerController!,
                                      allowScrubbing: true,
                                      colors: const VideoProgressColors(
                                        playedColor: AppColors.blue75,
                                        bufferedColor: AppColors.gray50,
                                        backgroundColor: AppColors.gray75,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(_formatDuration(_videoPlayerController!.value.position), style: AppTextStyles.caption.copyWith(color: AppColors.white)),
                                        Text(_formatDuration(_videoPlayerController!.value.duration), style: AppTextStyles.caption.copyWith(color: AppColors.white)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  
                  // Top bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 8,
                        bottom: 16,
                        left: 16,
                        right: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _videoPath == null ? (_isRecordingVideo ? 'Recording...' : 'Record Video') : 'Preview Video',
                            style: AppTextStyles.heading3.copyWith(color: AppColors.white),
                          ),
                          const Spacer(),
                          if (_videoPath == null && !_isRecordingVideo && _cameras.length > 1)
                            GestureDetector(
                              onTap: () async {
                                final newIndex = (_selectedCameraIndex + 1) % _cameras.length;
                                await _switchCamera(newIndex);
                                setDialogState(() {});
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                                child: Center(child: _buildCustomIcon(CustomIconType.flipCamera, size: 24)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bottom controls
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + 16,
                        top: 20,
                        left: 20,
                        right: 20,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              if (_isRecordingVideo) {
                                await _cameraController?.stopVideoRecording();
                                setDialogState(() => _isRecordingVideo = false);
                              }
                              if (_videoPath != null) {
                                await _videoPlayerController?.dispose();
                                setDialogState(() {
                                  _videoPath = null;
                                  _videoPlayerController = null;
                                  _isPlayingVideo = false;
                                });
                                setState(() {
                                  _videoPath = null;
                                  _videoPlayerController = null;
                                  _isPlayingVideo = false;
                                });
                                ref.read(questionnaireProvider.notifier).deleteVideo();
                              }
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gray75,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(_videoPath != null ? 'Retake' : 'Cancel', style: AppTextStyles.button),
                          ),
                          if (_videoPath == null)
                            ElevatedButton(
                              onPressed: () async {
                                if (_isRecordingVideo) {
                                  await _stopVideoRecording();
                                } else {
                                  await _startVideoRecording();
                                }
                                setDialogState(() {});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isRecordingVideo ? AppColors.red100 : AppColors.blue75,
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(_isRecordingVideo ? 'Stop' : 'Start', style: AppTextStyles.button),
                            )
                          else
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.green100,
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('Done', style: AppTextStyles.button.copyWith(color: AppColors.black100)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.red100),
    );
  }

  // ==================== BUILD METHOD ====================
  @override
  Widget build(BuildContext context) {
    final questionnaireState = ref.watch(questionnaireProvider);
    final hasContent = questionnaireState.answerText.isNotEmpty ||
        questionnaireState.hasAudio ||
        questionnaireState.hasVideo;
    
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;
    
    final showRecordingSheet = questionnaireState.isRecordingAudio ||
        questionnaireState.showAudioConfirmation ||
        questionnaireState.hasAudio;

    if (showRecordingSheet && _slideController.status != AnimationStatus.completed) {
      _slideController.forward();
    } else if (!showRecordingSheet && _slideController.status != AnimationStatus.dismissed) {
      _slideController.reverse();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      resizeToAvoidBottomInset: false,
      
      // ========== APP BAR ==========
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: AppColors.gray75, borderRadius: BorderRadius.circular(8)),
            child: const Center(child: Text('←', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold))),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('02', style: AppTextStyles.caption.copyWith(color: AppColors.gray50)),
        actions: [
          IconButton(
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: AppColors.gray75, borderRadius: BorderRadius.circular(8)),
              child: const Center(child: Text('×', style: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.bold))),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      
      // ========== BODY ==========
      body: Stack(
        children: [
          // Wavy background
          CustomPaint(size: Size.infinite, painter: WavyDiagonalLinesPainter()),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: isKeyboardOpen ? 10 : 80),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.white,
                    fontSize: isKeyboardOpen ? 18 : 28,
                    fontWeight: FontWeight.w600,
                  ),
                  child: const Text('Why do you want to host with us?'),
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Tell us about your intent and what motivates you to create experiences.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray50),
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: showRecordingSheet ? 3 : (isKeyboardOpen ? 4 : 8),
                  maxLength: AppConstants.questionTextLimit,
                  onChanged: (value) {
                    ref.read(questionnaireProvider.notifier).updateAnswerText(value);
                  },
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
                  decoration: InputDecoration(
                    hintText: '/ Start typing here',
                    hintStyle: AppTextStyles.hint.copyWith(color: AppColors.gray75),
                    counterStyle: AppTextStyles.caption.copyWith(color: AppColors.gray50),
                    filled: true,
                    fillColor: AppColors.black75.withOpacity(0.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.blue75, width: 2)),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),

              if (showRecordingSheet) ...[
                const SizedBox(height: 16),
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildRecordingSheet(questionnaireState),
                ),
              ],

              if (questionnaireState.hasVideo && _videoPath != null) ...[
                const SizedBox(height: 16),
                _buildVideoSheet(),
              ],

              const Spacer(),

              _buildBottomBar(questionnaireState, hasContent),

              SizedBox(height: keyboardHeight),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== RECORDING SHEET ==========
  Widget _buildRecordingSheet(QuestionnaireState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.black75,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: state.showAudioConfirmation || state.hasAudio ? AppColors.blue75 : AppColors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.hasAudio)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Audio Recorded - ${state.formattedDuration}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white, fontWeight: FontWeight.w600)),
            )
          else if (state.isRecordingAudio)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Recording Audio...', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white, fontWeight: FontWeight.w600)),
            ),
          
          Row(
            children: [
              _buildCircleButton(
                onTap: () {
                  if (state.isRecordingAudio) {
                    _stopRecording();
                  } else if (state.showAudioConfirmation) {
                    _confirmRecording();
                  } else if (state.hasAudio) {
                    _togglePlayback();
                  }
                },
                child: _buildCustomIcon(
                  state.isRecordingAudio
                      ? CustomIconType.stop
                      : state.showAudioConfirmation
                          ? CustomIconType.check
                          : _isPlayingAudio
                              ? CustomIconType.pause
                              : CustomIconType.play,
                ),
                color: state.isRecordingAudio
                    ? const Color.fromARGB(1000,145,150,255)
                    : state.showAudioConfirmation
                        ? const Color.fromARGB(1000,89,97,255)
                        : const Color.fromARGB(1000,89,97,255),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      25,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: 2.5,
                        height: state.isRecordingAudio ? max(8.0, _waveformHeights[index] * 40) : (index % 4 + 1) * 8.0,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              if (state.hasAudio)
                _buildCircleButton(
                  onTap: _deleteRecording,
                  child: _buildCustomIcon(CustomIconType.delete),
                  color: AppColors.transparent,
                )
              else
                Text(state.formattedDuration, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  // ========== VIDEO SHEET ==========
  Widget _buildVideoSheet() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.black75,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blue75, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: AppColors.black100, borderRadius: BorderRadius.circular(8)),
            child: _buildCustomIcon(CustomIconType.video, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text('Video Recorded', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white, fontWeight: FontWeight.w600)),
          ),
          _buildCircleButton(
            onTap: _deleteVideo,
            child: _buildCustomIcon(CustomIconType.delete),
            color: AppColors.transparent,
          ),
        ],
      ),
    );
  }

  // ========== BOTTOM BAR ==========
  Widget _buildBottomBar(QuestionnaireState state, bool hasContent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
        border: Border(top: BorderSide(color: AppColors.gray75.withOpacity(0.2), width: 1)),
      ),
      child: Row(
        children: [
          if (!state.hasAudio) ...[
            _buildActionButton(
              customIcon: CustomIconType.mic,
              onTap: () {
                if (state.isRecordingAudio) {
                  _cancelRecording();
                } else {
                  _startRecording();
                }
              },
              isActive: state.isRecordingAudio,
            ),
            Container(width: 1, height: 40, color: AppColors.gray50.withOpacity(0.3), margin: const EdgeInsets.symmetric(horizontal: 12)),
          ],
          if (!state.hasVideo)
            _buildActionButton(
              customIcon: CustomIconType.video,
              onTap: _showVideoRecordingDialog,
            ),
          const Spacer(),
          _buildNextButton(hasContent),
        ],
      ),
    );
  }

  // ========== ACTION BUTTON ==========
  Widget _buildActionButton({
    required CustomIconType customIcon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: isActive
              ? LinearGradient(colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.3)])
              : null,
          color: isActive ? null : AppColors.gray75.withOpacity(0.3),
          border: Border.all(color: AppColors.gray50.withOpacity(0.5), width: 1),
        ),
        child: Center(child: _buildCustomIcon(customIcon)),
      ),
    );
  }

  // ========== NEXT BUTTON ==========
  Widget _buildNextButton(bool isEnabled) {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.gray75.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray50.withOpacity(0.5), width: 1),
          ),
        ),
        if (isEnabled)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.25)]),
              ),
            ),
          ),
        if (isEnabled)
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              key: ValueKey(isEnabled),
              tween: Tween(begin: -1.0, end: 1.5),
              duration: const Duration(milliseconds: 1500),
              builder: (context, value, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Positioned(
                        left: value * 150,
                        child: Container(
                          width: 80,
                          height: 48,
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withOpacity(0.5), Colors.transparent])),
                        ),
                      ),
                    ],
                  ),
                );
              },
              onEnd: () {
                if (mounted && isEnabled) {
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) setState(() {});
                  });
                }
              },
            ),
          ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  backgroundColor: AppColors.black75,
                  title: Text('Success!', style: AppTextStyles.heading3.copyWith(color: AppColors.white)),
                  content: Text('Your response has been recorded.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray50)),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        ref.read(questionnaireProvider.notifier).reset();
                        ref.read(experienceSelectionProvider.notifier).clearSelection();
                        _audioPlayer.stop();
                        _videoPlayerController?.dispose();
                        setState(() {
                          _textController.clear();
                          _isPlayingAudio = false;
                          _isPlayingVideo = false;
                          _videoPath = null;
                          _videoPlayerController = null;
                          _tempAudioPath = null;
                          _waveformHeights = List.generate(25, (index) => 0.3);
                        });
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(foregroundColor: AppColors.blue75),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            } : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 120,
              height: 48,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Next', style: AppTextStyles.button.copyWith(color: isEnabled ? AppColors.white : AppColors.gray50, fontSize: 16)),
                  const SizedBox(width: 8),
                  CustomPaint(size: const Size(18, 18), painter: RightArrowPainter(color: isEnabled ? AppColors.white : AppColors.gray50)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircleButton({required VoidCallback onTap, required Widget child, required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(width: 48, height: 48, decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Center(child: child)),
    );
  }

  Widget _buildCustomIcon(CustomIconType type, {double size = 24}) {
    return CustomPaint(size: Size(size, size), painter: CustomIconPainter(type));
  }
}

// ========== CUSTOM ICON PAINTER ==========
enum CustomIconType { mic, video, play, pause, stop, check, delete, arrowRight, flipCamera }

class CustomIconPainter extends CustomPainter {
  final CustomIconType type;
  CustomIconPainter(this.type);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.white..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round;
    final fillPaint = Paint()..color = AppColors.white..style = PaintingStyle.fill;

    switch (type) {
      case CustomIconType.mic:
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(size.width / 2, size.height * 0.35), width: size.width * 0.4, height: size.height * 0.5), const Radius.circular(8)), paint);
        canvas.drawLine(Offset(size.width * 0.3, size.height * 0.8), Offset(size.width * 0.7, size.height * 0.8), paint);
        canvas.drawLine(Offset(size.width / 2, size.height * 0.6), Offset(size.width / 2, size.height * 0.8), paint);
        break;
      case CustomIconType.video:
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.1, size.height * 0.25, size.width * 0.5, size.height * 0.5), const Radius.circular(2)), paint);
        final path = Path()..moveTo(size.width * 0.6, size.height * 0.35)..lineTo(size.width * 0.9, size.height * 0.25)..lineTo(size.width * 0.9, size.height * 0.75)..lineTo(size.width * 0.6, size.height * 0.65)..close();
        canvas.drawPath(path, paint);
        break;
      case CustomIconType.play:
        final path = Path()..moveTo(size.width * 0.3, size.height * 0.2)..lineTo(size.width * 0.8, size.height * 0.5)..lineTo(size.width * 0.3, size.height * 0.8)..close();
        canvas.drawPath(path, fillPaint);
        break;
      case CustomIconType.pause:
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.25, size.height * 0.2, size.width * 0.15, size.height * 0.6), const Radius.circular(2)), fillPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.6, size.height * 0.2, size.width * 0.15, size.height * 0.6), const Radius.circular(2)), fillPaint);
        break;
      case CustomIconType.stop:
        canvas.drawRect(Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: size.width * 0.6, height: size.height * 0.6), fillPaint);
        break;
      case CustomIconType.check:
        final path = Path()..moveTo(size.width * 0.2, size.height * 0.5)..lineTo(size.width * 0.4, size.height * 0.7)..lineTo(size.width * 0.8, size.height * 0.3);
        canvas.drawPath(path, paint..strokeWidth = 3);
        break;
      case CustomIconType.delete:
        final double horizontalMargin = 0.02;
        canvas.drawLine(Offset(size.width * (horizontalMargin), size.height * 0.3),Offset(size.width * (1.0 - horizontalMargin), size.height * 0.3), paint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.3, size.height * 0.3, size.width * 0.5, size.height * 0.7), const Radius.circular(2)), paint);
        break;
      case CustomIconType.arrowRight:
        final path = Path()..moveTo(size.width * 0.3, size.height * 0.3)..lineTo(size.width * 0.7, size.height * 0.5)..lineTo(size.width * 0.3, size.height * 0.7);
        canvas.drawPath(path, paint..strokeWidth = 2);
        break;
      case CustomIconType.flipCamera:
        final rect = Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.width * 0.35);
        canvas.drawArc(rect, -0.5, 2.5, false, paint);
        canvas.drawArc(rect, 2.5, 2.5, false, paint);
        final arrowPath1 = Path()..moveTo(size.width * 0.7, size.height * 0.3)..lineTo(size.width * 0.85, size.height * 0.35)..lineTo(size.width * 0.75, size.height * 0.45);
        canvas.drawPath(arrowPath1, paint);
        final arrowPath2 = Path()..moveTo(size.width * 0.3, size.height * 0.7)..lineTo(size.width * 0.15, size.height * 0.65)..lineTo(size.width * 0.25, size.height * 0.55);
        canvas.drawPath(arrowPath2, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ========== WAVY BACKGROUND ==========
class WavyDiagonalLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.gray75.withOpacity(0.08)..strokeWidth = 1..style = PaintingStyle.stroke;
    const spacing = 30.0;
    const waveHeight = 5.0;
    const waveFrequency = 0.08;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      final path = Path();
      path.moveTo(0, i);
      for (double x = 0; x <= size.width; x += 3) {
        final y = i - x + waveHeight * math.sin(x * waveFrequency);
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ========== RIGHT ARROW ==========
class RightArrowPainter extends CustomPainter {
  final Color color;
  RightArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 2.5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final arrowPath = Path();
    arrowPath.moveTo(size.width * 0.4, size.height * 0.2);
    arrowPath.lineTo(size.width * 0.8, size.height * 0.5);
    arrowPath.lineTo(size.width * 0.4, size.height * 0.8);
    canvas.drawPath(arrowPath, paint);
    canvas.drawLine(Offset(size.width * 0.01, size.height * 0.5), Offset(size.width * 0.75, size.height * 0.5), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
