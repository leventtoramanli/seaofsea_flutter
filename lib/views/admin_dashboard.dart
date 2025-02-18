import 'package:flutter/material.dart';
import 'package:seaofsea/widgets/custom_app_bar.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(title: 'Admin Dashboard'),
      body: const Center(child: Text('Welcome, Admin!')),
    );
  }
}
