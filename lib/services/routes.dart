import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/main.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/views/admin_dashboard.dart';
import 'package:seaofsea/views/auth/auth_page.dart';
import 'package:seaofsea/views/companies/company_detail_page.dart';
import 'package:seaofsea/views/companies/company_setting_page.dart';
import 'package:seaofsea/views/companies/company_user_page.dart';
import 'package:seaofsea/views/companies/compny_list_page.dart';
import 'package:seaofsea/views/companies/create_new_compny.dart';
import 'package:seaofsea/views/companies/join_company_page.dart';
import 'package:seaofsea/views/companies/manage_companies.dart';
import 'package:seaofsea/views/companies/manage_company_users.dart';
import 'package:seaofsea/views/companies/update_company_page.dart';
import 'package:seaofsea/views/home_page.dart';
import 'package:seaofsea/views/public_profile_page.dart';
import 'package:seaofsea/views/user_settings/settings_page.dart';

Route<dynamic>? generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(builder: (context) => const MainPage());
    case '/login':
      return MaterialPageRoute(
          builder: (context) => const AuthPage(mode: AuthMode.login));
    case '/register':
      return MaterialPageRoute(
          builder: (context) => const AuthPage(mode: AuthMode.register));
    case '/home':
      return MaterialPageRoute(builder: (context) => const HomePage());
    case '/admin':
      return MaterialPageRoute(builder: (context) => const AdminDashboard());
    case '/settings':
      return MaterialPageRoute(
          builder: (context) => SettingsPage(arguments: settings.arguments));
    case '/public_profile_page':
      return MaterialPageRoute(
          builder: (context) => PublicProfilePage(
                userId: Provider.of<AuthProvider>(context, listen: false)
                    .userInfo?['id'],
              ));
    case '/manage_company':
      return MaterialPageRoute(builder: (context) => const ManageCompanyPage());
    case '/create_company':
      return MaterialPageRoute(builder: (context) => const CreateCompanyPage());
    case '/company_list':
      return MaterialPageRoute(builder: (context) => const CompanyListPage());
    case '/company_detail':
      return MaterialPageRoute(
        builder: (context) => CompanyShowcasePage(
          companyData: settings.arguments as Map<String, dynamic>,
        ),
      );
    case '/update_company':
      return MaterialPageRoute(
        builder: (context) => UpdateCompanyPage(
          companyData: settings.arguments as Map<String, dynamic>,
        ),
      );

    case '/manage_company_users':
      return MaterialPageRoute(
        builder: (context) => ManageCompanyUsersPage(
          companyData: settings.arguments as Map<String, dynamic>,
        ),
      );

    case '/company_settings':
      return MaterialPageRoute(
        builder: (context) => CompanySettingsPage(
          companyData: settings.arguments as Map<String, dynamic>,
        ),
      );
    case '/join_company':
      final args = settings.arguments as Map<String, dynamic>?;
      final int? companyId = args?['company_id'];
      return MaterialPageRoute(
        builder: (context) => JoinCompanyPage(companyId: companyId),
      );
    case '/company_users':
      final args = settings.arguments as Map<String, dynamic>?;
      final int? companyId = args?['company_id'];
      return MaterialPageRoute(
        builder: (context) => CompanyUsersPage(companyId: companyId ?? 0),
      );

    default:
      return MaterialPageRoute(
          builder: (context) => const Center(
                child: Text('Page not found'),
              ));
  }
}

void navigateReplacement(BuildContext context, String routeName,
    {Object? arguments}) {
  Navigator.of(context).pushReplacement(
    generateRoute(RouteSettings(name: routeName, arguments: arguments))!,
  );
}
