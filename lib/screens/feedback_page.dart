import 'package:flutter/material.dart';
import 'package:flutter_travel/screens/placeholder_page.dart';

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Feedback',
      subtitle: 'Share your travel experience with a simple survey later.',
      icon: Icons.feedback_outlined,
    );
  }
}
