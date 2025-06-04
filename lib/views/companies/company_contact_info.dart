import 'package:flutter/material.dart';
import 'package:seaofsea/views/companies/company_helpers.dart';

class CompanyContactInfo extends StatelessWidget {
  final Widget header;
  final Widget companyTypeSection;
  final Widget contactSection;

  const CompanyContactInfo({
    super.key,
    required this.header,
    required this.companyTypeSection,
    required this.contactSection,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          companyTypeSection,
          const Divider(),
          buildSectionTitle(context, Icons.contact_phone, 'Contact Info'),
          const SizedBox(height: 8),
          contactSection,
          const SizedBox(height: 24),
          const Divider(),
        ],
      ),
    );
  }
}
