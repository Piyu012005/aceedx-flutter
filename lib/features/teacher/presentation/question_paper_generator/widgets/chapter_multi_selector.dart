import 'package:flutter/material.dart';
import '../models/chapter_group.dart';

/// Reusable multi-select chapter selector widget.
///
/// Features:
/// - Displays selected chapters as removable chips ([Unit 1 ×] [Unit 2 ×])
/// - Searchable chapter group list overlay / dropdown
/// - Checkbox per chapter group with tristate support (all/some/no units selected)
/// - Bulk "Select All" and "Clear" controls
/// - Displays count of selected chapter groups
class ChapterMultiSelector extends StatefulWidget {
  final List<ChapterGroup> chapterGroups;
  final List<int> selectedChapterIds;
  final Set<int> selectedUnitIds;
  final ValueChanged<int> onToggleChapter;
  final VoidCallback onSelectAllChapters;
  final VoidCallback onClearAllChapters;
  final bool isLoading;
  final String? errorMessage;

  const ChapterMultiSelector({
    super.key,
    required this.chapterGroups,
    required this.selectedChapterIds,
    required this.selectedUnitIds,
    required this.onToggleChapter,
    required this.onSelectAllChapters,
    required this.onClearAllChapters,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  State<ChapterMultiSelector> createState() => _ChapterMultiSelectorState();
}

class _ChapterMultiSelectorState extends State<ChapterMultiSelector> {
  bool _isDropdownOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChapterGroup> get _filteredGroups {
    if (_searchQuery.isEmpty) return widget.chapterGroups;
    return widget.chapterGroups.where((g) {
      return g.displayName.toLowerCase().contains(_searchQuery) ||
          g.id.toString().contains(_searchQuery) ||
          g.units.any((u) => u.unitName.toLowerCase().contains(_searchQuery));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = widget.selectedChapterIds.length;
    final totalCount = widget.chapterGroups.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            const Text(
              'Chapters / Units (Select multiple) *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(width: 8),
            if (totalCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: selectedCount > 0 ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$selectedCount selected',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selectedCount > 0 ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),

        // Main Dropdown Trigger Field
        InkWell(
          onTap: () {
            if (!widget.isLoading && widget.chapterGroups.isNotEmpty) {
              setState(() {
                _isDropdownOpen = !_isDropdownOpen;
              });
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isDropdownOpen ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                width: _isDropdownOpen ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.bookmark_border_outlined,
                  size: 20,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: widget.selectedChapterIds.isEmpty
                      ? Text(
                          widget.isLoading
                              ? 'Loading chapters…'
                              : (widget.chapterGroups.isEmpty
                                  ? (widget.errorMessage ?? 'No chapters available')
                                  : 'Select Chapter'),
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.selectedChapterIds.isEmpty
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF0F172A),
                          ),
                        )
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: widget.selectedChapterIds.map((chId) {
                            final group = widget.chapterGroups.firstWhere(
                              (g) => g.id == chId,
                              orElse: () => ChapterGroup(
                                id: chId,
                                displayName: 'Unit $chId',
                                units: const [],
                              ),
                            );
                            return Chip(
                              label: Text(
                                group.displayName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              deleteIcon: const Icon(
                                Icons.close,
                                size: 14,
                                color: Color(0xFF1E3A8A),
                              ),
                              onDeleted: () => widget.onToggleChapter(chId),
                              backgroundColor: const Color(0xFFEFF6FF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: Color(0xFF93C5FD)),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
              ],
            ),
          ),
        ),

        // Dropdown Menu Body (Expanded View)
        if (_isDropdownOpen && widget.chapterGroups.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Bar with Search + Select All | Clear
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      // Search Input
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search chapters…',
                            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: widget.onSelectAllChapters,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                          foregroundColor: const Color(0xFF2563EB),
                        ),
                        child: const Text('Select All', style: TextStyle(fontSize: 12)),
                      ),
                      TextButton(
                        onPressed: widget.onClearAllChapters,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                          foregroundColor: const Color(0xFFDC2626),
                        ),
                        child: const Text('Clear', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

                // Chapter Group Checkbox List
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: _filteredGroups.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No matching chapters found',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filteredGroups.length,
                          itemBuilder: (context, index) {
                            final group = _filteredGroups[index];
                            final isChapterSelected = widget.selectedChapterIds.contains(group.id);
                            final selectedUnitsCount = group.getSelectedCount(widget.selectedUnitIds);
                            final isAllUnits = group.isAllSelected(widget.selectedUnitIds);
                            final isPartialUnits = group.isIndeterminate(widget.selectedUnitIds);

                            // Tristate checkbox value for chapter selection / unit selection status
                            bool? checkboxValue;
                            if (isChapterSelected) {
                              if (isAllUnits) {
                                checkboxValue = true;
                              } else if (isPartialUnits) {
                                checkboxValue = null; // Indeterminate state
                              } else {
                                checkboxValue = true;
                              }
                            } else {
                              checkboxValue = false;
                            }

                            return Material(
                              color: isChapterSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                              child: InkWell(
                                onTap: () => widget.onToggleChapter(group.id),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          tristate: true,
                                          value: checkboxValue,
                                          onChanged: (_) => widget.onToggleChapter(group.id),
                                          activeColor: const Color(0xFF1E3A8A),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          group.displayName,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isChapterSelected ? FontWeight.bold : FontWeight.w500,
                                            color: isChapterSelected
                                                ? const Color(0xFF1E3A8A)
                                                : const Color(0xFF1E293B),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${group.units.length} unit(s)${selectedUnitsCount > 0 ? " ($selectedUnitsCount selected)" : ""}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
