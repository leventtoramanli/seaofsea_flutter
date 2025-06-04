import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart' as quill_delta;
import 'package:provider/provider.dart';
import 'package:seaofsea/services/date_time_service.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/views/user_settings/cv_popup_editor.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:seaofsea/widgets/test_with_social_icons.dart';

class CVPageData {
  final Map<String, dynamic> user;
  final Map<String, dynamic> cv;
  final bool isOwn;
  final List<dynamic> allCertificates;

  CVPageData(
      {required this.user,
      required this.cv,
      required this.isOwn,
      required this.allCertificates});
}

class EditCVPage extends StatefulWidget {
  const EditCVPage({super.key});

  @override
  State<EditCVPage> createState() => _EditCVPageState();
}

class _EditCVPageState extends State<EditCVPage> {
  Future<Map<String, dynamic>> loadUserData() async {
    final api = Provider.of<ApiManager>(context, listen: false);
    final response = await api.post(context, 'get_user_info', {});
    debugPrint('User all data: $response');
    return response;
  }

  Future<CVPageData> fetchCVPageData() async {
    final api = Provider.of<ApiManager>(context, listen: false);

    final user = await api.post(context, 'get_user_info', {});
    final userId = user['data']?['id'];
    if (userId == null) throw Exception('User ID missing');

    final cv = await api.post(context, 'get_user_cvs', {'user_id': userId});
    final isOwn = cv['data']?['own'] == true;

    final certResponse = await api.post(context, 'list_certificates', {});
    final allCertificates = certResponse['data'] ?? [];

    return CVPageData(
        user: user, cv: cv, isOwn: isOwn, allCertificates: allCertificates);
  }

  Widget sectionBox({
    required String title,
    required Widget child,
    Widget? trailing,
    bool isDark = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(30),
      color: isDark ? Colors.grey[850] : Color.fromARGB(255, 225, 213, 178),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SelectableText(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                  decoration: TextDecoration.underline,
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  dynamic userData;

  @override
  void initState() {
    super.initState();
    getUserInfo();
  }

  void getUserInfo() async {
    final data = await loadUserData();
    setState(() {
      userData = data;
    });
  }

  Widget extractPlainText(String jsonDelta) {
    try {
      final delta = quill_delta.Delta.fromJson(jsonDecode(jsonDelta));
      final doc = quill.Document.fromDelta(delta);
      final controller = quill.QuillController(
          document: doc,
          selection: TextSelection.collapsed(offset: 0),
          readOnly: true);
      return DefaultTextStyle(
          style: const TextStyle(color: Colors.black),
          child: quill.QuillEditor.basic(controller: controller));
    } catch (e) {
      return '' as quill.QuillEditor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: FutureBuilder<CVPageData>(
        future: fetchCVPageData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final cv = data.cv;
          final isOwn = data.isOwn;
          final allCertificates = data.allCertificates;

          String basicInfo = cv['data']?['basic_info'] ?? '';
          String professionalTitle = cv['data']?['professional_title'] ?? '';
          final contactData = cv['data'] ?? {};
          final lastUpdated = cv['data']?['updated_at'] ?? '';

          final countryId = contactData['country_name'];
          final cityId = contactData['city_name'];
          final address = contactData['address'] ?? '';
          final zipCode = contactData['zip_code'] ?? '';

          final phones =
              List<String>.from(jsonDecode(contactData['phone'] ?? '[]'));
          final emails =
              List<String>.from(jsonDecode(contactData['email'] ?? '[]'));
          final socials =
              List<String>.from(jsonDecode(contactData['social'] ?? '[]'));

          final Widget myWidgets;

          final List<Widget> contactWidgets = [];

          final referencesRaw = cv['data']?['references'];
          List<dynamic> referencesList = [];
          final birthDate = userData['data']['dob'] ?? '-';
          final placeBirth = userData['data']['pob'] ?? '-';
          final gender = userData['data']['gender'] ?? '-';
          final maritalStatus = userData['data']['maritalStatus'] ?? '-';
          myWidgets = 
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Born on:'),
                    Text(DateTimeService.formatDate(birthDate, context)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Place of Birth:'),
                    Text(placeBirth),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Gender:'),
                    Text(gender),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Marital Status:'),
                    Text(maritalStatus),
                  ],
                ),
              ],
            );
          
          if (referencesRaw is String) {
            try {
              referencesList = jsonDecode(referencesRaw);
            } catch (e) {
              debugPrint("Error decoding references: $e");
            }
          } else if (referencesRaw is List) {
            referencesList = referencesRaw;
          }

          final workExperienceRaw = cv['data']?['work_experience'];
          List<dynamic> workExperienceList = [];

          if (workExperienceRaw is String && workExperienceRaw.isNotEmpty) {
            try {
              workExperienceList = jsonDecode(workExperienceRaw);
            } catch (e) {
              debugPrint("Error decoding work experience: $e");
            }
          } else if (workExperienceRaw is List) {
            workExperienceList = workExperienceRaw;
          }

          if (address.trim().isNotEmpty) {
            contactWidgets
                .add(TextWithIcons(text: address, isColored: Colors.white));
          }

          if (cityId != null || countryId != null) {
            contactWidgets.add(
              TextWithIcons(
                  text: '${cityId ?? ''} / ${countryId ?? ''}'.trim(),
                  isColored: Colors.white),
            );
          }

          if (zipCode.trim().isNotEmpty) {
            contactWidgets.add(TextWithIcons(
                text: 'Zip/Postal Code: $zipCode', isColored: Colors.white));
          }

          for (final phone in phones) {
            contactWidgets
                .add(TextWithIcons(text: phone, isColored: Colors.white));
          }

          for (final email in emails) {
            contactWidgets
                .add(TextWithIcons(text: email, isColored: Colors.white));
          }

          for (final social in socials) {
            contactWidgets
                .add(TextWithIcons(text: social, isColored: Colors.white));
          }

          final skillsRaw = cv['data']?['skills'];
          List<dynamic> skillsList = [];

          if (skillsRaw is String) {
            try {
              skillsList = jsonDecode(skillsRaw);
            } catch (_) {
              skillsList = [];
            }
          } else if (skillsRaw is List) {
            skillsList = skillsRaw;
          }

          final languagesRaw = cv['data']?['language'];
          List<dynamic> languagesList = [];

          if (languagesRaw is String) {
            try {
              languagesList = jsonDecode(languagesRaw);
            } catch (_) {
              languagesList = [];
            }
          } else if (languagesRaw is List) {
            languagesList = languagesRaw;
          }
          final stcwRaw = cv['data']?['certificates'];
          List<dynamic> stcwCertificates = [];

          if (stcwRaw is String && stcwRaw.isNotEmpty) {
            try {
              stcwCertificates = jsonDecode(stcwRaw);
            } catch (_) {
              stcwCertificates = [];
            }
          } else if (stcwRaw is List) {
            stcwCertificates = stcwRaw;
          }

          final educationRaw = cv['data']?['education'];
          List<dynamic> educationList = [];

          if (educationRaw is String) {
            try {
              educationList = jsonDecode(educationRaw);
            } catch (_) {
              educationList = [];
            }
          } else if (educationRaw is List) {
            educationList = educationRaw;
          }

          final educationWidgets = educationList.isEmpty
              ? [
                  const Text(
                    'No education added yet.',
                    style: TextStyle(color: Colors.grey),
                  )
                ]
              : educationList.map<Widget>((edu) {
                  final school = edu['school_name'] ?? '';
                  final degree = edu['degree'] ?? '';
                  final start = edu['start_date'] ?? '';
                  final end = edu['end_date'] ?? '';
                  final desc = edu['description'] ?? '';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$school ($start - $end)',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        if (degree.isNotEmpty)
                          Text(
                            degree,
                            style: const TextStyle(color: Colors.white),
                          ),
                        if (desc.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              desc,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList();
          debugPrint("CV Veri: ${cv['data']}");

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  children: [
                    //upper part
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          //image
                          Expanded(
                            flex: 35,
                            child: Container(
                              color: Colors.grey[850],
                              padding: const EdgeInsets.all(20),
                              child: FutureBuilder<Map<String, dynamic>>(
                                future: loadUserData(),
                                builder: (context, snapshot) {
                                  final api = Provider.of<ApiManager>(context,
                                      listen: false);
                                  final imageUrl = (snapshot.hasData &&
                                          snapshot.data?['data']
                                                  ?['user_image'] !=
                                              null)
                                      ? api.showImage(
                                          'images/user/user/${snapshot.data!['data']['user_image']}',
                                          false)
                                      : null;

                                  return CircleAvatar(
                                    radius: 100,
                                    backgroundColor: Colors.grey[300],
                                    child: ClipOval(
                                      child: imageUrl != null
                                          ? Image.network(
                                              imageUrl,
                                              width: 200,
                                              height: 200,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null) {
                                                  return child;
                                                }
                                                return const Center(
                                                    child:
                                                        CircularProgressIndicator());
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return const Icon(Icons.person,
                                                    size: 200,
                                                    color: Colors.white);
                                              },
                                            )
                                          : const Icon(Icons.person,
                                              size: 200, color: Colors.white),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          //profile
                          Expanded(
                            flex: 65,
                            child: Container(
                              padding: const EdgeInsets.all(30),
                              color: Color.fromARGB(255, 225, 213, 178),
                              child: sectionBox(
                                title: 'Profile',
                                trailing: isOwn
                                    ? IconButton(
                                        icon: const Icon(Icons.edit),
                                        color: const Color.fromARGB(
                                            255, 30, 22, 11),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => CVPopupEditor(
                                              title: 'Edit Profile',
                                              type: 'basic_info',
                                              initialText: cv['data']
                                                      ['basic_info'] ??
                                                  '',
                                              onSubmit: (updatedText) async {
                                                setState(() {
                                                  basicInfo = updatedText;
                                                });
                                              },
                                            ),
                                          );
                                        },
                                      )
                                    : null,
                                child: basicInfo.isNotEmpty
                                    ? extractPlainText(basicInfo)
                                    : Text(
                                        'Not filled yet.',
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontStyle: FontStyle.italic),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    //name and title part
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          //title part
                          Expanded(
                            flex: 35,
                            child: Container(
                              color: const Color.fromARGB(255, 26, 19, 0),
                              padding: const EdgeInsets.all(28),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  professionalTitle.isNotEmpty
                                      ? Text(professionalTitle,
                                          style: TextStyle(
                                              color: Color.fromARGB(
                                                  255, 225, 213, 178),
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold))
                                      : const Text('Professional Title',
                                          style: TextStyle(
                                              color: Color.fromARGB(
                                                  255, 225, 213, 178),
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold)),
                                  if (isOwn)
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      color: Colors.white,
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => CVPopupEditor(
                                            title: 'Edit Professional Title',
                                            initialText: professionalTitle,
                                            type: 'professional_title',
                                            onSubmit: (updatedText) {
                                              setState(() {
                                                professionalTitle = updatedText;
                                              });
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                          //name
                          Expanded(
                            flex: 65,
                            child: Container(
                              color: const Color(0xFFF4B400),
                              padding: const EdgeInsets.all(20),
                              alignment: Alignment.center,
                              child: Text(
                                  '${userData['data']['name'].toString().toUpperCase()} ${userData['data']['surname'].toString().toUpperCase()}',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                            ),
                          )
                        ],
                      ),
                    ),
                    //lover part
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //left side
                          Expanded(
                            flex: 35,
                            child: Container(
                              color: Colors.grey[850],
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  myWidgets,
                                  const SizedBox(height: 20),
                                  //contact
                                  _buildSimpleSection(
                                    'Contact',
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: contactWidgets,
                                    ),
                                    true,
                                    isOwn: true, //isOwnCV,
                                    widget: true,
                                    isColored: Colors.white,
                                    onEdit: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => CVPopupEditor(
                                          title: 'Edit Contact',
                                          type: 'contact',
                                          initialCV: cv['data'],
                                          onSubmit: (value) {
                                            if (value == 'success') {
                                              setState(() {});
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  //Expertise
                                  _buildSimpleSection(
                                    'Expertise',
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: skillsList.isEmpty
                                          ? [
                                              const Text(
                                                'No expertise added yet.',
                                                style: TextStyle(
                                                    color: Colors.grey),
                                              )
                                            ]
                                          : skillsList.map<Widget>((e) {
                                              final name = e['name'] ?? '';
                                              final percentage =
                                                  (e['percentage'] ?? 0)
                                                      .toDouble();
                                              return _buildSkill(
                                                  name, percentage ?? 0);
                                            }).toList(),
                                    ),
                                    true,
                                    isOwn: isOwn,
                                    widget: true,
                                    isColored: Colors.white,
                                    onEdit: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => CVPopupEditor(
                                          title: 'Edit Skills',
                                          type: 'skills',
                                          initialCV: cv['data'],
                                          onSubmit: (value) {
                                            if (value == 'success') {
                                              setState(() {});
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  _buildSimpleSection(
                                    'Languages',
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: languagesList.isEmpty
                                          ? [
                                              const Text(
                                                'No languages added yet.',
                                                style: TextStyle(
                                                    color: Colors.grey),
                                              )
                                            ]
                                          : languagesList.map<Widget>((e) {
                                              final name = e['name'] ?? '';
                                              final percentage =
                                                  (e['percentage'] ?? 0)
                                                      .toDouble();
                                              return _buildSkill(
                                                  name, percentage ?? 0);
                                            }).toList(),
                                    ),
                                    true,
                                    isOwn: isOwn,
                                    widget: true,
                                    isColored: Colors.white,
                                    onEdit: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => CVPopupEditor(
                                          title: 'Edit Languages',
                                          type: 'language',
                                          initialCV: cv['data'],
                                          onSubmit: (value) {
                                            if (value == 'success') {
                                              setState(() {});
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  _buildSimpleSection(
                                    'Education',
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: educationWidgets,
                                    ),
                                    true,
                                    isOwn: isOwn,
                                    widget: true,
                                    isColored: Colors.white,
                                    onEdit: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => CVPopupEditor(
                                          title: 'Edit Education',
                                          type: 'education',
                                          initialCV: cv['data'],
                                          onSubmit: (value) {
                                            if (value == 'success') {
                                              setState(() {});
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          //right side
                          Expanded(
                            flex: 65,
                            child: Container(
                              color: Color.fromARGB(255, 225, 213, 178),
                              padding: const EdgeInsets.all(30),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Work Experience Section
                                  _buildSimpleSection(
                                    'Work Experience',
                                    _buildWorkExperienceSection(
                                        workExperienceList),
                                    false,
                                    isOwn: isOwn,
                                    widget: true,
                                    onEdit: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => CVPopupEditor(
                                          title: 'Edit Work Experience',
                                          type: 'work_experience',
                                          initialCV: cv['data'],
                                          onSubmit: (value) {
                                            if (value == 'success') {
                                              setState(() {});
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 24),
                                  _buildSimpleSection(
                                    'References',
                                    _buildReferenceSection(referencesList),
                                    false,
                                    isOwn: isOwn,
                                    widget: true,
                                    onEdit: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => CVPopupEditor(
                                          title: 'Edit References',
                                          type: 'references',
                                          initialCV: cv['data'],
                                          onSubmit: (value) {
                                            if (value == 'success') {
                                              setState(() {});
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  if (isOwn)
                                    _buildSimpleSection(
                                      'Passport, Health, Certificates',
                                      _buildStcwCertificatesSection(
                                          stcwCertificates, allCertificates),
                                      false,
                                      isOwn: isOwn,
                                      widget: true,
                                      onEdit: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => CVPopupEditor(
                                            title: 'Edit STCW Certificates',
                                            type: 'stcw_certificates',
                                            allCertificates: allCertificates,
                                            initialCV: cv['data'],
                                            onSubmit: (value) {
                                              if (value == 'success') {
                                                setState(() {});
                                              }
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                        'Last Update: ${DateTimeService.formatFromISO(lastUpdated, context)}',
                        style: TextStyle(color: Colors.black, fontSize: 12)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStcwCertificatesSection(
      List<dynamic> certs, List<dynamic> allCertificates) {
    if (certs.isEmpty) {
      return const Text(
        'No STCW certificates added yet.',
        style: TextStyle(color: Colors.black),
      );
    }

    // 📌 Sertifikaları gruplama
    final Map<int, List<Map<String, dynamic>>> grouped = {};
    for (var cert in certs) {
      final groupId = int.tryParse(allCertificates
              .firstWhere((c) => c['id'] == cert['id'])['group_id']
              .toString()) ??
          0;
      grouped.putIfAbsent(groupId, () => []).add(cert as Map<String, dynamic>);
    }

    // 📌 Grup isimleri
    final Map<int, String> groupNames = {
      1: 'Travel Documents',
      2: 'Medical Certificates',
      3: 'Basic Safety Trainings',
      4: 'Advanced and Specialized Trainings',
      5: 'Officer Certificates',
      6: 'Deck & Engine Ratings',
      7: 'Onboard Services',
      8: 'Medical Crew',
      9: 'Fishing Vessel Certificates',
      10: 'Offshore Safety',
      11: 'Tug Operations & Pilotage',
      12: 'Pilotage Licenses',
      13: 'Luxury Yacht Services',
    };

    final sortedGroupIds = grouped.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedGroupIds.map((groupId) {
        final groupCerts = grouped[groupId]!;

        // 📌 Her gruptaki sertifikaları sıralama
        groupCerts.sort((a, b) {
          final orderA = int.tryParse(allCertificates
                  .firstWhere((c) => c['id'] == a['id'])['sort_order']
                  .toString()) ??
              0;
          final orderB = int.tryParse(allCertificates
                  .firstWhere((c) => c['id'] == b['id'])['sort_order']
                  .toString()) ??
              0;
          return orderA.compareTo(orderB);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                groupNames[groupId] ?? 'Group $groupId',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blueGrey,
                ),
              ),
            ),
            ...groupCerts.map((cert) {
              final certInfo =
                  allCertificates.firstWhere((c) => c['id'] == cert['id']);
              final name =
                  '${certInfo['name'] ?? ''} (${certInfo['stcw_code'] ?? ''})';
              final issue = cert['isd'] ?? '-';
              final expire = cert['exd'] ?? '-';

              // 🟦 Özelleşmiş alanlar (Pasaport, Seaman’s Book, Drivers License gibi)
              final docNumber = cert['dn']; // doc number kısaca

              // 🟦 Vize bilgileri (Seaman Visa için)
              final visas = cert['visas'] as List<dynamic>?;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🟦 Sertifika adı
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),

                    // 🟦 Document number varsa göster
                    if (docNumber != null && docNumber.toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          'Number/Type: $docNumber',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),

                    // 🟦 Issue & Expiry tarihleri (Seaman Visa harici)
                    if (name != 'Seaman Visa')
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Issue: $issue Expire: $expire',
                                style: const TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ),

                    // 🟦 Seaman Visa ise alt vize listesi
                    if (name == 'Seaman Visa' && visas != null)
                      Column(
                        children: visas.map((visa) {
                          final visaName = visa['vn'] ?? '-';
                          final visaIssue = visa['isd'] ?? '-';
                          final visaExpire = visa['exd'] ?? '-';
                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Visa: $visaName',
                                    style:
                                        const TextStyle(color: Colors.black)),
                                Text('Issue: $visaIssue Expire: $visaExpire',
                                    style:
                                        const TextStyle(color: Colors.black54)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              );
            }),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildReferenceSection(List<dynamic> references) {
    if (references.isEmpty) {
      return const Text(
        'No references added yet.',
        style: TextStyle(color: Colors.black),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: references.map<Widget>((ref) {
        final title = ref['title'] ?? '';
        final name = ref['name'] ?? '';
        final company = ref['company'] ?? '';
        final contact = ref['contact'] ?? '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$title: $name',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black)),
              if (company.isNotEmpty)
                Text('Company: $company',
                    style: const TextStyle(color: Colors.black)),
              if (contact.isNotEmpty)
                Text('Contact: $contact',
                    style: const TextStyle(color: Colors.black)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWorkExperienceSection(List<dynamic> experiences) {
    if (experiences.isEmpty) {
      return const Text('No work experience added yet.',
          style: TextStyle(color: Colors.black));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: experiences.map<Widget>((exp) {
        final type = exp['type'] ?? '';
        final position =
            exp['position_name'] ?? exp['position'] ?? exp['title'] ?? '';
        final period = exp['period'] ?? '';
        final period1 = exp['period1'] ?? '';
        final company = exp['company'] ?? '';
        final shipName = exp['shipName'] ?? '';
        final flag = exp['flag'] ?? '';
        final shipType = exp['shipType'] ?? '';
        final grt = exp['grt'] ?? '';
        final kw = exp['kw'] ?? '';
        final details = exp['details'] ?? [];

        // Ortak Başlık
        final header = Text(
          '$position (${period.isNotEmpty ? period : 'N/A'} - ${period1.isNotEmpty ? period1 : 'N/A'})',
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        );

        // Gemiyse yan yana gemi özellikleri
        Widget shipDetails = Container();
        if (type == 'sea') {
          shipDetails = Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (shipName.isNotEmpty)
                  Text('Ship: $shipName',
                      style: const TextStyle(color: Colors.black)),
                if (flag.isNotEmpty)
                  Text('Flag: $flag',
                      style: const TextStyle(color: Colors.black)),
                if (shipType.isNotEmpty)
                  Text('Type: $shipType',
                      style: const TextStyle(color: Colors.black)),
                if (grt.isNotEmpty)
                  Text('GRT: $grt',
                      style: const TextStyle(color: Colors.black)),
                if (kw.isNotEmpty)
                  Text('KW: $kw', style: const TextStyle(color: Colors.black)),
              ],
            ),
          );
        }

        // Office için sadece company
        Widget officeDetails = Container();
        if (type == 'office' && company.isNotEmpty) {
          officeDetails = Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('Company: $company',
                style: const TextStyle(color: Colors.black)),
          );
        }

        // Description kısmı (details) hep altta
        Widget detailsSection = Container();
        if (details is List && details.isNotEmpty) {
          detailsSection = Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: details.map<Widget>((d) {
                return Text('• $d',
                    style: const TextStyle(color: Colors.black));
              }).toList(),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              if (type == 'sea') shipDetails,
              if (type == 'office') officeDetails,
              if (detailsSection is! Container) detailsSection,
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSkill(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value / 100,
          backgroundColor: Colors.white24,
          color: const Color(0xFFF4B400),
          minHeight: 6,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSimpleSection(
    String title,
    dynamic content,
    bool isDark, {
    bool isOwn = false,
    bool widget = false,
    Color? isColored,
    VoidCallback? onEdit,
  }) {
    debugPrint('isColored: $isColored');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SelectableText(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
                decoration: TextDecoration.underline,
              ),
            ),
            if (isOwn && onEdit != null)
              IconButton(
                icon: Icon(Icons.edit,
                    color: isDark ? Colors.white : Colors.black),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 18,
              ),
          ],
        ),
        const SizedBox(height: 8),
        widget
            ? content
            : Text(
                content,
                style: TextStyle(
                    color: isColored ?? (isDark ? Colors.white : Colors.black)),
              ),
      ],
    );
  }
}
