class IncidentReport {
  final int? reportId;
  final int stationId;
  final int typeId;
  final String reporterName;
  final String description;
  final String? evidencePhoto;
  final String timestamp;
  final String? aiResult;
  final double? aiConfidence;
  final int synced;

  final String? stationName;
  final String? typeName;
  final String? severity;

  IncidentReport({
    this.reportId,
    required this.stationId,
    required this.typeId,
    required this.reporterName,
    required this.description,
    this.evidencePhoto,
    required this.timestamp,
    this.aiResult,
    this.aiConfidence,
    this.synced = 0,
    this.stationName,
    this.typeName,
    this.severity,
  });

  bool get isSynced => synced == 1;

  factory IncidentReport.fromMap(Map<String, dynamic> map) {
    return IncidentReport(
      reportId: map['report_id'],
      stationId: map['station_id'],
      typeId: map['type_id'],
      reporterName: map['reporter_name'],
      description: map['description'],
      evidencePhoto: map['evidence_photo'],
      timestamp: map['timestamp'],
      aiResult: map['ai_result'],
      aiConfidence: map['ai_confidence'],
      synced: map['synced'] ?? 0,
      // Map joined fields if they exist in the query result
      stationName: map['station_name'],
      typeName: map['type_name'],
      severity: map['severity'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (reportId != null) 'report_id': reportId,
      'station_id': stationId,
      'type_id': typeId,
      'reporter_name': reporterName,
      'description': description,
      'evidence_photo': evidencePhoto,
      'timestamp': timestamp,
      'ai_result': aiResult,
      'ai_confidence': aiConfidence,
      'synced': synced,
    };
  }

  Map<String, dynamic> toFirebaseMap(String firebaseEvidencePath) {
    return {
      'station_id': stationId,
      'type_id': typeId,
      'reporter_name': reporterName,
      'description': description,
      'evidence_photo': firebaseEvidencePath,
      'timestamp': timestamp,
      'ai_result': aiResult,
      'ai_confidence': aiConfidence,
    };
  }
}
