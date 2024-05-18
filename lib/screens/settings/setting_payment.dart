import 'package:flutter/material.dart';

class Payment extends StatefulWidget {
  const Payment({super.key});

  @override
  State<Payment> createState() {
    return _PaymentState();
  }
}

class _PaymentState extends State<Payment> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        ListTile(
            title: Text("Payment Settings:", style: TextStyle(fontSize: 25))),
        ListTile(
            title: Text("You haven't given us access to your money yet",
                style: TextStyle(fontSize: 20))),
      ],
    );
  }
}
