import 'package:flutter/material.dart';

class Terms extends StatefulWidget {
  const Terms({super.key});

  @override
  State<Terms> createState() => _TermsState();
}

class _TermsState extends State<Terms> {
  // Menü için başlıklar, alt başlıklar ve içerikleri
  final Map<String, Map<String, String>> _menuItems = {
    'Terms and Conditions': {
      'General Terms':
          'These terms and conditions ("Terms") govern the use of the SeaOfSea platform. By downloading, installing, accessing, or using our services, you acknowledge and agree to:\n'
              '- Fully read, understand, and accept these Terms.\n'
              '- Use the platform in accordance with these Terms.\n'
              '- Comply with all policies and legal regulations set forth by SeaOfSea.\n'
              'If you do not agree to these Terms, you must stop using the platform and delete your account.',
      'User Responsibilities': 'Users agree to:\n'
          '- Provide accurate, complete, and up-to-date information.\n'
          '- Securely maintain their account credentials and not share them with others.\n'
          '- Avoid any activities that may harm other users or disrupt the platform.\n'
          'Failure to meet these responsibilities may result in account suspension or termination by SeaOfSea.',
      'Modification Rights':
          'SeaOfSea reserves the right to update or modify these Terms at any time without prior notice.\n'
              '- Updated Terms will become effective immediately upon publication on the platform.\n'
              '- Users are responsible for regularly reviewing these Terms.\n'
              '- Continued use of the platform indicates acceptance of the updated Terms.',
      'Age Requirement':
          'The SeaOfSea platform is designed for individuals aged 18 and above.\n'
              'Users under 18 may only access the platform with parental or guardian consent.\n'
              'SeaOfSea reserves the right to verify users’ ages.',
      'Applicable Laws':
          'These Terms are governed by the laws of the Republic of Turkey.\n'
              'In the event of a dispute, Istanbul courts and enforcement offices will have jurisdiction.',
      'Prohibited Activities': 'Users must refrain from:\n'
          '- Sending spam, engaging in fraud, or distributing harmful software.\n'
          '- Violating the rights of other users.\n'
          '- Performing technical actions that may harm the platform\'s infrastructure.\n'
          'Violations may result in immediate account termination.',
      'Third-Party Services':
          'SeaOfSea may integrate third-party services to enhance functionality.\n'
              'SeaOfSea does not control or accept responsibility for the content or practices of such third-party services.',
      'Data Security':
          'SeaOfSea implements robust security measures, including encryption and secure servers, to protect user data.\n'
              '- Users are responsible for safeguarding their account credentials and devices.\n'
              'In case of a security breach, users should contact SeaOfSea immediately.',
      'Service Usage':
          'Users agree to use the platform only in lawful and ethical ways.\n'
              'Any misuse may result in restricted access or termination of services.',
      'Intellectual Property':
          'All content on the SeaOfSea platform, including logos, designs, text, and software, is owned by SeaOfSea or used under license.\n'
              '- Unauthorized reproduction, distribution, or commercial use is prohibited.',
      'Limitation of Liability':
          'SeaOfSea does not guarantee uninterrupted service and is not liable for any damages arising from the use of the platform.\n'
              'Users accept the platform "as is" and "as available."',
      'Termination Rights':
          'SeaOfSea reserves the right to suspend or terminate user accounts without prior notice in case of violations of these Terms.',
      'Force Majeure':
          'SeaOfSea is not responsible for service interruptions caused by events beyond its control, such as natural disasters, technical failures, or governmental actions.',
      'Dispute Resolution':
          'All disputes will be resolved under the laws of the Republic of Turkey.\n'
              'Users agree to the jurisdiction of Istanbul courts and enforcement offices.',
      'User-Generated Content':
          'Users retain ownership of the content they create on the platform but grant SeaOfSea the right to use, display, and distribute such content.\n'
              'Users must ensure their content complies with applicable laws.',
      'Accessibility':
          'SeaOfSea is committed to making its platform accessible to all users.\n'
              'Feedback and suggestions regarding accessibility can be sent to **support@seaofsea.com**.'
    },
    'Privacy Policy': {
      'Data Collection':
          'SeaOfSea collects personal and usage data to improve user experience, enhance security, and optimize services.\n'
              'The data collected may include:\n'
              '- Name, surname, email address, and other contact information,\n'
              '- Device type, operating system, and application usage data,\n'
              '- Preferences and usage habits related to our services.',
      'Data Usage': 'The collected data is used for the following purposes:\n'
          '- Improving and enhancing service performance,\n'
          '- Personalizing in-app user experience,\n'
          '- Providing customer support and resolving user issues,\n'
          '- Detecting and preventing security threats,\n'
          '- Developing new features based on user feedback.\n'
          'SeaOfSea processes this data in compliance with applicable laws and international privacy standards.',
      'Third-Party Sharing':
          'User data may only be shared with trusted partners in the following cases:\n'
              '- Payment processing services,\n'
              '- Performance and usage analytics providers,\n'
              '- When required by law or to ensure user safety with authorized authorities.\n'
              'SeaOfSea does not sell or share user data with third parties beyond these situations.',
      'Data Security':
          'SeaOfSea implements the latest technological security measures to protect user data.\n'
              '- Data is stored securely on servers and protected using encryption methods.\n'
              '- Access controls ensure only authorized personnel can access the data.\n'
              'However, no digital system is entirely secure. Users are encouraged to create strong passwords and keep their account information safe.',
      'Your Rights':
          'As a user, you have the following rights concerning your personal data stored on the SeaOfSea platform:\n'
              '- Requesting a copy of your data,\n'
              '- Updating incorrect or incomplete information,\n'
              '- Requesting deletion of your data,\n'
              '- Withdrawing or restricting consent for data processing.\n'
              'You can exercise these rights through the app or by contacting the support team.',
      'Data Processing Principles':
          'SeaOfSea follows these core principles for all data processing activities:\n'
              '- **Transparency**: Clearly informing users about why and how their data is processed.\n'
              '- **Necessity and Proportionality**: Collecting and processing only the data that is necessary.\n'
              '- **Retention Period**: Retaining data only as long as needed for the specified purposes.',
      'Global Data Protection Standards':
          'SeaOfSea complies with internationally recognized standards for data protection and processing.\n'
              '- Adheres to regulations such as CCPA in the United States, GDPR in Europe, KVKK in Turkey, and similar laws in Russia.\n'
              '- Ensures all data processing activities comply with local legal regulations where the user is located.\n'
              '- Transfers user data using secure and audited methods only.',
      'Policy Updates':
          'The Privacy Policy is periodically updated to reflect changes in legal regulations or operational practices.\n'
              '- All updates are shared through in-app notifications for users to review.\n'
              '- Users are responsible for checking and accepting these changes.\n'
              '- Users who do not accept the updated policies may discontinue using the services.'
    },
    'Cookies Policy': {
      'What Are Cookies?':
          'SeaOfSea uses cookies to enhance the user experience, remember preferences, and analyze service performance. Cookies are small text files stored on your device that contain specific information.',
      'Types of Cookies We Use': 'The types of cookies used include:\n'
          '- **Session Cookies:** These track user activities during a session and are automatically deleted when the session ends.\n'
          '- **Persistent Cookies:** These are stored on your device for a defined period to remember your preferences and settings.\n'
          '- **Performance Cookies:** These analyze user interactions to measure and improve the app\'s performance.',
      'Purpose of Cookies': 'Cookies are used for the following purposes:\n'
          '- Storing user preferences and maintaining session continuity,\n'
          '- Improving the technical functionality of the app,\n'
          '- Personalizing the user experience,\n'
          '- Detecting errors and optimizing services,\n'
          '- Analyzing in-app behaviors to develop new features.',
      'Managing Cookies':
          'Users have full control over how cookies are managed or disabled.\n'
              '- You can modify cookie settings directly within the app.\n'
              '- Please note that disabling cookies entirely may affect the functionality of certain services.',
      'Third-Party Cookies':
          'SeaOfSea may use cookies from analytics providers and other partners.\n'
              '- These cookies are used to measure and improve service performance.\n'
              '- Third-party privacy policies apply to these cookies.',
      'Policy Updates':
          'The Cookies Policy may be updated periodically to reflect changes in legal regulations or operational practices.\n'
              '- Updates will be made available for users to review within the app.'
    },
    'Contact Us': {
      'Email Communication':
          'Users can reach us for inquiries or support requests by sending an email to **support@seaofsea.com**. Our team will respond to your requests as soon as possible.',
      'In-App Communication':
          'SeaOfSea provides an in-app communication feature where users can submit support requests or provide feedback directly through the application.',
      'Working Hours':
          'Our support team operates during [e.g., 09:00 AM - 06:00 PM]. Requests made outside these hours will be addressed on the next business day.'
    },
    'About Us': {
      'Founder\'s Background':
          'SeaOfSea was established under the leadership of **Capt. Levent Toramanlı**, who began his maritime career in 1999. '
              'As a Master Mariner (Unlimited), Capt. Toramanlı launched his first technological initiative in 2013 with the "SivilDenizcilik" project. '
              'With decades of experience and a visionary approach, he has positioned SeaOfSea as a provider of innovative solutions in the maritime industry.',
      'Our Mission':
          'To make maritime operations safer, smarter, and more efficient by leveraging innovative technologies.',
      'Our Journey':
          'Founded in 2024, SeaOfSea focuses on transforming maritime operations and enhancing passenger and crew experiences. '
              'With a commitment to innovation and sustainability, we aim to deliver comprehensive solutions for the maritime sector.',
      'Initial Focus Areas': '- **Connecting Companies and Personnel:**\n'
          '  - Helping companies (ships and yachts) find qualified personnel.\n'
          '  - Assisting maritime personnel in finding suitable companies.\n'
          '- **Planned Maintenance Systems:**\n'
          '  - Developing maintenance planning systems for ships, yachts, and private boats.\n'
          '  - Supporting ISM (International Safety Management) compliance with planned maintenance solutions.\n'
          '- **Procurement and Supplier Solutions:**\n'
          '  - Facilitating procurement processes and connecting companies with suppliers.\n'
          '  - Helping suppliers find potential customers.\n'
          '- **Performance Metrics:**\n'
          '  - Creating tools for KPI (Key Performance Indicator) tracking.\n'
          '- **Vessel Sales:**\n'
          '  - Simplifying the sales process for ships, yachts, and boats.',
      'Future Plans': '- **Chartering and Brokerage Portals:**\n'
          '  - Establishing dedicated platforms for chartering and brokerage services.\n'
          '- **Onboard Personnel Tracking System:**\n'
          '  - Developing systems to track the location of onboard crew members.\n'
          '- **Advanced Maritime Modules:**\n'
          '  - Creating a hospital module for onboard medical management.\n'
          '  - Developing a hotel module for managing accommodations for passengers and crew.\n'
          '- **Free Options:**\n'
          '  - SeaOfSea aims to set a new standard in the maritime industry by offering free options for its modules, making its solutions more accessible to users.',
      'Core Values': '- **Innovation:** Delivering cutting-edge solutions to the maritime industry.\n'
          '- **Safety:** Prioritizing the safety of users, vessels, and maritime operations.\n'
          '- **Sustainability:** Promoting environmentally responsible practices in maritime solutions.\n'
          '- **Accessibility:** Providing solutions that are suitable and accessible to all users.',
      'Our Vision':
          'SeaOfSea strives to be a global leader in maritime solutions, leveraging advanced technologies to build a better future for the maritime industry.'
    },
  };

  // Varsayılan olarak "Terms and Conditions" seçili
  String? _selectedTitle = 'Terms and Conditions';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shadowColor: Theme.of(context).colorScheme.shadow,
        title: const Text('SeaOfSea'),
        centerTitle: true,
      ),
      body: Row(
        children: [
          // Sol menü
          NavigationRail(
            backgroundColor: Theme.of(context).colorScheme.surface,
            selectedIconTheme:
                IconThemeData(color: Theme.of(context).colorScheme.surface),
            selectedIndex: _menuItems.keys.toList().indexOf(_selectedTitle!),
            
            onDestinationSelected: (index) {
              setState(() {
                _selectedTitle = _menuItems.keys.toList()[index];
              });
            },
            destinations: _menuItems.keys
                .map((title) => NavigationRailDestination(
                      icon: const Icon(Icons.article),
                      label: Text(title),
                    ))
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // İçerik alanı
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seçilen başlık
                  Text(
                    _selectedTitle!,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  // Alt başlıklar ve içerikler
                  Expanded(
                    child: ListView(
                      children: _menuItems[_selectedTitle!]!
                          .entries
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    entry.value,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    textAlign: TextAlign.justify,
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
