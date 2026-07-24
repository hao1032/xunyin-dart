import 'package:dio/dio.dart';

import 'logging/app_logger.dart';

const _requestTimeout = Duration(seconds: 15);

/// 创建应用共用的 HTTP 客户端。
///
/// 仅在 logger 启用时附加脱敏请求日志；不记录请求/响应正文和请求头。
Dio createHttpClient(AppLogger logger, {BaseOptions? options}) {
  final dio = Dio(
    (options ?? BaseOptions()).copyWith(
      connectTimeout: _requestTimeout,
      sendTimeout: _requestTimeout,
      receiveTimeout: _requestTimeout,
    ),
  );
  if (logger.isEnabled) {
    dio.interceptors.add(_HttpLogInterceptor(logger));
  }
  return dio;
}

class _HttpLogInterceptor extends Interceptor {
  _HttpLogInterceptor(this._logger);

  static const _startedAtKey = 'xunyin.log.started_at';
  final AppLogger _logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = DateTime.now();
    _logger.debug('http', 'request', data: _requestData(options));
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _logger.info(
      'http',
      'response',
      data: {
        ..._requestData(response.requestOptions),
        'status_code': response.statusCode,
        'duration_ms': _elapsedMs(response.requestOptions),
      },
    );
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    final options = error.requestOptions;
    _logger.error(
      'http',
      'request_failed',
      error: error,
      stackTrace: error.stackTrace,
      data: {
        ..._requestData(options),
        'status_code': error.response?.statusCode,
        'error_type': error.type.name,
        'duration_ms': _elapsedMs(options),
      },
    );
    handler.next(error);
  }

  Map<String, Object?> _requestData(RequestOptions options) {
    return {
      'method': options.method,
      'host': options.uri.host,
      'path': options.uri.path,
    };
  }

  int? _elapsedMs(RequestOptions options) {
    final startedAt = options.extra[_startedAtKey];
    if (startedAt is! DateTime) return null;
    return DateTime.now().difference(startedAt).inMilliseconds;
  }
}
