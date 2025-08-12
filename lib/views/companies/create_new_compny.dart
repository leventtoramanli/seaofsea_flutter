// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/views/companies/compny_list_page.dart';
import 'package:seaofsea/widgets/custom_image_picker.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

class CreateCompanyPage extends StatefulWidget {
  const CreateCompanyPage({super.key});

  @override
  State<CreateCompanyPage> createState() => _CreateCompanyPageState();
}

class _CreateCompanyPageState extends State<CreateCompanyPage> {
  File? _companyLogo;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _rankController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _submitCompany() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _rankController.text.trim().isEmpty) {
      setState(() => _error = 'All fields are required.');
      return;
    }

    if (!EmailValidator.validate(_emailController.text.trim())) {
      setState(() => _error = 'Email is not valid.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = Provider.of<ApiManager>(context, listen: false);

      // 1. Şirket oluştur
      final companyResponse = await api.post(context, 'create_company', {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
      });

      final success = companyResponse['success'] == true;
      final data = companyResponse['data'];
      final message = companyResponse['message'] ?? 'Company creation failed.';

      if (!success || data == null) {
        setState(() => _error = 'Error: $message');
        return;
      }

      final companyId = data['company_id']?.toString();
      debugPrint('Company created successfully. ID: $companyId');

      // 2. Kullanıcıyı şirkete admin olarak ekle
      final userCompanyResponse =
          await api.post(context, 'create_user_company', {
        'company_id': companyId,
        'rank': _rankController.text.trim(),
        'role': 'admin',
      });

      if (userCompanyResponse['success'] != true) {
        debugPrint('Error linking user to company. Deleting company...');
        await api.post(context, 'delete_company', {'company_id': companyId});
        setState(() => _error =
            userCompanyResponse['message'] ?? 'User-company linking failed.');
        return;
      }

      // 3. Logo yükle (varsa)
      if (_companyLogo != null) {
        final uploadResponse = await api.uploadImage(
          context,
          endpoint: 'upload_image_general',
          file: _companyLogo!,
          meta: {
            'type': 'company',
            'folder': 'images/companies/logo/',
            'prefix': 'c_$companyId',
            'thumb': 'true',
            'thumbSize': '128',
          },
        );

        if (uploadResponse != null && uploadResponse['success'] == true) {
          final uploadedFileName = uploadResponse['data']?['file_name'];

          if (uploadedFileName != null) {
            final Map<String, dynamic> updateData = {
              'company_id': companyId,
              'logo': uploadedFileName,
            };

            await api.post(context, 'update_company', updateData);
          } else {
            debugPrint('⚠️ Upload response does not contain file_name.');
          }
        } else {
          debugPrint('❌ Logo upload failed.');
        }
      }

      // 4. Başarılı -> Şirket listesine dön
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CompanyListPage()),
      );
    } catch (e) {
      debugPrint('Error during company creation: $e');
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double fieldEmp = 12.0;
    return CustomScaffold(
      title: 'Create Company',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLogoPicker(),
            SizedBox(height: fieldEmp),
            _buildTextField(_nameController, 'Company Name'),
            SizedBox(height: fieldEmp),
            _buildTextField(_emailController, 'Company E-Mail'),
            SizedBox(height: fieldEmp),
            _buildTextField(_rankController, 'Your Rank'),
            if (_error != null) ...[
              SizedBox(height: fieldEmp),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _submitCompany,
                    icon: const Icon(Icons.check),
                    label: const Text('Save Company'),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoPicker() {
    return Transform.translate(
      offset: const Offset(10, -50),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Column(
              children: [
                const SizedBox(height: 50),
                const Text('Company Logo'),
                const SizedBox(height: 20),
                Container(
                  width: 102,
                  height: 102,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 3,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CustomImagePicker(
                    aspectRatio: 1,
                    deleteOld: true,
                    addWatermark: true,
                    onImagePicked: (file, base64) {
                      setState(() {
                        _companyLogo = file;
                      });
                    },
                    meta: {'type': 'company'},
                    iwidth: 100,
                    iheight: 100,
                    iradius: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
