import 'dart:convert';
import 'dart:io';

import 'packet_web_hit.dart';

Future<List<WebPacketHit>> searchSeedPacketsOnlineImpl(String query) async {
  final q = query.trim();
  if (q.length < 2) {
    return const [];
  }

  final queries = [
    q,
    '$q seeds',
  ];
  final hits = <WebPacketHit>[];
  final seen = <String>{};

  for (final searchQuery in queries) {
    final html = await _fetchResultsHtml(searchQuery);
    if (html == null || html.isEmpty) {
      continue;
    }
    for (final hit in _parseHits(html)) {
      if (seen.contains(hit.url) || _isSkippedHost(hit.url)) {
        continue;
      }
      seen.add(hit.url);
      hits.add(hit);
    }
  }

  hits.sort((a, b) => _hostScore(b.url).compareTo(_hostScore(a.url)));
  if (hits.length <= 8) {
    return hits;
  }
  return hits.sublist(0, 8);
}

List<WebPacketHit> _parseHits(String html) {
  final hits = <WebPacketHit>[];
  final block = RegExp(
    r'class="result__a"[^>]*href="(?<href>[^"]+)"[^>]*>(?<title>[\s\S]*?)</a>[\s\S]*?class="result__snippet"[^>]*>(?<snippet>[\s\S]*?)</a>',
    caseSensitive: false,
  );
  for (final match in block.allMatches(html)) {
    final url = _decodeDdgUrl(match.namedGroup('href')!);
    if (url.isEmpty) {
      continue;
    }
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

bool _isSkippedHost(String url) {
  final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  const skip = [
    'pinterest.',
    'youtube.',
    'youtu.be',
    'facebook.',
    'instagram.',
    'tiktok.',
    'twitter.',
    'x.com',
    'reddit.',
  ];
  return skip.any(host.contains);
}

int _hostScore(String url) {
  final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  const preferred = [
    'burpee',
    'johnnyseeds',
    'botanicalinterests',
    'ferry-morse',
    'ferrymorse',
    'rareseeds',
    'seedsavers',
    'parkseed',
    'edenbrothers',
    'territorialseed',
    'highmowing',
    'reneesgarden',
    'trueleafmarket',
    'swallowtailgardenseeds',
    'selectseeds',
    'americanmeadows',
  ];
  if (preferred.any(host.contains)) {
    return 2;
  }
  if (host.contains('seed')) {
    return 1;
  }
  return 0;
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
  if (host.contains('rareseeds') || host.contains('bakercreek')) {
    return 'Baker Creek';
  }
  if (host.contains('seedsavers')) {
    return 'Seed Savers Exchange';
  }
  if (host.contains('parkseed')) {
    return 'Park Seed';
  }
  if (host.contains('territorialseed')) {
    return 'Territorial';
  }
  if (host.contains('highmowing')) {
    return 'High Mowing';
  }
  if (host.contains('reneesgarden')) {
    return "Renee's Garden";
  }
  if (host.contains('edenbrothers')) {
    return 'Eden Brothers';
  }
  if (host.replaceFirst('www.', '').isEmpty) {
    return host;
  }
  return host.replaceFirst('www.', '');
}

Future<String?> _fetchResultsHtml(String query) async {
  final getHtml = await _readHtml((client) async {
    final request = await client.getUrl(
      Uri.https('html.duckduckgo.com', '/html/', {'q': query}),
    );
    request.headers.set(HttpHeaders.acceptHeader, 'text/html');
    request.headers.set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9');
    return request.close();
  });
  if (getHtml != null && getHtml.contains('result__a')) {
    return getHtml;
  }

  return _readHtml((client) async {
    final request = await client.postUrl(
      Uri.https('html.duckduckgo.com', '/html/'),
    );
    request.headers.contentType = ContentType(
      'application',
      'x-www-form-urlencoded',
      charset: 'utf-8',
    );
    request.headers.set(HttpHeaders.acceptHeader, 'text/html');
    request.headers.set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9');
    request.write('q=${Uri.encodeQueryComponent(query)}');
    return request.close();
  });
}

Future<String?> _readHtml(
  Future<HttpClientResponse> Function(HttpClient client) send,
) async {
  final client = HttpClient();
  client.userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';
  client.connectionTimeout = const Duration(seconds: 8);
  try {
    final response = await send(client).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      await response.drain<void>();
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
