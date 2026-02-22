import 'dart:io';
import 'package:flutter/material.dart';
import '../helpers/db_helper.dart';
import '../helpers/firebase_helper.dart';
import '../models/incident_report.dart';
import '../constants/theme.dart';
import '../widgets/severity_badge.dart';
import '../widgets/sync_status_badge.dart';

class IncidentListScreen extends StatefulWidget {
  const IncidentListScreen({super.key});

  @override
  State<IncidentListScreen> createState() => _IncidentListScreenState();
}

class _IncidentListScreenState extends State<IncidentListScreen> {
  List<IncidentReport> _incidents = [];
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    setState(() => _isLoading = true);
    final incidents = await DatabaseHelper.instance.getAllIncidentReports();
    setState(() {
      _incidents = incidents;
      _isLoading = false;
    });
  }

  Future<void> _syncAll() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    final result = await FirebaseHelper.syncAllUnsynced();
    final s = result['success'] ?? 0;
    final f = result['failed'] ?? 0;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                f == 0 ? Icons.cloud_done : Icons.warning,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text('Synced: $s  |  Failed: $f'),
            ],
          ),
          backgroundColor: f == 0 ? AppTheme.success : AppTheme.warning,
        ),
      );
    }

    setState(() => _isSyncing = false);
    _loadIncidents();
  }

  Future<void> _confirmDelete(IncidentReport report) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete this incident report?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && report.reportId != null) {
      await DatabaseHelper.instance.deleteIncidentReport(report.reportId!);
      _loadIncidents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incident deleted.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unsyncedCount = _incidents.where((r) => !r.isSynced).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident List'),
        actions: [
          if (unsyncedCount > 0)
            _isSyncing
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : IconButton(
                    icon: Badge(
                      label: Text('$unsyncedCount'),
                      child: const Icon(Icons.cloud_upload),
                    ),
                    tooltip: 'Sync $unsyncedCount pending',
                    onPressed: _syncAll,
                  ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : _incidents.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No incidents found.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadIncidents,
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _incidents.length,
                itemBuilder: (context, index) {
                  final report = _incidents[index];
                  return _buildIncidentCard(report);
                },
              ),
            ),
    );
  }

  Widget _buildIncidentCard(IncidentReport report) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  report.evidencePhoto != null &&
                      report.evidencePhoto != "OFFLINE_ONLY" &&
                      !report.evidencePhoto!.startsWith('http')
                  ? Image.file(
                      File(report.evidencePhoto!),
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          report.typeName ?? 'Unknown Violation',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SyncStatusBadge(isSynced: report.isSynced),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 13,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          report.stationName ?? 'Unknown Station',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      SeverityBadge(severity: report.severity),
                      const Spacer(),
                      Text(
                        report.timestamp.split(' ')[0],
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppTheme.error,
                size: 22,
              ),
              onPressed: () => _confirmDelete(report),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.image_not_supported,
        color: Colors.grey,
        size: 28,
      ),
    );
  }
}
