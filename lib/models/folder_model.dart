class FolderModel {
  String id;
  String name;
  DateTime createdAt;
  String? coverImagePath;
  int mediaCount;

  FolderModel({
    required this.id,
    required this.name,
    required this.createdAt,
    this.coverImagePath,
    this.mediaCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'coverImagePath': coverImagePath,
      'mediaCount': mediaCount,
    };
  }

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      coverImagePath: json['coverImagePath'] as String?,
      mediaCount: json['mediaCount'] as int? ?? 0,
    );
  }
}
