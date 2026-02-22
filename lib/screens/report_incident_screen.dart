import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../helpers/db_helper.dart';
import '../helpers/firebase_helper.dart';
import '../helpers/ai_helper.dart';
import '../models/polling_station.dart';
import '../models/violation_type.dart';
import '../models/incident_report.dart';
import '../constants/theme.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  List<PollingStation> _stations = [];
  List<ViolationType> _violationTypes = [];

  int? _selectedStationId;
  int? _selectedTypeId;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final AIHelper _aiHelper = AIHelper();
  String? _aiResult;
  double? _aiConfidence;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadFormData();
    _aiHelper.initModel();
  }

  Future<void> _loadFormData() async {
    final dbHelper = DatabaseHelper.instance;
    final stations = await dbHelper.getAllPollingStations();
    final violationTypes = await dbHelper.getAllViolationTypes();

    setState(() {
      _stations = stations;
      _violationTypes = violationTypes;
      _isLoading = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _aiResult = null; 
      });
      _processImageWithAI(pickedFile.path);
    }
  }

  Future<void> _processImageWithAI(String imagePath) async {
    final result = await _aiHelper.classifyImage(imagePath);

    setState(() {
      _aiResult = result['label'];
      _aiConfidence = result['confidence'];

      if (_aiResult != null && _aiResult != 'Unknown') {
        int mappedId = _aiHelper.mapLabelToViolationTypeId(_aiResult!);
        if (_violationTypes.any((v) => v.typeId == mappedId)) {
          _selectedTypeId = mappedId;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'AI detected $_aiResult. Auto-selected violation type.',
              ),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
      }
    });
  }

  Future<void> _saveReport() async {
    if (!_formKey.currentState!.validate() ||
        _selectedStationId == null ||
        _selectedTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields and selections.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      // Format: YYYY-MM-DD HH:MM:SS
      final timestamp =
          "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

      final report = IncidentReport(
        stationId: _selectedStationId!,
        typeId: _selectedTypeId!,
        reporterName: _nameController.text.trim(),
        description: _descController.text.trim(),
        evidencePhoto: _imageFile?.path,
        timestamp: timestamp,
        aiResult: _aiResult,
        aiConfidence: _aiConfidence,
      );

      final insertedId = await DatabaseHelper.instance.insertIncidentReport(
        report,
      );

      final savedReport = IncidentReport(
        reportId: insertedId,
        stationId: report.stationId,
        typeId: report.typeId,
        reporterName: report.reporterName,
        description: report.description,
        evidencePhoto: report.evidencePhoto,
        timestamp: report.timestamp,
        aiResult: report.aiResult,
        aiConfidence: report.aiConfidence,
      );

      final firebaseSaved = await FirebaseHelper.saveIncidentOnline(
        savedReport,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  firebaseSaved ? Icons.cloud_done : Icons.cloud_off,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    firebaseSaved
                        ? 'Saved: SQLite + Firebase'
                        : 'Saved: SQLite only (Firebase failed)',
                  ),
                ),
              ],
            ),
            backgroundColor: firebaseSaved
                ? AppTheme.success
                : AppTheme.warning,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context); // Go back home
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving report: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Incident'),
        actions: [
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
          : SingleChildScrollView(
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
                            if (_imageFile != null)
                              Image.file(
                                _imageFile!,
                                height: 200,
                                fit: BoxFit.cover,
                              )
                            else
                              Container(
                                height: 150,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Camera'),
                                  onPressed: () =>
                                      _pickImage(ImageSource.camera),
                                ),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Gallery'),
                                  onPressed: () =>
                                      _pickImage(ImageSource.gallery),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_aiResult != null)
                      Card(
                        color: AppTheme.background,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.memory,
                                color: AppTheme.primaryGreen,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AI Analysis: $_aiResult',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Confidence: ${(_aiConfidence! * 100).toStringAsFixed(1)}%',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<int>(
                      value: _selectedStationId,
                      decoration: const InputDecoration(
                        labelText: 'Polling Station',
                      ),
                      items: _stations
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.stationId,
                              child: Text(s.stationName),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedStationId = val),
                      validator: (val) => val == null
                          ? 'Please select a polling station'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<int>(
                      value: _selectedTypeId,
                      decoration: const InputDecoration(
                        labelText: 'Violation Type',
                      ),
                      items: _violationTypes
                          .map(
                            (v) => DropdownMenuItem(
                              value: v.typeId,
                              child: Text(v.typeName),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _selectedTypeId = val),
                      validator: (val) =>
                          val == null ? 'Please select a violation type' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Reporter Name',
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required field' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 3,
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required field' : null,
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveReport,
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Submit Report',
                                style: TextStyle(fontSize: 18),
                              ),
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
    _descController.dispose();
    super.dispose();
  }
}
