import 'package:flutter/material.dart';

// Custom Timeline Implementation
class CustomTimeline extends StatelessWidget {
  final List<CustomTimelineItem> items;
  final double nodePosition;
  final Color connectorColor;
  final double connectorThickness;
  final double indicatorSize;
  final ScrollPhysics? physics;
  final double spacing;

  const CustomTimeline({
    super.key,
    required this.items,
    this.nodePosition = 0.04,
    this.connectorColor = Colors.grey,
    this.connectorThickness = 2.0,
    this.indicatorSize = 15.0,
    this.physics,
    this.spacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: physics,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isLast = index == items.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline indicator and connector
              SizedBox(
                width: MediaQuery.of(context).size.width * nodePosition,
                child: Column(
                  children: [
                    // Indicator
                    Container(
                      width: indicatorSize,
                      height: indicatorSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item.indicatorColor ?? connectorColor,
                      ),
                      child: item.indicatorWidget,
                    ),
                    // Connector line
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: connectorThickness,
                          color: item.connectorColor ?? connectorColor,
                        ),
                      ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 8.0,
                    bottom: isLast ? 0 : spacing,
                  ),
                  child: item.content,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CustomTimelineItem {
  final Widget content;
  final Widget? indicatorWidget;
  final Color? indicatorColor;
  final Color? connectorColor;

  const CustomTimelineItem({
    required this.content,
    this.indicatorWidget,
    this.indicatorColor,
    this.connectorColor,
  });
}

// Dot Indicator Widget
class CustomDotIndicator extends StatelessWidget {
  final Color color;
  final double size;

  const CustomDotIndicator({
    super.key,
    required this.color,
    this.size = 15.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

// Timeline Builder similar to TimelineTileBuilder.connected
class CustomTimelineTileBuilder {
  static Widget connected({
    required int itemCount,
    required Widget Function(BuildContext, int) contentsBuilder,
    required Widget Function(BuildContext, int) indicatorBuilder,
    required Widget Function(BuildContext, int, String) connectorBuilder,
    double nodePosition = 0.04,
    ScrollPhysics? physics,
  }) {
    return Builder(
      builder: (context) {
        return ListView.builder(
          physics: physics,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            final isLast = index == itemCount - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Timeline indicator and connector
                  SizedBox(
                    width: MediaQuery.of(context).size.width * nodePosition,
                    child: Column(
                      children: [
                        // Indicator
                        indicatorBuilder(context, index),
                        // Connector line
                        if (!isLast)
                          Expanded(
                            child: connectorBuilder(context, index, 'line'),
                          ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 8.0,
                        bottom: 16.0,
                      ),
                      child: contentsBuilder(context, index),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// Decorated Line Connector
class CustomDecoratedLineConnector extends StatelessWidget {
  final BoxDecoration decoration;

  const CustomDecoratedLineConnector({
    super.key,
    required this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2.0,
      decoration: decoration,
    );
  }
}

// Solid Line Connector
class CustomSolidLineConnector extends StatelessWidget {
  final Color color;
  final double thickness;

  const CustomSolidLineConnector({
    super.key,
    required this.color,
    this.thickness = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: thickness,
      color: color,
    );
  }
}
