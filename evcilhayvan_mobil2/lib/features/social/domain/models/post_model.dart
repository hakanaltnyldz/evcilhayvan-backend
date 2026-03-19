class PostComment {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String text;
  final DateTime? createdAt;

  const PostComment({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.text,
    this.createdAt,
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
    );
  }

  Post copyWith({List<String>? likes, List<PostComment>? comments}) {
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
    );
  }
}
