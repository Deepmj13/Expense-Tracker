import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

enum FeedbackType {
  bugReport,
  featureRequest,
  generalFeedback;

  String get label {
    switch (this) {
      case FeedbackType.bugReport:
        return 'Bug Report';
      case FeedbackType.featureRequest:
        return 'Feature Request';
      case FeedbackType.generalFeedback:
        return 'General Feedback';
    }
  }

  String get subjectPrefix {
    switch (this) {
      case FeedbackType.bugReport:
        return 'Bug Report';
      case FeedbackType.featureRequest:
        return 'Feature Request';
      case FeedbackType.generalFeedback:
        return 'Feedback';
    }
  }
}

class FeedbackSheet extends StatefulWidget {
  const FeedbackSheet({super.key});

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  final _feedbackController = TextEditingController();
  FeedbackType _selectedType = FeedbackType.bugReport;
  bool _isSending = false;
  bool _isSent = false;

  static const _formspreeUrl = 'https://formspree.io/f/YOUR_FORM_ID';

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  String _getFormattedFeedback() {
    return '''
${_selectedType.subjectPrefix} - Expense Tracker App

${_feedbackController.text.trim()}

---
Feedback Type: ${_selectedType.label}
App Version: 1.0.0
Date: ${DateTime.now().toIso8601String()}
''';
  }

  Future<void> _sendFeedback() async {
    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your feedback first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      await http.post(
        Uri.parse(_formspreeUrl),
        headers: {'Content-Type': 'application/json'},
        body: '{\n'
            '  "subject": "${_selectedType.subjectPrefix} - Expense Tracker App",\n'
            '  "message": "${_getFormattedFeedback().replaceAll('"', '\\"').replaceAll('\n', '\\n')}"\n'
            '}',
      );

      if (mounted) {
        setState(() {
          _isSending = false;
          _isSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Feedback sent successfully!'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        _showFallbackOptions();
      }
    }
  }

  void _showFallbackOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.email_outlined, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'Could not send email directly',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose an alternative way to send your feedback:',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _openEmailApp();
              },
              icon: const Icon(Icons.email),
              label: const Text('Open Email App'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _copyToClipboard();
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy to Clipboard'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _openEmailApp() async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'deepmujpara@gmail.com',
      queryParameters: {
        'subject': '${_selectedType.subjectPrefix} - Expense Tracker App',
        'body': _getFormattedFeedback(),
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (mounted) {
          _copyToClipboard();
        }
      }
    } catch (e) {
      if (mounted) {
        _copyToClipboard();
      }
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _getFormattedFeedback()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Feedback copied! Paste it in any app.'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.feedback,
                    color: Colors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Send Feedback',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Help us improve the app',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Feedback Type',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FeedbackType.values.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = type);
                    }
                  },
                  selectedColor: colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _feedbackController,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: _selectedType == FeedbackType.bugReport
                    ? 'Describe the bug'
                    : _selectedType == FeedbackType.featureRequest
                        ? 'Describe your feature idea'
                        : 'Your feedback',
                hintText: _selectedType == FeedbackType.bugReport
                    ? 'Describe what went wrong...'
                    : _selectedType == FeedbackType.featureRequest
                        ? 'Describe the feature you would like...'
                        : 'Share your thoughts...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isSending || _isSent ? null : _sendFeedback,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(_isSent ? Icons.check : Icons.send),
              label: Text(_isSent
                  ? 'Sent!'
                  : _isSending
                      ? 'Sending...'
                      : 'Send Feedback'),
              style: FilledButton.styleFrom(
                backgroundColor: _isSent ? Colors.green : null,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isSending ? null : () => Navigator.pop(context),
              child: Text(_isSending ? 'Please wait...' : 'Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
