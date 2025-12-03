import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider(this._apiService) {
    _sessionId = const Uuid().v4();
  }

  final ApiService _apiService;
  final List<ChatMessageModel> _messages = [];
  bool _isSending = false;
  String? _error;
  late String _sessionId;

  // Conversation state tracking
  String _conversationState = 'idle';
  String? _detectedTemplateId;
  List<String> _pendingFields = [];
  Map<String, dynamic> _collectedValues = {};
  String? _generatedDocument;
  String? _documentTitle;

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;
  String? get error => _error;
  String get sessionId => _sessionId;
  String get conversationState => _conversationState;
  String? get detectedTemplateId => _detectedTemplateId;
  List<String> get pendingFields => _pendingFields;
  Map<String, dynamic> get collectedValues => _collectedValues;
  String? get generatedDocument => _generatedDocument;
  String? get documentTitle => _documentTitle;

  bool get hasGeneratedDocument =>
      _generatedDocument != null && _generatedDocument!.isNotEmpty;

  void resetSession() {
    _sessionId = const Uuid().v4();
    _messages.clear();
    _conversationState = 'idle';
    _detectedTemplateId = null;
    _pendingFields = [];
    _collectedValues = {};
    _generatedDocument = null;
    _documentTitle = null;
    _error = null;
    notifyListeners();
  }

  Future<void> sendMessage(String text,
      {String? templateId, Map<String, dynamic>? variables}) async {
    _isSending = true;
    _error = null;
    final pendingMessage = ChatMessageModel(
      id: const Uuid().v4(),
      message: text,
      isUser: true,
      templateId: templateId,
      timestamp: DateTime.now(),
    );
    _messages.add(pendingMessage);
    notifyListeners();

    try {
      final response = await _apiService.sendMessage(
        message: text,
        sessionId: _sessionId,
        templateId: templateId,
        variables: variables,
      );

      // Update conversation state from response
      _conversationState = response['state'] as String? ?? 'idle';
      _detectedTemplateId = response['template_id'] as String?;
      _pendingFields = List<String>.from(response['pending_fields'] ?? []);
      _collectedValues =
          Map<String, dynamic>.from(response['collected_values'] ?? {});
      _generatedDocument = response['generated_document'] as String?;
      _documentTitle = response['document_title'] as String?;

      // Add AI response to messages
      final reply = ChatMessageModel(
        id: const Uuid().v4(),
        message: response['reply'] as String,
        isUser: false,
        templateId: _detectedTemplateId,
        timestamp: DateTime.now(),
        metadata: {
          'state': _conversationState,
          'hasDocument': _generatedDocument != null,
        },
      );
      _messages.add(reply);
    } catch (error) {
      _error = error.toString();
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> saveGeneratedDocument() async {
    if (_generatedDocument == null || _documentTitle == null) {
      return null;
    }

    try {
      final doc = await _apiService.createDocument(
        title: _documentTitle!,
        content: _generatedDocument!,
        templateId: _detectedTemplateId,
        filledValues: _collectedValues,
      );

      // Reset the document state after saving
      _generatedDocument = null;
      _documentTitle = null;
      notifyListeners();

      return doc;
    } catch (e) {
      _error = 'Failed to save document: $e';
      notifyListeners();
      return null;
    }
  }
}
