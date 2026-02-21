import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/backend_api_service.dart';
import '../../widgets/urgency_badge.dart';
import '../../models/missing_person.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  double _geoAlertRadius = 2.0;
  bool _geoAlertEnabled = false;
  String _searchQuery = '';
  bool _isLoadingCases = true;
  String? _casesLoadError;

  // dynamic monitoring state
  List<MissingPerson> _urgentCases = [];
  List<MissingPerson> _feedPosts = [];
  int _casesFound = 0;
  int _tipsSubmitted = 0;
  int _activeUsers = 0;
  int _activeSearches = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
    _loadCases();
  }

  Future<void> _loadCases() async {
    setState(() {
      _isLoadingCases = true;
      _casesLoadError = null;
    });

    try {
      final apiCases = await BackendApiService.fetchCases();
      if (!mounted) return;
      setState(() {
        // Separate cases by urgency: high/critical go to urgent, others to feed
        _urgentCases = apiCases
            .where((c) => c.urgency == UrgencyLevel.high || c.urgency == UrgencyLevel.critical)
            .toList();
        // Feed shows all cases but prioritizes recent ones
        _feedPosts = apiCases;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _casesLoadError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCases = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urgentCases = _urgentCases.where((caseItem) {
      if (_searchQuery.trim().isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return caseItem.name.toLowerCase().contains(query) ||
          caseItem.lastSeenLocation.toLowerCase().contains(query);
    }).toList()..sort(_compareCasePriority);

    final prioritizedPosts = _feedPosts.where((caseItem) {
      if (_searchQuery.trim().isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return caseItem.name.toLowerCase().contains(query) ||
          caseItem.lastSeenLocation.toLowerCase().contains(query) ||
          caseItem.description.toLowerCase().contains(query);
    }).toList()..sort(_compareCasePriority);

    return Scaffold(
      drawer: _buildSideNavBar(context),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 148,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              elevation: 0,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  tooltip: 'Open navigation menu',
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.only(top: 36, left: 24, right: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.85),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white.withOpacity(0.95),
                          child: Icon(
                            Icons.person,
                            color: AppColors.primary,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Welcome back',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Location not set',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_geoAlertEnabled) _buildGeoAlertBanner(),
                    if (_isLoadingCases)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: LinearProgressIndicator(),
                      ),
                    if (_casesLoadError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Unable to load cases: $_casesLoadError',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    _buildSearchBar(),
                    const SizedBox(height: 24),
                    _buildUrgentCasesSection(urgentCases),
                    const SizedBox(height: 32),
                    _buildMissingPostsSection(prioritizedPosts),
                    const SizedBox(height: 32),
                    _buildCommunityImpactPanel(),
                    const SizedBox(height: 32),
                    _buildActiveSearchStatus(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            AppConstants.routeReportMissing,
          );
          if (result is MissingPerson) {
            setState(() {
              _urgentCases.insert(0, result);
              _feedPosts.insert(0, result);
              _casesFound++;
              _activeUsers++;
              _activeSearches++;
            });
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Report Missing'),
        tooltip: 'Report a missing person',
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search by name or location',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.06)
            : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildGeoAlertBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF9800).withOpacity(0.1),
            const Color(0xFFFF6F00).withOpacity(0.05),
          ],
        ),
        border: Border.all(color: const Color(0xFFFF9800)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on, color: Color(0xFFFF9800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Geo Alert Active',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'SMS alerts to nearby users within ${_geoAlertRadius.toStringAsFixed(1)} km',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              setState(() {
                _geoAlertEnabled = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSideNavBar(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              ),
            ),
            child: DrawerHeader(
              decoration: const BoxDecoration(color: Colors.transparent),
              margin: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ResQLink',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your Safety Network',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildDrawerMenuItem(
            icon: Icons.home,
            title: 'Home',
            onTap: () => Navigator.pop(context),
          ),
          _buildDrawerMenuItem(
            icon: Icons.report,
            title: 'Report Missing',
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.pushNamed(
                context,
                AppConstants.routeReportMissing,
              );
              if (result is MissingPerson) {
                setState(() {
                  _urgentCases.insert(0, result);
                  _feedPosts.insert(0, result);
                  _casesFound++;
                  _activeUsers++;
                  _activeSearches++;
                });
              }
            },
          ),
          _buildDrawerMenuItem(
            icon: Icons.feed,
            title: 'All Cases',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppConstants.routeCaseFeed);
            },
          ),
          _buildDrawerMenuItem(
            icon: Icons.chat,
            title: 'AI Assistant',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppConstants.routeAIChat);
            },
          ),
          _buildDrawerMenuItem(
            icon: Icons.track_changes,
            title: 'Case Tracking',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppConstants.routeCaseTracking);
            },
          ),
          const Divider(height: 1),
          _buildDrawerMenuItem(
            icon: Icons.notifications,
            title: 'Notifications',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppConstants.routeNotifications);
            },
          ),
          _buildDrawerMenuItem(
            icon: Icons.person,
            title: 'Profile',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppConstants.routeProfile);
            },
          ),
          _buildDrawerMenuItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppConstants.routeSettings);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.location_on,
              color: _geoAlertEnabled ? const Color(0xFFFF9800) : null,
            ),
            title: const Text('Geo Alerts'),
            trailing: Switch(
              value: _geoAlertEnabled,
              onChanged: (value) {
                Navigator.pop(context);
                setState(() {
                  _geoAlertEnabled = value;
                });
                if (value) {
                  _showGeoAlertDialog(context);
                }
              },
            ),
            onTap: () {
              Navigator.pop(context);
              _showGeoAlertDialog(context);
            },
          ),
          const Divider(height: 1),
          _buildDrawerMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            isLogout: true,
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? AppColors.error : null),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? AppColors.error : null,
          fontWeight: isLogout ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppConstants.routeLogin,
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showGeoAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Geo Alert System'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enable location-based alerts to send SMS notifications to nearby users about missing persons in your area.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Alert Radius (km):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Slider(
                value: _geoAlertRadius,
                min: 0.5,
                max: 10,
                divisions: 19,
                label: '${_geoAlertRadius.toStringAsFixed(1)} km',
                onChanged: (value) {
                  setState(() {
                    _geoAlertRadius = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Send SMS to nearby contacts'),
                value: true,
                onChanged: (value) {},
              ),
              CheckboxListTile(
                title: const Text('Enable push notifications'),
                value: true,
                onChanged: (value) {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _geoAlertEnabled = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Geo alert activated! SMS will be sent to users within ${_geoAlertRadius.toStringAsFixed(1)} km.',
                  ),
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Activate'),
          ),
        ],
      ),
    );
  }

  int _urgencyRank(UrgencyLevel urgency) {
    switch (urgency) {
      case UrgencyLevel.critical:
        return 0;
      case UrgencyLevel.high:
        return 1;
      case UrgencyLevel.normal:
        return 2;
    }
  }

  int _compareCasePriority(MissingPerson a, MissingPerson b) {
    final urgencyCompare = _urgencyRank(
      a.urgency,
    ).compareTo(_urgencyRank(b.urgency));
    if (urgencyCompare != 0) return urgencyCompare;
    return b.lastSeenTime.compareTo(a.lastSeenTime);
  }

  String _timeSinceMissing(DateTime lastSeenTime) {
    final duration = DateTime.now().difference(lastSeenTime);
    if (duration.inMinutes < 60) {
      return '${math.max(duration.inMinutes, 1)} min ago';
    }
    if (duration.inHours < 24) {
      return '${duration.inHours} hr ago';
    }
    return '${duration.inDays} day${duration.inDays == 1 ? '' : 's'} ago';
  }

  Widget _buildUrgentCasesSection(List<MissingPerson> urgentCases) {
    // show a red banner if any case is marked critical
    final hasCritical = urgentCases.any((c) {
      try {
        return c.urgency == UrgencyLevel.critical;
      } catch (_) {
        return false;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasCritical)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              border: Border.all(color: AppColors.error),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: AppColors.error),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Critical alert! Please review urgent cases immediately.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Urgent Cases Near You',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.primary,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, AppConstants.routeCaseFeed);
              },
              child: Text(
                'View All',
                style: TextStyle(color: AppColors.accent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (urgentCases.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: AppColors.info, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No urgent cases nearby at the moment.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          )
        else
          ...urgentCases
              .take(3)
              .map(
                (caseItem) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMissingPostCard(caseItem),
                ),
              ),
      ],
    );
  }

  Widget _buildMissingPostsSection(List<MissingPerson> posts) {
    // Filter out urgent cases to avoid duplication with urgentCasesSection
    final nonUrgentPosts = posts
        .where((p) => p.urgency != UrgencyLevel.high && p.urgency != UrgencyLevel.critical)
        .toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Latest Missing Reports',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        if (nonUrgentPosts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.08),
              border: Border.all(color: AppColors.info.withOpacity(0.25)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No reports available yet. Post a missing person to see it here.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ...nonUrgentPosts.map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildMissingPostCard(post),
            ),
          ),
      ],
    );
  }

  Widget _buildMissingPostCard(MissingPerson post) {
    final photoPath = post.photoUrl.trim();
    final isUrlLike =
        photoPath.startsWith('http') ||
        photoPath.startsWith('blob:') ||
        photoPath.startsWith('data:') ||
        photoPath.startsWith('file:');
    final resolvedPhotoPath = isUrlLike || photoPath.isEmpty
        ? photoPath
        : 'file://$photoPath';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppConstants.routeCaseDetail,
            arguments: post,
          );
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.04)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: resolvedPhotoPath.isNotEmpty
                      ? Image.network(
                          resolvedPhotoPath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPhotoPlaceholder(),
                        )
                      : _buildPhotoPlaceholder(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            post.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        UrgencyBadge(urgency: post.urgency, compact: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Missing: ${_timeSinceMissing(post.lastSeenTime)}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            post.lastSeenLocation,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      post.description.isEmpty
                          ? 'No additional information provided.'
                          : post.description,
                      style: const TextStyle(height: 1.35),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppConstants.routeSubmitTip,
                            arguments: post.id,
                          );
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('Found Missing Person'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      color: AppColors.primary.withOpacity(0.08),
      child: Center(
        child: Icon(
          Icons.person_search,
          size: 64,
          color: AppColors.primary.withOpacity(0.55),
        ),
      ),
    );
  }

  Widget _buildCommunityImpactPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.accent.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.people, color: AppColors.accent, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Community Impact',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildImpactStat('$_casesFound', 'Cases Found'),
              _buildImpactStat('$_tipsSubmitted', 'Tips Submitted'),
              _buildImpactStat('$_activeUsers', 'Active Users'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildActiveSearchStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withOpacity(0.1),
            AppColors.success.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Active Search Operations',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_activeSearches active searches in your region',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
