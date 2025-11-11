import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/experience_model.dart';
import '../services/api_service.dart';

class ExperienceSelectionState {
  final List<Experience> experiences;
  final bool isLoading;
  final String? errorMessage;
  final List<int> selectedExperienceIds;
  final String experienceText;

  ExperienceSelectionState({
    this.experiences = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedExperienceIds = const [],
    this.experienceText = '',
  });

  ExperienceSelectionState copyWith({
    List<Experience>? experiences,
    bool? isLoading,
    String? errorMessage,
    List<int>? selectedExperienceIds,
    String? experienceText,
  }) {
    return ExperienceSelectionState(
      experiences: experiences ?? this.experiences,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedExperienceIds: selectedExperienceIds ?? this.selectedExperienceIds,
      experienceText: experienceText ?? this.experienceText,
    );
  }
}

class ExperienceSelectionNotifier extends StateNotifier<ExperienceSelectionState> {
  ExperienceSelectionNotifier() : super(ExperienceSelectionState());

  final ApiService _apiService = ApiService();

  Future<void> fetchExperiences() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _apiService.fetchExperiences();
      state = state.copyWith(
        experiences: response.experiences,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void toggleExperience(int experienceId) {
    final currentSelection = List<int>.from(state.selectedExperienceIds);
    
    if (currentSelection.contains(experienceId)) {
      currentSelection.remove(experienceId);
    } else {
      currentSelection.add(experienceId);
    }

    state = state.copyWith(selectedExperienceIds: currentSelection);
  }

  bool isSelected(int experienceId) {
    return state.selectedExperienceIds.contains(experienceId);
  }

  void updateExperienceText(String text) {
    state = state.copyWith(experienceText: text);
  }

  // NEW METHOD - Clear all selections
  void clearSelection() {
    state = ExperienceSelectionState(
      experiences: state.experiences,
      isLoading: state.isLoading,
      errorMessage: state.errorMessage,
      selectedExperienceIds: [],
      experienceText: '',
    );
  }
}

final experienceSelectionProvider =
    StateNotifierProvider<ExperienceSelectionNotifier, ExperienceSelectionState>(
  (ref) => ExperienceSelectionNotifier(),
);
