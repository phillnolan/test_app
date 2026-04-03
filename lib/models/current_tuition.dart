class CurrentTuition {
  const CurrentTuition({
    required this.semesterLabel,
    required this.registerPeriodLabel,
    required this.totalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.items,
  });

  final String semesterLabel;
  final String registerPeriodLabel;
  final double totalAmount;
  final double paidAmount;
  final double outstandingAmount;
  final List<TuitionSubjectCharge> items;

  Map<String, dynamic> toJson() {
    return {
      'semesterLabel': semesterLabel,
      'registerPeriodLabel': registerPeriodLabel,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'outstandingAmount': outstandingAmount,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory CurrentTuition.fromJson(Map<String, dynamic> json) {
    return CurrentTuition(
      semesterLabel: (json['semesterLabel'] ?? '').toString(),
      registerPeriodLabel: (json['registerPeriodLabel'] ?? '').toString(),
      totalAmount: _toDouble(json['totalAmount']),
      paidAmount: _toDouble(json['paidAmount']),
      outstandingAmount: _toDouble(json['outstandingAmount']),
      items: ((json['items'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) => TuitionSubjectCharge.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class TuitionSubjectCharge {
  const TuitionSubjectCharge({
    required this.subjectName,
    required this.amount,
    this.subjectCode,
    this.note,
  });

  final String subjectName;
  final String? subjectCode;
  final double amount;
  final String? note;

  Map<String, dynamic> toJson() {
    return {
      'subjectName': subjectName,
      'subjectCode': subjectCode,
      'amount': amount,
      'note': note,
    };
  }

  factory TuitionSubjectCharge.fromJson(Map<String, dynamic> json) {
    return TuitionSubjectCharge(
      subjectName: (json['subjectName'] ?? '').toString(),
      subjectCode: json['subjectCode']?.toString(),
      amount: CurrentTuition._toDouble(json['amount']),
      note: json['note']?.toString(),
    );
  }
}
