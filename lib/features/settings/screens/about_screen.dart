import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version = snapshot.data?.version ?? '1.0.0';
          final build = snapshot.data?.buildNumber ?? '1';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionHeader(context, 'App Info'),
              ListTile(
                title: const Text('Version'),
                subtitle: Text('$version+$build'),
              ),
              const Divider(),
              _sectionHeader(context, 'Links'),
              ListTile(
                title: const Text('Open source licenses'),
                leading: const Icon(Icons.description_outlined),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'PureNote',
                  applicationVersion: version,
                ),
              ),
              ListTile(
                title: const Text('Privacy policy'),
                leading: const Icon(Icons.privacy_tip_outlined),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _launchUrl('https://purenote.app/privacy'),
              ),
              ListTile(
                title: const Text('Send feedback'),
                leading: const Icon(Icons.feedback_outlined),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _launchUrl('mailto:support@purenote.app'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
