import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

typedef CoverFallbackBuilder = Widget Function(BuildContext context);

class CachedCoverImage extends StatelessWidget {
  const CachedCoverImage({
    super.key,
    required this.url,
    required this.placeholderBuilder,
    this.errorBuilder,
    this.fit = BoxFit.cover,
    this.decodeLogicalSize,
  });

  final String? url;
  final CoverFallbackBuilder placeholderBuilder;
  final CoverFallbackBuilder? errorBuilder;
  final BoxFit fit;
  final Size? decodeLogicalSize;

  static final Map<String, Future<File>> _pendingDownloads = {};

  @override
  Widget build(BuildContext context) {
    final value = url?.trim();
    if (value == null || value.isEmpty) {
      return placeholderBuilder(context);
    }

    return FutureBuilder<File>(
      future: _cachedFile(value),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file != null) {
          final decodeSize = decodeLogicalSize;
          final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
          return Image.file(
            file,
            fit: fit,
            cacheWidth: decodeSize == null
                ? null
                : (decodeSize.width * devicePixelRatio).round(),
            cacheHeight: decodeSize == null
                ? null
                : (decodeSize.height * devicePixelRatio).round(),
            gaplessPlayback: true,
            errorBuilder: (_, _, _) =>
                (errorBuilder ?? placeholderBuilder)(context),
          );
        }
        if (snapshot.hasError) {
          return (errorBuilder ?? placeholderBuilder)(context);
        }
        return placeholderBuilder(context);
      },
    );
  }

  static Future<File> _cachedFile(String url) {
    return _pendingDownloads.putIfAbsent(url, () async {
      try {
        final directory = await _cacheDirectory();
        final file = File('${directory.path}/${_cacheKey(url)}.img');
        if (await file.exists() && await file.length() > 0) return file;

        final temp = File(
          '${file.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
        );
        await _download(url, temp);
        return temp.rename(file.path);
      } finally {
        _pendingDownloads.remove(url);
      }
    });
  }

  static Future<Directory> _cacheDirectory() async {
    final base = await getTemporaryDirectory();
    final directory = Directory('${base.path}/cover_cache');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  static String _cacheKey(String url) {
    return sha1.convert(url.codeUnits).toString();
  }

  static Future<void> _download(String url, File destination) async {
    final uri = Uri.parse(url);
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/126 Safari/537.36',
      );
      request.headers.set(
        HttpHeaders.refererHeader,
        'https://www.bilibili.com/',
      );

      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Cover download failed with HTTP ${response.statusCode}',
          uri: uri,
        );
      }

      final sink = destination.openWrite();
      try {
        await response.pipe(sink);
      } catch (_) {
        await sink.close();
        rethrow;
      }
    } finally {
      client.close(force: true);
    }
  }
}
