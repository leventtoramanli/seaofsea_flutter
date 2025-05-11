import 'package:flutter/material.dart';

final Map<String, Map<String, dynamic>> contactFieldDefinitions = {
    'phones': {
      'label': 'Phone Label',
      'hint': 'e.g. Mobile, Office',
      'icon': const Icon(Icons.label),
      'valueLabel': 'Phone Number',
      'valueHint': 'e.g. +90 555 555 5555',
      'isPhone': true,
      'valueIcon': const Icon(Icons.phone),
    },
    'emails': {
      'label': 'Email Label',
      'hint': 'e.g. Work, Personal',
      'icon': const Icon(Icons.label),
      'valueLabel': 'Email Address',
      'valueHint': 'e.g. example@domain.com',
      'isEmail': true,
      'valueIcon': const Icon(Icons.email),
    },
    'addresses': {
      'label': 'Address Label',
      'hint': 'e.g. Office, HQ',
      'icon': const Icon(Icons.label),
      'valueLabel': 'Full Address',
      'valueHint': 'Street, City, Country',
      'maxLines': 3,
      'valueIcon': const Icon(Icons.location_on),
    },
    'websites': {
      'label': 'Website Label',
      'hint': 'e.g. Main, Portfolio',
      'icon': const Icon(Icons.label),
      'valueLabel': 'Website URL',
      'valueHint': 'https://example.com',
      'isUrl': true,
      'valueIcon': const Icon(Icons.language),
    },
  };