import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';
import '../providers/document_provider.dart';
import '../theme/colors.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(BuildContext context) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await context.read<ChatProvider>().sendMessage(text);
    await Future.delayed(const Duration(milliseconds: 100));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _resetChat(BuildContext context) {
    context.read<ChatProvider>().resetSession();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat reset. Start a new conversation!')),
    );
  }

  Future<void> _saveDocument(BuildContext context) async {
    final chatProvider = context.read<ChatProvider>();
    final documentProvider = context.read<DocumentProvider>();

    if (!chatProvider.hasGeneratedDocument) return;

    // Save to documents
    final doc = await documentProvider.addDocument(
      title: chatProvider.documentTitle ?? 'Untitled Document',
      content: chatProvider.generatedDocument!,
      templateId: chatProvider.detectedTemplateId,
      filledValues: chatProvider.collectedValues,
    );

    if (doc != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Document saved! Check the Documents tab.')),
      );
      // Send save command to update conversation state
      await chatProvider.sendMessage('save');
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    return Column(
      children: [
        // Header with state indicator and reset button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          ),
          child: Row(
            children: [
              _buildStateIndicator(chatProvider.conversationState),
              const Spacer(),
              if (chatProvider.hasGeneratedDocument) ...[
                ElevatedButton.icon(
                  onPressed: () => _saveDocument(context),
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save Document'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              TextButton.icon(
                onPressed: () => _resetChat(context),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('New Chat'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary),
              ),
            ],
          ),
        ),

        // Chat messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: chatProvider.messages.length,
            itemBuilder: (context, index) {
              final message = chatProvider.messages[index];
              return _buildMessageBubble(context, message, chatProvider);
            },
          ),
        ),

        // Error display
        if (chatProvider.error != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.error.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 18),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(chatProvider.error!,
                        style: const TextStyle(color: AppColors.error))),
              ],
            ),
          ),

        // Input area
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: _getInputHint(chatProvider.conversationState),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    filled: true,
                    fillColor: AppColors.background,
                  ),
                  onSubmitted: (_) => _sendMessage(context),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 12),
              FloatingActionButton(
                onPressed:
                    chatProvider.isSending ? null : () => _sendMessage(context),
                backgroundColor: AppColors.accent,
                child: chatProvider.isSending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStateIndicator(String state) {
    IconData icon;
    String label;
    Color color;

    switch (state) {
      case 'template_detected':
        icon = Icons.description;
        label = 'Template Found';
        color = AppColors.info;
        break;
      case 'collecting_info':
        icon = Icons.edit_note;
        label = 'Collecting Info';
        color = AppColors.accent;
        break;
      case 'ready_to_generate':
        icon = Icons.check_circle;
        label = 'Ready to Generate';
        color = AppColors.success;
        break;
      case 'document_generated':
        icon = Icons.article;
        label = 'Document Ready';
        color = AppColors.success;
        break;
      case 'document_saved':
        icon = Icons.save;
        label = 'Document Saved';
        color = AppColors.success;
        break;
      default:
        icon = Icons.chat;
        label = 'Chat';
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      BuildContext context, dynamic message, ChatProvider provider) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight:
                isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SelectableText(
          message.message,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.textPrimary,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  String _getInputHint(String state) {
    switch (state) {
      case 'collecting_info':
        return 'Enter the requested information...';
      case 'ready_to_generate':
        return 'Type "generate" to create document...';
      case 'document_generated':
        return 'Type "save" to keep, or "edit" to modify...';
      default:
        return 'Type a message (e.g., "Create an NDA")...';
    }
  }
}
