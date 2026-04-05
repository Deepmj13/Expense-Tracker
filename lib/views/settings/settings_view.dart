import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/app_providers.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  String _getThemeTitle(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.settings_brightness;
    }
  }

  Future<void> _reportBug(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'deepmujpara@gmail.com',
      queryParameters: {
        'subject': 'Bug Report - Expense Tracker',
        'body':
            'Describe the bug:\n\n\n\nSteps to reproduce:\n1. \n2. \n3. \n\nExpected behavior:\n\nActual behavior:',
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open email app'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Appearance'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getThemeIcon(themeMode),
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: const Text('Theme'),
            subtitle: Text(_getThemeTitle(themeMode)),
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (v) => ref.read(themeModeProvider.notifier).state =
                  v ? ThemeMode.dark : ThemeMode.light,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Data'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.file_download, color: Colors.green),
            ),
            title: const Text('Export Transactions'),
            subtitle: const Text('Save CSV file to your device'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final transactions = ref.read(transactionsControllerProvider);

              final rows = [
                ['id', 'title', 'amount', 'type', 'category', 'date', 'note'],
                ...transactions.map((t) => [
                      t.id,
                      t.title,
                      t.amount,
                      t.type.name,
                      t.category,
                      t.date.toIso8601String(),
                      t.note,
                    ]),
              ];

              final csv = const ListToCsvConverter().convert(rows);
              final timestamp =
                  DateTime.now().toIso8601String().replaceAll(':', '-');
              final bytes = Uint8List.fromList(csv.codeUnits);

              final result = await FilePicker.platform.saveFile(
                dialogTitle: 'Choose save location',
                fileName: 'expense_export_$timestamp.csv',
                type: FileType.custom,
                allowedExtensions: ['csv'],
                bytes: bytes,
              );

              if (context.mounted) {
                if (result != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('CSV saved to: $result'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Export cancelled'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Help'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bug_report, color: Colors.orange),
            ),
            title: const Text('Report a Bug'),
            subtitle: const Text('Send feedback to developer'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _reportBug(context),
          ),
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Account'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout, color: Colors.red),
            ),
            title: const Text('Logout'),
            subtitle: const Text('Sign out of your account'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ),
        const SizedBox(height: 32),
        Center(
          child: Text(
            'Expense Tracker v1.0.0',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}
