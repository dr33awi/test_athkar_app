// lib/features/home/presentation/widgets/category_grid.dart
// تصميم مبتكر - نمط Timeline مع تدرجات ديناميكية

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../../app/themes/app_theme.dart';
import '../../../../app/routes/app_router.dart';
import '../../../../app/di/service_locator.dart';
import '../../../../core/infrastructure/services/logging/logger_service.dart';

class CategoryGrid extends StatefulWidget {
  const CategoryGrid({super.key});

  @override
  State<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<CategoryGrid> with SingleTickerProviderStateMixin {
  late final LoggerService _logger;
  late final AnimationController _animationController;
  int _selectedIndex = -1;

  final List<CategoryItem> _categories = [
    CategoryItem(
      id: 'prayer_times',
      title: 'مواقيت الصلاة',
      subtitle: 'أوقات الصلوات الخمس',
      icon: Icons.mosque,
      backgroundIcon: Icons.access_time_filled,
      gradient: [Color(0xFF1E88E5), Color(0xFF1565C0)],
      progress: 0.85,
      stats: '5 صلوات يومياً',
      routeName: AppRouter.prayerTimes,
    ),
    CategoryItem(
      id: 'athkar',
      title: 'الأذكار',
      subtitle: 'أذكار الصباح والمساء',
      icon: Icons.auto_awesome,
      backgroundIcon: Icons.menu_book,
      gradient: [Color(0xFF00897B), Color(0xFF00695C)],
      progress: 0.65,
      stats: '132 ذكر متنوع',
      routeName: AppRouter.athkar,
    ),
    CategoryItem(
      id: 'quran',
      title: 'القرآن الكريم',
      subtitle: 'تلاوة وحفظ وتدبر',
      icon: Icons.book,
      backgroundIcon: Icons.import_contacts,
      gradient: [Color(0xFF5E35B1), Color(0xFF4527A0)],
      progress: 0.45,
      stats: '114 سورة',
      routeName: '/quran',
    ),
    CategoryItem(
      id: 'qibla',
      title: 'اتجاه القبلة',
      subtitle: 'البوصلة الذكية',
      icon: Icons.navigation,
      backgroundIcon: Icons.explore,
      gradient: [Color(0xFFE53935), Color(0xFFD32F2F)],
      progress: 1.0,
      stats: 'دقة 100%',
      routeName: AppRouter.qibla,
    ),
    CategoryItem(
      id: 'tasbih',
      title: 'المسبحة الرقمية',
      subtitle: 'عداد التسبيح الذكي',
      icon: Icons.radio_button_checked,
      backgroundIcon: Icons.fingerprint,
      gradient: [Color(0xFFFB8C00), Color(0xFFEF6C00)],
      progress: 0.33,
      stats: '1000+ تسبيحة',
      routeName: '/tasbih',
    ),
    CategoryItem(
      id: 'dua',
      title: 'الأدعية',
      subtitle: 'أدعية من القرآن والسنة',
      icon: Icons.pan_tool,
      backgroundIcon: Icons.favorite,
      gradient: [Color(0xFF00ACC1), Color(0xFF00838F)],
      progress: 0.78,
      stats: '200+ دعاء',
      routeName: '/dua',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _logger = context.getService<LoggerService>();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onCategoryTap(CategoryItem category, int index) {
    HapticFeedback.lightImpact();
    
    setState(() {
      _selectedIndex = index;
    });
    
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        _selectedIndex = -1;
      });
    });
    
    _logger.logEvent('category_tapped', parameters: {
      'category_id': category.id,
      'category_title': category.title,
    });
    
    if (category.routeName != null) {
      Navigator.pushNamed(context, category.routeName!).catchError((error) {
        if (mounted) {
          context.showWarningSnackBar('هذه الميزة قيد التطوير');
        }
        return null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: ThemeConstants.space4),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= _categories.length) return null;
            
            return Padding(
              padding: EdgeInsets.only(bottom: ThemeConstants.space3),
              child: _buildCategoryItem(
                context,
                _categories[index],
                index,
              ),
            );
          },
          childCount: _categories.length,
        ),
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, CategoryItem category, int index) {
    final isDark = context.isDarkMode;
    final isSelected = _selectedIndex == index;
    
    return AnimatedScale(
      scale: isSelected ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: Container(
        height: 120,
        child: Stack(
          children: [
            // الخلفية المتدرجة
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    category.gradient[0].withOpacity(isDark ? 0.25 : 0.15),
                    category.gradient[1].withOpacity(isDark ? 0.15 : 0.08),
                  ],
                ),
              ),
            ),
            
            // النمط الدائري المتحرك
            Positioned(
              right: -40,
              top: -40,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _animationController.value * 2 * math.pi,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: category.gradient[0].withOpacity(0.1),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // أيقونة الخلفية
            Positioned(
              left: -30,
              bottom: -30,
              child: Icon(
                category.backgroundIcon,
                size: 100,
                color: category.gradient[1].withOpacity(0.05),
              ),
            ),
            
            // المحتوى
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: () => _onCategoryTap(category, index),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(ThemeConstants.space4),
                  child: Row(
                    children: [
                      // الأيقونة الرئيسية
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: category.gradient,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: category.gradient[0].withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              category.icon,
                              color: Colors.white,
                              size: 32,
                            ),
                            // مؤشر التقدم الدائري
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                value: category.progress,
                                strokeWidth: 2,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      ThemeConstants.space4.w,
                      
                      // المعلومات
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    category.title,
                                    style: context.titleMedium?.copyWith(
                                      fontWeight: ThemeConstants.bold,
                                      color: isDark ? Colors.white : category.gradient[0],
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: ThemeConstants.space2,
                                    vertical: ThemeConstants.space1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: category.gradient[0].withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${(category.progress * 100).toInt()}%',
                                    style: context.labelSmall?.copyWith(
                                      color: category.gradient[0],
                                      fontWeight: ThemeConstants.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            ThemeConstants.space1.h,
                            
                            Text(
                              category.subtitle,
                              style: context.bodySmall?.copyWith(
                                color: (isDark ? Colors.white : category.gradient[0])
                                    .withOpacity(0.7),
                              ),
                            ),
                            
                            ThemeConstants.space2.h,
                            
                            // Timeline Progress Bar
                            Stack(
                              children: [
                                Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: context.dividerColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: category.progress,
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: category.gradient,
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: category.gradient[0].withOpacity(0.5),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            ThemeConstants.space2.h,
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  category.stats,
                                  style: context.labelSmall?.copyWith(
                                    color: category.gradient[0],
                                    fontWeight: ThemeConstants.medium,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: category.gradient[0].withOpacity(0.5),
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
          ],
        ),
      ),
    );
  }
}

class CategoryItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final IconData backgroundIcon;
  final List<Color> gradient;
  final double progress;
  final String stats;
  final String? routeName;

  const CategoryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundIcon,
    required this.gradient,
    required this.progress,
    required this.stats,
    this.routeName,
  });
}