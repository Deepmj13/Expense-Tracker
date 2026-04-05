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
    required this.password,
    required this.country,
    required this.currencySymbol,
  });

  final String id;
  final String name;
  final String email;
  final String password;
  final String country;
  final String currencySymbol;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
        'country': country,
        'currencySymbol': currencySymbol,
      };

  factory AppUser.fromMap(Map<dynamic, dynamic> map) => AppUser(
        id: map['id'] as String,
        name: map['name'] as String,
        email: map['email'] as String,
        password: map['password'] as String,
        country: map['country'] as String? ?? 'India',
        currencySymbol: map['currencySymbol'] as String? ?? '₹',
      );
}
