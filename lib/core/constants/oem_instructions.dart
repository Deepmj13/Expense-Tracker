class OemInstruction {
  const OemInstruction({
    required this.title,
    required this.steps,
    this.imageHint,
  });

  final String title;
  final List<String> steps;
  final String? imageHint;
}

class OemInstructions {
  OemInstructions._();

  static OemInstruction? getInstructions(String manufacturer) {
    final lowerManufacturer = manufacturer.toLowerCase();

    if (lowerManufacturer.contains('xiaomi') ||
        lowerManufacturer.contains('redmi')) {
      return const OemInstruction(
        title: 'MIUI Auto-Start Settings',
        steps: [
          'Go to Settings → Apps → Manage Apps',
          'Find and tap on "Expenses" app',
          'Tap on "Autostart" and enable it',
          'Go to Settings → Battery & Performance',
          'Tap on "App battery saver"',
          'Select "Expenses" and choose "No restrictions"',
        ],
      );
    }

    if (lowerManufacturer.contains('samsung')) {
      return const OemInstruction(
        title: 'Samsung Background Restrictions',
        steps: [
          'Go to Settings → Apps → Expenses',
          'Tap on "Battery"',
          'Select "Unrestricted" to allow background activity',
          'Go back and tap on "Mobile data"',
          'Ensure "Allow background data usage" is enabled',
        ],
      );
    }

    if (lowerManufacturer.contains('huawei') ||
        lowerManufacturer.contains('honor')) {
      return const OemInstruction(
        title: 'Huawei/Honor Protected Apps',
        steps: [
          'Open Phone Manager app',
          'Tap on "Optimize battery usage"',
          'Find "Expenses" in the list',
          'Tap on it and select "Don\'t restrict"',
          'Go back to Phone Manager → Startup Manager',
          'Enable auto-start for "Expenses"',
        ],
      );
    }

    if (lowerManufacturer.contains('oppo') ||
        lowerManufacturer.contains('realme')) {
      return const OemInstruction(
        title: 'OPPO/Realme Auto-Start',
        steps: [
          'Go to Settings → App Management',
          'Find and tap on "Expenses"',
          'Tap on "Battery usage" → "Allow background activity"',
          'Go to Settings → Battery',
          'Tap on "Expenses" and enable "Allow background running"',
        ],
      );
    }

    if (lowerManufacturer.contains('vivo')) {
      return const OemInstruction(
        title: 'Vivo Background Activity',
        steps: [
          'Go to Settings → Battery',
          'Tap on "Background power consumption management"',
          'Find "Expenses" and enable it',
          'Go to Settings → Apps & Permissions',
          'Find "Expenses" → "Allow autostart"',
        ],
      );
    }

    if (lowerManufacturer.contains('oneplus')) {
      return const OemInstruction(
        title: 'OnePlus Battery Optimization',
        steps: [
          'Go to Settings → Battery → Battery Optimization',
          'Tap the three dots → "Advanced Optimization"',
          'Disable optimization for "Expenses"',
          'Go to Settings → Apps → Expenses → Battery',
          'Select "Don\'t optimize" or "No restrictions"',
        ],
      );
    }

    if (lowerManufacturer.contains('asus')) {
      return const OemInstruction(
        title: 'ASUS Auto-Start',
        steps: [
          'Open the pre-installed "Auto-start Manager" app',
          'Find "Expenses" in the list',
          'Enable the toggle for auto-start',
          'Go to Settings → Battery → "Expenses"',
          'Select "No restrictions" for background activity',
        ],
      );
    }

    if (lowerManufacturer.contains('letv') ||
        lowerManufacturer.contains('leeco')) {
      return const OemInstruction(
        title: 'LeEco Auto-Start',
        steps: [
          'Open "LeEco Security" app',
          'Tap on "Autoboot Manager"',
          'Enable auto-start for "Expenses"',
          'Go to Settings → Battery → "Expenses"',
          'Select "No restrictions"',
        ],
      );
    }

    if (lowerManufacturer.contains('nokia')) {
      return const OemInstruction(
        title: 'Nokia Battery Settings',
        steps: [
          'Go to Settings → Apps → Expenses',
          'Tap on "Battery"',
          'Select "Don\'t optimize"',
          'Go to Settings → Battery → "Expenses"',
          'Enable "Allow background activity"',
        ],
      );
    }

    return null;
  }

  static bool needsAutoStartSettings(String manufacturer) {
    final lowerManufacturer = manufacturer.toLowerCase();
    final restrictedOems = [
      'xiaomi',
      'redmi',
      'huawei',
      'honor',
      'oppo',
      'realme',
      'vivo',
      'samsung',
      'oneplus',
      'asus',
      'letv',
      'leeco',
      'nokia',
    ];
    return restrictedOems.any((oem) => lowerManufacturer.contains(oem));
  }
}
