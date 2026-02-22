import 'package:flutter/material.dart';
import '../helpers/db_helper.dart';
import '../models/polling_station.dart';
import '../constants/theme.dart';

class EditStationFormScreen extends StatefulWidget {
  final PollingStation station;

  const EditStationFormScreen({super.key, required this.station});

  @override
  State<EditStationFormScreen> createState() => _EditStationFormScreenState();
}

class _EditStationFormScreenState extends State<EditStationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _zoneController;
  late TextEditingController _provinceController;
  bool _isSaving = false;

  final List<String> _validPrefixes = [
    "โรงเรียน", "วัด", "เต็นท์", "ศาลา", "หอประชุม"
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.station.stationName);
    _zoneController = TextEditingController(text: widget.station.zone);
    _provinceController = TextEditingController(text: widget.station.province);
  }

  Future<void> _saveStation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    
    String newName = _nameController.text.trim();
    final dbHelper = DatabaseHelper.instance;

    bool hasValidPrefix = _validPrefixes.any((prefix) => newName.startsWith(prefix));
    if (!hasValidPrefix) {
      _showErrorDialog("Invalid Name Prefix", "Station name must start with one of: ${_validPrefixes.join(', ')}");
      setState(() => _isSaving = false);
      return;
    }

    bool isDuplicate = await dbHelper.isDuplicateStationName(newName, widget.station.stationId);
    if (isDuplicate) {
      _showErrorDialog("Duplicate Name", "This station name already exists. Please choose a different name.");
      setState(() => _isSaving = false);
      return;
    }

    int incidentCount = await dbHelper.getIncidentCountForStation(widget.station.stationId);

    if (incidentCount > 0) {
      bool confirm = await _showConfirmDialog(incidentCount);
      if (!confirm) {
        setState(() => _isSaving = false);
        return;
      }
    }

    PollingStation updatedStation = PollingStation(
      stationId: widget.station.stationId,
      stationName: newName,
      zone: _zoneController.text.trim(),
      province: _provinceController.text.trim(),
    );

    await dbHelper.updatePollingStation(updatedStation);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Station updated successfully'), backgroundColor: AppTheme.success),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _showErrorDialog(String title, String message) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(color: AppTheme.error)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmDialog(int count) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Warning'),
        content: Text('This station has $count incident report(s). Confirm edit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm Edit'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Station'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text('Station ID: ${widget.station.stationId}', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Station Name',
                  helperText: 'Must start with: โรงเรียน, วัด, เต็นท์, ศาลา, หอประชุม',
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _zoneController,
                decoration: const InputDecoration(labelText: 'Zone'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _provinceController,
                decoration: const InputDecoration(labelText: 'Province'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveStation,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Changes', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _zoneController.dispose();
    _provinceController.dispose();
    super.dispose();
  }
}
