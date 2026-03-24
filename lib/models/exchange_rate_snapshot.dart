class ExchangeRateSnapshot {
  final String baseCurrency;
  final String quoteCurrency;
  final double rate;
  final DateTime rateDate;
  final String source;

  const ExchangeRateSnapshot({
    required this.baseCurrency,
    required this.quoteCurrency,
    required this.rate,
    required this.rateDate,
    required this.source,
  });

  factory ExchangeRateSnapshot.fromJson(Map<String, dynamic> json) =>
      ExchangeRateSnapshot(
        baseCurrency: (json['base_currency'] ?? 'USD') as String,
        quoteCurrency: (json['quote_currency'] ?? 'TRY') as String,
        rate: ((json['rate'] as num?) ?? 0).toDouble(),
        rateDate: DateTime.parse(
          (json['rate_date'] ?? json['exchange_rate_date']) as String,
        ),
        source: (json['source'] ?? json['exchange_rate_source'] ?? 'TCMB')
            as String,
      );
}
