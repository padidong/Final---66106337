import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/incident_report.dart';
import 'db_helper.dart';

class FirebaseHelper {

  static CollectionReference get _incidentsCollection =>
      FirebaseFirestore.instance.collection('incident_reports');

  static Future<bool> saveIncidentOnline(IncidentReport report) async {
    try {
      String firebaseEvidencePath = _resolveEvidencePath(report.evidencePhoto);

      Map<String, dynamic> data = report.toFirebaseMap(firebaseEvidencePath);
      await _incidentsCollection.add(data).timeout(const Duration(seconds: 8));

      if (report.reportId != null) {
        await DatabaseHelper.instance.markAsSynced(report.reportId!);
      }

      print("Saved to Firebase: report_id=${report.reportId}");
      return true;
    } catch (e) {
      print("Firebase save failed: $e");
      return false;
    }
  }

  static Future<Map<String, int>> syncAllUnsynced() async {
    int success = 0;
    int failed = 0;

    try {
      final unsynced = await DatabaseHelper.instance.getUnsyncedReports();
      for (final report in unsynced) {
        try {
          String evidencePath = _resolveEvidencePath(report.evidencePhoto);
          Map<String, dynamic> data = report.toFirebaseMap(evidencePath);
          await _incidentsCollection
              .add(data)
              .timeout(const Duration(seconds: 8));

          if (report.reportId != null) {
            await DatabaseHelper.instance.markAsSynced(report.reportId!);
          }
          success++;
        } catch (e) {
          print("Failed to sync report_id=${report.reportId}: $e");
          failed++;
        }
      }
    } catch (e) {
      print("Sync batch error: $e");
    }

    return {'success': success, 'failed': failed};
  }

  static Future<bool> isFirebaseAvailable() async {
    try {
      if (Firebase.apps.isEmpty) return false;

      await FirebaseFirestore.instance
          .collection('incident_reports')
          .limit(1)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      print("Firebase availability check failed: $e");
      return false;
    }
  }

  static String _resolveEvidencePath(String? evidencePhoto) {
    if (evidencePhoto == null) return "null";
    if (evidencePhoto.startsWith('http://') ||
        evidencePhoto.startsWith('https://')) {
      return evidencePhoto;
    }
    return "OFFLINE_ONLY";
  }
}
