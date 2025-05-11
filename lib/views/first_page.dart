import 'package:flutter/material.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth > 900;

    return CustomScaffold(
      title: 'Dashboard',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isWideScreen
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sol Menü veya Profil
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildCard(context, Icons.people, 'Crew Module'),
                        const SizedBox(height: 16),
                        _buildCard(
                            context, Icons.medical_services, 'Hospital Module'),
                        const SizedBox(height: 16),
                        _buildCard(context, Icons.local_hotel, 'Hotel Modules'),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Orta Modül Grid
                  Expanded(
                    flex: 5,
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildModuleBox(
                            context, Icons.engineering, 'Planned Maintenance'),
                        _buildModuleBox(context, Icons.store, 'Store Module'),
                        _buildModuleBox(
                            context, Icons.badge, 'Certificate Module'),
                        _buildModuleBox(
                            context, Icons.shopping_cart, 'Purchase Module'),
                        _buildModuleBox(
                            context, Icons.forum, 'Discussion Forum'),
                        _buildModuleBox(context, Icons.article, 'Blog & Posts'),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Sağ Kısa Panel
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildCard(context, Icons.domain, 'Companies'),
                        const SizedBox(height: 16),
                        _buildCard(
                            context, Icons.directions_boat, 'Fleet Management'),
                      ],
                    ),
                  ),
                ],
              )
            : ListView(
                children: [
                  _buildCard(context, Icons.people, 'Crew Module'),
                  _buildCard(context, Icons.engineering, 'Planned Maintenance'),
                  _buildCard(context, Icons.store, 'Store Module'),
                  _buildCard(context, Icons.badge, 'Certificate Module'),
                  _buildCard(context, Icons.shopping_cart, 'Purchase Module'),
                  _buildCard(
                      context, Icons.medical_services, 'Hospital Module'),
                  _buildCard(context, Icons.local_hotel, 'Hotel Modules'),
                  _buildCard(context, Icons.domain, 'Companies'),
                  _buildCard(
                      context, Icons.directions_boat, 'Fleet Management'),
                  _buildCard(context, Icons.forum, 'Discussion Forum'),
                  _buildCard(context, Icons.article, 'Blog & Posts'),
                ],
              ),
      ),
    );
  }
}

Widget _buildModuleBox(BuildContext context, IconData icon, String title) {
  return SizedBox(
    width: 160,
    height: 140,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withAlpha(10),
        side: BorderSide(color: Colors.white.withAlpha(30)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
      ),
      onPressed: () {},
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.white),
          const SizedBox(height: 8),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white)),
        ],
      ),
    ),
  );
}

Widget _buildCard(BuildContext context, IconData icon, String title) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withAlpha(15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withAlpha(30)),
    ),
    child: Row(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(color: Colors.white)),
      ],
    ),
  );
}
