class PostReply {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String text;
  final DateTime? createdAt;

  const PostReply({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.text,
    this.createdAt,
  });

  factory PostReply.fromJson(Map<String, dynamic> json) {
    return PostReply(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName'] ?? '',
      userAvatar: json['userAvatar'],
      text: json['text'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class PostComment {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String text;
  final DateTime? createdAt;
  final List<PostReply> replies;

  const PostComment({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.text,
    this.createdAt,
    this.replies = const [],
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName'] ?? '',
      userAvatar: json['userAvatar'],
      text: json['text'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      replies: (json['replies'] as List?)
              ?.map((r) => PostReply.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Post {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String? content;
  final List<String> photos;
  final String? petId;
  final String? petName;
  final List<String> likes;
  final List<PostComment> comments;
  final DateTime? createdAt;
  final int likeCount;
  final int saveCount;
  final bool isLiked;
  final bool isSaved;
  final List<String> hashtags;

  const Post({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.content,
    required this.photos,
    this.petId,
    this.petName,
    required this.likes,
    required this.comments,
    this.createdAt,
    this.likeCount = 0,
    this.saveCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.hashtags = const [],
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final likesList = (json['likes'] as List?)
            ?.map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];
    final commentsList = (json['comments'] as List?)
            ?.map((c) => PostComment.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [];
    final photosList = (json['photos'] as List?)
            ?.whereType<String>()
            .toList() ??
        [];

    return Post(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName'] ?? '',
      userAvatar: json['userAvatar'],
      content: json['content'],
      photos: photosList,
      petId: json['petId']?.toString(),
      petName: json['petName'],
      likes: likesList,
      comments: commentsList,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? likesList.length,
      saveCount: (json['saveCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] == true,
      isSaved: json['isSaved'] == true,
      hashtags: (json['hashtags'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Post copyWith({List<String>? likes, List<PostComment>? comments, bool? isLiked, bool? isSaved, int? likeCount, int? saveCount}) {
    return Post(
      id: id,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      content: content,
      photos: photos,
      petId: petId,
      petName: petName,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      saveCount: saveCount ?? this.saveCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      hashtags: hashtags,
    );
  }
}
