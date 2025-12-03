import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';

import '../models/template_model.dart';
import '../providers/template_provider.dart';
import '../theme/colors.dart';

class TemplateEditorScreen extends StatefulWidget {
  const TemplateEditorScreen({super.key, this.template});

  final TemplateModel? template;

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late QuillController _quillController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    _descriptionController = TextEditingController(text: widget.template?.description ?? '');
    
    if (widget.template != null && widget.template!.content.isNotEmpty) {
      try {
        final json = jsonDecode(widget.template!.content);
        _quillController = QuillController(
          document: Document.fromJson(json),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        // Fallback for plain text
        _quillController = QuillController(
          document: Document()..insert(0, widget.template!.content),
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } else {
      _quillController = QuillController.basic();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _saveTemplate() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a template name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final content = jsonEncode(_quillController.document.toDelta().toJson());
      
      final template = TemplateModel(
        id: widget.template?.id ?? '', // ID will be ignored on create
        name: _nameController.text,
        description: _descriptionController.text,
        content: content,
        category: 'custom',
      );

      if (widget.template == null) {
        await context.read<TemplateProvider>().createTemplate(template);
      } else {
        await context.read<TemplateProvider>().updateTemplate(template);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving template: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(widget.template == null ? 'New Template' : 'Edit Template'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveTemplate,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Template Name',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Theme(
                  data: ThemeData.light().copyWith(
                    scaffoldBackgroundColor: Colors.white,
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.accent,
                      surface: Colors.white,
                      onSurface: Colors.black,
                    ),
                    textTheme: ThemeData.light().textTheme.apply(
                      bodyColor: Colors.black,
                      displayColor: Colors.black,
                    ),
                    textSelectionTheme: const TextSelectionThemeData(
                      cursorColor: Colors.black,
                      selectionColor: Color(0xFFB3D7FF),
                      selectionHandleColor: Colors.blue,
                    ),
                  ),
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Roboto',
                    ),
                    child: Column(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                            border: Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
                          ),
                          child: QuillSimpleToolbar(
                            controller: _quillController,
                          ),
                        ),
                        Expanded(
                          child: ColoredBox(
                            color: Colors.white,
                            child: QuillEditor.basic(
                              controller: _quillController,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
