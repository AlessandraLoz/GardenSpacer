class WebPacketHit {
  final String title;
  final String snippet;
  final String url;
  final String? brand;

  const WebPacketHit({
    required this.title,
    required this.snippet,
    required this.url,
    this.brand,
  });
}
