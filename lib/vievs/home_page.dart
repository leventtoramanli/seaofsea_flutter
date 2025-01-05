import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/utils/auth_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsers(); // Kullanıcı listesini yükleme
  }

  Future<List<Map<String, dynamic>>> _fetchUsers() {
    final apiManager = Provider.of<ApiManager>(context, listen: false);
    return apiManager.getUsersWithRoles(context);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userInfo = authProvider.userInfo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SeaOfSea Home'),
        actions: [
          IconButton(
            onPressed: () {
              authProvider.logout();
              Navigator.pushReplacementNamed(context, '/');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          if (userInfo != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Welcome, ${userInfo['name']}'),
            ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                final users = snapshot.data!;
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user['name'][0]), // İlk harfi göster
                      ),
                      title: Text(user['name']),
                      subtitle: Text('Role: ${user['role_name']}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
