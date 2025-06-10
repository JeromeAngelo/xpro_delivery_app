import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/widgets/default_drawer.dart';
import 'package:x_pro_delivery_app/src/summary_trip/presentation/screen/summary_collection_screen.dart';
import 'package:x_pro_delivery_app/src/summary_trip/presentation/screen/summary_undeliverable_screen.dart';

class SummaryTripView extends StatefulWidget {
  const SummaryTripView({super.key});

  @override
  State<SummaryTripView> createState() => _SummaryTripViewState();
}

class _SummaryTripViewState extends State<SummaryTripView>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState!.openDrawer(),
        ),
        title: const Text('Trip Summary'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  icon: Icon(Icons.receipt_long_outlined),
                  text: 'Collections',
                ),
                Tab(
                  icon: Icon(Icons.keyboard_return_sharp),
                  text: 'Returns',
                ),
                Tab(
                  icon: Icon(Icons.cancel_presentation_rounded),
                  text: 'Undelivered',
                ),
              ],
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.black,
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  width: 3,
                  color: Theme.of(context).colorScheme.primary,
                ),
                insets: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ),
      ),
      key: _scaffoldKey,
      drawer: const DefaultDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SummaryCollectionScreen(),
     //     SummaryReturnScreen(),
          SummaryUndeliverableScreen(),
        ],
      ),
    );
  }
}
