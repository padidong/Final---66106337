import 'package:flutter/material.dart';
import '../helpers/db_helper.dart';
import '../helpers/firebase_helper.dart';
import '../constants/theme.dart';
import 'report_incident_screen.dart';
import 'edit_station_list_screen.dart';
import 'incident_list_screen.dart';
import 'search_filter_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _totalIncidents = 0;
  List<Map<String, dynamic>> _topStations = [];
  bool _isLoading = true;
  bool _isSyncing = false;

  // Sync stats
  int _syncedCount = 0;
  int _unsyncedCount = 0;
  bool? _firebaseAvailable;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    final dbHelper = DatabaseHelper.instance;

    final count = await dbHelper.getIncidentReportCount();

    final topStations = await dbHelper.getTopPollingStations();

    final syncStats = await dbHelper.getSyncStats();

    final fbAvailable = await FirebaseHelper.isFirebaseAvailable();

    setState(() {
      _totalIncidents = count;
      _topStations = topStations;
      _syncedCount = syncStats['synced'] ?? 0;
      _unsyncedCount = syncStats['unsynced'] ?? 0;
      _firebaseAvailable = fbAvailable;
      _isLoading = false;
    });
  }

  Future<void> _syncToFirebase() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    final result = await FirebaseHelper.syncAllUnsynced();
    final success = result['success'] ?? 0;
    final failed = result['failed'] ?? 0;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                failed == 0 ? Icons.cloud_done : Icons.warning,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text('Synced: $success  |  Failed: $failed'),
            ],
          ),
          backgroundColor: failed == 0 ? AppTheme.success : AppTheme.warning,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    setState(() => _isSyncing = false);
    _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Election Watch Dashboard'),
        actions: [
          _buildAppBarSyncIcon(),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 24),
                    Text(
                      'Top 3 Stations by Incidents',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    _buildTopStationsList(),
                    const SizedBox(height: 24),
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    _buildActionGrid(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAppBarSyncIcon() {
    final isOnline = _firebaseAvailable == true;

    if (_isSyncing) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }

    return Tooltip(
      message: isOnline
          ? 'Firebase: Online\nSynced: $_syncedCount | Pending: $_unsyncedCount'
          : 'Firebase: Offline\nPending: $_unsyncedCount',
      child: InkWell(
        onTap: _unsyncedCount > 0 ? _syncToFirebase : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                color: Colors.white,
                size: 24,
              ),
              if (_unsyncedCount > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_unsyncedCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (_unsyncedCount == 0 && isOnline)
                Positioned(
                  bottom: 2,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.lightGreenAccent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryGreen,
                        width: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      color: AppTheme.primaryGreen,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Incidents',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Text(
                    '$_totalIncidents',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white54,
              size: 64,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopStationsList() {
    if (_topStations.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.bar_chart, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                'No incidents reported yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final maxCount = (_topStations.first['report_count'] as int).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: _topStations.map((station) {
            final count = (station['report_count'] as int).toDouble();
            final ratio = maxCount > 0 ? count / maxCount : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: AppTheme.primaryGreen,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                station['station_name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${station['report_count']} รายงาน',
                        style: const TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(
                            height: 10,
                            width: constraints.maxWidth,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          Container(
                            height: 10,
                            width: constraints.maxWidth * ratio,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildActionCard(
          context,
          'Report Incident',
          Icons.add_a_photo,
          () => _navigateAndRefresh(context, const ReportIncidentScreen()),
        ),
        _buildActionCard(
          context,
          'Incident List',
          Icons.list_alt,
          () => _navigateAndRefresh(context, const IncidentListScreen()),
        ),
        _buildActionCard(
          context,
          'Edit Stations',
          Icons.edit_location_alt,
          () => _navigateAndRefresh(context, const EditStationListScreen()),
        ),
        _buildActionCard(
          context,
          'Search & Filter',
          Icons.search,
          () => _navigateAndRefresh(context, const SearchFilterScreen()),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 4,
        margin: EdgeInsets.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppTheme.primaryGreen),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateAndRefresh(BuildContext context, Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
    _loadDashboardData();
  }

  void _drawerNavigate(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Future.microtask(() => _navigateAndRefresh(context, screen));
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AppTheme.primaryGreen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.how_to_vote, color: Colors.white, size: 40),
                SizedBox(height: 8),
                Text(
                  'Election Watch',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ระบบเฝ้าระวังการเลือกตั้ง',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: AppTheme.primaryGreen),
            title: const Text('Dashboard'),
            selected: true,
            selectedTileColor: AppTheme.background,
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(
              Icons.add_a_photo,
              color: AppTheme.primaryGreen,
            ),
            title: const Text('Report Incident'),
            onTap: () => _drawerNavigate(context, const ReportIncidentScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt, color: AppTheme.primaryGreen),
            title: const Text('Incident List'),
            onTap: () => _drawerNavigate(context, const IncidentListScreen()),
          ),
          ListTile(
            leading: const Icon(
              Icons.edit_location_alt,
              color: AppTheme.primaryGreen,
            ),
            title: const Text('Edit Stations'),
            onTap: () =>
                _drawerNavigate(context, const EditStationListScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.search, color: AppTheme.primaryGreen),
            title: const Text('Search & Filter'),
            onTap: () => _drawerNavigate(context, const SearchFilterScreen()),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.grey),
            title: const Text('App Version: 1.0.0'),
            enabled: false,
          ),
        ],
      ),
    );
  }
}
