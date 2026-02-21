import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/backend_api_service.dart';
import '../../widgets/glass_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
  with WidgetsBindingObserver {
  String _name = 'Profile not set';
  String _bio = 'Add your details to personalize ResQLink';
  String _email = '';
  String _phone = '';
  int _honorScore = 0;
  int _rescues = 0;
  String _badge = 'None';
  int _redeemPoints = 0;
  int? _userId;
  bool _loadingRewards = true;
  List<Map<String, dynamic>> _rewards = [];
  bool _loadingRedemptions = true;
  List<Map<String, dynamic>> _redemptions = [];
  Timer? _autoSyncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProfile();
    _loadRewards();
    _loadRedemptions();
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final userId = _userId;
      if (userId != null) {
        _syncProfileFromServer(userId);
      }
    }
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    setState(() {
      _name = prefs.getString('profile_name') ?? _name;
      _bio = prefs.getString('profile_bio') ?? _bio;
      _email = prefs.getString('profile_email') ?? '';
      _phone = prefs.getString('profile_phone') ?? '';
      _honorScore = prefs.getInt('honor_score') ?? 0;
      _rescues = prefs.getInt('rescues_count') ?? 0;
      _badge = prefs.getString('honor_badge') ?? 'None';
      _redeemPoints = prefs.getInt('redeem_points') ?? _honorScore;
      _userId = userId;
    });

    if (userId != null) {
      _startAutoSync(userId);
      await _syncProfileFromServer(userId);
    } else {
      _autoSyncTimer?.cancel();
      _autoSyncTimer = null;
    }
  }

  void _startAutoSync(int userId) {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _syncProfileFromServer(userId),
    );
  }

  Future<void> _syncProfileFromServer(int userId) async {
    try {
      final remoteProfile = await BackendApiService.fetchUserProfile(userId: userId);
      if (!mounted || remoteProfile.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final remoteScore = (remoteProfile['score'] as num?)?.toInt() ?? 0;
      final remoteName = (remoteProfile['name'] ?? '').toString().trim();
      final remoteEmail = (remoteProfile['email'] ?? '').toString().trim();

      await prefs.setInt('honor_score', remoteScore);
      await prefs.setInt('redeem_points', remoteScore);
      if (remoteName.isNotEmpty) {
        await prefs.setString('profile_name', remoteName);
      }
      if (remoteEmail.isNotEmpty && !remoteEmail.endsWith('@phone.local')) {
        await prefs.setString('profile_email', remoteEmail);
      }

      if (!mounted) return;
      setState(() {
        if (remoteName.isNotEmpty) {
          _name = remoteName;
        }
        if (remoteEmail.isNotEmpty && !remoteEmail.endsWith('@phone.local')) {
          _email = remoteEmail;
        }
        _honorScore = remoteScore;
        _redeemPoints = remoteScore;
      });
    } catch (_) {
    }
  }

  Future<void> _loadRewards() async {
    try {
      final rewards = await BackendApiService.fetchRewards();
      if (!mounted) return;
      setState(() {
        _rewards = rewards;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rewards = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingRewards = false;
        });
      }
    }
  }

  Future<void> _loadRedemptions() async {
    try {
      final userId = _userId;
      if (userId == null) {
        setState(() {
          _redemptions = [];
        });
        return;
      }
      
      final coupons = await BackendApiService.fetchUserCoupons(userId: userId);
      if (!mounted) return;
      setState(() {
        _redemptions = coupons;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _redemptions = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingRedemptions = false;
        });
      }
    }
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: _name);
    final bioController = TextEditingController(text: _bio);
    final emailController = TextEditingController(text: _email);
    final phoneController = TextEditingController(text: _phone);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: bioController, decoration: const InputDecoration(labelText: 'Bio')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (result != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', nameController.text.trim());
    await prefs.setString('profile_bio', bioController.text.trim());
    await prefs.setString('profile_email', emailController.text.trim());
    await prefs.setString('profile_phone', phoneController.text.trim());
    await _loadProfile();
  }

  Future<void> _redeemReward(Map<String, dynamic> reward) async {
    final userId = _userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log in to redeem rewards.')),
      );
      return;
    }

    final pointsRequired = reward['points_required'] as int? ?? 0;
    if (_redeemPoints < pointsRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough points to redeem.')),
      );
      return;
    }

    try {
      await BackendApiService.redeemReward(
        rewardId: reward['id'] as int,
        userId: userId,
      );
      await _syncProfileFromServer(userId);
      await _loadRedemptions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Redemption request submitted.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Redeem failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editProfile,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, AppConstants.routeSettings);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.accent.withOpacity(0.1),
                  child: Icon(Icons.person, size: 40, color: AppColors.accent),
                ),
                const SizedBox(height: 12),
                Text(
                  _name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.primary,
                  ),
                ),
                Text(
                  _bio,
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                if (_email.isNotEmpty || _phone.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    [_email, _phone].where((value) => value.isNotEmpty).join(' • '),
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Honour Panel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('$_honorScore', 'Honour Score'),
                    _buildStatItem('$_rescues', 'Rescues'),
                    _buildStatItem(_badge, 'Badge'),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Redeemable Points: $_redeemPoints'),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _honorScore == 0 ? 0.0 : (_honorScore % 100) / 100,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(AppColors.accent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Rewards'),
          if (_loadingRewards)
            const Center(child: CircularProgressIndicator())
          else if (_rewards.isEmpty)
            GlassCard(
              child: const ListTile(
                title: Text('No rewards available right now.'),
              ),
            )
          else
            ..._rewards.map(
              (reward) => GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(reward['name']?.toString() ?? 'Reward'),
                  subtitle: Text(
                    '${reward['points_required'] ?? 0} points',
                  ),
                  trailing: TextButton(
                    onPressed: () => _redeemReward(reward),
                    child: const Text('Redeem'),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          _buildSectionTitle('My Coupons'),
          if (_loadingRedemptions)
            const Center(child: CircularProgressIndicator())
          else if (_redemptions.isEmpty)
            GlassCard(
              child: const ListTile(
                title: Text('No coupons yet. Redeem a reward!'),
              ),
            )
          else
            ..._redemptions.map(
              (coupon) {
                final rewardName = (coupon['rewardName'] ?? 'Coupon').toString();
                final status = (coupon['status'] ?? 'Active').toString().toLowerCase();
                final statusColor = status == 'active' ? Colors.green : status == 'used' ? Colors.grey : Colors.orange;
                return GlassCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(Icons.card_giftcard, color: statusColor),
                    title: Text(rewardName),
                    subtitle: Text(
                      'Status: ${coupon['status'] ?? 'Active'}',
                      style: TextStyle(color: statusColor),
                    ),
                    trailing: status == 'active'
                        ? Icon(Icons.check_circle, color: Colors.green)
                        : status == 'used'
                            ? Icon(Icons.done_all, color: Colors.grey)
                            : Icon(Icons.schedule, color: Colors.orange),
                  ),
                );
              },
            ),
          const SizedBox(height: 24),
          _buildSectionTitle('Contribution History'),
          GlassCard(
            child: ListTile(
              leading: Icon(Icons.history, color: AppColors.textSecondary),
              title: const Text('Recent activity'),
              subtitle: Text('Your verified tips and reports appear here.'),
            ),
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.textSecondary),
              title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppConstants.routeLogin,
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
