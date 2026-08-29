import 'packet_web_hit.dart';
import 'packet_web_search_stub.dart'
    if (dart.library.io) 'packet_web_search_io.dart' as impl;

export 'packet_web_hit.dart';

Future<List<WebPacketHit>> searchSeedPacketsOnline(String query) {
  return impl.searchSeedPacketsOnlineImpl(query);
}

String packetNameFromTitle(String title) {
  return title
      .replaceAll(RegExp(r'\s*[|\-–].*$'), '')
      .replaceAll(RegExp(r'\s+seeds?\b', caseSensitive: false), '')
      .trim();
}
