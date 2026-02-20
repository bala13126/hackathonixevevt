import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/urgency_badge.dart';
import '../../models/missing_person.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final urgentCases = const [];

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.accent.withOpacity(0.1),
                        child: Icon(Icons.person, color: AppColors.accent, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Welcome back',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Location not set',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: isDark ? Colors.white : AppColors.primary,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, AppConstants.routeNotifications);
                        },
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
                    _buildUrgentCasesSection(urgentCases),
                    const SizedBox(height: 32),
                    _buildQuickActionsSection(context),
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
    );
  }

  Widget _buildUrgentCasesSection(List<dynamic> urgentCases) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              onPressed: () {},
              child: Text('View All', style: TextStyle(color: AppColors.accent)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (urgentCases.isEmpty)
          GlassCard(
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.textSecondary),
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
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: urgentCases.length,
              itemBuilder: (context, index) {
                final person = urgentCases[index];
                return Container(
                  width: 160,
                  margin: EdgeInsets.only(right: index < urgentCases.length - 1 ? 16 : 0),
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 80,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.backgroundLight,
                          ),
                          child: const Icon(Icons.person, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Unassigned',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text('Age --', style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Row(
                          children: const [
                            Icon(Icons.location_on, size: 12, color: AppColors.textSecondary),
                            SizedBox(width: 2),
                            Text('-- km', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: const [
                            UrgencyBadge(urgency: UrgencyLevel.normal),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _buildActionCard(
              'Report Missing',
              Icons.report,
              AppColors.error,
              () => Navigator.pushNamed(context, AppConstants.routeReportMissing),
            ),
            _buildActionCard(
              'AI Assistant',
              Icons.auto_awesome,
              AppColors.accent,
              () => Navigator.pushNamed(context, AppConstants.routeAIChat),
            ),
            _buildActionCard(
              'Nearby Cases',
              Icons.location_on,
              AppColors.warning,
              () => Navigator.pushNamed(context, AppConstants.routeCaseFeed),
            ),
            _buildActionCard(
              'Emergency Help',
              Icons.emergency,
              AppColors.critical,
              () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityImpactPanel() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: AppColors.accent, size: 28),
              const SizedBox(width: 8),
              Text(
                'Community Impact',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildImpactItem('Honour Score', '0', Icons.star),
              ),
              Expanded(
                child: _buildImpactItem('Rescues', '0', Icons.check_circle),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Current Badge: None',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.0,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '0% to Next Badge',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accent, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildActiveSearchStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Search Status',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No active searches right now.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
