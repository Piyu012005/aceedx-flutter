/// Models for dropdown data fetched from `GET /api/teacher/dropdown/{school_id}`.
class TeacherDropdownData {
  final List<DropdownBoard> boards;
  final List<DropdownSubject> subjects;
  final List<String> classes;

  const TeacherDropdownData({
    this.boards = const [],
    this.subjects = const [],
    this.classes = const [],
  });

  factory TeacherDropdownData.fromJson(Map<String, dynamic> json) {
    final rawBoards = json['boards'];
    final rawSubjects = json['subjects'];
    final rawClasses = json['classes'];

    final boardsList = <DropdownBoard>[];
    if (rawBoards is List) {
      for (final item in rawBoards) {
        if (item is Map<String, dynamic>) {
          boardsList.add(DropdownBoard.fromJson(item));
        } else if (item is String && item.isNotEmpty) {
          boardsList.add(DropdownBoard(id: 0, name: item));
        }
      }
    }

    final subjectsList = <DropdownSubject>[];
    if (rawSubjects is List) {
      for (final item in rawSubjects) {
        if (item is Map<String, dynamic>) {
          subjectsList.add(DropdownSubject.fromJson(item));
        } else if (item is String && item.isNotEmpty) {
          subjectsList.add(DropdownSubject(id: 0, name: item));
        }
      }
    }

    final classesList = <String>[];
    if (rawClasses is List) {
      for (final item in rawClasses) {
        if (item != null) {
          final str = item.toString().trim();
          if (str.isNotEmpty && !classesList.contains(str)) {
            classesList.add(str);
          }
        }
      }
    }

    return TeacherDropdownData(
      boards: boardsList,
      subjects: subjectsList,
      classes: classesList,
    );
  }
}

class DropdownBoard {
  final int id;
  final String name;

  const DropdownBoard({
    required this.id,
    required this.name,
  });

  factory DropdownBoard.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final parsedId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '0') ?? 0;
    final nameStr = (json['name'] ?? json['board_name'] ?? json['boardName'] ?? json['board'] ?? '').toString();

    return DropdownBoard(
      id: parsedId,
      name: nameStr,
    );
  }
}

class DropdownSubject {
  final int id;
  final String name;

  const DropdownSubject({
    required this.id,
    required this.name,
  });

  factory DropdownSubject.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['subject_id'];
    final parsedId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '0') ?? 0;
    final nameStr = (json['name'] ?? json['subject_name'] ?? json['subjectName'] ?? '').toString();

    return DropdownSubject(
      id: parsedId,
      name: nameStr,
    );
  }
}
