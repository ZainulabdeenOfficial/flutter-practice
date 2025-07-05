class Document {
  final String id;
  final String name;
  final List<String> imagePaths;
  final String? pdfPath;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final List<String> tags;
  final int pageCount;
  final double sizeInMB;

  Document({
    required this.id,
    required this.name,
    required this.imagePaths,
    this.pdfPath,
    required this.createdAt,
    required this.modifiedAt,
    this.tags = const [],
    required this.pageCount,
    required this.sizeInMB,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imagePaths': imagePaths,
      'pdfPath': pdfPath,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'tags': tags,
      'pageCount': pageCount,
      'sizeInMB': sizeInMB,
    };
  }

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      name: json['name'],
      imagePaths: List<String>.from(json['imagePaths']),
      pdfPath: json['pdfPath'],
      createdAt: DateTime.parse(json['createdAt']),
      modifiedAt: DateTime.parse(json['modifiedAt']),
      tags: List<String>.from(json['tags'] ?? []),
      pageCount: json['pageCount'] ?? 0,
      sizeInMB: (json['sizeInMB'] ?? 0.0).toDouble(),
    );
  }

  Document copyWith({
    String? id,
    String? name,
    List<String>? imagePaths,
    String? pdfPath,
    DateTime? createdAt,
    DateTime? modifiedAt,
    List<String>? tags,
    int? pageCount,
    double? sizeInMB,
  }) {
    return Document(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePaths: imagePaths ?? this.imagePaths,
      pdfPath: pdfPath ?? this.pdfPath,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      tags: tags ?? this.tags,
      pageCount: pageCount ?? this.pageCount,
      sizeInMB: sizeInMB ?? this.sizeInMB,
    );
  }
}

