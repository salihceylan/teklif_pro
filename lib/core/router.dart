import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/home/company_home_screen.dart';
import '../screens/notifications/notification_settings_screen.dart';
import '../screens/customers/customers_screen.dart';
import '../screens/customers/customer_detail_screen.dart';
import '../screens/customers/customer_form_screen.dart';
import '../screens/service_requests/service_requests_screen.dart';
import '../screens/service_requests/service_request_detail_screen.dart';
import '../screens/service_requests/service_request_form_screen.dart';
import '../screens/quotes/quotes_screen.dart';
import '../screens/quotes/quote_detail_screen.dart';
import '../screens/quotes/quote_form_screen.dart';
import '../screens/visits/visits_screen.dart';
import '../screens/visits/visit_detail_screen.dart';
import '../screens/visits/visit_form_screen.dart';
import '../screens/invoices/invoices_screen.dart';
import '../screens/invoices/invoice_detail_screen.dart';
import '../screens/invoices/invoice_form_screen.dart';

GoRouter buildRouter(BuildContext context) {
  final auth = Provider.of<AuthProvider>(context, listen: false);

  return GoRouter(
    initialLocation: '/',
    redirect: (ctx, state) {
      final loggedIn = auth.isLoggedIn;
      final location = state.matchedLocation;
      final onAuth = location == '/login' || location == '/register';
      final isPublic = location == '/' || onAuth;

      if (!loggedIn && !isPublic) return '/login';
      if (loggedIn && onAuth) return '/panel';
      return null;
    },
    refreshListenable: auth,
    routes: [
      GoRoute(path: '/', builder: (_, _) => const CompanyHomeScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/panel', builder: (_, _) => const DashboardScreen()),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationSettingsScreen(),
      ),
      GoRoute(path: '/customers', builder: (_, _) => const CustomersScreen()),
      GoRoute(
        path: '/customers/new',
        builder: (_, s) =>
            CustomerFormScreen(returnTo: s.uri.queryParameters['returnTo']),
      ),
      GoRoute(
        path: '/customers/:id/edit',
        builder: (_, s) => CustomerFormScreen(
          customerId: int.parse(s.pathParameters['id']!),
          returnTo: s.uri.queryParameters['returnTo'],
        ),
      ),
      GoRoute(
        path: '/customers/:id',
        builder: (_, s) => CustomerDetailScreen(
          customerId: int.parse(s.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/service-requests',
        builder: (_, _) => const ServiceRequestsScreen(),
      ),
      GoRoute(
        path: '/service-requests/new',
        builder: (_, _) => const ServiceRequestFormScreen(),
      ),
      GoRoute(
        path: '/service-requests/:id/edit',
        builder: (_, s) => ServiceRequestFormScreen(
          requestId: int.parse(s.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/service-requests/:id',
        builder: (_, s) => ServiceRequestDetailScreen(
          requestId: int.parse(s.pathParameters['id']!),
        ),
      ),
      GoRoute(path: '/quotes', builder: (_, _) => const QuotesScreen()),
      GoRoute(path: '/quotes/new', builder: (_, _) => const QuoteFormScreen()),
      GoRoute(
        path: '/quotes/:id/edit',
        builder: (_, s) =>
            QuoteFormScreen(quoteId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/quotes/:id',
        builder: (_, s) =>
            QuoteDetailScreen(quoteId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(path: '/visits', builder: (_, _) => const VisitsScreen()),
      GoRoute(path: '/visits/new', builder: (_, _) => const VisitFormScreen()),
      GoRoute(
        path: '/visits/:id/edit',
        builder: (_, s) =>
            VisitFormScreen(visitId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/visits/:id',
        builder: (_, s) =>
            VisitDetailScreen(visitId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(path: '/invoices', builder: (_, _) => const InvoicesScreen()),
      GoRoute(
        path: '/invoices/new',
        builder: (_, _) => const InvoiceFormScreen(),
      ),
      GoRoute(
        path: '/invoices/:id/edit',
        builder: (_, s) =>
            InvoiceFormScreen(invoiceId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/invoices/:id',
        builder: (_, s) =>
            InvoiceDetailScreen(invoiceId: int.parse(s.pathParameters['id']!)),
      ),
    ],
  );
}
