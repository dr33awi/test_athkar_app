// lib/app/themes/constants/app_animations.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

/// نظام الحركات والانتقالات الموحد
/// يستخدم flutter_staggered_animations لحركات احترافية
class AppAnimations {
  AppAnimations._();

  // ===== مدد الحركات =====
  static const Duration durationInstant = Duration(milliseconds: 100);
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 400);
  static const Duration durationVerySlow = Duration(milliseconds: 600);
  static const Duration durationExtraSlow = Duration(milliseconds: 1000);
  
  // ===== منحنيات الحركة =====
  static const Curve curveDefault = Curves.easeInOut;
  static const Curve curveSharp = Curves.easeInOutCubic;
  static const Curve curveSmooth = Curves.easeInOutQuint;
  static const Curve curveBounce = Curves.elasticOut;
  static const Curve curveOvershoot = Curves.backOut;
  static const Curve curveAnticipate = Curves.backIn;
  
  // ===== انتقالات الصفحات =====
  
  /// انتقال منزلق من اليمين (للعربية)
  static Route<T> slideFromRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: durationNormal,
      reverseTransitionDuration: durationNormal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = curveDefault;
        
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
  
  /// انتقال منزلق من اليسار
  static Route<T> slideFromLeft<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: durationNormal,
      reverseTransitionDuration: durationNormal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0);
        const end = Offset.zero;
        const curve = curveDefault;
        
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
  
  /// انتقال منزلق من الأسفل
  static Route<T> slideFromBottom<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: durationNormal,
      reverseTransitionDuration: durationNormal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = curveDefault;
        
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
  
  /// انتقال تلاشي
  static Route<T> fade<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: durationSlow,
      reverseTransitionDuration: durationSlow,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
  
  /// انتقال مقياس
  static Route<T> scale<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: durationNormal,
      reverseTransitionDuration: durationNormal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: curveOvershoot,
            ),
          ),
          child: child,
        );
      },
    );
  }
  
  // ===== إعدادات الحركات المتسلسلة =====
  static const int defaultColumnDelay = 50; // تأخير بين عناصر العمود
  static const int defaultGridDelay = 100; // تأخير بين عناصر الشبكة
  
  // ===== حركات القوائم =====
  
  /// قائمة متحركة عمودية
  static Widget animatedColumn({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    int? delayMilliseconds,
  }) {
    return AnimationLimiter(
      child: Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: AnimationConfiguration.toStaggeredList(
          duration: durationNormal,
          delay: Duration(milliseconds: delayMilliseconds ?? defaultColumnDelay),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: widget,
            ),
          ),
          children: children,
        ),
      ),
    );
  }
  
  /// قائمة متحركة - ListView
  static Widget animatedListView({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return AnimationLimiter(
      child: ListView.builder(
        controller: controller,
        padding: padding,
        shrinkWrap: shrinkWrap,
        physics: physics,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: durationNormal,
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: itemBuilder(context, index),
              ),
            ),
          );
        },
      ),
    );
  }
  
  /// شبكة متحركة - GridView
  static Widget animatedGridView({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    required int crossAxisCount,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    double? mainAxisSpacing,
    double? crossAxisSpacing,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return AnimationLimiter(
      child: GridView.builder(
        controller: controller,
        padding: padding,
        shrinkWrap: shrinkWrap,
        physics: physics,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing ?? 8.0,
          crossAxisSpacing: crossAxisSpacing ?? 8.0,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: durationNormal,
            columnCount: crossAxisCount,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: itemBuilder(context, index),
              ),
            ),
          );
        },
      ),
    );
  }
  
  // ===== حركات المكونات الفردية =====
  
  /// حركة ظهور تدريجي
  static Widget fadeIn({
    required Widget child,
    Duration? duration,
    Duration? delay,
  }) {
    return FadeInAnimation(
      duration: duration ?? durationNormal,
      delay: delay ?? Duration.zero,
      child: child,
    );
  }
  
  /// حركة انزلاق من الأسفل
  static Widget slideFromBottom({
    required Widget child,
    Duration? duration,
    double offset = 50.0,
  }) {
    return SlideAnimation(
      duration: duration ?? durationNormal,
      verticalOffset: offset,
      child: child,
    );
  }
  
  /// حركة انزلاق من الجانب
  static Widget slideFromSide({
    required Widget child,
    Duration? duration,
    double offset = 50.0,
    bool fromRight = true,
  }) {
    return SlideAnimation(
      duration: duration ?? durationNormal,
      horizontalOffset: fromRight ? offset : -offset,
      child: child,
    );
  }
  
  /// حركة مقياس
  static Widget scaleIn({
    required Widget child,
    Duration? duration,
    double scale = 0.0,
  }) {
    return ScaleAnimation(
      duration: duration ?? durationNormal,
      scale: scale,
      child: child,
    );
  }
  
  /// حركة دوران
  static Widget flipIn({
    required Widget child,
    Duration? duration,
    FlipAxis axis = FlipAxis.x,
  }) {
    return FlipAnimation(
      duration: duration ?? durationSlow,
      flipAxis: axis,
      child: child,
    );
  }
  
  /// حركة مركبة - انزلاق وتلاشي ومقياس
  static Widget bounceIn({
    required Widget child,
    Duration? duration,
    Duration? delay,
  }) {
    return AnimationConfiguration.synchronized(
      duration: duration ?? durationNormal,
      delay: delay ?? Duration.zero,
      child: ScaleAnimation(
        scale: 0.5,
        child: FadeInAnimation(
          child: SlideAnimation(
            verticalOffset: 50,
            child: child,
          ),
        ),
      ),
    );
  }
  
  // ===== حركات خاصة بتطبيق الأذكار =====
  
  /// حركة ظهور بطاقة الذكر
  static Widget athkarCardAnimation({
    required Widget child,
    required int index,
    Duration? duration,
  }) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: duration ?? durationNormal,
      delay: Duration(milliseconds: index * 50),
      child: SlideAnimation(
        verticalOffset: 30,
        child: FadeInAnimation(
          child: ScaleAnimation(
            scale: 0.95,
            child: child,
          ),
        ),
      ),
    );
  }
  
  /// حركة العداد (التسبيح)
  static Widget counterAnimation({
    required Widget child,
    Duration? duration,
  }) {
    return ScaleAnimation(
      duration: duration ?? durationFast,
      scale: 0.8,
      curve: Curves.elasticOut,
      child: child,
    );
  }
  
  /// حركة بوصلة القبلة
  static Widget qiblaAnimation({
    required Widget child,
    double angle,
  }) {
    return AnimatedRotation(
      turns: angle / 360,
      duration: durationSlow,
      curve: Curves.easeInOutCubic,
      child: child,
    );
  }
  
  // ===== تكوينات PageTransitionsTheme =====
  static const PageTransitionsTheme pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  );
  
  // ===== ظلال متحركة =====
  static List<BoxShadow> animatedShadow(double elevation) {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.05 * elevation),
        blurRadius: 2.0 * elevation,
        offset: Offset(0, elevation),
      ),
    ];
  }
}