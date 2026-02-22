import 'package:flutter/material.dart';
import '../helpers/db_helper.dart';
import '../models/polling_station.dart';
import '../constants/theme.dart';
import 'edit_station_form_screen.dart';

class EditStationListScreen extends StatefulWidget {
  const EditStationListScreen({super.key});

  @override
  State<EditStationListScreen> createState() => _EditStationListScreenState();
}

class _EditStationListScreenState extends State<EditStationListScreen> {
  List<PollingStation> _stations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() => _isLoading = true);
    final stations = await DatabaseHelper.instance.getAllPollingStations();
    setState(() {
      _stations = stations;
      _isLoading = false;
    });
  }

  Future<void> _navigateToEdit(PollingStation station) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditStationFormScreen(station: station)),
    );
    
    if (result == true) {
      _loadStations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Station to Edit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : ListView.builder(
              itemCount: _stations.length,
              itemBuilder: (context, index) {
                final station = _stations[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.edit_location, color: AppTheme.primaryGreen),
                    title: Text(station.stationName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${station.zone}, ${station.province}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _navigateToEdit(station),
                  ),
                );
              },
            ),
    );
  }
}
