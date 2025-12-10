enum MediaType {
  image,
  video,
}

class MediaItem {
  String id;
  String folderId;
  String filePath;
  MediaType mediaType;
  DateTime createdAt;
  String? memo;
  String? thumbnailPath;
  
  // Web platform: store base64 data
  String? webDataUrl;
  int? fileSize; // in bytes

  MediaItem({
    required this.id,
    required this.folderId,
    required this.filePath,
    required this.mediaType,
    required this.createdAt,
    this.memo,
    this.thumbnailPath,
    this.webDataUrl,
    this.fileSize,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'folderId': folderId,
      'filePath': filePath,
      'mediaType': mediaType.index,
      'createdAt': createdAt.toIso8601String(),
      'memo': memo,
      'thumbnailPath': thumbnailPath,
      'webDataUrl': webDataUrl,
      'fileSize': fileSize,
    };
  }

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      folderId: json['folderId'] as String,
      filePath: json['filePath'] as String,
      mediaType: MediaType.values[json['mediaType'] as int],
      createdAt: DateTime.parse(json['createdAt'] as String),
      memo: json['memo'] as String?,
      thumbnailPath: json['thumbnailPath'] as String?,
      webDataUrl: json['webDataUrl'] as String?,
      fileSize: json['fileSize'] as int?,
    );
  }
}
