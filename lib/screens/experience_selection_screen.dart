import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../providers/experience_selection_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/constants.dart';
import 'question_screen.dart';

class ExperienceSelectionScreen extends ConsumerStatefulWidget {
  const ExperienceSelectionScreen({super.key});

  @override
  ConsumerState<ExperienceSelectionScreen> createState() =>
      _ExperienceSelectionScreenState();
}

class _ExperienceSelectionScreenState
    extends ConsumerState<ExperienceSelectionScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isKeyboardVisible = false;

  final List<double> _rotationAngles = [
    -0.05, 0.03, -0.04, 0.06, -0.03, 0.05, -0.06, 0.04,
    -0.05, 0.03, -0.04, 0.06, -0.03, 0.05, -0.06, 0.04, -0.05, 0.03
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(experienceSelectionProvider.notifier).fetchExperiences();
    });
    
    _focusNode.addListener(() {
      setState(() {
        _isKeyboardVisible = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final experienceState = ref.watch(experienceSelectionProvider);
    final hasSelection = experienceState.selectedExperienceIds.isNotEmpty;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;

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
            decoration: BoxDecoration(
              color: AppColors.gray75,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                '←',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppColors.black75,
                title: Text(
                  'Coming Soon',
                  style: AppTextStyles.heading3.copyWith(color: AppColors.white),
                ),
                content: Text(
                  'This feature will be available soon!',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray50),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.blue75,
                    ),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
        ),
        title: Text(
          '01',
          style: AppTextStyles.caption.copyWith(color: AppColors.gray50),
        ),
        actions: [
          IconButton(
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.gray75,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'X',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  backgroundColor: AppColors.black75,
                  title: Text(
                    'Clear All?',
                    style: AppTextStyles.heading3.copyWith(color: AppColors.white),
                  ),
                  content: Text(
                    'Are you sure you want to clear all selections and go back to start?',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray50),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.gray50),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Close dialog first
                        Navigator.pop(dialogContext);
                        
                        // Reset selections in provider
                        try {
                          ref.read(experienceSelectionProvider.notifier).clearSelection();
                        } catch (e) {
                          debugPrint('Error clearing selection: $e');
                        }
                        
                        // Clear text field
                        if (_textController.text.isNotEmpty) {
                          _textController.clear();
                        }
                        
                        // Go back safely
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.red100,
                      ),
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      // ========== BODY ==========
      body: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: WavyDiagonalLinesPainter(),
          ),
          
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
                    fontSize: isKeyboardOpen ? 18 : 24,
                    fontWeight: FontWeight.w600,
                  ),
                  child: const Text(
                    'What kind of hotspots do you want to host?',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              if (experienceState.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.blue75),
                  ),
                )
              else if (experienceState.errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      experienceState.errorMessage!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.red100,
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: isKeyboardOpen ? 140 : 180,
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    itemCount: experienceState.experiences.length,
                    itemBuilder: (context, index) {
                      final experience = experienceState.experiences[index];
                      final isSelected = ref
                          .read(experienceSelectionProvider.notifier)
                          .isSelected(experience.id);

                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _buildStampCard(
                          experience.name,
                          experience.imageUrl,
                          isSelected,
                          index,
                          isKeyboardOpen,
                          () {
                            ref
                                .read(experienceSelectionProvider.notifier)
                                .toggleExperience(experience.id);
                          },
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: isKeyboardOpen ? 2 : 4,
                  maxLength: AppConstants.experienceTextLimit,
                  onChanged: (value) {
                    ref
                        .read(experienceSelectionProvider.notifier)
                        .updateExperienceText(value);
                  },
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: '/ Describe your perfect hotspot',
                    hintStyle: AppTextStyles.hint.copyWith(
                      color: AppColors.gray75,
                    ),
                    counterStyle: AppTextStyles.caption.copyWith(
                      color: AppColors.gray50,
                    ),
                    filled: true,
                    fillColor: AppColors.black75.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.blue75,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _buildNextButton(hasSelection),

              SizedBox(height: keyboardHeight),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStampCard(
    String name,
    String imageUrl,
    bool isSelected,
    int index,
    bool isCompact,
    VoidCallback onTap,
  ) {
    final rotation = _rotationAngles[index % _rotationAngles.length];
    final cardWidth = isCompact ? 100.0 : 130.0;
    final cardHeight = isCompact ? 130.0 : 170.0;

    return Transform.rotate(
      angle: rotation,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: ClipPath(
            clipper: StampClipper(),
            child: Stack(
              children: [
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    isSelected ? Colors.transparent : Colors.grey,
                    isSelected ? BlendMode.dst : BlendMode.saturation,
                  ),
                  child: Image.network(
                    imageUrl,
                    width: cardWidth,
                    height: cardHeight,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: cardWidth,
                        height: cardHeight,
                        color: AppColors.gray75,
                        child: const Center(
                          child: Icon(Icons.error, color: AppColors.white, size: 20),
                        ),
                      );
                    },
                  ),
                ),

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 6,
                  left: 6,
                  right: 6,
                  child: Text(
                    name.toUpperCase(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isCompact ? 9 : 11,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),

                if (isSelected)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.white.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton(bool isEnabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.gray75.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.gray50.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),

          if (isEnabled)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.25),
                    ],
                  ),
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
                          left: value * MediaQuery.of(context).size.width,
                          child: Container(
                            width: 150,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withOpacity(0.5),
                                  Colors.transparent,
                                ],
                              ),
                            ),
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
              onTap: isEnabled
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QuestionScreen(),
                        ),
                      );
                    }
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 56,
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Next',
                      style: AppTextStyles.button.copyWith(
                        color: isEnabled ? AppColors.white : AppColors.gray50,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Better arrow
                    CustomPaint(
                      size: const Size(22, 22),
                      painter: RightArrowPainter(
                        color: isEnabled ? AppColors.white : AppColors.gray50,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StampClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const zigzagSize = 6.0;
    const halfZigzag = zigzagSize / 2;

    path.moveTo(0, halfZigzag);

    for (double x = 0; x < size.width; x += zigzagSize) {
      path.lineTo(x + halfZigzag, 0);
      path.lineTo(x + zigzagSize, halfZigzag);
    }

    for (double y = halfZigzag; y < size.height; y += zigzagSize) {
      path.lineTo(size.width, y + halfZigzag);
      path.lineTo(size.width - halfZigzag, y + zigzagSize);
    }

    for (double x = size.width; x > 0; x -= zigzagSize) {
      path.lineTo(x - halfZigzag, size.height);
      path.lineTo(x - zigzagSize, size.height - halfZigzag);
    }

    for (double y = size.height - halfZigzag; y > 0; y -= zigzagSize) {
      path.lineTo(0, y - halfZigzag);
      path.lineTo(halfZigzag, y - zigzagSize);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class WavyDiagonalLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromARGB(255, 83, 83, 83).withValues(alpha: 0.08)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 30.0;
    const waveHeight = 10.0;
    const waveFrequency = 0.09;

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

// ========== BETTER RIGHT ARROW ==========
class RightArrowPainter extends CustomPainter {
  final Color color;

  RightArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw arrow pointing RIGHT (clean design)
    final arrowPath = Path();
    
    // Arrow head
    arrowPath.moveTo(size.width * 0.4, size.height * 0.2);
    arrowPath.lineTo(size.width * 0.8, size.height * 0.5);
    arrowPath.lineTo(size.width * 0.4, size.height * 0.8);
    
    canvas.drawPath(arrowPath, paint);
    
    // Arrow line (from left to tip)
    canvas.drawLine(
      Offset(size.width * 0.01, size.height * 0.5),
      Offset(size.width * 0.75, size.height * 0.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
