import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/experience_model.dart';
import '../providers/experience_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/constants.dart';
import '../utils/image_utils.dart';

class ExperienceCard extends ConsumerWidget {
  final Experience experience;

  const ExperienceCard({
    super.key,
    required this.experience,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the state to rebuild when selection changes
    final selectionState = ref.watch(experienceSelectionProvider);
    final isSelected = selectionState.selectedExperienceIds.contains(experience.id);

    return GestureDetector(
      onTap: () {
        ref.read(experienceSelectionProvider.notifier).toggleExperience(experience.id);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.green100 : AppColors.transparent,
            width: isSelected ? 3 : 0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              ColorFiltered(
                colorFilter: isSelected
                    ? const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.multiply,
                      )
                    : ImageUtils.grayscale,
                child: CachedNetworkImage(
                  imageUrl: experience.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.gray25,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.blue75,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.gray25,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: AppColors.gray50,
                      size: 32,
                    ),
                  ),
                ),
              ),
              
              // Gradient Overlay (for better text readability)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              
              // Experience Info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Experience Name
                      Text(
                        experience.name,
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.pureWhite,
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // Experience Description
                      Text(
                        experience.description,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.pureWhite,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Selection Indicator (Green Check)
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.green100,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '✓',  // Unicode checkmark
                        style: TextStyle(
                          color: AppColors.black100,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
