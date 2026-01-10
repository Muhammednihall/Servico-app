import 'package:flutter/material.dart';
import '../../models/detail_model.dart';
import '../../services/offer_service.dart';
import '../../widgets/cards/detail_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/empty_state_widget.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({Key? key}) : super(key: key);

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  final OfferService _offerService = OfferService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Special Offers'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<DetailModel>>(
        stream: _offerService.getAllOffers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(
              isLoading: true,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return CustomErrorWidget(
              errorMessage: 'Failed to load offers',
              onRetry: () => setState(() {}), // Rebuild to retry
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyStateWidget(
              title: 'No Offers',
              message: 'There are no special offers available at the moment.',
              icon: Icons.local_offer,
              onRetry: () => setState(() {}), // Rebuild to retry
            );
          }

          final offers = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DetailCard(
                  detail: offers[index],
                  onTap: () {
                    // TODO: Implement offer tap handler
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tapped on ${offers[index].name}')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}