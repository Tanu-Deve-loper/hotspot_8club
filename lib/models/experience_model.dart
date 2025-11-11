class Experience {
  final int id;
  final String name;
  final String tagline;
  final String description;
  final String imageUrl;
  final String iconUrl;
  final int order;

  Experience({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.imageUrl,
    required this.iconUrl,
    required this.order,
  });

  // Create Experience from JSON
  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      tagline: json['tagline'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      iconUrl: json['icon_url'] ?? '',
      order: json['order'] ?? 0,
    );
  }

  // Convert Experience to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tagline': tagline,
      'description': description,
      'image_url': imageUrl,
      'icon_url': iconUrl,
      'order': order,
    };
  }

  // CopyWith method for immutable updates
  Experience copyWith({
    int? id,
    String? name,
    String? tagline,
    String? description,
    String? imageUrl,
    String? iconUrl,
    int? order,
  }) {
    return Experience(
      id: id ?? this.id,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      iconUrl: iconUrl ?? this.iconUrl,
      order: order ?? this.order,
    );
  }
}

// API Response Model
class ExperiencesResponse {
  final String message;
  final List<Experience> experiences;

  ExperiencesResponse({
    required this.message,
    required this.experiences,
  });

  // Create ExperiencesResponse from JSON
  factory ExperiencesResponse.fromJson(Map<String, dynamic> json) {
    return ExperiencesResponse(
      message: json['message'] ?? '',
      experiences: (json['data']['experiences'] as List)
          .map((exp) => Experience.fromJson(exp))
          .toList(),
    );
  }
}
