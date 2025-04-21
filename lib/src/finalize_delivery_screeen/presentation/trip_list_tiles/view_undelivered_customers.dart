import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/widgets/list_tiles.dart';

class ViewUndeliveredCustomers extends StatelessWidget {
  const ViewUndeliveredCustomers({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonListTiles(
      onTap: () => context.push('/view-uc'),
      leading: Icon(Icons.cancel_presentation_rounded,
          color: Theme.of(context).colorScheme.primary),
      title: "Undelivered Customers",
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
