import 'package:flutter/material.dart';

class UpdateCompanyPage extends StatelessWidget {
  final Map<String, dynamic> companyData;

  const UpdateCompanyPage({super.key, required this.companyData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Company')),
      body: const Center(child: Text('UpdateCompanyPage (to be implemented)')),
    );
  }
}