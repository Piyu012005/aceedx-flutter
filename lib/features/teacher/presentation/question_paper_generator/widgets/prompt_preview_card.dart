import 'package:flutter/material.dart';

/// Read-only preview card displaying the auto-generated prompt block.
class PromptPreviewCard extends StatelessWidget {
  final String previewContent;

  const PromptPreviewCard({
    super.key,
    required this.previewContent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Included automatically in prompt (preview)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            previewContent.isEmpty ? 'Select formats above…' : previewContent,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              color: previewContent.isEmpty ? const Color(0xFF94A3B8) : const Color(0xFF334155),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
