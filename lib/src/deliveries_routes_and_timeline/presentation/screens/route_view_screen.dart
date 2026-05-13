import 'package:flutter/material.dart';
import '../widgets/route_widgets/route_map_widget.dart';
import '../widgets/route_widgets/search_bar_widget.dart';

class RouteViewScreen extends StatefulWidget {
  const RouteViewScreen({super.key});

  @override
  State<RouteViewScreen> createState() => _RouteViewScreenState();
}

class _RouteViewScreenState extends State<RouteViewScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const RouteMapWidget(),
          SafeArea(
            child: SearchBarWidget(
              controller: _searchController,
              onChanged: (value) {
                // TODO: implement search logic
              },
              onSearchTap: () {
                // TODO: implement search tap logic
              },
            ),
          ),
        ],
      ),
    );
  }
}
