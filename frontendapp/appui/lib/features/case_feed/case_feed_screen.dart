import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/missing_person_card.dart';
import '../../models/missing_person.dart';

class CaseFeedScreen extends StatefulWidget {
  const CaseFeedScreen({super.key});

  @override
  State<CaseFeedScreen> createState() => _CaseFeedScreenState();
}

class _CaseFeedScreenState extends State<CaseFeedScreen> {
  UrgencyLevel? _filterUrgency;

  List<MissingPerson> get _filteredCases {
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'All Cases',
          style: AppTextStyles.headlineMedium,
        ),
        actions: [
          PopupMenuButton<UrgencyLevel?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterUrgency = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Cases'),
              ),
              const PopupMenuItem(
                value: UrgencyLevel.critical,
                child: Text('Critical Only'),
              ),
              const PopupMenuItem(
                value: UrgencyLevel.high,
                child: Text('High Priority'),
              ),
              const PopupMenuItem(
                value: UrgencyLevel.normal,
                child: Text('Normal'),
              ),
            ],
          ),
        ],
      ),
      body: _filteredCases.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppConstants.spacing8),
              itemCount: _filteredCases.length,
              itemBuilder: (context, index) {
                final person = _filteredCases[index];
                return MissingPersonCard(
                  person: person,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppConstants.routeCaseDetail,
                      arguments: person,
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppConstants.spacing12),
            Text(
              'No cases available',
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: AppConstants.spacing8),
            Text(
              'Cases will appear here once submitted.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
