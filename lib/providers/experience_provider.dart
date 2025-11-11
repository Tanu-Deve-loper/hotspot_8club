import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/experience_model.dart';
import '../services/api_service.dart';

// Provider for API Service
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Provider to fetch experiences from API
final experiencesProvider = FutureProvider<List<Experience>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final response = await apiService.fetchExperiences();
  return response.experiences;
});

// State class for managing selected experiences
class ExperienceSelectionState {
  final List<int> selectedExperienceIds;
  final String experienceText;

  ExperienceSelectionState({
    this.selectedExperienceIds = const [],
    this.experienceText = '',
  });

  ExperienceSelectionState copyWith({
    List<int>? selectedExperienceIds,
    String? experienceText,
  }) {
    return ExperienceSelectionState(
      selectedExperienceIds: selectedExperienceIds ?? this.selectedExperienceIds,
      experienceText: experienceText ?? this.experienceText,
    );
  }
}

// StateNotifier for managing experience selection
class ExperienceSelectionNotifier extends StateNotifier<ExperienceSelectionState> {
  ExperienceSelectionNotifier() : super(ExperienceSelectionState());

  // Toggle experience selection
  void toggleExperience(int experienceId) {
    final currentIds = List<int>.from(state.selectedExperienceIds);
    
    if (currentIds.contains(experienceId)) {
      currentIds.remove(experienceId);
    } else {
      currentIds.add(experienceId);
    }
    
    state = state.copyWith(selectedExperienceIds: currentIds);
  }

  // Update experience text
  void updateExperienceText(String text) {
    state = state.copyWith(experienceText: text);
  }

  // Check if experience is selected
  bool isSelected(int experienceId) {
    return state.selectedExperienceIds.contains(experienceId);
  }

  // Get count of selected experiences
  int get selectedCount => state.selectedExperienceIds.length;

  // Reset selections
  void reset() {
    state = ExperienceSelectionState();
  }
}

// Provider for experience selection state
final experienceSelectionProvider = 
    StateNotifierProvider<ExperienceSelectionNotifier, ExperienceSelectionState>((ref) {
  return ExperienceSelectionNotifier();
});
