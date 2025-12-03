import 'package:flutter/material.dart';

import '../models/template_model.dart';
import '../services/api_service.dart';
import '../utils/debouncer.dart';

class TemplateProvider extends ChangeNotifier {
  TemplateProvider(this._apiService) : _debouncer = Debouncer(const Duration(milliseconds: 400));

  final ApiService _apiService;
  final Debouncer _debouncer;

  List<TemplateModel> _templates = [];
  bool _isLoading = false;
  String? _error;
  String? _searchQuery;

  List<TemplateModel> get templates => _templates;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get searchQuery => _searchQuery;

  Future<void> refresh({String? query, bool debounced = true}) async {
    _searchQuery = query;
    if (debounced) {
      _debouncer.run(() => _fetch(query));
      return;
    }
    await _fetch(query);
  }

  Future<void> _fetch(String? query) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _templates = await _apiService.fetchTemplates(search: query);
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void resetError() {
    _error = null;
    notifyListeners();
  }

  Future<void> createTemplate(TemplateModel template) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _apiService.createTemplate(template);
      await _fetch(_searchQuery);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTemplate(TemplateModel template) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _apiService.updateTemplate(template);
      await _fetch(_searchQuery);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTemplate(String id) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _apiService.deleteTemplate(id);
      await _fetch(_searchQuery);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}
