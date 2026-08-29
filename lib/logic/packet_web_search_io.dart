import 'dart:convert';
import 'dart:io';

import 'packet_web_hit.dart';

Future<List<WebPacketHit>> searchSeedPacketsOnlineImpl(String query) async {
  final q = query.trim();
  if (q.length < 2) {
    return const [];
  }

  final search = Uri.https('html.duckduckgo.com', '/html/', {
    'q': '$q seed packet spacing plants apart',
  });
  final html = await _get(search);
  if (html == null || html.isEmpty) {
    return const [];
  }

  final hits = <WebPacketHit>[];
  final seen = <String>{};
  final block = RegExp(
    r'class="result__a"[^>]*href="(?<href>[^"]+)"[^>]*>(?<title>[\s\S]*?)</a>[\s\S]*?class="result__snippet"[^>]*>(?<snippet>[\s\S]*?)</a>',
    caseSensitive: false,
  );

  for (final match in block.allMatches(html)) {
    if (hits.length >= 5) {
      break;
    }
    final url = _decodeDdgUrl(match.namedGroup('href')!);
    if (url.isEmpty || seen.contains(url)) {
      continue;
    }
    seen.add(url);
    final title = _stripTags(match.namedGroup('title')!);
    if (title.isEmpty) {
      continue;
    }
    hits.add(
      WebPacketHit(
        title: title,
        snippet: _stripTags(match.namedGroup('snippet')!),
        url: url,
        brand: brandFromUrl(url),
      ),
    );
  }
  return hits;
}

String brandFromUrl(String url) {
  final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  if (host.contains('burpee')) {
    return 'Burpee';
  }
  if (host.contains('johnnyseeds')) {
    return "Johnny's Selected Seeds";
  }
  if (host.contains('botanicalinterests')) {
    return 'Botanical Interests';
  }
  if (host.contains('ferry-morse') || host.contains('ferrymorse')) {
    return 'Ferry-Morse';
  }
  if (host.replaceFirst('www.', '').isEmpty) {
    return host;
  }
  return host.replaceFirst('www.', '');
}

Future<String?> _get(Uri uri) async {
  final client = HttpClient();
  client.userAgent =
      'Mozilla/5.0 (compatible; GardenSpacer/1.0; +https://github.com/AlessandraLoz/GardenSpacer)';
  client.connectionTimeout = const Duration(seconds: 8);
  try {
    final request = await client.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'text/html');
    final response = await request.close().timeout(const Duration(seconds: 10));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    return await response.transform(utf8.decoder).join();
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}

String _decodeDdgUrl(String href) {
  final decoded = href.replaceAll('&amp;', '&');
  final uri = Uri.tryParse(
    decoded.startsWith('//') ? 'https:$decoded' : decoded,
  );
  if (uri == null) {
    return '';
  }
  final uddg = uri.queryParameters['uddg'];
  if (uddg != null && uddg.isNotEmpty) {
    return uddg;
  }
  if (uri.hasScheme) {
    return uri.toString();
  }
  return '';
}

String _stripTags(String html) {
  return html
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&quot;', '"')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&#x27;', "'")
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
