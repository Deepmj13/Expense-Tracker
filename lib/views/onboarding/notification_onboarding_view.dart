import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/oem_instructions.dart';
import '../../services/notification_channel_service.dart';
import '../../core/constants/notification_apps.dart';

class NotificationOnboardingView extends ConsumerStatefulWidget {
  const NotificationOnboardingView({super.key});

  @override
  ConsumerState<NotificationOnboardingView> createState() =>
      _NotificationOnboardingViewState();
}

class _NotificationOnboardingViewState
    extends ConsumerState<NotificationOnboardingView>
    with WidgetsBindingObserver {
  final _channelService = NotificationChannelService();

  int _currentStep = 0;
  bool _isLoading = true;
  bool _hasNotificationPermission = false;
  bool _hasBatteryOptimization = false;
  String _deviceManufacturer = 'unknown';
  bool _needsAutoStart = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAllPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAllPermissions();
    }
  }

  Future<void> _checkAllPermissions() async {
    final hasNotification = await _channelService.isNotificationAccessEnabled();
    final hasBattery = await _channelService.isBatteryOptimizationDisabled();
    final manufacturer = await _channelService.getDeviceManufacturer();
    final needsAutoStart = OemInstructions.needsAutoStartSettings(manufacturer);

    if (mounted) {
      setState(() {
        _hasNotificationPermission = hasNotification;
        _hasBatteryOptimization = hasBattery;
        _deviceManufacturer = manufacturer;
        _needsAutoStart = needsAutoStart;
        _isLoading = false;

        if (_hasNotificationPermission) {
          _currentStep = 1;
        }
        if (_hasBatteryOptimization) {
          _currentStep = _needsAutoStart ? 2 : 3;
        }
      });
    }
  }

  Future<void> _openNotificationSettings() async {
    await _channelService.openNotificationSettings();
  }

  Future<void> _requestBatteryExemption() async {
    await _channelService.requestBatteryOptimizationExemption();
    await Future.delayed(const Duration(milliseconds: 1000));
    await _checkAllPermissions();
  }

  Future<void> _openAutoStartSettings() async {
    await _channelService.openAutoStartSettings();
    await Future.delayed(const Duration(milliseconds: 1000));
    await _checkAllPermissions();
  }

  Future<void> _skipOnboarding() async {
    final box = Hive.box('app_box');
    await box.put('notification_onboarding_completed', true);
    await _channelService
        .setMonitoredApps(NotificationApps.defaultPackagePatterns);
    if (mounted) {
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _completeOnboarding() async {
    final box = Hive.box('app_box');
    await box.put('notification_onboarding_completed', true);
    await _channelService
        .setMonitoredApps(NotificationApps.defaultPackagePatterns);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: colorScheme.primary,
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressIndicator(colorScheme),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildCurrentStep(colorScheme),
              ),
            ),
            _buildBottomButtons(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ColorScheme colorScheme) {
    final totalSteps = _needsAutoStart ? 3 : 2;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStepIndicator(0, totalSteps, 'Access', Icons.notifications),
          Expanded(child: _buildConnector(0, totalSteps, colorScheme)),
          _buildStepIndicator(
              1, totalSteps, 'Battery', Icons.battery_charging_full),
          if (_needsAutoStart) ...[
            Expanded(child: _buildConnector(1, totalSteps, colorScheme)),
            _buildStepIndicator(
                2, totalSteps, 'Auto-Start', Icons.power_settings_new),
          ],
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, int total, String label, IconData icon) {
    final isCompleted = _currentStep > step;
    final isCurrent = _currentStep == step;
    final colorScheme = Theme.of(context).colorScheme;

    Color backgroundColor;
    Color iconColor;

    if (isCompleted) {
      backgroundColor = Colors.green;
      iconColor = Colors.white;
    } else if (isCurrent) {
      backgroundColor = colorScheme.primary;
      iconColor = Colors.white;
    } else {
      backgroundColor = colorScheme.outlineVariant;
      iconColor = colorScheme.onSurfaceVariant;
    }

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isCurrent || isCompleted
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(int afterStep, int total, ColorScheme colorScheme) {
    final isCompleted = _currentStep > afterStep;
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green : colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildCurrentStep(ColorScheme colorScheme) {
    switch (_currentStep) {
      case 0:
        return _buildNotificationStep(colorScheme);
      case 1:
        return _buildBatteryStep(colorScheme);
      case 2:
        return _buildAutoStartStep(colorScheme);
      default:
        return _buildCompletedStep(colorScheme);
    }
  }

  Widget _buildNotificationStep(ColorScheme colorScheme) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _hasNotificationPermission
                ? Icons.check_circle
                : Icons.notifications,
            size: 56,
            color:
                _hasNotificationPermission ? Colors.green : colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _hasNotificationPermission
              ? 'Notification Access Enabled'
              : 'Enable Notification Access',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          _hasNotificationPermission
              ? 'Great! You can receive transaction notifications.'
              : 'We need permission to read transaction notifications from your payment apps.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildInfoCard(
          icon: Icons.security,
          title: 'Secure & Private',
          description:
              'We only read notifications from selected payment apps. No personal data leaves your device.',
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          icon: Icons.speed,
          title: 'Auto-Detection',
          description:
              'Transactions are automatically detected and added after your confirmation.',
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  Widget _buildBatteryStep(ColorScheme colorScheme) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _hasBatteryOptimization ? Icons.check_circle : Icons.battery_alert,
            size: 56,
            color: _hasBatteryOptimization ? Colors.green : Colors.orange,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _hasBatteryOptimization
              ? 'Battery Optimization Disabled'
              : 'Disable Battery Optimization',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          _hasBatteryOptimization
              ? 'Excellent! Background detection is enabled.'
              : 'To detect transactions in the background, please disable battery optimization.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildInfoCard(
          icon: Icons.info_outline,
          title: 'Why this is needed',
          description:
              'Android restricts apps from running in background. Disabling optimization ensures consistent transaction detection.',
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          icon: Icons.battery_charging_full,
          title: 'Minimal impact',
          description:
              'Our app uses very little battery. The impact on your device is negligible.',
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  Widget _buildAutoStartStep(ColorScheme colorScheme) {
    final instructions = OemInstructions.getInstructions(_deviceManufacturer);

    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.power_settings_new,
            size: 56,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Enable Auto-Start',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Your device (${_getManufacturerName()}) requires additional settings to run apps in background.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        if (instructions != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.phone_android, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      instructions.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...instructions.steps.asMap().entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ] else ...[
          _buildInfoCard(
            icon: Icons.phone_android,
            title: 'General Settings',
            description:
                'Go to Settings → Apps → Expenses → Battery and enable background activity.',
            colorScheme: colorScheme,
          ),
        ],
      ],
    );
  }

  Widget _buildCompletedStep(ColorScheme colorScheme) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            size: 80,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'All Set!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Your app is configured to automatically detect and track transactions.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildInfoCard(
          icon: Icons.notifications_active,
          title: 'Transaction Alerts',
          description:
              'Make a payment with Google Pay, PhonePe, or Paytm to see automatic tracking in action.',
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          icon: Icons.undo,
          title: 'Undo Available',
          description:
              'Each auto-added transaction can be undone within 5 seconds using the snackbar.',
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (_currentStep == 0) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _openNotificationSettings();
                  await Future.delayed(const Duration(milliseconds: 1000));
                  await _checkAllPermissions();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _hasNotificationPermission
                      ? 'Continue'
                      : 'Enable Notification Access',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _skipOnboarding,
              child: Text(
                'Skip for now',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ] else if (_currentStep == 1) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _requestBatteryExemption();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _hasBatteryOptimization
                      ? 'Continue'
                      : 'Disable Battery Optimization',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ] else if (_currentStep == 2 && _needsAutoStart) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _openAutoStartSettings();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Open Auto-Start Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _currentStep = 3;
                });
              },
              child: Text(
                'I\'ve configured the settings',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _completeOnboarding,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Start Tracking',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getManufacturerName() {
    final manufacturer = _deviceManufacturer.toLowerCase();

    final names = {
      'xiaomi': 'Xiaomi/MIUI',
      'redmi': 'Xiaomi/Redmi',
      'samsung': 'Samsung',
      'huawei': 'Huawei',
      'honor': 'Honor',
      'oppo': 'OPPO',
      'realme': 'Realme',
      'vivo': 'Vivo',
      'oneplus': 'OnePlus',
      'asus': 'ASUS',
      'nokia': 'Nokia',
    };

    for (final entry in names.entries) {
      if (manufacturer.contains(entry.key)) {
        return entry.value;
      }
    }

    return _deviceManufacturer.isNotEmpty
        ? '${_deviceManufacturer[0].toUpperCase()}${_deviceManufacturer.substring(1)}'
        : 'Android';
  }
}

Future<bool> showNotificationOnboarding(BuildContext context) async {
  final box = Hive.box('app_box');
  final completed =
      box.get('notification_onboarding_completed', defaultValue: false);

  if (completed == true) {
    return false;
  }

  if (!Platform.isAndroid) {
    return false;
  }

  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => const NotificationOnboardingView(),
    ),
  );

  return result ?? false;
}
