import 'package:flutter/material.dart';
import 'package:seaofsea/main.dart';
import 'package:seaofsea/pages/permission_debug_page.dart';
import 'package:seaofsea/utils/auth_provider.dart';

// Views
import 'package:seaofsea/views/admin_dashboard.dart';
import 'package:seaofsea/views/auth/auth_page.dart';
import 'package:seaofsea/views/companies/pages/job_post_review_page.dart';
import 'package:seaofsea/views/home_page.dart';
import 'package:seaofsea/views/public_profile_page.dart';
import 'package:seaofsea/views/user_settings/settings_page.dart';

// Companies
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

// Recruitment
import 'package:seaofsea/views/companies/pages/job_application_page.dart';
import 'package:seaofsea/views/jobs/jobs_explore_page.dart';
import 'package:seaofsea/views/companies/pages/job_post_detail_page.dart'; // yeni detay sayfası

// ---------- yardımcı ----------
int? _asInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v);
  return null;
}

Route<dynamic>? generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(builder: (_) => const MainPage());

    case '/login':
      return MaterialPageRoute(
          builder: (_) => const AuthPage(mode: AuthMode.login));

    case '/register':
      return MaterialPageRoute(
          builder: (_) => const AuthPage(mode: AuthMode.register));

    case '/home':
      return MaterialPageRoute(builder: (_) => const HomePage());

    case '/admin':
      return MaterialPageRoute(
          builder: (_) => const AdminDashboard(), settings: settings);

    case '/settings':
      return MaterialPageRoute(
        builder: (_) => SettingsPage(arguments: settings.arguments),
        settings: settings,
      );

    case '/public_profile_page':
      {
        final args = settings.arguments as Map<String, dynamic>?;
        final dynamic rawId =
            args?['user_id'] ?? AuthProvider.instance.userInfo?['id'];
        final int? userId =
            (rawId is int) ? rawId : int.tryParse(rawId?.toString() ?? '');
        return MaterialPageRoute(
            builder: (_) => PublicProfilePage(userId: userId));
      }

    case '/manage_company':
      return MaterialPageRoute(builder: (_) => const ManageCompanyPage());

    case '/create_company':
      return MaterialPageRoute(builder: (_) => const CreateCompanyPage());

    case '/company_list':
      return MaterialPageRoute(builder: (_) => const CompanyListPage());

    case '/company_detail':
      {
        final args = settings.arguments;
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => CompanyDetailPage(companyData: args),
            settings: settings,
          );
        }
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => CompanyDetailPage(companyData: {'id': args}),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => const _BadArgsPage(
              message: 'Missing or invalid arguments for /company_detail'),
          settings: settings,
        );
      }

    case '/update_company':
      {
        final args = (settings.arguments as Map<String, dynamic>?) ?? {};
        return MaterialPageRoute(
          builder: (_) => UpdateCompanyPage(companyData: args),
          settings: settings,
        );
      }

    case '/manage_company_users':
      return MaterialPageRoute(
        builder: (_) => ManageCompanyUsersPage(
          companyData: settings.arguments as Map<String, dynamic>,
        ),
      );

    case '/company_settings':
      return MaterialPageRoute(
        builder: (_) => CompanySettingsPage(
          companyData: settings.arguments as Map<String, dynamic>,
        ),
      );

    case '/join_company':
      {
        final args = settings.arguments as Map<String, dynamic>?;
        final int? companyId = _asInt(args?['company_id']);
        return MaterialPageRoute(
            builder: (_) => JoinCompanyPage(companyId: companyId));
      }

    // ==== Recruitment ====

    // Başvuru formu
    // Beklenen argümanlar:
    // - company_id: int (zorunlu)
    // - job_post_id veya job_id: int (opsiyonel)
    case '/job_application':
      {
        final args = (settings.arguments as Map<String, dynamic>?) ?? {};
        final int? companyId = _asInt(args['company_id']);
        final int? jobPostId = _asInt(args['job_post_id'] ??
            args['job_id']); // her iki isim de desteklenir
        if (companyId == null) {
          return MaterialPageRoute(
            builder: (_) => const _BadArgsPage(
                message: 'company_id is required for /job_application'),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => JobApplicationPage(
            companyId: companyId,
            jobPostId: jobPostId,
          ),
          settings: settings,
        );
      }

    // İlan editörü (mevcut davranış korunur)
    case '/job_editor':
      {
        final args = (settings.arguments as Map<String, dynamic>?) ?? {};
        final int companyId = _asInt(args['company_id']) ?? 0;
        final int? jobId = _asInt(args['job_id']);
        return MaterialPageRoute(
          builder: (_) => JobEditorPage(companyId: companyId, jobId: jobId),
          settings: settings,
        );
      }

    // Yayındaki işler (public)
    case '/jobs_explore':
      return MaterialPageRoute(
          builder: (_) => const JobsExplorePage(), settings: settings);

    // Şirket kullanıcıları
    case '/company_users':
      {
        final args = settings.arguments as Map<String, dynamic>?;
        final int companyId = _asInt(args?['company_id']) ?? 0;
        return MaterialPageRoute(
            builder: (_) => CompanyUsersPage(companyId: companyId));
      }

    case '/perm_debug':
      return MaterialPageRoute(
          builder: (_) => const PermissionDebugPage(), settings: settings);

    case '/company_notifications':
      return MaterialPageRoute(
          builder: (_) => const CompanyNotificationsPage(), settings: settings);

    case '/company_announcements':
      {
        final args = (settings.arguments as Map?) ?? {};
        final int companyId = _asInt(args['company_id']) ?? 0;
        return MaterialPageRoute(
          builder: (_) => CompanyAnnouncementsPage(companyId: companyId),
          settings: settings,
        );
      }

    // Şirket başvuruları (status opsiyonel)
    case '/company_applications':
      {
        final args = (settings.arguments as Map?) ?? {};
        final int cid = _asInt(args['company_id']) ?? 0;
        final String? status = args['status'] as String?;
        return MaterialPageRoute(
          builder: (_) => CompanyApplicationsPage(
            companyId: cid,
            initialStatus: status, // sayfada destekledik (patch aşağıda)
          ),
          settings: settings,
        );
      }

    // Şirket ilan listesi (status opsiyonel)
    case '/company_job_list':
      {
        final args = (settings.arguments as Map<String, dynamic>?) ?? {};
        final int cid = _asInt(args['company_id']) ?? 0;
        final String? status = args['status'] as String?;
        return MaterialPageRoute(
          builder: (_) => CompanyJobListPage(
            companyId: cid,
            initialStatus: status, // sayfada destekledik (patch aşağıda)
          ),
          settings: settings,
        );
      }

    // İlan detay (yeni)
    // Beklenen arg: id veya post_id
    case '/job_post_detail':
      {
        final args = (settings.arguments as Map<String, dynamic>?) ?? {};
        final int? id = _asInt(args['id'] ?? args['post_id']);
        if (id == null) {
          return MaterialPageRoute(
            builder: (_) => const _BadArgsPage(
                message: 'id/post_id is required for /job_post_detail'),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => JobPostDetailPage(postId: id),
          settings: settings,
        );
      }

    case '/position_permissions':
      return MaterialPageRoute(
          builder: (_) => const PositionPermissionsPage(), settings: settings);
    // onGenerateRoute içinde:
    case '/job_review':
      final args = settings.arguments as Map?;
      final id = args?['post_id'] as int? ?? 0;
      return MaterialPageRoute(builder: (_) => JobPostReviewPage(postId: id));

    default:
      return MaterialPageRoute(
        builder: (_) => const Center(child: Text('Page not found')),
      );
  }
}

class _BadArgsPage extends StatelessWidget {
  final String message;
  const _BadArgsPage({this.message = 'Bad or missing arguments', super.key});

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
