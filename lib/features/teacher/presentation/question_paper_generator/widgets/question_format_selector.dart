import 'package:flutter/material.dart';
import '../state/question_paper_generator_state.dart';

/// Interactive UI selector for the 27 Question Formats recovered from old AceEdx.
class QuestionFormatSelector extends StatelessWidget {
  final Set<String> selectedFormats;
  final ValueChanged<String> onToggleFormat;

  const QuestionFormatSelector({
    super.key,
    required this.selectedFormats,
    required this.onToggleFormat,
  });

  void _showFormatPicker(BuildContext context) {
    final activeSelectedFormats = Set<String>.from(selectedFormats);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            void toggle(String format) {
              onToggleFormat(format);
              if (activeSelectedFormats.contains(format)) {
                if (activeSelectedFormats.length > 1) {
                  activeSelectedFormats.remove(format);
                }
              } else {
                activeSelectedFormats.add(format);
              }
              setModalState(() {});
            }

            return Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              clipBehavior: Clip.antiAlias,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                  maxWidth: 600,
                ),
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Modal Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        const Text(
                          'Select Question Formats',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${activeSelectedFormats.length} selected',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Format Checklist
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: kAllQuestionFormats.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: Colors.grey.shade100,
                      ),
                      itemBuilder: (context, index) {
                        final format = kAllQuestionFormats[index];
                        final isSelected = activeSelectedFormats.contains(format);

                        return ListTile(
                          dense: true,
                          title: Text(
                            format,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF1E293B),
                            ),
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            activeColor: const Color(0xFF1E3A8A),
                            onChanged: (_) => toggle(format),
                          ),
                          onTap: () => toggle(format),
                        );
                      },
                    ),
                  ),

                  // Bottom Done Button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selCount = selectedFormats.length;
    final summaryText = selCount == 0
        ? 'Tap to choose formats…'
        : (selCount == 1
            ? '1 selected: ${selectedFormats.first}'
            : '$selCount selected: ${selectedFormats.join(', ')}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Question format',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showFormatPicker(context),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.format_list_bulleted, color: Color(0xFF64748B), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    summaryText,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: selCount == 0 ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                      fontWeight: selCount > 0 ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
