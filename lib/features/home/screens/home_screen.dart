// lib/features/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../../../app/themes/app_theme.dart';
import '../widgets/category_grid.dart';
import '../widgets/prayer_times_card.dart';
import '../widgets/quick_stats_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            backgroundColor: context.backgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'تطبيق الأذكار',
                style: context.headlineMedium?.copyWith(
                  fontWeight: ThemeConstants.bold,
                ),
              ),
              centerTitle: true,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.pushNamed(context, '/settings'),
              ),
            ],
          ),
          
          // Welcome Message
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(ThemeConstants.space4),
              padding: const EdgeInsets.all(ThemeConstants.space4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.primaryColor.withOpacity(0.1),
                    context.primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.wb_sunny,
                    color: context.primaryColor,
                    size: ThemeConstants.iconLg,
                  ),
                  ThemeConstants.space3.w,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'صباح الخير',
                          style: context.titleLarge?.semiBold,
                        ),
                        Text(
                          'لا تنس أذكار الصباح',
                          style: context.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Prayer Times Card
          const SliverToBoxAdapter(
            child: PrayerTimesCard(),
          ),
          
          SliverToBoxAdapter(
            child: ThemeConstants.space4.h,
          ),
          
          // Quick Stats
          SliverToBoxAdapter(
            child: QuickStatsCard(
              dailyProgress: 75,
              lastReadTime: '٨:٣٠ ص',
              onStatTap: (stat) {
                context.showInfoSnackBar('تم النقر على: $stat');
              },
            ),
          ),
          
          SliverToBoxAdapter(
            child: ThemeConstants.space4.h,
          ),
          
          // Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ThemeConstants.space4,
                vertical: ThemeConstants.space2,
              ),
              child: Text(
                'الأقسام الرئيسية',
                style: context.titleLarge?.semiBold,
              ),
            ),
          ),
          
          // Category Grid
          const CategoryGrid(),
          
          // Bottom Padding
          SliverToBoxAdapter(
            child: ThemeConstants.space8.h,
          ),
        ],
      ),
    );
  }
}