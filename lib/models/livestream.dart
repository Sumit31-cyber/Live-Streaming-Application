class LiveStream {
  final String title;
  final String image;
  final String uid;
  final String userName;
  final startedAt;
  final int viewers;
  final String channelId;

  LiveStream(
      {required this.title,
      required this.image,
      required this.uid,
      required this.userName,
      required this.startedAt,
      required this.viewers,
      required this.channelId});

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'image': image,
      'uid': uid,
      'userName': userName,
      'startedAt': startedAt,
      'viewers': viewers,
      'channelId': channelId,
    };
  }

  factory LiveStream.fromMap(Map<String, dynamic> map) {
    return LiveStream(
        title: map['title'] ?? '',
        image: map['image'] ?? '',
        uid: map['uid'] ?? '',
        userName: map['userName'] ?? '',
        startedAt: map['startedAt'] ?? '',
        viewers: map['viewers']?.toInt() ?? 0,
        channelId: map['channelId'] ?? '');
  }
}
