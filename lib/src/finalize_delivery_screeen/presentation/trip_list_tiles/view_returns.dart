import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/widgets/list_tiles.dart';

class ViewReturns extends StatelessWidget {
  const ViewReturns({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonListTiles(
      onTap: () => context.push('/view-returns'),
      leading: Icon(Icons.keyboard_return_sharp,
          color: Theme.of(context).colorScheme.primary),
      title: "Return Items",
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
