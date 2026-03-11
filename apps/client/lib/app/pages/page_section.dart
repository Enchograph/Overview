import 'package:flutter/material.dart';

class PageSection extends StatelessWidget {
  const PageSection({
    required this.title,
    required this.description,
    required this.highlights,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    super.key,
  });

  final String title;
  final String description;
  final List<String> highlights;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text(
                description,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onPrimaryAction,
                icon: const Icon(Icons.arrow_forward_outlined),
                label: Text(primaryActionLabel),
              ),
              const SizedBox(height: 24),
              for (final highlight in highlights) ...[
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(highlight),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
