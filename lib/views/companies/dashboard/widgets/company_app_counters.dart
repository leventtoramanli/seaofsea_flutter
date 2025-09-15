import 'package:flutter/material.dart';
import 'package:seaofsea/views/companies/dashboard/widgets/recruitment_counters.dart';

class CompanyAppCounters extends StatelessWidget {
  final int companyId;
  final void Function(String status)? onTapStatus; // opsiyonel, derleme için
  const CompanyAppCounters({super.key, required this.companyId, this.onTapStatus});
  @override
  Widget build(BuildContext context) => RecruitmentCounters(companyId: companyId);
}
