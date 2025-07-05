class DocumentPage {
  final String id;
  final String originalPath;
  final String processedPath;
  final int pageNumber;
  final DateTime createdAt;
  final String? enhancedPath;
  final String? filterType;

  DocumentPage({
    required this.id,
    required this.originalPath,
    required this.processedPath,
    required this.pageNumber,
    required this.createdAt,
    this.enhancedPath,
    this.filterType,
  });

  DocumentPage copyWith({
    String? id,
    String? originalPath,
    String? processedPath,
    int? pageNumber,
    DateTime? createdAt,
    String? enhancedPath,
    String? filterType,
  }) {
    return DocumentPage(
      id: id ?? this.id,
      originalPath: originalPath ?? this.originalPath,
      processedPath: processedPath ?? this.processedPath,
      pageNumber: pageNumber ?? this.pageNumber,
      createdAt: createdAt ?? this.createdAt,
      enhancedPath: enhancedPath ?? this.enhancedPath,
      filterType: filterType ?? this.filterType,
    );
  }

  String get finalPath => enhancedPath ?? processedPath;

  // Convert to Map for PDF service compatibility
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'originalPath': originalPath,
      'processedPath': processedPath,
      'pageNumber': pageNumber,
      'createdAt': createdAt.toIso8601String(),
      'enhancedPath': enhancedPath,
      'filterType': filterType,
      'finalPath': finalPath,
    };
  }

  // Create from Map
  factory DocumentPage.fromMap(Map<String, dynamic> map) {
    return DocumentPage(
      id: map['id'],
      originalPath: map['originalPath'],
      processedPath: map['processedPath'],
      pageNumber: map['pageNumber'],
      createdAt: DateTime.parse(map['createdAt']),
      enhancedPath: map['enhancedPath'],
      filterType: map['filterType'],
    );
  }
}
