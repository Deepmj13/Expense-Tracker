class Country {
  final String name;
  final String code;
  final String currency;
  final String currencySymbol;

  const Country({
    required this.name,
    required this.code,
    required this.currency,
    required this.currencySymbol,
  });

  static const List<Country> countries = [
    Country(name: 'India', code: 'IN', currency: 'INR', currencySymbol: '₹'),
    Country(
        name: 'United States',
        code: 'US',
        currency: 'USD',
        currencySymbol: '\$'),
    Country(
        name: 'United Kingdom',
        code: 'UK',
        currency: 'GBP',
        currencySymbol: '£'),
    Country(
        name: 'European Union',
        code: 'EU',
        currency: 'EUR',
        currencySymbol: '€'),
    Country(name: 'Japan', code: 'JP', currency: 'JPY', currencySymbol: '¥'),
    Country(name: 'Canada', code: 'CA', currency: 'CAD', currencySymbol: 'C\$'),
    Country(
        name: 'Australia', code: 'AU', currency: 'AUD', currencySymbol: 'A\$'),
    Country(
        name: 'Singapore', code: 'SG', currency: 'SGD', currencySymbol: 'S\$'),
  ];
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.country,
    required this.currencySymbol,
    this.sessionToken,
  });

  final String id;
  final String name;
  final String email;
  final String country;
  final String currencySymbol;
  final String? sessionToken;

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? country,
    String? currencySymbol,
    String? sessionToken,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      country: country ?? this.country,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      sessionToken: sessionToken ?? this.sessionToken,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'country': country,
        'currencySymbol': currencySymbol,
        'sessionToken': sessionToken,
      };

  factory AppUser.fromMap(Map<dynamic, dynamic> map) => AppUser(
        id: map['id'] as String,
        name: map['name'] as String,
        email: map['email'] as String,
        country: map['country'] as String? ?? 'India',
        currencySymbol: map['currencySymbol'] as String? ?? '₹',
        sessionToken: map['sessionToken'] as String?,
      );
}
