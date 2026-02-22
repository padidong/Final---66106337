import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/polling_station.dart';
import '../models/violation_type.dart';
import '../models/incident_report.dart';

class DatabaseHelper {
  static const _databaseName = "election_watch.db";
  static const _databaseVersion = 2;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);

    bool dbExists = await databaseExists(path);
    if (!dbExists) {
      print("Database does not exist. Creating new DB.");
    } else {
      print("Database already exists.");
    }

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE incident_report ADD COLUMN synced INTEGER DEFAULT 0',
      );
      print("Database upgraded to v2: added synced column.");
    }
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE polling_station (
        station_id INTEGER PRIMARY KEY,
        station_name TEXT,
        zone TEXT,
        province TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE violation_type (
        type_id INTEGER PRIMARY KEY,
        type_name TEXT,
        severity TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE incident_report (
        report_id INTEGER PRIMARY KEY AUTOINCREMENT,
        station_id INTEGER,
        type_id INTEGER,
        reporter_name TEXT,
        description TEXT,
        evidence_photo TEXT,
        timestamp TEXT,
        ai_result TEXT,
        ai_confidence REAL,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY(station_id) REFERENCES polling_station(station_id),
        FOREIGN KEY(type_id) REFERENCES violation_type(type_id)
      )
    ''');

    await _insertSeedData(db);
  }

  Future<void> _insertSeedData(Database db) async {
    await db.insert('polling_station', {
      'station_id': 101,
      'station_name': 'โรงเรียนวัดพระมหาธาตุ',
      'zone': 'เขต 1',
      'province': 'นครศรีธรรมราช',
    });
    await db.insert('polling_station', {
      'station_id': 102,
      'station_name': 'เต็นท์หน้าตลาดท่าวัง',
      'zone': 'เขต 1',
      'province': 'นครศรีธรรมราช',
    });
    await db.insert('polling_station', {
      'station_id': 103,
      'station_name': 'ศาลากลางหมู่บ้านคีรีวง',
      'zone': 'เขต 2',
      'province': 'นครศรีธรรมราช',
    });
    await db.insert('polling_station', {
      'station_id': 104,
      'station_name': 'หอประชุมอำเภอทุ่งสง',
      'zone': 'เขต 3',
      'province': 'นครศรีธรรมราช',
    });

    await db.insert('violation_type', {
      'type_id': 1,
      'type_name': 'ซื้อสิทธิ์ขายเสียง (Buying Votes)',
      'severity': 'High',
    });
    await db.insert('violation_type', {
      'type_id': 2,
      'type_name': 'ขนคนไปลงคะแนน (Transportation)',
      'severity': 'High',
    });
    await db.insert('violation_type', {
      'type_id': 3,
      'type_name': 'หาเสียงเกินเวลา (Overtime Campaign)',
      'severity': 'Medium',
    });
    await db.insert('violation_type', {
      'type_id': 4,
      'type_name': 'ทำลายป้ายหาเสียง (Vandalism)',
      'severity': 'Low',
    });
    await db.insert('violation_type', {
      'type_id': 5,
      'type_name': 'เจ้าหน้าที่วางตัวไม่เป็นกลาง (Bias Official)',
      'severity': 'High',
    });

    await db.insert('incident_report', {
      'station_id': 101,
      'type_id': 1,
      'reporter_name': 'พลเมืองดี 01',
      'description': 'พบเห็นการแจกเงินบริเวณหน้าหน่วย',
      'evidence_photo': null,
      'timestamp': '2026-02-08 09:30:00',
      'ai_result': 'Money',
      'ai_confidence': 0.95,
    });
    await db.insert('incident_report', {
      'station_id': 102,
      'type_id': 3,
      'reporter_name': 'สมชาย ใจกล้า',
      'description': 'มีการเปิดรถแห่เสียงดังรบกวน',
      'evidence_photo': null,
      'timestamp': '2026-02-08 10:15:00',
      'ai_result': 'Crowd',
      'ai_confidence': 0.75,
    });
    await db.insert('incident_report', {
      'station_id': 103,
      'type_id': 5,
      'reporter_name': 'Anonymous',
      'description': 'เจ้าหน้าที่พูดจาชี้นำผู้ลงคะแนน',
      'evidence_photo': null,
      'timestamp': '2026-02-08 11:00:00',
      'ai_result': null,
      'ai_confidence': 0.0,
    });
  }

  Future<int> getIncidentReportCount() async {
    Database db = await instance.database;
    var result = await db.rawQuery('SELECT COUNT(*) FROM incident_report');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getTopPollingStations() async {
    Database db = await instance.database;
    return await db.rawQuery('''
      SELECT p.station_name, COUNT(i.report_id) as report_count 
      FROM incident_report i
      JOIN polling_station p ON i.station_id = p.station_id
      GROUP BY i.station_id
      ORDER BY report_count DESC
      LIMIT 3
    ''');
  }

  Future<List<PollingStation>> getAllPollingStations() async {
    Database db = await instance.database;
    var res = await db.query('polling_station');
    return res.map((c) => PollingStation.fromMap(c)).toList();
  }

  Future<List<ViolationType>> getAllViolationTypes() async {
    Database db = await instance.database;
    var res = await db.query('violation_type');
    return res.map((c) => ViolationType.fromMap(c)).toList();
  }

  Future<int> insertIncidentReport(IncidentReport report) async {
    Database db = await instance.database;
    return await db.insert('incident_report', report.toMap());
  }

  Future<bool> isDuplicateStationName(String name, int excludeStationId) async {
    Database db = await instance.database;
    var res = await db.query(
      'polling_station',
      where: 'station_name = ? AND station_id != ?',
      whereArgs: [name, excludeStationId],
    );
    return res.isNotEmpty;
  }

  Future<int> getIncidentCountForStation(int stationId) async {
    Database db = await instance.database;
    var res = await db.rawQuery(
      'SELECT COUNT(*) FROM incident_report WHERE station_id = ?',
      [stationId],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<int> updatePollingStation(PollingStation station) async {
    Database db = await instance.database;
    return await db.update(
      'polling_station',
      station.toMap(),
      where: 'station_id = ?',
      whereArgs: [station.stationId],
    );
  }

  Future<List<IncidentReport>> getAllIncidentReports() async {
    Database db = await instance.database;
    var res = await db.rawQuery('''
      SELECT 
        i.*, 
        p.station_name, 
        v.type_name, 
        v.severity 
      FROM incident_report i
      JOIN polling_station p ON i.station_id = p.station_id
      JOIN violation_type v ON i.type_id = v.type_id
      ORDER BY i.timestamp DESC
    ''');
    return res.map((c) => IncidentReport.fromMap(c)).toList();
  }

  Future<int> deleteIncidentReport(int reportId) async {
    Database db = await instance.database;
    return await db.delete(
      'incident_report',
      where: 'report_id = ?',
      whereArgs: [reportId],
    );
  }

  Future<List<IncidentReport>> searchAndFilterIncidents(
    String searchTerm,
    String? severityFilter,
  ) async {
    Database db = await instance.database;
    String query = '''
      SELECT 
        i.*, 
        p.station_name, 
        v.type_name, 
        v.severity 
      FROM incident_report i
      JOIN polling_station p ON i.station_id = p.station_id
      JOIN violation_type v ON i.type_id = v.type_id
      WHERE 1=1
    ''';
    List<dynamic> args = [];

    if (searchTerm.isNotEmpty) {
      query += ' AND (i.reporter_name LIKE ? OR i.description LIKE ?)';
      args.add('%$searchTerm%');
      args.add('%$searchTerm%');
    }

    if (severityFilter != null &&
        severityFilter.isNotEmpty &&
        severityFilter != 'All') {
      query += ' AND v.severity = ?';
      args.add(severityFilter);
    }

    query += ' ORDER BY i.timestamp DESC';

    var res = await db.rawQuery(query, args);
    return res.map((c) => IncidentReport.fromMap(c)).toList();
  }

  Future<int> markAsSynced(int reportId) async {
    Database db = await instance.database;
    return await db.update(
      'incident_report',
      {'synced': 1},
      where: 'report_id = ?',
      whereArgs: [reportId],
    );
  }

  Future<List<IncidentReport>> getUnsyncedReports() async {
    Database db = await instance.database;
    var res = await db.rawQuery('''
      SELECT 
        i.*, 
        p.station_name, 
        v.type_name, 
        v.severity 
      FROM incident_report i
      JOIN polling_station p ON i.station_id = p.station_id
      JOIN violation_type v ON i.type_id = v.type_id
      WHERE i.synced = 0
      ORDER BY i.timestamp ASC
    ''');
    return res.map((c) => IncidentReport.fromMap(c)).toList();
  }

  Future<Map<String, int>> getSyncStats() async {
    Database db = await instance.database;
    var total = await db.rawQuery('SELECT COUNT(*) FROM incident_report');
    var synced = await db.rawQuery(
      'SELECT COUNT(*) FROM incident_report WHERE synced = 1',
    );
    int totalCount = Sqflite.firstIntValue(total) ?? 0;
    int syncedCount = Sqflite.firstIntValue(synced) ?? 0;
    return {
      'total': totalCount,
      'synced': syncedCount,
      'unsynced': totalCount - syncedCount,
    };
  }
}
