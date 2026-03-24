import '../models/invoice.dart';
import '../models/quote.dart';
import '../models/service_request.dart';
import '../models/visit.dart';
import 'customer_service.dart';
import 'invoice_service.dart';
import 'quote_service.dart';
import 'service_request_service.dart';
import 'visit_service.dart';

class CustomerDeleteImpact {
  final List<Invoice> invoices;
  final List<ServiceVisit> visits;
  final List<Quote> quotes;
  final List<ServiceRequest> serviceRequests;

  const CustomerDeleteImpact({
    required this.invoices,
    required this.visits,
    required this.quotes,
    required this.serviceRequests,
  });

  int get invoiceCount => invoices.length;
  int get visitCount => visits.length;
  int get quoteCount => quotes.length;
  int get serviceRequestCount => serviceRequests.length;
  int get totalDependencies =>
      invoiceCount + visitCount + quoteCount + serviceRequestCount;
  bool get hasDependencies => totalDependencies > 0;
}

class CustomerDeleteService {
  final _customerService = CustomerService();
  final _invoiceService = InvoiceService();
  final _visitService = VisitService();
  final _quoteService = QuoteService();
  final _serviceRequestService = ServiceRequestService();

  Future<CustomerDeleteImpact> inspect(int customerId) async {
    final snapshot = await _loadSnapshot(customerId);
    return CustomerDeleteImpact(
      invoices: snapshot.invoices,
      visits: snapshot.visits,
      quotes: snapshot.quotes,
      serviceRequests: snapshot.serviceRequests,
    );
  }

  Future<CustomerDeleteImpact> deleteCascade(int customerId) async {
    final snapshot = await _loadSnapshot(customerId);

    for (final invoice in snapshot.invoices) {
      await _invoiceService.delete(invoice.id);
    }
    for (final visit in snapshot.visits) {
      await _visitService.delete(visit.id);
    }
    for (final quote in snapshot.quotes) {
      await _quoteService.delete(quote.id);
    }
    for (final request in snapshot.serviceRequests) {
      await _serviceRequestService.delete(request.id);
    }

    await _customerService.delete(customerId);

    return CustomerDeleteImpact(
      invoices: snapshot.invoices,
      visits: snapshot.visits,
      quotes: snapshot.quotes,
      serviceRequests: snapshot.serviceRequests,
    );
  }

  Future<_CustomerDependencySnapshot> _loadSnapshot(int customerId) async {
    final results = await Future.wait([
      _invoiceService.list(),
      _visitService.list(),
      _quoteService.list(),
      _serviceRequestService.list(),
    ]);

    final invoices = (results[0] as List<Invoice>)
        .where((item) => item.customerId == customerId)
        .toList();
    final visits = (results[1] as List<ServiceVisit>)
        .where((item) => item.customerId == customerId)
        .toList();
    final quotes = (results[2] as List<Quote>)
        .where((item) => item.customerId == customerId)
        .toList();
    final serviceRequests = (results[3] as List<ServiceRequest>)
        .where((item) => item.customerId == customerId)
        .toList();

    return _CustomerDependencySnapshot(
      invoices: invoices,
      visits: visits,
      quotes: quotes,
      serviceRequests: serviceRequests,
    );
  }
}

class _CustomerDependencySnapshot {
  final List<Invoice> invoices;
  final List<ServiceVisit> visits;
  final List<Quote> quotes;
  final List<ServiceRequest> serviceRequests;

  const _CustomerDependencySnapshot({
    required this.invoices,
    required this.visits,
    required this.quotes,
    required this.serviceRequests,
  });
}
