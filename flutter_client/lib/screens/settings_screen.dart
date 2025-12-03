import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _baseUrlController =
      TextEditingController(text: 'http://localhost:11434');
  final _modelNameController = TextEditingController(text: 'llama3.1:8b');
  final _systemPromptController = TextEditingController();
  final _temperatureController = TextEditingController(text: '0.7');
  final _topPController = TextEditingController(text: '0.9');
  final _topKController = TextEditingController(text: '40');
  final _numCtxController = TextEditingController(text: '4096');
  final _repeatPenaltyController = TextEditingController(text: '1.1');

  bool _isLoading = false;
  String? _testStatus;
  bool? _modelFound;
  String? _modelTestResult;
  bool? _supportsTools;

  // Tool calling mode
  bool _useToolCalling = true;
  List<String> _toolCapableModels = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<AuthProvider>().apiService;

      // Load settings and tool-capable models in parallel
      final results = await Future.wait([
        api.getSettings(),
        api.getToolCapableModels(),
      ]);

      final settings = results[0] as Map<String, dynamic>;
      final toolModelsData = results[1] as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _baseUrlController.text =
              settings['base_url'] ?? 'http://localhost:11434';
          _modelNameController.text = settings['model_name'] ?? 'llama3.1:8b';
          _systemPromptController.text = settings['system_prompt'] ?? '';
          _temperatureController.text =
              (settings['temperature'] ?? 0.7).toString();
          _topPController.text = (settings['top_p'] ?? 0.9).toString();
          _topKController.text = (settings['top_k'] ?? 40).toString();
          _numCtxController.text = (settings['num_ctx'] ?? 4096).toString();
          _repeatPenaltyController.text =
              (settings['repeat_penalty'] ?? 1.1).toString();
          _useToolCalling = settings['use_tool_calling'] ?? true;

          // Load tool-capable models list
          _toolCapableModels =
              List<String>.from(toolModelsData['models'] ?? []);
        });
      }
    } catch (e) {
      // Handle error silently or show toast
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<AuthProvider>().apiService;
      await api.updateSettings({
        'base_url': _baseUrlController.text,
        'model_name': _modelNameController.text,
        'system_prompt': _systemPromptController.text,
        'temperature': double.tryParse(_temperatureController.text) ?? 0.7,
        'top_p': double.tryParse(_topPController.text) ?? 0.9,
        'top_k': int.tryParse(_topKController.text) ?? 40,
        'num_ctx': int.tryParse(_numCtxController.text) ?? 4096,
        'repeat_penalty': double.tryParse(_repeatPenaltyController.text) ?? 1.1,
        'use_tool_calling': _useToolCalling,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _testStatus = null;
      _modelFound = null;
      _modelTestResult = null;
      _supportsTools = null;
    });
    try {
      final api = context.read<AuthProvider>().apiService;
      final result = await api.testOllamaConnection({
        'base_url': _baseUrlController.text,
        'model_name': _modelNameController.text,
      });
      if (mounted) {
        setState(() {
          final models = result['models'] as List? ?? [];
          _modelFound = result['model_found'] as bool? ?? false;
          _modelTestResult = result['model_test'] as String?;
          _supportsTools = result['supports_tools'] as bool? ?? false;

          if (_modelFound == true) {
            _testStatus =
                'Connection Successful! Model "${_modelNameController.text}" found and tested.';
            if (_modelTestResult != null) {
              _testStatus = '$_testStatus\n$_modelTestResult';
            }
            if (_supportsTools == true) {
              _testStatus =
                  '$_testStatus\n✅ Model supports native tool calling.';
            } else {
              _testStatus =
                  '$_testStatus\n⚠️ Model may not support native tool calling. LLM mode recommended.';
            }
          } else {
            _testStatus =
                'Connection OK but model "${_modelNameController.text}" not found.\nAvailable models: ${models.map((m) => m['name']).join(', ')}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testStatus = 'Connection Failed: $e';
          _modelFound = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _modelNameController.dispose();
    _systemPromptController.dispose();
    _temperatureController.dispose();
    _topPController.dispose();
    _topKController.dispose();
    _numCtxController.dispose();
    _repeatPenaltyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Ollama Connection',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _baseUrlController,
          label: 'Ollama Base URL',
          hint: 'http://localhost:11434',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _modelNameController,
          label: 'Model Name',
          hint: 'llama3',
          helperText:
              'The exact name of the model to use (e.g., llama3, mistral, codellama)',
        ),
        const SizedBox(height: 24),

        // Test Connection Status
        if (_testStatus != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: (_modelFound == true)
                  ? AppColors.success.withValues(alpha: 0.1)
                  : (_modelFound == false)
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (_modelFound == true)
                    ? AppColors.success
                    : (_modelFound == false)
                        ? AppColors.error
                        : AppColors.info,
              ),
            ),
            child: Text(
              _testStatus!,
              style: TextStyle(
                color: (_modelFound == true)
                    ? AppColors.success
                    : (_modelFound == false)
                        ? AppColors.error
                        : AppColors.info,
              ),
            ),
          ),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _testConnection,
                icon: _isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.wifi_tethering),
                label: const Text('Test Connection & Model'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.accent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),
        const Divider(color: AppColors.textSecondary),
        const SizedBox(height: 24),

        // Tool Calling Mode Section
        const Text(
          'AI Processing Mode',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose how the AI processes your document requests.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _useToolCalling
                              ? 'Native Tool Calling Mode'
                              : 'LLM Structured Mode',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _useToolCalling
                              ? 'Uses Ollama\'s native function calling. Best for tool-capable models (llama3.1, qwen2.5, etc.)'
                              : 'Uses structured JSON prompts. Works with any model but may be less reliable.',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _useToolCalling,
                    onChanged: (value) {
                      setState(() => _useToolCalling = value);
                    },
                    activeColor: AppColors.accent,
                    activeTrackColor: AppColors.accent.withValues(alpha: 0.3),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.textSecondary, height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    _useToolCalling ? Icons.build_circle : Icons.psychology,
                    size: 20,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _useToolCalling
                          ? 'AI can call: list_templates, select_template, get_template_fields, generate_document'
                          : 'AI uses JSON responses to simulate tool actions',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              if (_toolCapableModels.isNotEmpty) ...[
                const SizedBox(height: 8),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: 8),
                  title: const Text(
                    'Tool-capable models',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _toolCapableModels.take(15).map((model) {
                        final isCurrentModel =
                            _modelNameController.text.contains(model) ||
                                model.contains(
                                    _modelNameController.text.split(':').first);
                        return Chip(
                          label: Text(
                            model,
                            style: TextStyle(
                              fontSize: 10,
                              color: isCurrentModel
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                          backgroundColor: isCurrentModel
                              ? AppColors.accent
                              : AppColors.surface,
                          side: BorderSide(
                            color: isCurrentModel
                                ? AppColors.accent
                                : AppColors.textSecondary
                                    .withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 32),
        const Divider(color: AppColors.textSecondary),
        const SizedBox(height: 24),

        const Text(
          'System Prompt',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        const Text(
          'This prompt defines how the AI assistant behaves when no template is matched.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _systemPromptController,
          style: const TextStyle(color: AppColors.textPrimary),
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'You are a helpful document assistant...',
            hintStyle: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.5)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.textSecondary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accent),
            ),
          ),
        ),

        const SizedBox(height: 32),
        const Divider(color: AppColors.textSecondary),
        const SizedBox(height: 24),

        const Text(
          'Generation Parameters',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        const Text(
          'Fine-tune how the AI generates responses.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _temperatureController,
                label: 'Temperature',
                hint: '0.7',
                helperText: 'Creativity (0.0-2.0). Higher = more random.',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _topPController,
                label: 'Top P',
                hint: '0.9',
                helperText: 'Nucleus sampling (0.0-1.0).',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _topKController,
                label: 'Top K',
                hint: '40',
                helperText: 'Limits vocabulary choices.',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _repeatPenaltyController,
                label: 'Repeat Penalty',
                hint: '1.1',
                helperText: 'Penalizes repetition (1.0-2.0).',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _numCtxController,
          label: 'Context Length',
          hint: '4096',
          helperText: 'Max tokens for context window. Higher uses more memory.',
          keyboardType: TextInputType.number,
        ),

        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('Save All Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? helperText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        helperMaxLines: 2,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        helperStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.7),
            fontSize: 11),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.textSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
      ),
    );
  }
}
