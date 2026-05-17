import 'package:flutter/material.dart';
import 'package:flutter_travel/screens/placeholder_page.dart';

class ItineraryPage extends StatelessWidget {
  const ItineraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Itinerary',
      subtitle: 'Build and review your travel plan here in the next step.',
      icon: Icons.event_note,
    );
  }
}
