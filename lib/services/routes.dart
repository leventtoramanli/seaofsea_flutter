import 'package:flutter/material.dart';
import 'package:seaofsea/main.dart';
import 'package:seaofsea/pages/permission_debug_page.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/views/admin_dashboard.dart';
import 'package:seaofsea/views/auth/auth_page.dart';
import 'package:seaofsea/views/companies/announcements/company_announcements_page.dart';
import 'package:seaofsea/views/companies/company_detail_page.dart';
import 'package:seaofsea/views/companies/config/position_permissions_page.dart';
import 'package:seaofsea/views/companies/pages/company_applications_page.dart';
import 'package:seaofsea/views/companies/pages/company_job_list_page.dart';
import 'package:seaofsea/views/companies/pages/company_notifications_page.dart';
import 'package:seaofsea/views/companies/pages/company_setting_page.dart';
import 'package:seaofsea/views/companies/pages/company_user_page.dart';
import 'package:seaofsea/views/companies/pages/company_list_page.dart';
import 'package:seaofsea/views/companies/pages/create_new_company_page.dart';
import 'package:seaofsea/views/companies/pages/job_editor_page.dart';
import 'package:seaofsea/views/companies/pages/join_company_page.dart';
import 'package:seaofsea/views/companies/pages/manage_companies.dart';
import 'package:seaofsea/views/companies/pages/manage_company_users.dart';
import 'package:seaofsea/views/companies/update_company_page.dart';
import 'package:seaofsea/views/home_page.dart';
import 'package:seaofsea/views/companies/pages/job_application_page.dart';
import 'package:seaofsea/views/jobs/jobs_explore_page.dart';
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
    // routes.dart (veya onGenerateRoute içinde)
    case '/admin':
      return MaterialPageRoute(
        builder: (_) => const AdminDashboard(),
        settings: settings,
      );

    case '/settings':
      return MaterialPageRoute(
          builder: (context) => SettingsPage(arguments: settings.arguments));
    case '/public_profile_page':
      {
        final args = settings.arguments as Map<String, dynamic>?;

        // Öncelik: arguments.user_id, yoksa oturumdaki kullanıcı
        final dynamic rawId =
            args?['user_id'] ?? AuthProvider.instance.userInfo?['id'];

        // Güvenli int’e çevir (null olabilir)
        final int? userId =
            (rawId is int) ? rawId : int.tryParse(rawId?.toString() ?? '');

        return MaterialPageRoute(
          builder: (_) => PublicProfilePage(userId: userId),
        );
      }

    case '/manage_company':
      return MaterialPageRoute(builder: (context) => const ManageCompanyPage());
    case '/create_company':
      return MaterialPageRoute(builder: (context) => const CreateCompanyPage());
    case '/company_list':
      return MaterialPageRoute(builder: (context) => const CompanyListPage());
    case '/company_detail':
      {
        final args = settings.arguments;

        // 1) Map olarak geldiyse direkt kullan
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => CompanyDetailPage(
              // ← sınıf adını *gerçek* olanla eşleştir
              companyData: args,
            ),
            settings: settings,
          );
        }

        // 2) Sadece ID geldiyse (bazı yerlerde int dönebiliyor)
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => CompanyDetailPage(
              companyData: {'id': args}, // minimal data
            ),
            settings: settings,
          );
        }

        // 3) Hatalı/eksik argüman
        return MaterialPageRoute(
          builder: (_) => const _BadArgsPage(
            message: 'Missing or invalid arguments for /company_detail',
          ),
          settings: settings,
        );
      }
    case '/update_company':
      final args = (settings.arguments as Map<String, dynamic>?) ?? {};
      return MaterialPageRoute(
        builder: (_) => UpdateCompanyPage(companyData: args),
        settings: settings,
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
    case '/job_application':
      {
        final args = (settings.arguments as Map<String, dynamic>?) ?? {};
        final int? companyId = args['company_id'] as int?;
        final int? jobId = args['job_id'] as int?;
        final String? companyName = args['company_name'] as String?;
        return MaterialPageRoute(
          builder: (context) => JobApplicationPage(
            jobId: jobId!, // ← jobId ile başvuru
            companyId: companyId,
            companyName: companyName,
          ),
          settings: settings,
        );
      }

    case '/job_editor':
      {
        final args = (settings.arguments as Map<String, dynamic>?) ?? {};
        final int companyId = (args['company_id'] as int?) ?? 0;
        final int? jobId = args['job_id'] as int?;
        return MaterialPageRoute(
          builder: (_) => JobEditorPage(companyId: companyId, jobId: jobId),
          settings: settings,
        );
      }
    case '/jobs_explore':
      return MaterialPageRoute(
        builder: (_) => const JobsExplorePage(),
        settings: settings,
      );

    case '/company_users':
      final args = settings.arguments as Map<String, dynamic>?;
      final int? companyId = args?['company_id'];
      return MaterialPageRoute(
        builder: (context) => CompanyUsersPage(companyId: companyId ?? 0),
      );
    case '/perm_debug':
      return MaterialPageRoute(
        builder: (context) => const PermissionDebugPage(),
        settings: settings,
      );
    case '/company_notifications':
      return MaterialPageRoute(
        builder: (_) => const CompanyNotificationsPage(),
        settings: settings,
      );
    case '/company_announcements':
      {
        final args = (settings.arguments as Map?) ?? {};
        final companyId = (args['company_id'] as int?) ?? 0;

        return MaterialPageRoute(
          builder: (_) => CompanyAnnouncementsPage(companyId: companyId),
          settings: settings,
        );
      }

    case '/company_applications':
      {
        final args = (settings.arguments as Map?) ?? {};
        final cid = (args['company_id'] as int?) ?? 0;
        final status = args['status'] as String?;

        return MaterialPageRoute(
          builder: (_) => CompanyApplicationsPage(
            companyId: cid,
            initialStatus: status,
          ),
          settings: settings,
        );
      }

    case '/company_job_list':
      final args = (settings.arguments as Map<String, dynamic>?) ?? {};
      final cid = (args['company_id'] as int?) ?? 0;
      final status = args['status'] as String?;
      return MaterialPageRoute(
        builder: (_) =>
            CompanyJobListPage(companyId: cid, initialStatus: status),
        settings: settings,
      );
    case '/position_permissions':
      return MaterialPageRoute(
        builder: (_) => const PositionPermissionsPage(),
        settings: settings,
      );

    default:
      return MaterialPageRoute(
          builder: (context) => const Center(
                child: Text('Page not found'),
              ));
  }
}

class _BadArgsPage extends StatelessWidget {
  final String message;
  const _BadArgsPage({this.message = 'Bad or missing arguments'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navigation Error')),
      body: Center(child: Text(message)),
    );
  }
}

void navigateReplacement(BuildContext context, String routeName,
    {Object? arguments}) {
  final r = generateRoute(RouteSettings(name: routeName, arguments: arguments));
  if (r != null) Navigator.of(context).pushReplacement(r);
}
