import 'dart:io';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/services/v1/v1_config.dart';
import 'package:seaofsea/widgets/v1_permission_gate.dart';
import 'package:seaofsea/utils/theme_provider.dart';
import 'package:seaofsea/views/companies/config/contact_field_definitions.dart';
import 'package:seaofsea/widgets/custom_button.dart';
import 'package:seaofsea/widgets/custom_form_field.dart';
import 'package:seaofsea/widgets/custom_image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

/// Küçük icon butonlar için ortak yapı
Widget buildIconButton(IconData icon, VoidCallback onPressed, String tooltip) {
  return IconButton(
    icon: Icon(icon, size: 20),
    onPressed: onPressed,
    tooltip: tooltip,
  );
}

/// Bölüm başlığı
Widget buildSectionTitle(BuildContext context, IconData icon, String title) {
  final cs = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withAlpha(150),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: cs.onSurfaceVariant),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: cs.onSurface,
              ),
        ),
      ],
    ),
  );
}

/// Contact info list tile
Widget buildContactListTile({
  required String label,
  required String value,
  VoidCallback? onTap,
  List<Widget>? trailing,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Builder(
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: cs.surfaceContainerHighest.withAlpha(150),
          title: Text(label),
          subtitle: Text(
            value,
            style: const TextStyle(decoration: TextDecoration.underline),
          ),
          trailing: trailing != null
              ? Row(mainAxisSize: MainAxisSize.min, children: trailing)
              : null,
          onTap: onTap,
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('Copied to clipboard')),
            );
          },
        );
      },
    ),
  );
}

Widget buildHeader({
  required BuildContext context,
  required bool isDesktop,
  required bool isTablet,
  required bool isAdmin,
  required bool isEditor,
  required int companyId,
  required String? logo,
  required Widget adminButtons,
  required Widget actionButtons,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      buildCompanyLogo(context, companyId, logo),
      Column(
        children: [
          // Rol bağımlılığını kaldırdık; izinler her butonun içinde kontrol ediliyor.
          adminButtons,
          const SizedBox(height: 5),
          actionButtons,
        ],
      ),
    ],
  );
}

Widget buildCompanyLogo(
  BuildContext context,
  int companyId,
  String? existingLogo,
) {
  final imageUrl = (existingLogo != null && existingLogo.isNotEmpty)
      ? '${V1Config.baseUrl}uploads/images/companies/logo/$existingLogo'
      : null;

  return FutureBuilder<bool>(
    future: V1PermissionGate.check(
      context: context,
      code: 'company.update',
      companyId: companyId,
    ),
    builder: (context, snapshot) {
      final hasPermission = snapshot.data == true;
      return CustomImagePicker(
        aspectRatio: 1,
        existingImageUrl: imageUrl,
        addWatermark: true,
        deleteOld: true,
        meta: {'type': 'company'},
        iwidth: 80,
        iheight: 80,
        iradius: 40,
        ishadow: true,
        canEdit: hasPermission,
        doUpload: hasPermission,

        // Upload endpoint sende çalıştığı için aynı bırakıldı.
        uploadEndpoint: 'upload_image_general',
        uploadMeta: {
          'type': 'company',
          'folder': 'uploads/images/companies/logo/',
          'prefix': 'c_$companyId',
          'thumb': 'true',
          'thumbSize': '128',
        },

        onUploaded: (uploadedFileName) async {
          final v1 = context.read<V1ApiManager>();
          final res = await v1.call(
            module: 'company',
            action: 'update',
            params: {
              'id': companyId, // dikkat: 'company_id' değil 'id'
              'logo': uploadedFileName,
            },
          );
          if (res['success'] == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Logo updated.')),
            );
          }
        },

        onImagePicked: (_, __) {},
      );
    },
  );
}

Widget buildAdminButtons(
  BuildContext context,
  int companyId,
  Map<String, dynamic> companyData, {
  VoidCallback? onChanged,
}) {
  return Row(
    children: [
      // Edit
      V1PermissionGate(
        code: 'company.update',
        companyId: companyId,
        child: IconButton(
          icon: const Icon(Icons.edit),
          tooltip: 'Edit Company',
          onPressed: () async {
            final updated = await Navigator.pushNamed(
              context,
              '/update_company',
              arguments: companyData,
            );
            if (updated == true) {
              onChanged?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Company updated.')),
              );
            }
          },
        ),
      ),

      // Members
      V1PermissionGate(
        code: 'company.members.view',
        companyId: companyId,
        child: IconButton(
          icon: const Icon(Icons.group),
          onPressed: () => Navigator.pushNamed(
            context,
            '/manage_company_users',
            arguments: companyData,
          ),
          tooltip: 'Manage Users',
        ),
      ),

      // Settings (izin: company.update)
      V1PermissionGate(
        code: 'company.update',
        companyId: companyId,
        child: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => Navigator.pushNamed(
            context,
            '/company_settings',
            arguments: companyData,
          ),
          tooltip: 'Company Settings',
        ),
      ),

      // Üç nokta menüsü: hide / unhide / archive (company.update ile gate)
      V1PermissionGate(
        code: 'company.update',
        companyId: companyId,
        child: PopupMenuButton<_CompanyAdminAction>(
          icon: const Icon(Icons.more_vert),
          onSelected: (act) => _handleAdminAction(
            context: context,
            action: act,
            companyId: companyId,
            companyName: (companyData['name'] ?? '').toString(),
            onChanged: onChanged,
          ),
          itemBuilder: (ctx) => <PopupMenuEntry<_CompanyAdminAction>>[
            const PopupMenuItem(
              value: _CompanyAdminAction.hide,
              child: ListTile(
                leading: Icon(Icons.visibility_off),
                title: Text('Hide'),
              ),
            ),
            const PopupMenuItem(
              value: _CompanyAdminAction.unhide,
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('Unhide'),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: _CompanyAdminAction.archive,
              child: ListTile(
                leading: Icon(Icons.archive_outlined),
                title: Text('Archive (soft delete)'),
              ),
            ),
            // Hard delete: ayrı izin kontrolü (company.delete.hard)
            PopupMenuItem<_CompanyAdminAction>(
              enabled: false, // içerde FutureBuilder ile kontrol
              child: FutureBuilder<bool>(
                future: V1PermissionGate.check(
                  context: ctx,
                  code: 'company.delete.hard',
                  companyId: companyId,
                ),
                builder: (c, snap) {
                  final allowed = snap.data == true;
                  return ListTile(
                    enabled: allowed,
                    leading:
                        const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Delete permanently',
                        style: TextStyle(color: Colors.red)),
                    onTap: allowed
                        ? () {
                            Navigator.pop(c); // menüyü kapat
                            _handleAdminAction(
                              context: context,
                              action: _CompanyAdminAction.deleteHard,
                              companyId: companyId,
                              companyName:
                                  (companyData['name'] ?? '').toString(),
                              onChanged: onChanged,
                            );
                          }
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

enum _CompanyAdminAction { hide, unhide, archive, deleteHard }

Future<void> _handleAdminAction({
  required BuildContext context,
  required _CompanyAdminAction action,
  required int companyId,
  required String companyName,
  VoidCallback? onChanged,
}) async {
  final v1 = context.read<V1ApiManager>();

  Future<bool> confirm(String title, String body) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('OK'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void okSnack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  void errSnack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text('❌ $m')));

  switch (action) {
    case _CompanyAdminAction.hide:
      if (!await confirm('Hide company',
          'This will make "$companyName" invisible. Continue?')) {
        return;
      }
      final resHide = await v1.call(
        module: 'company',
        action: 'hide',
        params: {'company_id': companyId},
      );
      if (resHide['success'] == true) {
        okSnack('Company hidden.');
        onChanged?.call();
        Navigator.maybePop(context);
      } else {
        errSnack(resHide['message'] ?? 'Hide failed.');
      }
      break;

    case _CompanyAdminAction.unhide:
      if (!await confirm(
          'Unhide company', 'Make "$companyName" visible again?')) {
        return;
      }
      final resUnhide = await v1.call(
        module: 'company',
        action: 'unhide',
        params: {'company_id': companyId},
      );
      if (resUnhide['success'] == true) {
        okSnack('Company visible.');
        onChanged?.call();
      } else {
        errSnack(resUnhide['message'] ?? 'Unhide failed.');
      }
      break;

    case _CompanyAdminAction.archive:
      if (!await confirm('Archive company',
          'This will disable the company and mark it as deleted (soft). Continue?')) {
        return;
      }
      final resArch = await v1.call(
        module: 'company',
        action: 'archive',
        params: {'company_id': companyId},
      );
      final bool ok =
          (resArch['success'] == true) || (resArch['data']?['deleted'] == true);
      if (ok) {
        okSnack('Company archived.');
        Navigator.maybePop(context);
      } else {
        errSnack(resArch['message'] ?? 'Archive failed.');
      }
      break;

    case _CompanyAdminAction.deleteHard:
      final phraseCtl = TextEditingController();
      final passCtl = TextEditingController();
      final okDel = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Delete permanently'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText(
                    'Type the phrase below to confirm:\n\nDELETE $companyName'),
                const SizedBox(height: 8),
                TextField(
                  controller: phraseCtl,
                  decoration: const InputDecoration(
                    labelText: 'Confirm phrase',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Your password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );
      if (okDel != true) return;

      final resDel = await v1.call(
        module: 'company',
        action: 'delete',
        params: {
          'company_id': companyId,
          'confirm_phrase': phraseCtl.text.trim(),
          'password': passCtl.text,
        },
      );
      if (resDel['success'] == true) {
        okSnack('Company scheduled for deletion.');
        Navigator.maybePop(context);
      } else {
        errSnack(resDel['message'] ?? 'Delete failed.');
      }
      break;
  }
}

Widget buildActionButtons(BuildContext context, bool isViewer, bool isFollower,
    bool isEmployee, int companyId) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (isViewer || isFollower)
        CustomButton(
          label: 'Apply for a Job',
          icon: Icons.work_outline,
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/join_company',
              arguments: {'company_id': companyId},
            );
          },
        ),
      if (isEmployee)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.meeting_room),
            label: const Text('Enter Workspace'),
          ),
        ),
    ],
  );
}

Map<String, List<Map<String, String>>> parseContactInfo(dynamic raw) {
  if (raw == null || raw is! Map) return {};
  final Map<String, List<Map<String, String>>> parsed = {};
  for (final entry in raw.entries) {
    final key = entry.key.toString();
    final valueList = entry.value;
    if (valueList is List) {
      parsed[key] = valueList.map<Map<String, String>>((item) {
        return {
          'label': item['label']?.toString() ?? '',
          'value': item['value']?.toString() ?? '',
        };
      }).toList();
    }
  }
  return parsed;
}

Future<void> handleAddCompanyType({
  required BuildContext context,
  required List<Map<String, dynamic>> allTypes,
  required List<int> selectedIds,
  required Function(List<int>) onSelectedUpdated,
}) async {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Select Company Types'),
        content: SizedBox(
          width: 400,
          child: DropdownSearch<Map<String, dynamic>>.multiSelection(
            items: allTypes,
            selectedItems: selectedIds
                .map((id) => allTypes.firstWhere(
                      (t) => t['id'] == id,
                      orElse: () => {},
                    ))
                .where((e) => e.isNotEmpty)
                .toList(),
            itemAsString: (item) => item['name'] ?? 'Unnamed',
            compareFn: (item, selected) => item['id'] == selected['id'],
            popupProps: const PopupPropsMultiSelection.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  labelText: 'Search',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            onChanged: (selected) {
              onSelectedUpdated(selected.map((e) => e['id'] as int).toList());
            },
            dropdownDecoratorProps: const DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                labelText: 'Company Types',
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

Future<void> updateCompanyTypesOnServer(
  BuildContext context,
  List<int> selectedIds,
  int companyId,
) async {
  final v1 = context.read<V1ApiManager>();
  final res = await v1.call(
    module: 'company',
    action: 'update',
    params: {
      'id': companyId,
      'type_ids': selectedIds, // backend 'type_ids' bekliyor
    },
  );

  final message = res['success'] == true
      ? 'Company types updated successfully.'
      : '❌ ${res['message'] ?? 'Update failed.'}';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<void> fetchCompanyTypes({
  required BuildContext context,
  required Function(List<Map<String, dynamic>>) onFetched,
  List<int> filterIds = const [],
  int perPage = 500, // <— eklendi
}) async {
  final v1 = context.read<V1ApiManager>();
  final res = await v1.call(
    module: 'company',
    action: 'types',
    params: {
      if (filterIds.isNotEmpty) 'filter_ids': filterIds,
      'perPage': perPage, // <— eklendi
    },
    requiresAuth: false,
  );

  if (res['success'] == true) {
    final data = res['data'];
    List items;
    if (data is List) {
      items = data;
    } else if (data is Map && data['items'] is List) {
      items = data['items'];
    } else {
      items = const [];
    }

    final safeList = items
        .where((e) => e is Map && e['id'] != null && e['name'] != null)
        .cast<Map<String, dynamic>>()
        .toList();

    onFetched(safeList);
  } else {
    onFetched([]);
  }
}

Future<void> updateContactInfoOnServer({
  required BuildContext context,
  required int companyId,
  required Map<String, List<Map<String, String>>> contactInfo,
}) async {
  final v1 = context.read<V1ApiManager>();
  final res = await v1.call(
    module: 'company',
    action: 'update',
    params: {
      'id': companyId, // 'company_id' değil
      'contact_info': contactInfo,
    },
  );

  final message = res['success'] == true
      ? 'Contact info updated successfully.'
      : 'Failed to update contact info.';
  if (context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

Future<void> handleContactTap(
  BuildContext context,
  String category,
  String value,
) async {
  Uri? uri;
  switch (category) {
    case 'phones':
      showPhoneOptions(context, value);
      return;
    case 'emails':
      uri = Uri(scheme: 'mailto', path: value);
      break;
    case 'websites':
      uri = Uri.parse(value.startsWith('http') ? value : 'https://$value');
      break;
    case 'addresses':
      final query =
          value.replaceAll('.', '').trim().replaceAll(RegExp(r'\s+'), '+');
      uri = Uri.parse('https://yandex.com/maps/?text=$query');
      break;
    default:
      return;
  }
  await launchDirectly(context, uri.toString());
}

Future<void> launchDirectly(BuildContext context, String url) async {
  try {
    if (Platform.isWindows) {
      // 'start' bir shell built-in; cmd üzerinden çağır.
      await Process.run('cmd', ['/c', 'start', '', url]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [url]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [url]);
    } else if (Platform.isAndroid || Platform.isIOS) {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri)) {
        throw Exception('Could not launch $url');
      }
    } else {
      throw UnsupportedError('Platform not supported');
    }
  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('❌ Failed to launch: $url')));
  }
}

void showPhoneOptions(BuildContext context, String phoneNumber) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Wrap(
          children: [
            if (Platform.isAndroid || Platform.isIOS)
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Call'),
                onTap: () async {
                  final uri = Uri(scheme: 'tel', path: phoneNumber);
                  try {
                    await launchUrl(uri);
                  } catch (_) {}
                  Navigator.pop(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: phoneNumber));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Phone number copied to clipboard')));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<void> showContactDialog({
  required BuildContext context,
  required ThemeProvider themeProvider,
  required String category,
  Map<String, String>? item,
  required Map<String, List<Map<String, String>>> contactInfo,
  required Function(Map<String, List<Map<String, String>>>) onUpdate,
}) async {
  final def = contactFieldDefinitions[category] ?? {};
  final labelController = TextEditingController(text: item?['label'] ?? '');
  final valueController = TextEditingController(text: item?['value'] ?? '');
  final isEditMode = item != null;

  String? errorText; // basit inline hata

  bool validate(String value) {
    final v = value.trim();
    if (v.isEmpty) return false;

    switch (category) {
      case 'emails':
        final email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
        return email.hasMatch(v);
      case 'phones':
        // + başlasın, kalanlar digit/space/-
        final phone = RegExp(r'^\+?[0-9\-\s]{6,}$');
        return phone.hasMatch(v);
      case 'websites':
        // domain veya http(s) link basit kontrol
        final web = RegExp(r'^(https?:\/\/)?([a-z0-9\-]+\.)+[a-z]{2,}(\S*)$',
            caseSensitive: false);
        return web.hasMatch(v);
      default:
        return v.isNotEmpty;
    }
  }

  String normalize(String value) {
    var v = value.trim();
    switch (category) {
      case 'phones':
        if (!v.startsWith('+')) v = '+$v';
        break;
      case 'websites':
        if (!v.startsWith('http')) v = 'https://$v';
        break;
      case 'emails':
        v = v.toLowerCase();
        break;
    }
    return v;
  }

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Text(
              '${isEditMode ? "Edit" : "Add"} ${category[0].toUpperCase()}${category.substring(1)}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomFormField(
                controller: labelController,
                label: def['label'] ?? 'Label',
                hint: def['hint'] ?? '',
                icon: def['icon'] ?? const Icon(Icons.label),
                validationMessage: 'Label cannot be empty',
                maxLines: 1,
                themeProvider: themeProvider,
              ),
              const SizedBox(height: 12),
              CustomFormField(
                controller: valueController,
                label: def['valueLabel'] ?? 'Value',
                hint: def['valueHint'] ?? '',
                icon: def['valueIcon'] ?? const Icon(Icons.info),
                validationMessage: errorText ?? 'Value cannot be empty',
                isEmail: def['isEmail'] ?? (category == 'emails'),
                isPhone: def['isPhone'] ?? (category == 'phones'),
                isNumeric: def['isNumeric'] ?? false,
                isUrl: def['isUrl'] ?? (category == 'websites'),
                maxLines: def['maxLines'] ?? 1,
                themeProvider: themeProvider,
              ),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(errorText!,
                      style: const TextStyle(color: Colors.red)),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final label = labelController.text.trim();
                final raw = valueController.text.trim();

                if (label.isEmpty) {
                  setState(() => errorText = 'Label cannot be empty');
                  return;
                }
                if (!validate(raw)) {
                  setState(() {
                    switch (category) {
                      case 'emails':
                        errorText = 'Please enter a valid email address';
                        break;
                      case 'phones':
                        errorText = 'Please enter a valid phone number';
                        break;
                      case 'websites':
                        errorText = 'Please enter a valid website';
                        break;
                      default:
                        errorText = 'Value cannot be empty';
                    }
                  });
                  return;
                }

                final value = normalize(raw);

                if (isEditMode) {
                  final index = contactInfo[category]?.indexOf(item);
                  if (index != null && index != -1) {
                    contactInfo[category]?[index] = {
                      'label': label,
                      'value': value,
                    };
                  }
                } else {
                  contactInfo.putIfAbsent(category, () => []);
                  contactInfo[category]!.add({'label': label, 'value': value});
                }
                onUpdate(contactInfo);
                Navigator.pop(context);
              },
              child: Text(isEditMode ? 'Update' : 'Add'),
            ),
          ],
        );
      });
    },
  );
}

IconData getIconForCategory(String category) {
  switch (category.toLowerCase()) {
    case 'phones':
      return Icons.phone;
    case 'emails':
      return Icons.email;
    case 'addresses':
      return Icons.location_on;
    case 'websites':
      return Icons.language;
    default:
      return Icons.info_outline;
  }
}

void deleteContactItem(
  BuildContext context,
  String category,
  Map<String, String> item,
  Map<String, List<Map<String, String>>> contactInfo,
  Function(Map<String, List<Map<String, String>>>) onUpdate,
) {
  contactInfo[category]?.remove(item);
  onUpdate(contactInfo);
}

Widget buildCompanyTypeSection(
  List<Map<String, dynamic>> allTypes,
  List<int> selectedIds,
  bool isAdmin,
  bool isEditor,
  VoidCallback onAddPressed,
) {
  final sortedChips = selectedIds
      .map((id) => allTypes.firstWhere(
            (t) => t['id'] == id,
            orElse: () => {'id': id, 'name': 'Unknown', 'description': ''},
          ))
      .toList()
    ..sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

  return Builder(
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return Card(
        elevation: 0,
        color: cs.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.business, size: 20),
                  const SizedBox(width: 8),
                  const Text('Company Type:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  if (isAdmin || isEditor)
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Add Company Type',
                      onPressed: onAddPressed,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (selectedIds.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 28, bottom: 8),
                  child: Text('Not specified'),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: -4,
                    children: sortedChips.map((matched) {
                      return Tooltip(
                        message: matched['description'] ?? '',
                        child: InputChip(
                          label: Text(matched['name'] ?? 'Unknown'),
                          onPressed: null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

Widget buildContactSection({
  required BuildContext context,
  required String userRole,
  required Map<String, List<Map<String, String>>> contactInfo,
  required void Function(String category) onAddPressed,
  required void Function(String category, Map<String, String> item)
      onEditPressed,
  required void Function(
    String category,
    Map<String, String> item,
    Map<String, List<Map<String, String>>> updatedInfo,
  ) onDeletePressed,
  required void Function(String category, String value) onTap,
}) {
  final allCategories = ['phones', 'emails', 'addresses', 'websites'];
  final isEditorOrAdmin = userRole == 'admin' || userRole == 'editor';

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: allCategories.map((category) {
      final items = contactInfo[category] ?? [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(getIconForCategory(category), size: 18),
              const SizedBox(width: 8),
              SelectableText(
                category[0].toUpperCase() + category.substring(1),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (isEditorOrAdmin)
                GestureDetector(
                  onTap: () => onAddPressed(category),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.add_circle, size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(left: 32),
              child: Text('-'),
            )
          else
            ...items.map((item) {
              final label = item['label'] ?? '';
              final value = item['value'] ?? '';
              final isPhone = category == 'phones';
              final displayValue =
                  isPhone ? (value.startsWith('+') ? value : '+$value') : value;

              // Hızlı aksiyonlar: Open + Copy
              final quickActions = <Widget>[
                buildIconButton(
                  Icons.open_in_new,
                  () => onTap(category, displayValue),
                  'Open',
                ),
                buildIconButton(
                  Icons.copy,
                  () {
                    Clipboard.setData(ClipboardData(text: displayValue));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                  'Copy',
                ),
              ];

              // Admin/Editor için mevcut Edit/Delete’i de ekle
              final editActions = isEditorOrAdmin
                  ? <Widget>[
                      buildIconButton(
                        Icons.edit,
                        () => onEditPressed(category, item),
                        'Edit',
                      ),
                      buildIconButton(
                        Icons.delete,
                        () => onDeletePressed(category, item, contactInfo),
                        'Delete',
                      ),
                    ]
                  : <Widget>[];

              return buildContactListTile(
                label: label,
                value: displayValue,
                onTap: () => onTap(category, displayValue),
                trailing: [
                  ...quickActions,
                  ...editActions,
                ],
              );
            }),
          const SizedBox(height: 12),
        ],
      );
    }).toList(),
  );
}
