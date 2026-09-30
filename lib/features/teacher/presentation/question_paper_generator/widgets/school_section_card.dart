import 'package:flutter/material.dart';

/// Card representing the School selection and dropdown loading section.
class SchoolSectionCard extends StatelessWidget {
  final TextEditingController schoolIdController;
  final String? schoolName;
  final bool isLoading;
  final VoidCallback onLoadDropdownPressed;

  const SchoolSectionCard({
    super.key,
    required this.schoolIdController,
    this.schoolName,
    this.isLoading = false,
    required this.onLoadDropdownPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school_outlined, color: Color(0xFF1E3A8A), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'School',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (schoolName != null && schoolName!.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      schoolName!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 520;

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSchoolIdField(),
                      const SizedBox(height: 12),
                      _buildLoadButton(),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _buildSchoolIdField(),
                    ),
                    const SizedBox(width: 12),
                    _buildLoadButton(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolIdField() {
    return TextField(
      controller: schoolIdController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'School ID',
        hintText: 'Enter school ID',
        prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: Color(0xFF64748B)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildLoadButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onLoadDropdownPressed,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.refresh_rounded, size: 18),
        label: Text(
          isLoading ? 'Loading...' : 'Load dropdown',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}
