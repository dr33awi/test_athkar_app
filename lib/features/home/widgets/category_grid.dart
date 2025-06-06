// lib/features/home/presentation/widgets/category_grid.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/themes/app_theme.dart';
import '../../../../app/routes/app_router.dart';
import '../../../../app/di/service_locator.dart';
import '../../../../core/infrastructure/services/logging/logger_service.dart';

class CategoryGrid extends StatefulWidget {
  const CategoryGrid({super.key});

  @override
  State<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<CategoryGrid> 
    with SingleTickerProviderStateMixin {
  late final LoggerService _logger;
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  
  int? _pressedIndex;

  final List<CategoryItem> _categories = const [
    CategoryItem(
      id: 'prayer_times',
      title: 'مواقيت الصلاة',
      icon: Icons.access_time,
      primaryColor: Color(0xFF00BCD4),
      gradientColors: [Color(0xFF00BCD4), Color(0xFF80DEEA)],
      routeName: AppRouter.prayerTimes,
    ),
    CategoryItem(
      id: 'athkar',
      title: 'الأذكار',
      icon: Icons.menu_book_rounded,
      primaryColor: Color(0xFF2E7D32),
      gradientColors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
      routeName: AppRouter.athkar,
    ),
    CategoryItem(
      id: 'quran',
      title: 'القرآن',
      icon: Icons.auto_stories,
      primaryColor: Color(0xFF00695C),
      gradientColors: [Color(0xFF00695C), Color(0xFF4DB6AC)],
      routeName: '/quran',
    ),
    CategoryItem(
      id: 'qibla',
      title: 'القبلة',
      icon: Icons.explore,
      primaryColor: Color(0xFF0277BD),
      gradientColors: [Color(0xFF0277BD), Color(0xFF4FC3F7)],
      routeName: AppRouter.qibla,
    ),
    CategoryItem(
      id: 'tasbih',
      title: 'التسبيح',
      icon: Icons.touch_app,
      primaryColor: Color(0xFF6A1B9A),
      gradientColors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
      routeName: '/tasbih',
    ),
    CategoryItem(
      id: 'dua',
      title: 'الدعاء',
      icon: Icons.record_voice_over,
      primaryColor: Color(0xFFD84315),
      gradientColors: [Color(0xFFD84315), Color(0xFFFF7043)],
      routeName: '/dua',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _logger = context.getService<LoggerService>();
    
    _animationController = AnimationController(
      duration: ThemeConstants.durationFast,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: ThemeConstants.curveDefault,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onCategoryTap(CategoryItem category, int index) {
    HapticFeedback.lightImpact();
    
    setState(() => _pressedIndex = index);
    _animationController.forward().then((_) {
      _animationController.reverse();
      if (mounted) {
        setState(() => _pressedIndex = null);
      }
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
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: ThemeConstants.space3,
          mainAxisSpacing: ThemeConstants.space3,
          childAspectRatio: 1.0,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => AnimationConfiguration.staggeredGrid(
            position: index,
            duration: ThemeConstants.durationSlow,
            columnCount: 3,
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildCategoryItem(
                  context,
                  _categories[index],
                  index,
                ),
              ),
            ),
          ),
          childCount: _categories.length,
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    CategoryItem category,
    int index,
  ) {
    final isPressed = _pressedIndex == index;
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isPressed ? _scaleAnimation.value : 1.0,
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
        child: InkWell(
          onTap: () => _onCategoryTap(category, index),
          borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: category.gradientColors,
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: category.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background decoration
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(
                    category.icon,
                    size: 80,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                
                // Content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon container
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          category.icon,
                          color: Colors.white,
                          size: ThemeConstants.iconMd,
                        ),
                      ),
                      
                      ThemeConstants.space2.h,
                      
                      // Title
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ThemeConstants.space2,
                          vertical: ThemeConstants.space1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(
                            ThemeConstants.radiusFull,
                          ),
                        ),
                        child: Text(
                          category.title,
                          style: context.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: ThemeConstants.semiBold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
}

class CategoryItem {
  final String id;
  final String title;
  final IconData icon;
  final Color primaryColor;
  final List<Color> gradientColors;
  final String? routeName;

  const CategoryItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.primaryColor,
    required this.gradientColors,
    this.routeName,
  });
}