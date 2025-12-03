import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/template_provider.dart';
import '../widgets/template_card.dart';
import 'template_editor_screen.dart';
import '../theme/colors.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TemplateProvider>().refresh(debounced: false);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openEditor([dynamic template]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateEditorScreen(template: template),
      ),
    );
  }

  Future<void> _deleteTemplate(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<TemplateProvider>().deleteTemplate(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TemplateProvider>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search templates'),
                  onChanged: (value) => provider.refresh(query: value),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add),
                label: const Text('New Template'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: () {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (provider.error != null) {
                return Center(
                  child: Text(provider.error!, style: const TextStyle(color: Colors.redAccent)),
                );
              }
              if (provider.templates.isEmpty) {
                return const Center(child: Text('No templates yet. Try creating one!'));
              }
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: provider.templates.length,
                itemBuilder: (context, index) {
                  final template = provider.templates[index];
                  return TemplateCard(
                    template: template,
                    onTap: () => _openEditor(template),
                    onDelete: () => _deleteTemplate(template.id),
                  );
                },
              );
            }(),
          ),
        ],
      ),
    );
  }
}
