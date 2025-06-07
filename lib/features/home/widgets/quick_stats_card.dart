// lib/features/home/presentation/widgets/quick_stats_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../../app/themes/app_theme.dart';

class QuickStatsCard extends StatefulWidget {
  final int dailyProgress;
  final String? lastReadTime;
  final Function(String) onStatTap;

  const QuickStatsCard({
    super.key,
    required this.dailyProgress,
    required this.lastReadTime,
    required this.onStatTap,
  });

  @override
  State<QuickStatsCard> createState() => _QuickStatsCardState();
}

class _QuickStatsCardState extends State<QuickStatsCard> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _rotationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    // Progress animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.dailyProgress / 100,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutBack,
    ));
    
    // Rotation animation for background pattern
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    // Start animations
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: ThemeConstants.space4),
      height: 160,
      child: Row(
        children: [
          // Daily progress - Modern circular design
          Expanded(
            flex: 2,
            child: _buildCircularProgressCard(context),
          ),
          
          ThemeConstants.space3.w,
          
          // Stats column
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Favorites
                Expanded(
                  child: _buildModernStatItem(
                    context: context,
                    icon: Icons.favorite,
                    backgroundIcon: Icons.favorite_border,
                    label: 'المفضلة',
                    gradient: [
                      Color(0xFFE91E63),
                      Color(0xFFC2185B),
                    ],
                    onTap: () => widget.onStatTap('favorites'),
                  ),
                ),
                
                ThemeConstants.space3.h,
                
                // Streak with animation
                Expanded(
                  child: _buildModernStatItem(
                    context: context,
                    icon: Icons.local_fire_department,
                    backgroundIcon: Icons.whatshot_outlined,
                    label: 'أيام متتالية',
                    gradient: [
                      Color(0xFFF57C00),
                      Color(0xFFE65100),
                    ],
                    onTap: () => widget.onStatTap('achievements'),
                    isStreak: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularProgressCard(BuildContext context) {
    final isDark = context.isDarkMode;
    final gradient = [
      Color(0xFF2196F3),
      Color(0xFF1976D2),
    ];
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onStatTap('daily_progress');
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Animated background pattern
              Positioned(
                right: -40,
                top: -40,
                child: AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationController.value * 2 * math.pi,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Background icon
              Positioned(
                left: -20,
                bottom: -20,
                child: Icon(
                  Icons.trending_up,
                  size: 80,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              
              // Content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Circular progress with modern design
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer decorative ring
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      
                      // Background circle
                      Container(
                        width: 75,
                        height: 75,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                      ),
                      
                      // Animated progress
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return SizedBox(
                            width: 75,
                            height: 75,
                            child: CircularProgressIndicator(
                              value: _progressAnimation.value,
                              strokeWidth: 6,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      // Percentage text
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '%',
                              style: context.titleMedium?.copyWith(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: ThemeConstants.semiBold,
                              ),
                            ),
                          ),
                          Text(
                            '${widget.dailyProgress}',
                            style: context.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: ThemeConstants.bold,
                              fontSize: 32,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  ThemeConstants.space3.h,
                  
                  Text(
                    'إنجاز اليوم',
                    style: context.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: ThemeConstants.bold,
                      fontSize: 16,
                    ),
                  ),
                  
                  Text(
                    'استمر في التقدم',
                    style: context.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      fontWeight: ThemeConstants.medium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernStatItem({
    required BuildContext context,
    required IconData icon,
    required IconData backgroundIcon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
    bool isStreak = false,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              
              // Background icon
              Positioned(
                left: -15,
                bottom: -15,
                child: Icon(
                  backgroundIcon,
                  size: 60,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              
              // Content
              Container(
                padding: const EdgeInsets.all(ThemeConstants.space3),
                child: Row(
                  children: [
                    // Icon with modern container
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            icon,
                            color: Colors.white,
                            size: 24,
                          ),
                          if (isStreak)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.yellowAccent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.yellowAccent.withOpacity(0.5),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    ThemeConstants.space3.w,
                    
                    // Text content
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: context.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: ThemeConstants.bold,
                            ),
                          ),
                          
                          ThemeConstants.space2.h,
                          
                          // Progress bar
                          Stack(
                            children: [
                              Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Container(
                                height: 4,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.5),
                                      blurRadius: 4,
                                    ),
                                  ],
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
            ],
          ),
        ),
      ),
    );
  }
}