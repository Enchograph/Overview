import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../ai/ai_scope.dart';
import '../ai/ai_store.dart';

class AiRoute extends StatefulWidget {
  const AiRoute({super.key});

  @override
  State<AiRoute> createState() => _AiRouteState();
}

class _AiRouteState extends State<AiRoute> {
  final TextEditingController _questionController = TextEditingController();

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final aiStore = AiScope.of(context);
    final answer = aiStore.lastAnswer;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l10n.aiBody,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          if (!aiStore.isRemoteEnabled)
            Card(
              child: ListTile(
                leading: const Icon(Icons.cloud_off_outlined),
                title: Text(l10n.aiUnavailableTitle),
                subtitle: Text(l10n.aiUnavailableBody),
              ),
            )
          else ...[
            TextField(
              controller: _questionController,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: l10n.aiQuestionLabel,
                hintText: l10n.aiQuestionHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: aiStore.isAnswerSubmitting
                      ? null
                      : () => _submitQuestion(aiStore),
                  icon: const Icon(Icons.send_outlined),
                  label: Text(
                    aiStore.isAnswerSubmitting
                        ? l10n.aiSubmitting
                        : l10n.aiAskAction,
                  ),
                ),
                TextButton(
                  onPressed: aiStore.isAnswerSubmitting
                      ? null
                      : () {
                          _questionController.clear();
                          aiStore.clearAnswer();
                        },
                  child: Text(l10n.aiClearAction),
                ),
              ],
            ),
            if (answer != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.aiAnswerTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(answer.answer),
                      const SizedBox(height: 12),
                      Text(
                        l10n.aiReferencedItems(answer.referencedItemCount),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (aiStore.answerErrorMessage != null) ...[
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.smart_toy_outlined),
                  title: Text(aiStore.answerErrorMessage!),
                ),
              ),
            ],
          ],
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: Text(l10n.aiShortcut),
              subtitle: Text(l10n.aiCta),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitQuestion(AiStore aiStore) async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      return;
    }

    await aiStore.askQuestion(question);
  }
}
