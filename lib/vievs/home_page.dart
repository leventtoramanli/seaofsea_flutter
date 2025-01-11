import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

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
    _usersFuture = _fetchUsers();
  }

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    final apiManager = Provider.of<ApiManager>(context, listen: false);
    final response = await apiManager.request(context,
        endpoint: 'get_users_with_roles', method: 'GET');
    if (response['success']) {
      return List<Map<String, dynamic>>.from(response['data']);
    } else {
      throw Exception(response['message']);
    }
    //return apiManager.getUsersWithRoles(context);
  }

  @override
  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Users',
      body: FutureBuilder<List<Map<String, dynamic>>>(
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
              return _buildUserCard(user);
            },
          );
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(user['name'][0])),
        title: Text(user['name']),
        subtitle: Text('Role: ${user['role_name']}'),
      ),
    );
  }
}
