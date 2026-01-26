import 'package:cloud_firestore/cloud_firestore.dart';

class CarouselModel {
  final String id;
  final String imageUrl;
  final int order;

  CarouselModel({
    required this.id,
    required this.imageUrl,
    required this.order,
  });

  factory CarouselModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    return CarouselModel(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      order: data['order'] is int
          ? data['order']
          : int.tryParse(data['order'].toString()) ?? 0,
    );
  }
}

class CarouselService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<CarouselModel>> streamCarousel() {
    return _firestore.collection('carousel').orderBy('order').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => CarouselModel.fromFirestore(doc))
          .toList();
    });
  }
}
