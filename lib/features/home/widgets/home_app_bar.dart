// lib/features/home/presentation/widgets/home_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/themes/app_theme.dart';

class HomeAppBar extends StatelessWidget {
  final String userName;
  final String greeting;
  final VoidCallback onNotificationTap;
  final VoidCallback onSettingsTap;

  const HomeAppBar({
    super.key,
    required this.userName,
    required this.greeting,
    required this.onNotificationTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        title: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.primaryColor,
                context.primaryColor.darken(0.1),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ThemeConstants.space4,
                    vertical: ThemeConstants.space3,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Greeting section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              greeting,
                              style: context.titleMedium?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            if (userName.isNotEmpty) ...[
                              ThemeConstants.space1.h,
                              Text(
                                userName,
                                style: context.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: ThemeConstants.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Action buttons
                      Row(
                        children: [
                          _buildActionButton(
                            icon: Icons.notifications_outlined,
                            onTap: onNotificationTap,
                            tooltip: 'الإشعارات',
                          ),
                          ThemeConstants.space2.w,
                          _buildActionButton(
                            icon: Icons.settings_outlined,
                            onTap: onSettingsTap,
                            tooltip: 'الإعدادات',
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
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(ThemeConstants.radiusFull),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(ThemeConstants.radiusFull),
        child: Container(
          padding: const EdgeInsets.all(ThemeConstants.space2),
          child: Icon(
            icon,
            color: Colors.white,
            size: ThemeConstants.iconMd,
          ),
        ),
      ).withTooltip(tooltip),
    );
  }
}

extension TooltipExtension on Widget {
  Widget withTooltip(String message) {
    return Tooltip(
      message: message,
      child: this,
    );
  }
}