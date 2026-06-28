import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:medvoice_flutter/core/config/env_config.dart';
import 'package:medvoice_flutter/core/network/api_exception.dart';

/// Configured Dio HTTP client for the MedVoice Django backend.
///
/// Session cookies and CSRF handling wired using PersistCookieJar.
class DioClient {
  DioClient._internal() : _dio = Dio(
           BaseOptions(
             baseUrl: EnvConfig.baseUrl,
             connectTimeout: EnvConfig.connectTimeout,
             receiveTimeout: EnvConfig.receiveTimeout,
             headers: {
               'Accept': 'application/json',
               'Content-Type': 'application/json',
               'X-Requested-With': 'XMLHttpRequest',
             },
             extra: {'withCredentials': true},
             validateStatus: (status) => status != null && status >= 200 && status < 400,
           ),
         ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint("COOKIES LOADED");
          debugPrint("REQUEST HEADERS: ${options.headers}");
          return handler.next(options);
        },
        onError: (error, handler) {
          handler.next(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: ApiException(
                message: _messageFromResponse(error.response),
                statusCode: error.response?.statusCode,
                originalError: error,
              ),
            ),
          );
        },
      ),
    );
  }

  factory DioClient() => _instance;
  static final DioClient _instance = DioClient._internal();

  final Dio _dio;
  CookieJar? _cookieJar;

  Dio get dio => _dio;

  /// Returns the current auth token if set.
  String? get currentToken {
    final auth = _dio.options.headers['Authorization'] as String?;
    if (auth != null && auth.startsWith('Token ')) {
      return auth.substring(6);
    }
    return null;
  }

  String _messageFromResponse(Response<dynamic>? response) {
    final data = response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.isNotEmpty) return message;
    }
    return 'Request failed with status ${response?.statusCode ?? 'unknown'}.';
  }

  Future<void> init() async {
    if (_cookieJar == null) {
      if (!kIsWeb) {
        final appDocDir = await getApplicationDocumentsDirectory();
        _cookieJar = PersistCookieJar(
          ignoreExpires: true,
          persistSession: true,
          storage: FileStorage('${appDocDir.path}/.cookies/'),
        );
        _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final cookies = await _cookieJar!.loadForRequest(options.uri);
            final cookieHeader = cookies.map((c) => '${c.name}=${c.value}').join('; ');
            if (cookieHeader.isNotEmpty) {
              options.headers['Cookie'] = cookieHeader;
            }
            return handler.next(options);
          },
          onResponse: (response, handler) async {
            debugPrint("SET COOKIE HEADERS:");
            debugPrint(response.headers['set-cookie'].toString());
            final cookies = response.headers['set-cookie'];
            if (cookies != null && cookies.isNotEmpty) {
              final uri = Uri.parse(response.requestOptions.uri.toString());
              final parsedCookies = cookies.map(
                (c) => Cookie.fromSetCookieValue(c),
              ).toList();
              await _cookieJar!.saveFromResponse(uri, parsedCookies);
              final saved = await _cookieJar!.loadForRequest(uri);
              debugPrint("SAVED COOKIES:");
              debugPrint(saved.toString());
            }
            return handler.next(response);
          },
        ),
      );
      }
    }

    if (!_csrfLoaded) {
      await _loadCsrfToken();
    }
  }
  String? _csrfToken;
  bool _csrfLoaded = false;

  Future<void> _loadCsrfToken() async {
    try {
      final response = await _dio.get('/api/csrf/');
      if (response.statusCode == 200 && response.data is Map) {
        _csrfToken = response.data['csrfToken'];
        _dio.options.headers['X-CSRFToken'] = _csrfToken;
      }
    } catch (_) {}
    _csrfLoaded = true;
  }

  Future<void> setCsrfToken(String token) async {
    _csrfToken = token;
    _dio.options.headers['X-CSRFToken'] = token;
  }

  Future<void> clearCookies() async {
    await _cookieJar?.deleteAll();
    _csrfToken = null;
    _csrfLoaded = false;
    _dio.options.headers.remove('X-CSRFToken');
    _dio.options.headers.remove('Authorization');
  }
}
