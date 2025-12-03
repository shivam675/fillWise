import 'package:flutter/material.dart';

import '../services/api_service.dart';

class GeneratedDocument {
  const GeneratedDocument({
    required this.id,
    required this.title,
    required this.content,
    this.templateId,
    this.templateName,
    this.filledValues,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final String? templateId;
  final String? templateName;
  final Map<String, dynamic>? filledValues;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory GeneratedDocument.fromJson(Map<String, dynamic> json) {
    return GeneratedDocument(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      templateId: json['template_id'] as String?,
      templateName: json['template_name'] as String?,
      filledValues: json['filled_values'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class DocumentProvider extends ChangeNotifier {
  DocumentProvider(this._apiService);

  final ApiService _apiService;
  final List<GeneratedDocument> _documents = [];
  bool _isLoading = false;
  String? _error;

  List<GeneratedDocument> get documents => List.unmodifiable(_documents);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.fetchDocuments();
      _documents.clear();
      _documents.addAll(data.map((d) => GeneratedDocument.fromJson(d)));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<GeneratedDocument?> addDocument({
    required String title,
    required String content,
    String? templateId,
    String? templateName,
    Map<String, dynamic>? filledValues,
  }) async {
    try {
      final data = await _apiService.createDocument(
        title: title,
        content: content,
        templateId: templateId,
        templateName: templateName,
        filledValues: filledValues,
      );
      final doc = GeneratedDocument.fromJson(data);
      _documents.insert(0, doc);
      notifyListeners();
      return doc;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateDocument({
    required String id,
    String? title,
    String? content,
    Map<String, dynamic>? filledValues,
  }) async {
    try {
      final data = await _apiService.updateDocument(
        id: id,
        title: title,
        content: content,
        filledValues: filledValues,
      );
      final updated = GeneratedDocument.fromJson(data);
      final index = _documents.indexWhere((d) => d.id == id);
      if (index >= 0) {
        _documents[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDocument(String id) async {
    try {
      await _apiService.deleteDocument(id);
      _documents.removeWhere((d) => d.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
