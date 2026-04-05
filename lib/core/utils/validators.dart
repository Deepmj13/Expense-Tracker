class Validators {
  static String? requiredField(String? value, {String field = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  static String? email(String? value) {
    final required = requiredField(value, field: 'Email');
    if (required != null) return required;
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(value!.trim())) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    final required = requiredField(value, field: 'Password');
    if (required != null) return required;
    if (value!.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? amount(String? value) {
    final required = requiredField(value, field: 'Amount');
    if (required != null) return required;
    final parsed = double.tryParse(value!);
    if (parsed == null || parsed <= 0) return 'Amount should be > 0';
    return null;
  }
}
