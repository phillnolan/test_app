class ProgramSubject {
  const ProgramSubject({
    required this.subjectCode,
    required this.subjectName,
    required this.knowledgeBlock,
    required this.semesterIndex,
    required this.credits,
    this.rawCountedForGpa,
  });

  final String subjectCode;
  final String subjectName;
  final String knowledgeBlock;
  final int semesterIndex;
  final int credits;
  final bool? rawCountedForGpa;

  String get normalizedSearchText =>
      '${_normalize(subjectName)} ${_normalize(knowledgeBlock)}';

  bool get isElective {
    final haystack = normalizedSearchText;
    return haystack.contains('tu chon');
  }

  bool get isGraduationProject {
    final haystack = normalizedSearchText;
    return haystack.contains('do an') ||
        haystack.contains('khoa luan') ||
        haystack.contains('tot nghiep');
  }

  bool get isPhysicalEducation {
    final haystack = normalizedSearchText;
    return haystack.contains('the chat') ||
        haystack.contains('giao duc the chat');
  }

  bool get isNationalDefense {
    final haystack = normalizedSearchText;
    return haystack.contains('quoc phong') ||
        haystack.contains('an ninh') ||
        haystack.contains('ky thuat chien dau bo binh') ||
        haystack.contains('duong loi quoc phong');
  }

  bool get isForeignLanguageRequirement {
    final haystack = normalizedSearchText;
    return haystack.contains('chuan dau ra ngoai ngu') ||
        haystack.contains('on thi chuan dau ra ngoai ngu') ||
        haystack.contains('tieng anh tang cuong');
  }

  bool get isCountedForGpa {
    return rawCountedForGpa ??
        !(isPhysicalEducation ||
            isNationalDefense ||
            isForeignLanguageRequirement);
  }

  String get curriculumGroup {
    if (isElective) return 'Tự chọn';
    if (isForeignLanguageRequirement) return 'Chuẩn đầu ra';
    if (isNationalDefense) return 'Giáo dục quốc phòng';
    if (isPhysicalEducation) return 'Giáo dục thể chất';

    final block = _prettyText(knowledgeBlock);
    final normalizedBlock = _normalize(knowledgeBlock);
    if (normalizedBlock.contains('ly luan chinh tri')) {
      return 'Lý luận chính trị';
    }
    if (block.isNotEmpty) {
      return block;
    }
    return 'Kiến thức ngành';
  }

  Map<String, dynamic> toJson() {
    return {
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'knowledgeBlock': knowledgeBlock,
      'semesterIndex': semesterIndex,
      'credits': credits,
      'rawCountedForGpa': rawCountedForGpa,
    };
  }

  factory ProgramSubject.fromJson(Map<String, dynamic> json) {
    return ProgramSubject(
      subjectCode: (json['subjectCode'] ?? '').toString(),
      subjectName: (json['subjectName'] ?? '').toString(),
      knowledgeBlock: (json['knowledgeBlock'] ?? '').toString(),
      semesterIndex: _toInt(json['semesterIndex']),
      credits: _toInt(json['credits']),
      rawCountedForGpa: _readNullableBool(json['rawCountedForGpa']),
    );
  }

  factory ProgramSubject.fromApi(Map<String, dynamic> json) {
    return ProgramSubject(
      subjectCode:
          (json['displaySubjectCode'] ??
                  json['subjectCode'] ??
                  json['subject']?['subjectCode'] ??
                  '')
              .toString(),
      subjectName:
          (json['displaySubjectName'] ??
                  json['subjectName'] ??
                  json['subject']?['subjectName'] ??
                  '')
              .toString(),
      knowledgeBlock:
          (json['typy'] ??
                  json['knowledgeProgram']?['knowledgeBlock']?['name'] ??
                  '')
              .toString(),
      semesterIndex: _toInt(json['semesterIndex']),
      credits: _toInt(
        json['numberOfCredit'] ?? json['subject']?['numberOfCredit'],
      ),
      rawCountedForGpa: _firstNullableBool([
        json['isCountedForGpa'],
        json['isCounted'],
        json['isMarkCalculated'],
        json['isCalculateMark'],
        json['calculatedMark'],
        json['countToGpa'],
        json['subject']?['isCountedForGpa'],
        json['subject']?['isCounted'],
        json['subject']?['isMarkCalculated'],
        json['subject']?['isCalculateMark'],
        json['subject']?['calculatedMark'],
        json['subject']?['countToGpa'],
      ]),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  static bool? _firstNullableBool(List<dynamic> values) {
    for (final value in values) {
      final parsed = _readNullableBool(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static bool? _readNullableBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase();
    if (text == null || text.isEmpty) return null;
    if (text == 'true' || text == '1' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'no') return false;
    return null;
  }

  static String _prettyText(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _normalize(String value) {
    final lower = value.toLowerCase();
    const replacements = {
      'à': 'a',
      'á': 'a',
      'ạ': 'a',
      'ả': 'a',
      'ã': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ậ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ặ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'è': 'e',
      'é': 'e',
      'ẹ': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ệ': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ì': 'i',
      'í': 'i',
      'ị': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ò': 'o',
      'ó': 'o',
      'ọ': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ộ': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ợ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ụ': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ự': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỵ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'đ': 'd',
    };
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(replacements[char] ?? char);
    }
    return buffer.toString();
  }
}
