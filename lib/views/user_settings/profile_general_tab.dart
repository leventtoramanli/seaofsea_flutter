import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/utils/theme_provider.dart';
import 'package:seaofsea/widgets/custom_form_field.dart';
import 'package:seaofsea/widgets/custom_image_picker.dart';

class ProfileGeneralTab extends StatefulWidget {
  const ProfileGeneralTab({super.key});

  @override
  State<ProfileGeneralTab> createState() => _ProfileGeneralTabState();
}

class _ProfileGeneralTabState extends State<ProfileGeneralTab> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _pobController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _msController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  Map<String, dynamic> infoData = {};
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final apiManager = Provider.of<ApiManager>(context, listen: false);
    final response = await apiManager.get(context, 'get_user_info');
    if (response['success'] == true) {
      if (mounted) {
        setState(() {
          infoData = response['data'] ?? {};
          _nameController.text = infoData['name'] ?? '';
          _surnameController.text = infoData['surname'] ?? '';
          _emailController.text = infoData['email'] ?? '';
          _msController.text = infoData['maritalStatus'] ?? '';
          _genderController.text = infoData['gender'] ?? '';
          _dobController.text = infoData['dob'] ?? '';
          _pobController.text = infoData['pob'] ?? '';
          _bioController.text = infoData['bio'] ?? '';
        });
      }
    }
  }

  Future<void> updateUserData() async {
    setState(() => isUpdating = true);
    final apiManager = Provider.of<ApiManager>(context, listen: false);
    final response = await apiManager.post(context, 'update_user', {
      'user_id': infoData['id'],
      'name': _nameController.text,
      'surname': _surnameController.text,
      'email': _emailController.text,
      'dob': _dobController.text,
      'pob': _pobController.text,
      'gender': _genderController.text,
      'maritalStatus': _msController.text,
      'bio': _bioController.text,
    });
    debugPrint('User all data: $response');
    setState(() => isUpdating = false);
    if (response['success'] == true) {
      await fetchUserData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
      }
    }
  }

  void _onImagePicked(File? file, String? base64, String type) async {
    final apiManager = Provider.of<ApiManager>(context, listen: false);
    final userId = infoData['id'];
    if (file != null && userId != null) {
      await apiManager.uploadImage(
        context,
        endpoint: 'upload_image',
        file: file,
        meta: {'type': type, 'user_id': userId.toString()},
      );
      await fetchUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiManager = Provider.of<ApiManager>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context);

    final String coverImageUrl = infoData['cover_image'] != null
        ? "${apiManager.baseUrl}/images/user/covers/${infoData['cover_image']}"
        : "assets/cover.jpg";

    final String userImageUrl = infoData['user_image'] != null
        ? "${apiManager.baseUrl}/images/user/user/${infoData['user_image']}"
        : "assets/sailorHat.png";

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: CustomImagePicker(
                      aspectRatio: 19 / 3,
                      existingImageUrl: coverImageUrl,
                      meta: const {'type': 'cover'},
                      onImagePicked: (file, base64) =>
                          _onImagePicked(file, base64, 'cover'),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha((0.8 * 255).round()),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Transform.translate(
            offset: const Offset(10, -50),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.black,
                  child: CustomImagePicker(
                    aspectRatio: 1,
                    existingImageUrl: userImageUrl,
                    meta: const {'type': 'user'},
                    onImagePicked: (file, base64) =>
                        _onImagePicked(file, base64, 'user'),
                    iwidth: 100,
                    iheight: 100,
                    iradius: 50,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.2 * 255).round()),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withAlpha((0.2 * 255).round()),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomFormField(
                        controller: _nameController,
                        themeProvider: themeProvider,
                        label: "Full Name",
                        hint: "Enter your full name",
                        icon: const Icon(Icons.person),
                        validationMessage: "Name is required",
                      ),
                      const SizedBox(height: 10),
                      CustomFormField(
                        controller: _surnameController,
                        themeProvider: themeProvider,
                        label: "Surname",
                        hint: "Enter your surname",
                        icon: const Icon(Icons.person_outline),
                        validationMessage: "Surname is required",
                      ),
                      const SizedBox(height: 10),
                      CustomFormField(
                        controller: _emailController,
                        themeProvider: themeProvider,
                        label: "Email",
                        hint: "Enter your E-Mail",
                        icon: const Icon(Icons.email),
                        validationMessage: "E-Mail is required",
                        isEmail: true,
                      ),
                      const SizedBox(height: 10),
                      CustomFormField(
                        controller: _dobController,
                        themeProvider: themeProvider,
                        label: "Date of Birth",
                        hint: "Enter your date of birth",
                        icon: const Icon(Icons.cake),
                        isRequired: false,
                        isDate: true,
                      ),
                      const SizedBox(height: 10),
                      CustomFormField(
                        controller: _pobController,
                        themeProvider: themeProvider,
                        label: "Place of Birth",
                        hint: "Enter your place of birth",
                        icon: const Icon(Icons.location_on),
                        isRequired: false,
                      ),
                      const SizedBox(height: 10),
                      CustomFormField(
                        controller: _genderController,
                        themeProvider: themeProvider,
                        label: "Gender",
                        hint: "Select your gender",
                        icon: const Icon(Icons.person_2_outlined),
                        isRequired: false,
                        isSelect: true,
                        selectItems: ['Male', 'Female', 'Other'],
                      ),
                      const SizedBox(height: 10),
                      CustomFormField(
                        controller: _msController,
                        themeProvider: themeProvider,
                        label: "Marital Status",
                        hint: "Select your marital status",
                        icon: const Icon(Icons.toll_rounded),
                        isRequired: false,
                        isSelect: true,
                        selectItems: ['Single', 'Married', 'Engaged'],
                      ),
                      const SizedBox(height: 20),
                      CustomFormField(
                        controller: _bioController,
                        themeProvider: themeProvider,
                        label: "About",
                        hint: "Tell us about yourself",
                        icon: const Icon(Icons.info_outline),
                        validationMessage: "Please enter something",
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: isUpdating ? null : updateUserData,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.blueAccent,
                        ),
                        child: isUpdating
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text("Save Changes"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
