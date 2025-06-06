// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/themes/app_theme.dart';
import '../../../../app/di/service_locator.dart';
import '../../../../core/infrastructure/services/storage/storage_service.dart';
import '../../../../core/infrastructure/services/logging/logger_service.dart';
import '../../../../core/infrastructure/services/notifications/notification_manager.dart';

import 'package:athkar_app/features/home/widgets/category_grid.dart';
import 'package:athkar_app/features/home/widgets/daily_reminder_card.dart';
import 'package:athkar_app/features/home/widgets/daily_verse_card.dart';
import 'package:athkar_app/features/home/widgets/home_app_bar.dart';
import 'package:athkar_app/features/home/widgets/prayer_times_card.dart';
import 'package:athkar_app/features/home/widgets/quick_stats_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Controllers
  late final ScrollController _scrollController;
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  
  // Animations
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  
  // Services
  late final StorageService _storageService;
  late final LoggerService _logger;
  
  // State
  bool _showFab = false;
  String _userName = '';
  int _dailyProgress = 0;
  String? _lastReadTime;

  @override
  void initState() {
    super.initState();
    
    // Initialize services
    _storageService = context.getService<StorageService>();
    _logger = context.getService<LoggerService>();
    
    // Initialize controllers
    _scrollController = ScrollController();
    _fadeController = AnimationController(
      duration: ThemeConstants.durationNormal,
      vsync: this,
    );
    _slideController = AnimationController(
      duration: ThemeConstants.durationSlow,
      vsync: this,
    );
    
    // Initialize animations
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: ThemeConstants.curveDefault,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: ThemeConstants.curveSmooth,
    ));
    
    // Setup listeners
    _setupScrollListener();
    
    // Load user data
    _loadUserData();
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    
    // Log screen view
    _logger.logEvent('home_screen_viewed');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final showFab = _scrollController.offset > 200;
      if (showFab != _showFab) {
        setState(() => _showFab = showFab);
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _userName = _storageService.getString('user_name') ?? '';
        _dailyProgress = _storageService.getInt('daily_progress') ?? 0;
        _lastReadTime = _storageService.getString('last_read_time');
      });
      
      _logger.debug(
        message: 'User data loaded',
        data: {
          'userName': _userName,
          'dailyProgress': _dailyProgress,
          'lastReadTime': _lastReadTime,
        },
      );
    } catch (e) {
      _logger.error(message: 'Error loading user data', error: e);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير';
    if (hour < 18) return 'مساء الخير';
    return 'مساء الخير';
  }

  void _scrollToTop() {
    HapticFeedback.lightImpact();
    _scrollController.animateTo(
      0,
      duration: ThemeConstants.durationSlow,
      curve: ThemeConstants.curveSmooth,
    );
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    
    // إعادة تحميل البيانات
    await _loadUserData();
    
    // محاكاة تحديث البيانات
    await Future.delayed(ThemeConstants.durationVerySlow);
    
    if (mounted) {
      context.showSuccessSnackBar('تم تحديث البيانات بنجاح');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          _buildBackground(),
          
          // Main content
          RefreshIndicator(
            onRefresh: _onRefresh,
            color: context.primaryColor,
            backgroundColor: context.cardColor,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // App bar
                HomeAppBar(
                  userName: _userName,
                  greeting: _getGreeting(),
                  onNotificationTap: _handleNotificationTap,
                  onSettingsTap: _handleSettingsTap,
                ),
                
                // Main content
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: ThemeConstants.space8),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Daily verse
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: const DailyVerseCard(),
                        ),
                      ),
                      
                      ThemeConstants.space4.h,
                      
                      // Prayer times
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: const PrayerTimesCard(),
                        ),
                      ),
                      
                      ThemeConstants.space4.h,
                      
                      // Quick stats
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: QuickStatsCard(
                            dailyProgress: _dailyProgress,
                            lastReadTime: _lastReadTime,
                            onStatTap: _handleStatTap,
                          ),
                        ),
                      ),
                      
                      ThemeConstants.space6.h,
                      
                      // Section title
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ThemeConstants.space4,
                        ),
                        child: Text(
                          'الأقسام الرئيسية',
                          style: context.titleLarge?.semiBold,
                        ),
                      ),
                      
                      ThemeConstants.space3.h,
                    ]),
                  ),
                ),
                
                // Categories grid
                const CategoryGrid(),
                
                // Daily reminder
                SliverPadding(
                  padding: const EdgeInsets.only(top: ThemeConstants.space6),
                  sliver: SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: const DailyReminderCard(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      
      // Floating action button
      floatingActionButton: AnimatedSlide(
        duration: ThemeConstants.durationFast,
        offset: _showFab ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: ThemeConstants.durationFast,
          opacity: _showFab ? 1 : 0,
          child: FloatingActionButton(
            onPressed: _scrollToTop,
            child: const Icon(Icons.arrow_upward),
            tooltip: 'العودة للأعلى',
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            context.primaryColor.withOpacity(0.05),
            context.backgroundColor,
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap() async {
    HapticFeedback.lightImpact();
    _logger.logEvent('notification_icon_tapped');
    
    // التحقق من حالة الإشعارات
    final hasPermission = await NotificationManager.instance.hasPermission();
    
    if (!hasPermission && mounted) {
      // طلب الإذن
      final granted = await NotificationManager.instance.requestPermission();
      if (granted && mounted) {
        context.showSuccessSnackBar('تم تفعيل الإشعارات بنجاح');
      }
    } else if (mounted) {
      // فتح إعدادات الإشعارات
      Navigator.pushNamed(context, '/notification-settings');
    }
  }

  void _handleSettingsTap() {
    HapticFeedback.lightImpact();
    _logger.logEvent('settings_icon_tapped');
    Navigator.pushNamed(context, '/settings');
  }

  void _handleStatTap(String statType) {
    HapticFeedback.lightImpact();
    _logger.logEvent('stat_card_tapped', parameters: {'type': statType});
    
    // التنقل حسب نوع الإحصائية
    switch (statType) {
      case 'daily_progress':
        Navigator.pushNamed(context, '/progress');
        break;
      case 'favorites':
        Navigator.pushNamed(context, '/favorites');
        break;
      case 'achievements':
        Navigator.pushNamed(context, '/achievements');
        break;
    }
  }
}