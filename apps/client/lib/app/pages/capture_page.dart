import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../planning/planning_store.dart';
import '../planning/planning_scope.dart';

class CapturePage extends StatefulWidget {
  const CapturePage({required this.onOpenAi, super.key});

  final VoidCallback onOpenAi;

  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage> {
  final TextEditingController _titleController = TextEditingController();
  CaptureItemKind _selectedKind = CaptureItemKind.task;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final store = PlanningScope.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(l10n.captureHeadline, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(l10n.captureBody, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 24),
        DropdownButtonFormField<CaptureItemKind>(
          initialValue: _selectedKind,
          decoration: InputDecoration(
            labelText: l10n.captureTypeLabel,
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(
              value: CaptureItemKind.task,
              child: Text(l10n.captureTypeTask),
            ),
            DropdownMenuItem(
              value: CaptureItemKind.schedule,
              child: Text(l10n.captureTypeSchedule),
            ),
            DropdownMenuItem(
              value: CaptureItemKind.memo,
              child: Text(l10n.captureTypeMemo),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedKind = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: l10n.captureTitleLabel,
            hintText: l10n.captureTitleHint,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: store.isSubmitting ? null : () => _submit(store),
          icon: const Icon(Icons.send_outlined),
          label: Text(
            store.isSubmitting ? l10n.captureSubmitting : l10n.captureSubmitAction,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: widget.onOpenAi,
          icon: const Icon(Icons.auto_awesome_outlined),
          label: Text(l10n.aiShortcut),
        ),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: const Icon(Icons.lightbulb_outline),
            title: Text(l10n.captureHintTitle),
            subtitle: Text(l10n.captureHintBody),
          ),
        ),
        if (store.errorMessage != null) ...[
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.error_outline),
              title: Text(store.errorMessage!),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _submit(PlanningStore store) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      return;
    }

    await store.createItem(kind: _selectedKind, title: title);
    if (!mounted) {
      return;
    }

    if (store.errorMessage == null) {
      _titleController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.captureSuccess)),
      );
    }
  }
}
