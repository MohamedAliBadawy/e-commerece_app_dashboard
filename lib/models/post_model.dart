import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Post {
  String postId;

  String text;

  String userId;

  String imgUrl;
  List? notInterestedBy = [];

  Timestamp? createdAt;

  int comments;
  int likes;

  Post({
    required this.postId,
    required this.userId,
    required this.text,
    required this.imgUrl,
    this.notInterestedBy,
    this.createdAt,
    required this.comments,
    required this.likes,
  });

  Map<String, Object?> toDocument() {
    return {
      'postId': postId,
      'userId': userId,
      'text': text,
      'imgUrl': imgUrl,
      'notInterestedBy': notInterestedBy,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'comments': comments,
      'likes': likes,
    };
  }

  static Post fromDocument(Map<String, dynamic> doc) {
    return Post(
      postId: doc['postId'],
      userId: doc['userId'],
      text: doc['text'],
      imgUrl: doc['imgUrl'],
      notInterestedBy: doc['notInterestedBy'] ?? [],
      createdAt: doc['createdAt'],
      comments: doc['comments'],
      likes: doc['likes'],
    );
  }

  String get formattedCreatedAt {
    if (createdAt == null) return 'Not available';

    final dateTime = createdAt!.toDate();
    final formatter = DateFormat(
      'MM/dd/yyyy, hh:mm a',
    ); // Customize format as needed
    return formatter.format(dateTime);
  }
}
