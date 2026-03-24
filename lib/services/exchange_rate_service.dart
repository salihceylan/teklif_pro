import '../core/api_client.dart';
import '../models/exchange_rate_snapshot.dart';

class ExchangeRateService {
  Future<ExchangeRateSnapshot> getUsdTry() async {
    final res = await ApiClient.instance.get('/exchange-rates/usd-try');
    return ExchangeRateSnapshot.fromJson(res.data as Map<String, dynamic>);
  }
}
