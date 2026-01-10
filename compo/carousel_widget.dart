import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../models/carousel_model.dart';
import '../../../services/firebase_service.dart';
import '../../../widgets/common/loading_widget.dart';
import '../../../widgets/common/error_widget.dart';
import '../../../config/app_colors.dart';
import '../../../main.dart' show languageProvider;

class CarouselWidget extends StatefulWidget {
  const CarouselWidget({Key? key}) : super(key: key);

  @override
  State<CarouselWidget> createState() => _CarouselWidgetState();
}

class _CarouselWidgetState extends State<CarouselWidget> {
  final FirebaseService _firebaseService = FirebaseService();
  int _current = 0;

  @override
  void initState() {
    super.initState();
    languageProvider.addListener(_onLanguageChange);
  }

  void _onLanguageChange() {
    setState(() {});
  }

  @override
  void dispose() {
    languageProvider.removeListener(_onLanguageChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CarouselModel>>(
      stream: _firebaseService.getCarouselItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingWidget(
            isLoading: true,
            child: Container(
              height: 220,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return CustomErrorWidget(
            errorMessage: 'Failed to load carousel items',
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            height: 220,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.silverLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text('No carousel items available'),
            ),
          );
        }

        final carouselItems = snapshot.data!;

        return Column(
          children: [
            CarouselSlider(
              items: carouselItems.map((item) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: NetworkImage(item.imageUrl),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AppColors.primaryDark.withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getDisplayTitle(item, languageProvider.languageCode),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textOnPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getDisplayDescription(item, languageProvider.languageCode),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textOnPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
              options: CarouselOptions(
                autoPlay: true,
                enlargeCenterPage: true,
                aspectRatio: 2.0,
                viewportFraction: 0.9,
                onPageChanged: (index, reason) {
                  setState(() {
                    _current = index;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: carouselItems.asMap().entries.map((entry) {
                return GestureDetector(
                  onTap: () => _current != entry.key ? setState(() => _current = entry.key) : {},
                  child: Container(
                    width: 10.0,
                    height: 10.0,
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textOnPrimary
                              : AppColors.primary)
                          .withOpacity(_current == entry.key ? 0.9 : 0.4),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
  
  String _getDisplayTitle(CarouselModel item, String languageCode) {
    if (languageCode == 'ml' && item.titleMalayalam.isNotEmpty) {
      return item.titleMalayalam;
    }
    return item.title;
  }
  
  String _getDisplayDescription(CarouselModel item, String languageCode) {
    if (languageCode == 'ml' && item.descriptionMalayalam.isNotEmpty) {
      return item.descriptionMalayalam;
    }
    return item.description;
  }
}