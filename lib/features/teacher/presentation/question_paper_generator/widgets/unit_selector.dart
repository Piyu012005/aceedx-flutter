import 'package:flutter/material.dart';
import '../../../../../models/unit.dart';
import '../models/chapter_group.dart';

/// Nested Unit Selector Widget displaying subtopic units grouped by selected Chapter Groups.
///
/// Features:
/// - Renders expandable/collapsible accordions per selected ChapterGroup
/// - Header checkboxes with tristate support (checked / unchecked / indeterminate)
/// - Per-group "Select All" and "Clear" actions (isolated per group)
/// - Displays individual units with exact formatting ("Chapter 1.2 — The Thiefs Story")
/// - Maintains unit selections across multiple active chapter groups
class UnitSelector extends StatelessWidget {
  final List<ChapterGroup> selectedChapterGroups;
  final Set<int> selectedUnitIds;
  final ValueChanged<Unit> onToggleUnit;
  final ValueChanged<ChapterGroup> onSelectAllGroupUnits;
  final ValueChanged<ChapterGroup> onClearGroupUnits;
  final ValueChanged<ChapterGroup> onToggleGroupExpanded;
  final bool isLoading;
  final String? errorMessage;

  const UnitSelector({
    super.key,
    required this.selectedChapterGroups,
    required this.selectedUnitIds,
    required this.onToggleUnit,
    required this.onSelectAllGroupUnits,
    required this.onClearGroupUnits,
    required this.onToggleGroupExpanded,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(height: 10),
              Text(
                'Loading units for selected chapters…',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 20, color: Color(0xFFDC2626)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                errorMessage!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF991B1B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (selectedChapterGroups.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: Color(0xFF94A3B8)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Select one or more chapters above to view and select subtopic units.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: selectedChapterGroups.map((group) {
        return _buildGroupCard(context, group);
      }).toList(),
    );
  }

  Widget _buildGroupCard(BuildContext context, ChapterGroup group) {
    final selCount = group.getSelectedCount(selectedUnitIds);
    final totalCount = group.units.length;
    final isAll = group.isAllSelected(selectedUnitIds);
    final isPart = group.isIndeterminate(selectedUnitIds);

    bool? groupCheckboxVal;
    if (isAll) {
      groupCheckboxVal = true;
    } else if (isPart) {
      groupCheckboxVal = null; // Indeterminate
    } else {
      groupCheckboxVal = false;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selCount > 0 ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          // Group Accordion Header
          InkWell(
            onTap: () => onToggleGroupExpanded(group),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selCount > 0 ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(9),
                  bottom: group.isExpanded ? Radius.zero : const Radius.circular(9),
                ),
              ),
              child: Row(
                children: [
                  // Group Header Checkbox (Tristate: All/Some/None)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      tristate: true,
                      value: groupCheckboxVal,
                      onChanged: (_) {
                        if (isAll) {
                          onClearGroupUnits(group);
                        } else {
                          onSelectAllGroupUnits(group);
                        }
                      },
                      activeColor: const Color(0xFF1E3A8A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Group Title & Selected Count
                  Text(
                    '${group.displayName} ($selCount selected)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: selCount > 0 ? const Color(0xFF1E3A8A) : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(width: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: selCount == 0 ? const Color(0xFFF1F5F9) : const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$selCount of $totalCount units',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: selCount == 0 ? const Color(0xFF64748B) : const Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Group Select All | Clear Actions
                  if (group.units.isNotEmpty) ...[
                    if (selCount < totalCount)
                      TextButton(
                        onPressed: () => onSelectAllGroupUnits(group),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                          foregroundColor: const Color(0xFF2563EB),
                        ),
                        child: const Text('Select All', style: TextStyle(fontSize: 12)),
                      ),
                    if (selCount > 0)
                      TextButton(
                        onPressed: () => onClearGroupUnits(group),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                          foregroundColor: const Color(0xFFDC2626),
                        ),
                        child: const Text('Clear', style: TextStyle(fontSize: 12)),
                      ),
                  ],

                  Icon(
                    group.isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Group Units List
          if (group.isExpanded) ...[
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            if (group.units.isEmpty)
              const Padding(
                padding: EdgeInsets.all(14.0),
                child: Text(
                  'No units available in this chapter group.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: group.units.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.shade100,
                ),
                itemBuilder: (context, index) {
                  final unit = group.units[index];
                  final isSelected = selectedUnitIds.contains(unit.id);
                  final uNumStr = unit.unitNumber?.toString().trim() ?? '';

                  return Material(
                    color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                    child: InkWell(
                      onTap: () => onToggleUnit(unit),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: isSelected,
                                onChanged: (_) => onToggleUnit(unit),
                                activeColor: const Color(0xFF1E3A8A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                uNumStr.isNotEmpty
                                    ? 'Chapter $uNumStr \u2014 ${unit.unitName}'
                                    : unit.unitName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}
