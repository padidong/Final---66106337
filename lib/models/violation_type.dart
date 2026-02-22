class ViolationType {
  final int typeId;
  final String typeName;
  final String severity;

  ViolationType({
    required this.typeId,
    required this.typeName,
    required this.severity,
  });

  factory ViolationType.fromMap(Map<String, dynamic> map) {
    return ViolationType(
      typeId: map['type_id'],
      typeName: map['type_name'],
      severity: map['severity'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type_id': typeId,
      'type_name': typeName,
      'severity': severity,
    };
  }
}
