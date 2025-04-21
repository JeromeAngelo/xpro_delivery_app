import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/widgets/list_tiles.dart';

class ViewCollections extends StatelessWidget {
  const ViewCollections({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonListTiles(
      onTap: () => context.push('/collection-screen'),  // Update this line
      leading: Icon(Icons.receipt_long_outlined,
          color: Theme.of(context).colorScheme.primary),
      title: "Collections",
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

