class GradeItem {
  const GradeItem({
    required this.subjectCode,
    required this.subjectName,
    required this.credits,
    required this.mark10,
    required this.mark4,
    required this.letter,
  });

  final String subjectCode;
  final String subjectName;
  final int credits;
  final double mark10;
  final double mark4;
  final String letter;

  factory GradeItem.fromApi(Map<String, dynamic> json) {
    return GradeItem(
      subjectCode:
          (json['subject']?['subjectCode'] ?? json['subjectCode'] ?? '--')
              .toString(),
      subjectName:
          (json['subject']?['subjectName'] ?? json['subjectName'] ?? 'Môn học')
              .toString(),
      credits: _toInt(
        json['subject']?['numberOfCredit'] ?? json['numberOfCredit'],
      ),
      mark10: _toDouble(json['mark']),
      mark4: _toDouble(json['mark4']),
      letter: (json['charMark'] ?? '--').toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'credits': credits,
      'mark10': mark10,
      'mark4': mark4,
      'letter': letter,
    };
  }

  factory GradeItem.fromJson(Map<String, dynamic> json) {
    return GradeItem(
      subjectCode: (json['subjectCode'] ?? '--').toString(),
      subjectName: (json['subjectName'] ?? 'Môn học').toString(),
      credits: _toInt(json['credits']),
      mark10: _toDouble(json['mark10']),
      mark4: _toDouble(json['mark4']),
      letter: (json['letter'] ?? '--').toString(),
    );
  }
}
