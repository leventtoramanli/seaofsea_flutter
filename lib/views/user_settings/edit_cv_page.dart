// lib/views/user_settings/edit_cv_page.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart' as quill_delta;
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';

import 'package:seaofsea/services/date_time_service.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/views/user_settings/cv_popup_editor.dart';
import 'package:seaofsea/widgets/online_images.dart';
import 'package:seaofsea/widgets/test_with_social_icons.dart';

class CVPageData {
  final Map<String, dynamic> user;
  final Map<String, dynamic> cv;
  final bool isOwn;
  final List<dynamic> allCertificates;

  CVPageData({
    required this.user,
    required this.cv,
    required this.isOwn,
    required this.allCertificates,
  });
}

class EditCVPage extends StatefulWidget {
  const EditCVPage({super.key});

  @override
  State<EditCVPage> createState() => _EditCVPageState();
}

class _EditCVPageState extends State<EditCVPage> {
  Future<CVPageData> fetchCVPageData() async {
    final api = Provider.of<V1ApiManager>(context, listen: false);

    // user.get_profile -> iki kat data zarfı
    final userRes =
        await api.call(module: 'user', action: 'get_profile', params: {}, context: context);
    final userData = (userRes['data']?['data'] ?? userRes['data'] ?? {})
        as Map<String, dynamic>;
    final userId = userData['id'] ?? userData['user_id'];
    if (userId == null) throw Exception('User ID missing');

    // cv.get_cv -> yine iki kat data zarfı
    final cvRes = await api.call(module: 'cv', action: 'get_cv', params: {}, context: context);
    final cvData =
        (cvRes['data']?['data'] ?? cvRes['data'] ?? {}) as Map<String, dynamic>;

    // cv.list_certificates -> iki kat data zarfı
    final certRes =
        await api.call(module: 'cv', action: 'list_certificates', params: {},context: context);
    final allCertificates =
        (certRes['data']?['data'] ?? certRes['data'] ?? []) as List<dynamic>;

    final isOwn = (cvData['own'] == true) || (cvData['user_id'] == userId);

    return CVPageData(
      user: userData,
      cv: {'data': cvData}, // mevcut kullanımını bozmamak için aynı şekil
      isOwn: isOwn,
      allCertificates: allCertificates,
    );
  }

  List<String> _parseStringList(dynamic raw) {
    try {
      if (raw == null) return [];
      if (raw is List) {
        return raw
            .map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      }
      if (raw is String) {
        if (raw.trim().isEmpty) return [];
        if (raw.trim().startsWith('[')) {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            return decoded
                .map((e) => e?.toString() ?? '')
                .where((e) => e.isNotEmpty)
                .toList();
          }
        }
        // Single value
        return [raw];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  List<dynamic> _parseDynamicList(dynamic raw) {
    try {
      if (raw == null) return [];
      if (raw is List) return raw;
      if (raw is String && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        return decoded is List ? decoded : [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Widget _extractRichText(String jsonDelta) {
    try {
      final delta = quill_delta.Delta.fromJson(jsonDecode(jsonDelta));
      final doc = quill.Document.fromDelta(delta);
      final controller = quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
      return DefaultTextStyle(
        style: const TextStyle(color: Colors.black),
        child: quill.QuillEditor.basic(controller: controller),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: FutureBuilder<CVPageData>(
        future: fetchCVPageData(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Bir şeyler ters gitti: ${snapshot.error}',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => setState(() {}), // yeniden dene
                    child: const Text('Yeniden dene'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final user = data.user;
          final cv = data.cv;
          final isOwn = data.isOwn;
          final allCertificates = data.allCertificates;

          String basicInfo = (cv['data']?['basic_info'] ?? '') as String;
          String professionalTitle =
              (cv['data']?['professional_title'] ?? '') as String;

          final contactData = (cv['data'] ?? {}) as Map<String, dynamic>;
          final lastUpdated = contactData['updated_at']?.toString() ?? '';

          final countryName = contactData['country_name'];
          final cityName = contactData['city_name'];
          final address = contactData['address']?.toString() ?? '';
          final zipCode = contactData['zip_code']?.toString() ?? '';

          final phones = _parseStringList(contactData['phone']);
          final emails = _parseStringList(contactData['email']);
          final socials = _parseStringList(contactData['social']);

          final List<Widget> contactWidgets = [];

          if (address.trim().isNotEmpty) {
            contactWidgets.add(const SizedBox(height: 4));
            contactWidgets
                .add(TextWithIcons(text: address, isColored: Colors.white));
          }

          if (cityName != null || countryName != null) {
            final loc = '${cityName ?? ''} / ${countryName ?? ''}'.trim();
            if (loc.isNotEmpty && loc != '/') {
              contactWidgets.add(
                TextWithIcons(text: loc, isColored: Colors.white),
              );
            }
          }

          if (zipCode.trim().isNotEmpty) {
            contactWidgets.add(
              TextWithIcons(
                text: 'Zip/Postal Code: $zipCode',
                isColored: Colors.white,
              ),
            );
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

          final referencesList = _parseDynamicList(contactData['references']);
          final workExperienceList =
              _parseDynamicList(contactData['work_experience']);
          final skillsList = _parseDynamicList(contactData['skills']);
          final languagesList = _parseDynamicList(contactData['language']);
          final stcwCertificates =
              _parseDynamicList(contactData['certificates']);
          final educationList = _parseDynamicList(contactData['education']);

          final birthDate = user['dob'];
          final placeBirth = user['pob']?.toString() ?? '-';
          final gender = user['gender']?.toString() ?? '-';
          final maritalStatus = user['maritalStatus']?.toString() ?? '-';

          Widget sectionBox({
            required String title,
            required Widget child,
            Widget? trailing,
            bool isDark = false,
          }) {
            return Container(
              padding: const EdgeInsets.all(30),
              color: isDark
                  ? Colors.grey[850]
                  : const Color.fromARGB(255, 225, 213, 178),
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

          final educationWidgets = educationList.isEmpty
              ? [
                  const Text(
                    'No education added yet.',
                    style: TextStyle(color: Colors.grey),
                  )
                ]
              : educationList.map<Widget>((edu) {
                  final school = edu['school_name']?.toString() ?? '';
                  final degree = edu['degree']?.toString() ?? '';
                  final start = edu['start_date']?.toString() ?? '';
                  final end = edu['end_date']?.toString() ?? '';
                  final desc = edu['description']?.toString() ?? '';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$school ($start - $end)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  children: [
                    // upper part
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // image
                          Expanded(
                            flex: 35,
                            child: Container(
                              color: Colors.grey[850],
                              padding: const EdgeInsets.all(20),
                              child: CircleAvatar(
                                radius: 100,
                                backgroundColor: Colors.grey[300],
                                child: ClipOval(
                                  child: OnlineImage(
                                    imagePath: 'user/',
                                    imageName:
                                        user['user_image']?.toString() ?? '',
                                    sizeW: 200,
                                    sizeH: 200,
                                    rounded: true,
                                    border: true,
                                    fallbackAsset:
                                        'assets/sailorHat.png',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // profile
                          Expanded(
                            flex: 65,
                            child: Container(
                              padding: const EdgeInsets.all(30),
                              color: const Color.fromARGB(255, 225, 213, 178),
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
                                                      ?['basic_info'] ??
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
                                    ? _extractRichText(basicInfo)
                                    : const Text(
                                        'Not filled yet.',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // name and title part
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          // title
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
                                      ? Text(
                                          professionalTitle,
                                          style: const TextStyle(
                                            color: Color.fromARGB(
                                                255, 225, 213, 178),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : const Text(
                                          'Professional Title',
                                          style: TextStyle(
                                            color: Color.fromARGB(
                                                255, 225, 213, 178),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
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
                          // name
                          Expanded(
                            flex: 65,
                            child: Container(
                              color: const Color(0xFFF4B400),
                              padding: const EdgeInsets.all(20),
                              alignment: Alignment.center,
                              child: Text(
                                '${(user['name'] ?? '').toString().toUpperCase()} ${(user['surname'] ?? '').toString().toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    // lower part
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // left side
                          Expanded(
                            flex: 35,
                            child: Container(
                              color: Colors.grey[850],
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // personal details
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Born on:',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          Text(
                                            DateTimeService.formatDate(
                                                birthDate, context),
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Place of Birth:',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          Text(placeBirth,
                                              style: const TextStyle(
                                                  color: Colors.white)),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Gender:',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          Text(gender,
                                              style: const TextStyle(
                                                  color: Colors.white)),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Marital Status:',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          Text(maritalStatus,
                                              style: const TextStyle(
                                                  color: Colors.white)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // contact
                                  _buildSimpleSection(
                                    'Contact',
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: contactWidgets,
                                    ),
                                    true,
                                    isOwn: true,
                                    widget: true,
                                    isColored: Colors.white,
                                    onEdit: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => CVPopupEditor(
                                          title: 'Edit Contact',
                                          type: 'contact',
                                          initialCV: cv['data']
                                              as Map<String, dynamic>?,
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

                                  // expertise
                                  _buildSimpleSection(
                                    'Expertise',
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: skillsList.isEmpty
                                          ? const [
                                              Text('No expertise added yet.',
                                                  style: TextStyle(
                                                      color: Colors.grey))
                                            ]
                                          : skillsList.map<Widget>((e) {
                                              final name =
                                                  e['name']?.toString() ?? '';
                                              final percentage =
                                                  double.tryParse(
                                                        (e['percentage'] ?? '0')
                                                            .toString(),
                                                      ) ??
                                                      0;
                                              return _buildSkill(
                                                  name, percentage);
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
                                          initialCV: cv['data']
                                              as Map<String, dynamic>?,
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

                                  // languages
                                  _buildSimpleSection(
                                    'Languages',
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: languagesList.isEmpty
                                          ? const [
                                              Text('No languages added yet.',
                                                  style: TextStyle(
                                                      color: Colors.grey))
                                            ]
                                          : languagesList.map<Widget>((e) {
                                              final name =
                                                  e['name']?.toString() ?? '';
                                              final percentage =
                                                  double.tryParse(
                                                        (e['percentage'] ?? '0')
                                                            .toString(),
                                                      ) ??
                                                      0;
                                              return _buildSkill(
                                                  name, percentage);
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
                                          initialCV: cv['data']
                                              as Map<String, dynamic>?,
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

                                  // education
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
                                          initialCV: cv['data']
                                              as Map<String, dynamic>?,
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

                          // right side
                          Expanded(
                            flex: 65,
                            child: Container(
                              color: const Color.fromARGB(255, 225, 213, 178),
                              padding: const EdgeInsets.all(30),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Work Experience
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
                                          initialCV: cv['data']
                                              as Map<String, dynamic>?,
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

                                  // References
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
                                          initialCV: cv['data']
                                              as Map<String, dynamic>?,
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

                                  // STCW (only own)
                                  if (isOwn)
                                    _buildSimpleSection(
                                      'Passport, Health, Certificates',
                                      _buildStcwCertificatesSection(
                                        stcwCertificates,
                                        allCertificates,
                                      ),
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
                                            initialCV: cv['data']
                                                as Map<String, dynamic>?,
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
                      style: const TextStyle(color: Colors.black, fontSize: 12),
                    ),
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
    
    Map<String, dynamic> _findCertInfo(List<dynamic> all, dynamic id) {
      for (final c in all) {
        final map = (c is Map) ? c : null;
        if (map == null) continue;
        if ('${map['id']}' == '$id') return Map<String, dynamic>.from(map);
      }
      return const {};
    }

    // Group by group_id
    final Map<int, List<Map<String, dynamic>>> grouped = {};
    for (var cert in certs) {
      if (cert is! Map) continue;
      final cid = cert['id'];
      final match = _findCertInfo(allCertificates, cid);
      final gid = int.tryParse((match?['group_id'] ?? '0').toString()) ?? 0;
      grouped.putIfAbsent(gid, () => []).add(Map<String, dynamic>.from(cert));
    }

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

        groupCerts.sort((a, b) {
          final infoA = _findCertInfo(allCertificates, a['id']);
          final infoB = _findCertInfo(allCertificates, b['id']);
          final orderA = int.tryParse('${infoA['sort_order'] ?? 0}') ?? 0;
          final orderB = int.tryParse('${infoB['sort_order'] ?? 0}') ?? 0;
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
              final certInfo = _findCertInfo(allCertificates, cert['id']);
              final rawName =
                  (certInfo['name'] ?? 'Unknown Certificate').toString();
              final stcwCode = (certInfo['stcw_code'] ?? '').toString();
              final displayName =
                  stcwCode.isNotEmpty ? '$rawName ($stcwCode)' : rawName;

              final issue = cert['isd']?.toString() ?? '-';
              final expire = cert['exd']?.toString() ?? '-';
              final docNumber = cert['dn']; // number/type
              final visas = cert['visas'] as List<dynamic>?;

              final isSeamanVisa = rawName == 'Seaman Visa';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    if (docNumber != null && docNumber.toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          'Number/Type: $docNumber',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    if (!isSeamanVisa)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                        child: Text(
                          'Issue: $issue   Expire: $expire',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    if (isSeamanVisa && visas != null)
                      Column(
                        children: visas.map((visa) {
                          final visaName = visa['vn']?.toString() ?? '-';
                          final visaIssue = visa['isd']?.toString() ?? '-';
                          final visaExpire = visa['exd']?.toString() ?? '-';
                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Visa: $visaName',
                                    style:
                                        const TextStyle(color: Colors.black)),
                                Text('Issue: $visaIssue   Expire: $visaExpire',
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
        final title = ref['title']?.toString() ?? '';
        final name = ref['name']?.toString() ?? '';
        final company = ref['company']?.toString() ?? '';
        final contact = ref['contact']?.toString() ?? '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$title: $name',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black),
              ),
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
      return const Text(
        'No work experience added yet.',
        style: TextStyle(color: Colors.black),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: experiences.map<Widget>((exp) {
        final type = exp['type']?.toString() ?? '';
        final position = exp['position_name']?.toString() ??
            exp['position']?.toString() ??
            exp['title']?.toString() ??
            '';
        final period = exp['period']?.toString() ?? '';
        final period1 = exp['period1']?.toString() ?? '';
        final company = exp['company']?.toString() ?? '';
        final shipName = exp['shipName']?.toString() ?? '';
        final flag = exp['flag']?.toString() ?? '';
        final shipType = exp['shipType']?.toString() ?? '';
        final grt = exp['grt']?.toString() ?? '';
        final kw = exp['kw']?.toString() ?? '';
        final details =
            (exp['details'] is List) ? exp['details'] as List : const [];

        final header = Text(
          '$position (${period.isNotEmpty ? period : 'N/A'} - ${period1.isNotEmpty ? period1 : 'N/A'})',
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        );

        Widget shipDetails = const SizedBox.shrink();
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

        Widget officeDetails = const SizedBox.shrink();
        if (type == 'office' && company.isNotEmpty) {
          officeDetails = Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('Company: $company',
                style: const TextStyle(color: Colors.black)),
          );
        }

        Widget detailsSection = const SizedBox.shrink();
        if (details.isNotEmpty) {
          detailsSection = Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: details.map<Widget>((d) {
                return Text('• ${d.toString()}',
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
              if (details.isNotEmpty) detailsSection,
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
          value: (value.clamp(0, 100)) / 100,
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
                content?.toString() ?? '',
                style: TextStyle(
                  color: isColored ?? (isDark ? Colors.white : Colors.black),
                ),
              ),
      ],
    );
  }
}
