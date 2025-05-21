import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/utils/theme_provider.dart';

class ContactFormSection extends StatefulWidget {
  final bool isDark;
  final Function(Map<String, dynamic>)? onChanged;
  final int? initialCountryId;
  final int? initialCityId;

  const ContactFormSection({
    super.key,
    this.isDark = false,
    this.onChanged,
    this.initialCountryId,
    this.initialCityId,
  });

  @override
  State<ContactFormSection> createState() => _ContactFormSectionState();
}

class _ContactFormSectionState extends State<ContactFormSection> {
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  List<TextEditingController> phoneControllers = [TextEditingController()];
  List<TextEditingController> emailControllers = [TextEditingController()];
  List<TextEditingController> socialControllers = [TextEditingController()];

  @override
  void dispose() {
    _countryController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    for (var c in phoneControllers) c.dispose();
    for (var c in emailControllers) c.dispose();
    for (var c in socialControllers) c.dispose();
    super.dispose();
  }

  void _notifyChange() {
    final data = {
      'country_id': selectedCountryId,
      'city_id': selectedCityId,
      'address': _addressController.text,
      'phones': phoneControllers.map((c) => c.text).toList(),
      'emails': emailControllers.map((c) => c.text).toList(),
      'socials': socialControllers.map((c) => c.text).toList(),
    };
    widget.onChanged?.call(data);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    selectedCountryId = widget.initialCountryId;
    selectedCityId = widget.initialCityId;
    loadCountries();
  }

  int? selectedCountryId;
  List<Map<String, dynamic>> countriesFields = [];
  bool isLoadingCountries = true;
  int? selectedCityId;
  List<Map<String, dynamic>> citiesFields = [];
  String? selectedCountryIso2;

  Widget _buildFlagWidget() {
    if (selectedCountryIso2 == null || selectedCountryIso2!.isEmpty) {
      return const CircleAvatar(
        backgroundColor: Colors.grey,
        child: Icon(Icons.flag, color: Colors.white),
      );
    }

    return CountryFlag.fromCountryCode(
        selectedCountryIso2!
            .toUpperCase(), // ISO2 uppercase olmalı (örn. TR, DE)
        height: 24,
        width: 36,
        shape: const RoundedRectangle(4));
  }

  Future<void> loadCities(String countryName) async {
    final api = Provider.of<ApiManager>(context, listen: false);
    final response = await api.post(context, 'listCitiesByCountry', {
      'country': countryName,
    });
    if (!mounted) return;
    if (response['success'] == true) {
      setState(() {
        citiesFields = List<Map<String, dynamic>>.from(response['data']);
        selectedCityId = null;
      });
    } else {
      debugPrint('Şehirler yüklenemedi: ${response['message']}');
    }
    if (widget.initialCityId != null) {
      setState(() {
        selectedCityId = widget.initialCityId;
      });
    }
  }

  Future<void> loadCountries() async {
    final api = Provider.of<ApiManager>(context, listen: false);
    final response = await api.post(context, 'listCountries', {});
    if (!mounted) return;

    if (response['success'] == true) {
      final data = List<Map<String, dynamic>>.from(response['data']);
      String? foundIso2;
      if (widget.initialCountryId != null) {
        final selected = data.firstWhere(
          (e) => e['id'] == widget.initialCountryId,
          orElse: () => {},
        );
        foundIso2 = selected['code2'] ?? selected['iso2'];
      }

      setState(() {
        countriesFields = data;
        selectedCountryIso2 = foundIso2;
        isLoadingCountries = false;
      });

      // Eğer city listesi de gösterilecekse, ülkeden sonra onu da çek:
      if (widget.initialCountryId != null) {
        final selected = data.firstWhere(
            (e) => e['id'] == widget.initialCountryId,
            orElse: () => {});
        if (selected.isNotEmpty && selected['name'] != null) {
          await loadCities(selected['name']);
        }
      }
    }
  }

  @override
  Widget _buildDynamicList(String label, List<TextEditingController> list,
      {IconData? icon}) {
    final color = Provider.of<ThemeProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              color: color.isDarkMode
                  ? Colors.white
                  : Colors.black, //widget.isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            )),
        ...list.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    onChanged: (_) => _notifyChange(),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: '$label ${index + 1}',
                      prefixIcon: icon != null ? Icon(icon) : null,
                    ),
                  ),
                ),
                if (index == list.length - 1)
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        list.add(TextEditingController());
                      });
                    },
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      setState(() {
                        list.removeAt(index);
                      });
                    },
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Provider.of<ThemeProvider>(context);
    debugPrint('ISO2 updated to!: $selectedCountryIso2');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isLoadingCountries
            ? const Center(child: CircularProgressIndicator())
            : Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: selectedCountryId,
                      items: countriesFields.map((country) {
                        return DropdownMenuItem<int>(
                          value: country['id'],
                          child: Text(country['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCountryId = value;
                          selectedCityId = null;
                        });

                        final selectedCountry = countriesFields.firstWhere(
                          (c) => c['id'] == value,
                          orElse: () => {},
                        );

                        if (selectedCountry.isNotEmpty &&
                            selectedCountry['name'] != null) {
                          final newIso2 = (selectedCountry['code2'] ?? '')
                              .toString()
                              .toUpperCase();

                          setState(() {
                            selectedCountryIso2 = newIso2;
                          });

                          loadCities(selectedCountry['name']);
                        }

                        _notifyChange();
                      },
                      decoration: InputDecoration(
                        labelText: 'Country',
                        labelStyle: TextStyle(
                          color: color.isDarkMode ? Colors.white : Colors.black,
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildFlagWidget(),
                ],
              ),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(
          value: selectedCityId,
          items: citiesFields.map((city) {
            return DropdownMenuItem<int>(
              value: city['id'],
              child: Text(city['name']),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedCityId = value;
            });
            _notifyChange(); // Veriyi güncelle
          },
          decoration: InputDecoration(
            labelText: 'City',
            labelStyle: TextStyle(
              color: color.isDarkMode ? Colors.white : Colors.black,
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _addressController,
          onChanged: (_) => _notifyChange(),
          decoration: InputDecoration(
              labelText: 'Address',
              labelStyle: TextStyle(
                  color: color.isDarkMode ? Colors.white : Colors.black),
              border: const OutlineInputBorder()),
        ),
        const SizedBox(height: 10),
        _buildDynamicList("Phone", phoneControllers, icon: Icons.phone),
        const SizedBox(height: 10),
        _buildDynamicList("Email", emailControllers, icon: Icons.email),
        const SizedBox(height: 10),
        _buildDynamicList("Social Media", socialControllers, icon: Icons.link),
      ],
    );
  }
}
