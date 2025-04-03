import 'dart:async';
import 'dart:core';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/src/default_retry_evaluator.dart';
import 'package:dio_smart_retry/src/http_status_codes.dart';
import 'package:dio_smart_retry/src/multipart_file_recreatable.dart';
import 'package:dio_smart_retry/src/retry_not_supported_exception.dart';

typedef RetryEvaluator = FutureOr<bool> Function(
  DioException error,
  int attempt,
  int retries,
);

/// An interceptor that will try to send failed request again
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.dio,
    this.logPrint,
    required this.getRetries,
    this.retryDelays = const [],
    RetryEvaluator? retryEvaluator,
    this.onBeforeRetry,
    this.onRetrySuccess,
    this.ignoreRetryEvaluatorExceptions = false,
    this.retryableExtraStatuses = const {},
  }) : _retryEvaluator = retryEvaluator ??
            DefaultRetryEvaluator({
              ...defaultRetryableStatuses,
              ...retryableExtraStatuses,
            }).evaluate {
    if (retryEvaluator != null && retryableExtraStatuses.isNotEmpty) {
      throw ArgumentError(
        '[retryableExtraStatuses] works only if [retryEvaluator] is null.'
            ' Set either [retryableExtraStatuses] or [retryEvaluator].'
            ' Not both.',
        'retryableExtraStatuses',
      );
    }
    if (getRetries() < 0) {
      throw ArgumentError(
        '[retries] cannot be less than 0',
        'retries',
      );
    }
  }

  static const _multipartRetryHelpLink =
      'https://github.com/rodion-m/dio_smart_retry#retry-requests-with-multipartform-data';

  /// The original dio
  final Dio dio;

  /// For logging purpose
  final void Function(String message)? logPrint;

  /// Ignore exception if [_retryEvaluator] throws it (not recommend)
  final bool ignoreRetryEvaluatorExceptions;

  /// The delays between attempts.
  /// Empty [retryDelays] means no delay.
  ///
  /// If [retries] count more than [retryDelays] count,
  ///   the last element value of [retryDelays] will be used.
  final List<Duration> retryDelays;

  /// Evaluating if a retry is necessary.regarding the error.
  ///
  /// It can be a good candidate for additional operations too, like
  ///   updating authentication token in case of a unauthorized error
  ///   (be careful with concurrency though).
  ///
  /// Defaults to [DefaultRetryEvaluator.evaluate]
  ///   with [defaultRetryableStatuses].
  final RetryEvaluator _retryEvaluator;

  final RequestOptions Function(RequestOptions)? onBeforeRetry;
  final void Function(RequestOptions)? onRetrySuccess;
  final int Function() getRetries;

  /// Specifies an extra retryable statuses,
  ///   which will be taken into account with [defaultRetryableStatuses]
  /// IMPORTANT: THIS SETTING WORKS ONLY IF [_retryEvaluator] is null
  final Set<int> retryableExtraStatuses;

  /// Redirects to [DefaultRetryEvaluator.evaluate]
  ///   with [defaultRetryableStatuses]
  static final FutureOr<bool> Function(DioException error, int attempt, int retries)
      defaultRetryEvaluator =
      DefaultRetryEvaluator(defaultRetryableStatuses).evaluate;

  Future<bool> _shouldRetry(DioException error, int attempt, int retries) async {
    try {
      return await _retryEvaluator(error, attempt, retries);
    } catch (e) {
      logPrint?.call('There was an exception in _retryEvaluator: $e');
      if (!ignoreRetryEvaluatorExceptions) {
        rethrow;
      }
    }
    return true;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _printErrorIfRequestHasMultipartFile(options);
    super.onRequest(options, handler);
  }


  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if(_checkDataNotEmpty(response)){
      super.onResponse(response, handler);
    } else {
      handler.reject(DioException(requestOptions: response.requestOptions, response: response, message: "no data"), true);
    }
  }

  @override
  Future<dynamic> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.requestOptions.disableRetry) {
      return super.onError(err, handler);
    }
    bool isRequestCancelled() =>
        err.requestOptions.cancelToken?.isCancelled ?? false;
    final retries = getRetries();
    final attempt = err.requestOptions._attempt + 1;
    final shouldRetry = retries > 0 && await _shouldRetry(err, attempt, retries);

    if (!shouldRetry) {
      return super.onError(err, handler);
    }

    err.requestOptions._attempt = attempt;
    final delay = _getDelay(attempt);
    logPrint?.call(
      '[${err.requestOptions.uri}] An error occurred during request, '
      'trying again '
      '(attempt: $attempt/$retries, '
      'wait ${delay.inMilliseconds} ms, '
      'error: ${err.error ?? err})',
    );

    var requestOptions = err.requestOptions;
    if (requestOptions.data is FormData) {
      try {
        requestOptions = _recreateOptions(err.requestOptions);
      } on RetryNotSupportedException catch (e) {
        return super.onError(
          DioException(requestOptions: requestOptions, error: e),
          handler,
        );
      }
    }

    if(onBeforeRetry != null){
      requestOptions = onBeforeRetry!.call(requestOptions);
    }

    if (delay != Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (isRequestCancelled()) {
      logPrint?.call('Request was cancelled. Cancel retrying.');
      return super.onError(err, handler);
    }

    try {
      await dio
          .fetch<void>(requestOptions)
          .then((value) {
            if(requestOptions.attempt == value.requestOptions.attempt){
              onRetrySuccess?.call(value.requestOptions);
            }
        handler.resolve(value);
      });
    } on DioException catch (e) {
      super.onError(e, handler);
    }
  }

  Duration _getDelay(int attempt) {
    if (retryDelays.isEmpty) return Duration.zero;
    return attempt - 1 < retryDelays.length
        ? retryDelays[attempt - 1]
        : retryDelays.last;
  }

  RequestOptions _recreateOptions(RequestOptions options) {
    if (options.data is! FormData) {
      throw ArgumentError(
        'requestOptions.data is not FormData',
        'requestOptions',
      );
    }
    final formData = options.data as FormData;
    final newFormData = FormData();
    newFormData.fields.addAll(formData.fields);
    for (final pair in formData.files) {
      final file = pair.value;
      if (file is MultipartFileRecreatable) {
        newFormData.files.add(MapEntry(pair.key, file.recreate()));
      } else {
        throw RetryNotSupportedException(
          'Use MultipartFileRecreatable class '
          'instead of MultipartFile to make retry available. '
          'See: $_multipartRetryHelpLink',
        );
      }
    }
    return options.copyWith(data: newFormData);
  }

  var _multipartFileChecked = false;

  void _printErrorIfRequestHasMultipartFile(RequestOptions options) {
    if (_multipartFileChecked) return;
    if (options.data is FormData) {
      final data = options.data as FormData;
      if (data.files.any((pair) => pair.value is! MultipartFileRecreatable)) {
        final printer = logPrint ?? print;
        printer(
          'WARNING: Retry is not supported for MultipartFile class. '
          'Use MultipartFileRecreatable class '
          'instead of MultipartFile to make retry available. '
          'See: $_multipartRetryHelpLink',
        );
      }
    }
    _multipartFileChecked = true;
  }

  bool _checkDataNotEmpty(Response res){
    if(!res.requestOptions.uri.path.startsWith("/api")){
      return true;
    }
    var data = res.data as Map;
    return res.data != null && data.length > 0;
  }
}

const _kDisableRetryKey = 'ro_disable_retry';

extension RequestOptionsX on RequestOptions {
  static const _kAttemptKey = 'ro_attempt';

  int get attempt => _attempt;

  bool get disableRetry => (extra[_kDisableRetryKey] as bool?) ?? false;

  set disableRetry(bool value) => extra[_kDisableRetryKey] = value;

  int get _attempt => (extra[_kAttemptKey] as int?) ?? 0;

  set _attempt(int value) => extra[_kAttemptKey] = value;
}

extension OptionsX on Options {
  bool get disableRetry => (extra?[_kDisableRetryKey] as bool?) ?? false;

  set disableRetry(bool value) {
    extra = Map.of(extra ??= <String, dynamic>{});
    extra![_kDisableRetryKey] = value;
  }
}
