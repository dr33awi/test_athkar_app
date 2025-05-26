// lib/app/widgets/virtues_athkar_card.dart
import 'package:athkar_app/app/themes/app_theme.dart'; // تم الاستيراد
import 'package:athkar_app/app/themes/theme_constants.dart'; // تم الاستيراد
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class VirtuesAthkarCard extends StatelessWidget {
  final Color primaryColor;

  const VirtuesAthkarCard({
    Key? key,
    required this.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // تحديد لون النص المتباين مع primaryColor (لون خلفية البطاقة)
    // نفترض أن primaryColor هو لون الخلفية الرئيسي، لذا النصوص عليه يجب أن تكون متباينة
    final Color onPrimaryColor = ThemeData.estimateBrightnessForColor(primaryColor) == Brightness.dark
        ? Colors.white // نص فاتح على خلفية داكنة
        : Colors.black; // نص داكن على خلفية فاتحة

    // لون لخلفيات العناصر الداخلية الشفافة، يعتمد على onPrimaryColor لضمان التباين
    final Color internalElementBgColor = onPrimaryColor == Colors.white 
        ? Colors.black.withOpacity(0.2) 
        : Colors.white.withOpacity(0.25);
    
    final Color internalElementBorderColor = onPrimaryColor == Colors.white
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.12);


    return AnimationConfiguration.synchronized(
      duration: const Duration(milliseconds: 400), // تعديل طفيف للمدة
      child: SlideAnimation(
        verticalOffset: 40.0, // تعديل طفيف للإزاحة
        child: FadeInAnimation(
          duration: const Duration(milliseconds: 500), // تعديل طفيف للمدة
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                ThemeSizes.marginMedium, 0, ThemeSizes.marginMedium, ThemeSizes.marginMedium),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(ThemeSizes.marginMedium),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusLarge), // استخدام ThemeSizes
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    primaryColor,
                    primaryColor.withOpacity(0.75), // تعديل طفيف للشفافية
                  ],
                  stops: const [0.2, 1.0], // تعديل طفيف لنقاط التوقف
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.25), // تعديل شفافية الظل
                    blurRadius: 12, // تعديل نصف قطر التمويه
                    offset: const Offset(0, 6), // تعديل الإزاحة
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: ThemeSizes.marginSmall), // استخدام ThemeSizes
                      padding: const EdgeInsets.symmetric(
                        horizontal: ThemeSizes.marginMedium, // استخدام ThemeSizes
                        vertical: ThemeSizes.marginXSmall,    // استخدام ThemeSizes
                      ),
                      decoration: BoxDecoration(
                        color: internalElementBgColor,
                        borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusCircular), // استخدام ThemeSizes
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'فضل الأذكار',
                        style: AppTheme.getBodyStyle(context, fontSize: 14, fontWeight: FontWeight.w600)
                            .copyWith(color: onPrimaryColor), // استخدام AppTheme وتحديد اللون
                      ),
                    ),
                  ),
                  const SizedBox(height: ThemeSizes.marginXSmall),
                  Container(
                    padding: const EdgeInsets.all(ThemeSizes.marginMedium), // استخدام ThemeSizes
                    margin: const EdgeInsets.only(bottom: ThemeSizes.marginSmall), // استخدام ThemeSizes
                    decoration: BoxDecoration(
                      color: onPrimaryColor.withOpacity(0.08), // خلفية شفافة بلون النص المتباين
                      borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium), // استخدام ThemeSizes
                      border: Border.all(
                        color: internalElementBorderColor,
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Icon(
                            Icons.format_quote_rounded, // استخدام أيقونة rounded
                            size: 18, // تعديل الحجم
                            color: onPrimaryColor.withOpacity(0.5),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: ThemeSizes.marginXSmall), // تعديل الحشوة
                          child: Text(
                            'قال رسول الله ﷺ: مثل الذي يذكر ربه والذي لا يذكر ربه مثل الحي والميت',
                            textAlign: TextAlign.center,
                            // استخدام AppTheme وتحديد اللون والخط
                            style: AppTheme.getArabicTextStyle(context, isLarge: false, fontSize: 17) 
                                .copyWith(color: onPrimaryColor, fontFamily: 'Amiri-Bold', height: 1.9),
                          ),
                        ),
                        Positioned(
                          bottom: -4,
                          left: -4,
                          child: Transform.rotate(
                            angle: 3.14159, // 180 درجة
                            child: Icon(
                              Icons.format_quote_rounded, // استخدام أيقونة rounded
                              size: 18, // تعديل الحجم
                              color: onPrimaryColor.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ThemeSizes.marginMedium, // استخدام ThemeSizes
                        vertical: ThemeSizes.marginXSmall,    // استخدام ThemeSizes
                      ),
                      decoration: BoxDecoration(
                        color: internalElementBgColor,
                        borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusCircular), // استخدام ThemeSizes
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'رواه البخاري',
                        // استخدام AppTheme وتحديد اللون
                        style: AppTheme.getCaptionStyle(context).copyWith(color: onPrimaryColor, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}