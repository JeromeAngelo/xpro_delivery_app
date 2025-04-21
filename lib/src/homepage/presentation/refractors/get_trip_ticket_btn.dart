import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/widgets/rounded_%20button.dart';
import 'package:x_pro_delivery_app/src/homepage/presentation/utils/enter_code.dart';
import 'package:x_pro_delivery_app/src/homepage/presentation/utils/scan_qr_code.dart';

class GetTripTicketBtn extends StatelessWidget {
  const GetTripTicketBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: RoundedButton(
        label: 'Get Trip Ticket',
        onPressed: () {},
        dropdownItems: const [
          DropdownItem(
            icon: Icons.qr_code_scanner,
            label: 'Scan QR Code',
          ),
          DropdownItem(
            icon: Icons.keyboard,
            label: 'Enter Code',
          ),
        ],
        onDropdownSelected: (DropdownItem selectedItem) {
          switch (selectedItem.label) {
            case 'Scan QR Code':
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const QRScannerView(),
                ),
              );
              break;
            case 'Enter Code':
              return showDialog(
                context: context,
                builder: (context) => const EnterCode(),
              );
          }
        },
      ),
    );
  }
}
