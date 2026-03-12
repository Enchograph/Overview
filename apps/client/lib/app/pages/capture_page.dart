import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../ai/ai_repository.dart';
import '../ai/ai_scope.dart';
import '../ai/speech_input_scope.dart';
import '../ai/speech_input_store.dart';
import '../ai/ai_store.dart';
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
  final TextEditingController _startAtController = TextEditingController();
  final TextEditingController _endAtController = TextEditingController();
  final TextEditingController _dueAtController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _listIdController = TextEditingController(
    text: 'inbox',
  );
  CaptureItemKind _selectedKind = CaptureItemKind.task;

  @override
  void dispose() {
    _titleController.dispose();
    _startAtController.dispose();
    _endAtController.dispose();
    _dueAtController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    _listIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final store = PlanningScope.of(context);
    final aiStore = AiScope.of(context);
    final speechStore = SpeechInputScope.of(context);
    final suggestion = aiStore.lastSuggestion;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(l10n.captureHeadline,
            style: Theme.of(context).textTheme.headlineMedium),
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
            store.isSubmitting
                ? l10n.captureSubmitting
                : l10n.captureSubmitAction,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: aiStore.isSubmitting ? null : () => _parseWithAi(aiStore),
          icon: const Icon(Icons.auto_awesome_outlined),
          label: Text(
            aiStore.isSubmitting
                ? l10n.captureAiParsing
                : l10n.captureAiParseAction,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: aiStore.isVoiceSubmitting
              ? null
              : () => _toggleVoiceInput(speechStore, aiStore),
          icon: Icon(
            speechStore.isRecording ? Icons.mic : Icons.mic_none_outlined,
          ),
          label: Text(
            aiStore.isVoiceSubmitting
                ? l10n.captureVoiceTranscribing
                : (speechStore.isRecording
                ? l10n.captureVoiceStopAction
                : l10n.captureVoiceAction),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: widget.onOpenAi,
          icon: const Icon(Icons.auto_awesome_outlined),
          label: Text(l10n.aiShortcut),
        ),
        if (suggestion != null) ...[
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.captureAiSuggestionTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.captureAiSuggestionBody(
                      _typeLabel(l10n, suggestion.suggestedType),
                      suggestion.title,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.captureAiConfidenceLabel(
                      (suggestion.confidence * 100).round(),
                    ),
                  ),
                  if (suggestion.requiresConfirmation.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.captureAiNeedsConfirm(
                        suggestion.requiresConfirmation
                            .map((field) => _fieldLabel(l10n, field))
                            .join(', '),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ..._buildStructuredFields(l10n, suggestion),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton(
                        onPressed: store.isSubmitting
                            ? null
                            : () => _confirmSuggestion(store, aiStore, suggestion),
                        child: Text(l10n.captureAiConfirmAction),
                      ),
                      TextButton(
                        onPressed: aiStore.clearSuggestion,
                        child: Text(l10n.captureAiDismissAction),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
        if (aiStore.errorMessage != null) ...[
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.smart_toy_outlined),
              title: Text(aiStore.errorMessage!),
            ),
          ),
        ],
        if (speechStore.errorMessage != null) ...[
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.mic_off_outlined),
              title: Text(
                !speechStore.hasPermission
                    ? l10n.captureVoiceUnavailableTitle
                    : l10n.captureVoiceErrorTitle,
              ),
              subtitle: Text(
                !speechStore.hasPermission
                    ? l10n.captureVoiceUnavailableBody
                    : speechStore.errorMessage!,
              ),
            ),
          ),
        ],
        if (aiStore.voiceErrorMessage != null) ...[
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.smart_toy_outlined),
              title: Text(l10n.captureVoiceErrorTitle),
              subtitle: Text(aiStore.voiceErrorMessage!),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _submit(PlanningStore store) async {
    final title = _titleController.text.trim();
    final suggestion = AiScope.of(context).lastSuggestion;
    if (title.isEmpty) {
      return;
    }

    await store.createItem(
      kind: _selectedKind,
      title: title,
      startAt: suggestion == null ? null : _parseDateTime(_startAtController.text),
      endAt: suggestion == null ? null : _parseDateTime(_endAtController.text),
      dueAt: suggestion == null ? null : _parseDateTime(_dueAtController.text),
      location: suggestion == null ? null : _trimmedOrNull(_locationController.text),
      durationMinutes: suggestion == null ? null : _parseInt(_durationController.text),
      listId: suggestion == null ? null : _trimmedOrNull(_listIdController.text),
    );
    if (!mounted) {
      return;
    }

    if (store.errorMessage == null) {
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.captureSuccess)),
      );
    }
  }

  Future<void> _parseWithAi(AiStore aiStore) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      return;
    }

    await aiStore.ingestText(title);
    final suggestion = aiStore.lastSuggestion;
    if (suggestion != null) {
      _prefillStructuredFields(suggestion);
    }
  }

  Future<void> _toggleVoiceInput(
    SpeechInputStore speechStore,
    AiStore aiStore,
  ) async {
    if (speechStore.isRecording) {
      final audio = await speechStore.stopRecording();
      if (audio == null || !mounted) {
        return;
      }

      final locale = Localizations.localeOf(context).languageCode == 'zh'
          ? 'zh-CN'
          : 'en-US';
      final transcript = await aiStore.transcribeAudio(
        audioBytes: audio.bytes,
        mimeType: audio.mimeType,
        locale: locale,
      );
      if (!mounted || transcript == null || transcript.trim().isEmpty) {
        return;
      }

      setState(() {
        _titleController.text = transcript;
      });
      await _handleVoiceResult(aiStore, transcript);
      return;
    }

    await speechStore.startRecording();
  }

  Future<void> _confirmSuggestion(
    PlanningStore store,
    AiStore aiStore,
    AiSuggestion suggestion,
  ) async {
    final kind = switch (suggestion.suggestedType) {
      AiSuggestionType.schedule => CaptureItemKind.schedule,
      AiSuggestionType.task => CaptureItemKind.task,
      AiSuggestionType.memo => CaptureItemKind.memo,
    };

    setState(() {
      _selectedKind = kind;
      _titleController.text = suggestion.title;
    });

    await _submit(store);
    if (store.errorMessage == null) {
      aiStore.clearSuggestion();
    }
  }

  String _typeLabel(AppLocalizations l10n, AiSuggestionType type) {
    return switch (type) {
      AiSuggestionType.schedule => l10n.captureTypeSchedule,
      AiSuggestionType.task => l10n.captureTypeTask,
      AiSuggestionType.memo => l10n.captureTypeMemo,
    };
  }

  List<Widget> _buildStructuredFields(
    AppLocalizations l10n,
    AiSuggestion suggestion,
  ) {
    switch (suggestion.suggestedType) {
      case AiSuggestionType.schedule:
        return [
          TextField(
            controller: _startAtController,
            decoration: InputDecoration(
              labelText: l10n.captureAiStartAtLabel,
              hintText: l10n.captureAiDateTimeHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _endAtController,
            decoration: InputDecoration(
              labelText: l10n.captureAiEndAtLabel,
              hintText: l10n.captureAiDateTimeHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: l10n.captureAiLocationLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.captureAiDurationLabel,
              hintText: l10n.captureAiDurationHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ];
      case AiSuggestionType.task:
        return [
          TextField(
            controller: _dueAtController,
            decoration: InputDecoration(
              labelText: l10n.captureAiDueAtLabel,
              hintText: l10n.captureAiDateTimeHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: l10n.captureAiLocationLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.captureAiDurationLabel,
              hintText: l10n.captureAiDurationHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ];
      case AiSuggestionType.memo:
        return [
          TextField(
            controller: _listIdController,
            decoration: InputDecoration(
              labelText: l10n.captureAiListIdLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.captureAiDurationLabel,
              hintText: l10n.captureAiDurationHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ];
    }
  }

  void _prefillStructuredFields(AiSuggestion suggestion) {
    final extracted = suggestion.extracted;
    setState(() {
      _selectedKind = switch (suggestion.suggestedType) {
        AiSuggestionType.schedule => CaptureItemKind.schedule,
        AiSuggestionType.task => CaptureItemKind.task,
        AiSuggestionType.memo => CaptureItemKind.memo,
      };
      _titleController.text = suggestion.title;
      _startAtController.text = extracted['startAt'] as String? ?? '';
      _endAtController.text = extracted['endAt'] as String? ?? '';
      _dueAtController.text = extracted['dueAt'] as String? ?? '';
      _locationController.text = extracted['location'] as String? ?? '';
      _durationController.text = extracted['durationMinutes']?.toString() ?? '';
      _listIdController.text = extracted['listId'] as String? ?? 'inbox';
    });
  }

  void _resetForm() {
    _titleController.clear();
    _startAtController.clear();
    _endAtController.clear();
    _dueAtController.clear();
    _locationController.clear();
    _durationController.clear();
    _listIdController.text = 'inbox';
  }

  String _fieldLabel(AppLocalizations l10n, String field) {
    switch (field) {
      case 'startAt':
        return l10n.captureAiStartAtLabel;
      case 'endAt':
        return l10n.captureAiEndAtLabel;
      case 'dueAt':
        return l10n.captureAiDueAtLabel;
      case 'location':
        return l10n.captureAiLocationLabel;
      case 'durationMinutes':
        return l10n.captureAiDurationLabel;
      case 'listId':
        return l10n.captureAiListIdLabel;
      default:
        return field;
    }
  }

  DateTime? _parseDateTime(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    return DateTime.tryParse(trimmed)?.toUtc();
  }

  int? _parseInt(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    return int.tryParse(trimmed);
  }

  String? _trimmedOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _handleVoiceResult(AiStore aiStore, String transcript) async {
    if (!aiStore.isRemoteEnabled || transcript.trim().isEmpty) {
      return;
    }

    await aiStore.ingestText(transcript);
    final suggestion = aiStore.lastSuggestion;
    if (suggestion != null) {
      _prefillStructuredFields(suggestion);
    }
  }
}
