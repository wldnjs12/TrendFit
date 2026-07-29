/// 백엔드 TrendArticleResponse에 대응. 홈 화면 "트렌드 리포트" 갤러리에서 쓴다.
class TrendArticle {
  final String sourceName;
  final String title;
  final String link;
  final String imageUrl;

  TrendArticle({
    required this.sourceName,
    required this.title,
    required this.link,
    required this.imageUrl,
  });

  factory TrendArticle.fromJson(Map<String, dynamic> json) {
    return TrendArticle(
      sourceName: json['sourceName'] ?? '',
      title: json['title'] ?? '',
      link: json['link'] ?? '',
      imageUrl: json['imageUrl'],
    );
  }
}
