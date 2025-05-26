// lib/features/athkar/presentation/widgets/athkar_section.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../app/routes/app_router.dart';

import '../../data/datasources/athkar_service.dart';

class AthkarSection extends StatefulWidget {
  const AthkarSection({Key? key}) : super(key: key);

  @override
  State<AthkarSection> createState() => _AthkarSectionState();
}

class _AthkarSectionState extends State<AthkarSection> {
  final AthkarService _athkarService = AthkarService();
  
  // للتحكم في حالة التحميل
  bool _isLoading = true;
  List<dynamic> _featuredCategories = [];
  
  @override
  void initState() {
    super.initState();
    _loadFeaturedCategories();
  }
  
  // تحميل فئات الأذكار المميزة
  Future<void> _loadFeaturedCategories() async {
    try {
      final allCategories = await _athkarService.loadAllAthkarCategories();
      
      // حدد الفئات التي تريد عرضها في الشاشة الرئيسية
      final List<dynamic> featured = [];
      
      // إذا كانت الفئات متاحة، اختر المناسبة منها
      if (allCategories.isNotEmpty) {
        for (var category in allCategories) {
          if (['morning', 'evening', 'sleep', 'wake', 'prayer'].contains(category.id)) {
            featured.add(category);
            if (featured.length >= 3) break; // اكتفي بثلاثة فئات
          }
        }
        
        // إذا لم نجد الفئات المطلوبة، استخدم أي فئات متاحة
        if (featured.isEmpty && allCategories.length > 0) {
          featured.addAll(allCategories.take(3));
        }
      }
      
      if (mounted) {
        setState(() {
          _featuredCategories = featured;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading featured categories: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان القسم مع زر عرض المزيد
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الأذكار',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.athkarCategories);
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('عرض الكل'),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 14),
                    ],
                  ),
                ),
              ],
            ),
            
            const Divider(),
            
            // محتوى القسم
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _featuredCategories.isEmpty
                    ? _buildEmptyState()
                    : _buildFeaturedCategories(),
          ],
        ),
      ),
    );
  }
  
  // بناء حالة عدم وجود فئات
  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text(
          'لا توجد أذكار متاحة حالياً',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
  
  // بناء قائمة الفئات المميزة
  Widget _buildFeaturedCategories() {
    return Column(
      children: _featuredCategories.map((category) {
        return _buildCategoryItem(category);
      }).toList(),
    );
  }
  
  // بناء عنصر فئة واحد
  Widget _buildCategoryItem(dynamic category) {
    final Color categoryColor = _getCategoryColor(category.id);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: () {
            // الانتقال إلى صفحة تفاصيل الفئة
            Navigator.pushNamed(
              context,
              AppRouter.athkarDetails,
              arguments: {
                'category': category,
              },
            );
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // أيقونة الفئة
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      _getIconFromString(category.icon),
                      color: categoryColor,
                      size: 24,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // تفاصيل الفئة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (category.description != null && category.description.isNotEmpty)
                        Text(
                          category.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                
                // سهم الانتقال
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // الحصول على لون للفئة
  Color _getCategoryColor(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return const Color(0xFFFFD54F); // أصفر للصباح
      case 'evening':
        return const Color(0xFFAB47BC); // بنفسجي للمساء
      case 'sleep':
        return const Color(0xFF5C6BC0); // أزرق للنوم
      case 'wake':
        return const Color(0xFFFFB74D); // برتقالي للاستيقاظ
      case 'prayer':
        return const Color(0xFF4DB6AC); // أخضر مزرق للصلاة
      case 'home':
        return const Color(0xFF66BB6A); // أخضر للمنزل
      case 'food':
        return const Color(0xFFE57373); // أحمر للطعام
      case 'quran':
        return const Color(0xFF9575CD); // بنفسجي فاتح للقرآن
      default:
        return Colors.teal; // لون افتراضي
    }
  }
  
  // تحويل نص الأيقونة إلى IconData
  IconData _getIconFromString(String iconString) {
    // تعيين نصوص الأيقونة إلى كائنات IconData
    Map<String, IconData> iconMap = {
      'Icons.wb_sunny': Icons.wb_sunny,
      'Icons.nightlight_round': Icons.nightlight_round,
      'Icons.bedtime': Icons.bedtime,
      'Icons.alarm': Icons.alarm,
      'Icons.mosque': Icons.mosque,
      'Icons.home': Icons.home,
      'Icons.restaurant': Icons.restaurant,
      'Icons.menu_book': Icons.menu_book,
      'Icons.favorite': Icons.favorite,
      'Icons.star': Icons.star,
      'Icons.water_drop': Icons.water_drop,
      'Icons.insights': Icons.insights,
      'Icons.travel_explore': Icons.travel_explore,
      'Icons.healing': Icons.healing,
      'Icons.family_restroom': Icons.family_restroom,
      'Icons.school': Icons.school,
      'Icons.work': Icons.work,
      'Icons.emoji_events': Icons.emoji_events,
      'Icons.auto_awesome': Icons.auto_awesome,
      'Icons.label_important': Icons.label_important,
    };
    
    return iconMap[iconString] ?? Icons.label_important;
  }
}