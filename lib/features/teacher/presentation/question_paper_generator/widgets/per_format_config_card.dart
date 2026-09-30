import 'package:flutter/material.dart';
import '../state/question_paper_generator_state.dart';

/// Card rendering per-format question count (1–20) and marks per question (1–25) settings.
class PerFormatConfigCard extends StatelessWidget {
  final Set<String> selectedFormats;
  final Map<String, int> formatQuestionCounts;
  final Map<String, int> formatMarksEach;
  final void Function(String format, int count) onQuestionCountChanged;
  final void Function(String format, int marks) onMarksEachChanged;

  const PerFormatConfigCard({
    super.key,
    required this.selectedFormats,
    required this.formatQuestionCounts,
    required this.formatMarksEach,
    required this.onQuestionCountChanged,
    required this.onMarksEachChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedFormats.isEmpty) return const SizedBox.shrink();

    // Preserve the canonical ordering from kAllQuestionFormats
    final orderedFormats = kAllQuestionFormats.where(selectedFormats.contains).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Per format — number of questions (1–20) and marks per question (1–25)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orderedFormats.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final format = orderedFormats[index];
            final qCount = formatQuestionCounts[format] ?? 1;
            final marksEach = formatMarksEach[format] ?? 1;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 480;

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          format,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStepper(
                                label: 'Questions',
                                value: qCount,
                                min: 1,
                                max: 20,
                                onChanged: (val) => onQuestionCountChanged(format, val),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStepper(
                                label: 'Marks each',
                                value: marksEach,
                                min: 1,
                                max: 25,
                                onChanged: (val) => onMarksEachChanged(format, val),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          format,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _buildStepper(
                          label: 'Questions',
                          value: qCount,
                          min: 1,
                          max: 20,
                          onChanged: (val) => onQuestionCountChanged(format, val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _buildStepper(
                          label: 'Marks each',
                          value: marksEach,
                          min: 1,
                          max: 25,
                          onChanged: (val) => onMarksEachChanged(format, val),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStepper({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isDense: true,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
              ),
              items: List.generate(max - min + 1, (i) => min + i).map((countVal) {
                return DropdownMenuItem<int>(
                  value: countVal,
                  child: Text('$countVal'),
                );
              }).toList(),
              onChanged: (newVal) {
                if (newVal != null) {
                  onChanged(newVal);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
