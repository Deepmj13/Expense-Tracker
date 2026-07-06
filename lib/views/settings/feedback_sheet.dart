import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    await _openEmailApp();
    if (mounted) {
      setState(() => _isSending = false);
    }
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
              onPressed: _isSending ? null : _sendFeedback,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_isSending ? 'Opening Email...' : 'Send Feedback'),
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
