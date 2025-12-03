import 'package:dio/dio.dart';

import '../models/template_model.dart';

class ApiService {
  ApiService({Dio? dio}) : _dio = dio ?? Dio(_options) {
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        return handler.next(
          DioException(
            requestOptions: error.requestOptions,
            error: error.error,
            response: error.response,
            type: error.type,
            message: error.message ?? 'Network error',
          ),
        );
      },
    ));
  }

  static final BaseOptions _options = BaseOptions(
    baseUrl: const String.fromEnvironment('API_BASE_URL',
        defaultValue: 'http://localhost:8000'),
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 25),
    contentType: 'application/json',
  );

  final Dio _dio;

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

  Future<String?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: FormData.fromMap({
          'username': email,
          'password': password,
        }),
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      return response.data['access_token'];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> signup(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/users/',
        data: {
          'email': email,
          'password': password,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchCurrentUser() async {
    final response = await _dio.get('/api/users/me');
    return response.data;
  }

  Future<Map<String, dynamic>> updateUser(Map<String, dynamic> data) async {
    final response = await _dio.put('/api/users/me', data: data);
    return response.data;
  }

  Future<List<TemplateModel>> fetchTemplates({String? search}) async {
    final query = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final Response<dynamic> response = await _dio.get<dynamic>(
      '/api/templates',
      queryParameters: query.isEmpty ? null : query,
    );
    final dynamic payload = response.data;
    final List<dynamic> rawItems;
    if (payload is List) {
      rawItems = payload;
    } else if (payload is Map<String, dynamic>) {
      rawItems = (payload['items'] as List<dynamic>?) ?? const [];
    } else {
      rawItems = const [];
    }
    return rawItems
        .map((item) =>
            TemplateModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<TemplateModel> createTemplate(TemplateModel model) async {
    final payload = Map<String, dynamic>.from(model.toJson());
    payload.remove('id');
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/templates/',
      data: payload,
    );
    return TemplateModel.fromJson(response.data!);
  }

  Future<TemplateModel> updateTemplate(TemplateModel model) async {
    final payload = Map<String, dynamic>.from(model.toJson());
    payload.remove('id');
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/templates/${model.id}',
      data: payload,
    );
    return TemplateModel.fromJson(response.data!);
  }

  Future<void> deleteTemplate(String id) async {
    await _dio.delete('/api/templates/$id');
  }

  Future<Map<String, dynamic>> sendMessage({
    required String message,
    String? sessionId,
    String? templateId,
    Map<String, dynamic>? variables,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/chat/message',
      data: {
        'message': message,
        'session_id': sessionId,
        'template_id': templateId,
        'variables': variables,
      },
    );
    return response.data!;
  }

  // Document APIs
  Future<List<Map<String, dynamic>>> fetchDocuments() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/documents');
    final data = response.data!;
    return List<Map<String, dynamic>>.from(data['items'] as List);
  }

  Future<Map<String, dynamic>> getDocument(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/documents/$id');
    return response.data!;
  }

  Future<Map<String, dynamic>> createDocument({
    required String title,
    required String content,
    String? templateId,
    String? templateName,
    Map<String, dynamic>? filledValues,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/documents',
      data: {
        'title': title,
        'content': content,
        'template_id': templateId,
        'template_name': templateName,
        'filled_values': filledValues ?? {},
      },
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> updateDocument({
    required String id,
    String? title,
    String? content,
    Map<String, dynamic>? filledValues,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/documents/$id',
      data: {
        if (title != null) 'title': title,
        if (content != null) 'content': content,
        if (filledValues != null) 'filled_values': filledValues,
      },
    );
    return response.data!;
  }

  Future<void> deleteDocument(String id) async {
    await _dio.delete('/api/documents/$id');
  }

  Future<Map<String, dynamic>> getSettings() async {
    final response = await _dio.get('/api/settings/');
    return response.data;
  }

  Future<Map<String, dynamic>> updateSettings(
      Map<String, dynamic> settings) async {
    final response = await _dio.post('/api/settings/', data: settings);
    return response.data;
  }

  Future<Map<String, dynamic>> getToolCapableModels() async {
    final response = await _dio.get('/api/settings/tool-capable-models');
    return response.data;
  }

  Future<Map<String, dynamic>> testOllamaConnection(
      Map<String, dynamic> settings) async {
    final response =
        await _dio.post('/api/settings/test-connection', data: settings);
    return response.data;
  }
}
