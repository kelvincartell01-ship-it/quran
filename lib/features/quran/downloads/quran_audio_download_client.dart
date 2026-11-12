import 'dart:async';
import 'dart:io';

abstract interface class QuranAudioDownloadClient {
  Future<QuranAudioDownloadResponse> get(Uri uri, {int? rangeStart});

  Future<void> close();
}

class QuranAudioDownloadResponse {
  const QuranAudioDownloadResponse({
    required this.statusCode,
    required this.body,
    required this.contentLength,
    required this.contentRange,
    required this.abort,
  });

  final int statusCode;
  final Stream<List<int>> body;
  final int? contentLength;
  final String? contentRange;
  final void Function() abort;
}

class IoQuranAudioDownloadClient implements QuranAudioDownloadClient {
  IoQuranAudioDownloadClient({HttpClient? client})
    : _client = client ?? HttpClient();

  final HttpClient _client;

  @override
  Future<QuranAudioDownloadResponse> get(Uri uri, {int? rangeStart}) async {
    if (uri.scheme != 'https' || uri.host != 'cdn.islamic.network') {
      throw ArgumentError.value(
        uri,
        'uri',
        'Only the verified HTTPS CDN is allowed.',
      );
    }
    if (rangeStart != null && rangeStart < 1) {
      throw ArgumentError.value(rangeStart, 'rangeStart');
    }

    final request = await _client
        .getUrl(uri)
        .timeout(const Duration(seconds: 25));
    request.headers
      ..set(HttpHeaders.acceptHeader, 'audio/mpeg, audio/*')
      ..set(HttpHeaders.userAgentHeader, 'QuranApp/1.0');
    if (rangeStart != null) {
      request.headers.set(HttpHeaders.rangeHeader, 'bytes=$rangeStart-');
    }
    final response = await request.close().timeout(const Duration(seconds: 45));
    final contentLength = response.contentLength;
    return QuranAudioDownloadResponse(
      statusCode: response.statusCode,
      body: response,
      contentLength: contentLength >= 0 ? contentLength : null,
      contentRange: response.headers.value(HttpHeaders.contentRangeHeader),
      abort: () {
        request.abort(const HttpException('Audio download cancelled.'));
      },
    );
  }

  @override
  Future<void> close() async {
    _client.close(force: true);
  }
}

class QuranAudioDownloadException implements Exception {
  const QuranAudioDownloadException(
    this.message, {
    this.statusCode,
    this.retryable = false,
  });

  final String message;
  final int? statusCode;
  final bool retryable;

  @override
  String toString() => message;
}
