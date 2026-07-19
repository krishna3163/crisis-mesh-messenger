import 'package:flutter/material.dart';
import '../tabs/market_tab.dart';
import '../tabs/volunteer_tab.dart';
import '../tabs/election_tab.dart';

class CommunityHubScreen extends StatelessWidget {
  const CommunityHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Community Hub'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.shopping_bag), text: 'Barter Market'),
              Tab(icon: Icon(Icons.volunteer_activism), text: 'Registry'),
              Tab(icon: Icon(Icons.how_to_vote), text: 'Elections'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            MarketTab(),
            VolunteerTab(),
            ElectionTab(),
          ],
        ),
      ),
    );
  }
}
