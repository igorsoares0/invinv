import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/clients/screens/clients_screen.dart';
import '../../features/clients/screens/client_form_screen.dart';
import '../../features/clients/screens/client_details_screen.dart';
import '../../features/products/screens/products_screen.dart';
import '../../features/products/screens/product_form_screen.dart';
import '../../features/invoices/screens/invoices_screen.dart';
import '../../features/invoices/screens/invoice_form_screen.dart';
import '../../features/invoices/screens/invoice_details_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../shared/models/models.dart';
import '../app.dart';

class AppRoutes {
  static const String home = '/';
  static const String clients = '/clients';
  static const String clientForm = '/clients/form';
  static const String clientDetails = '/clients/details';
  static const String products = '/products';
  static const String productForm = '/products/form';
  static const String invoices = '/invoices';
  static const String settings = '/settings';

  static final GoRouter router = GoRouter(
    initialLocation: home,
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: home,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: clients,
            builder: (context, state) => const ClientsScreen(),
          ),
          GoRoute(
            path: clientForm,
            builder: (context, state) {
              final clientId = state.extra as int?;
              return ClientFormScreen(
                client: clientId != null ? null : null, // TODO: Load client by ID
              );
            },
          ),
          GoRoute(
            path: '$clientDetails/:id',
            builder: (context, state) {
              final clientId = int.parse(state.pathParameters['id']!);
              return ClientDetailsScreen(clientId: clientId);
            },
          ),
          GoRoute(
            path: products,
            builder: (context, state) => const ProductsScreen(),
          ),
          GoRoute(
            path: productForm,
            builder: (context, state) {
              final productId = state.extra as int?;
              return ProductFormScreen(
                product: productId != null ? null : null, // TODO: Load product by ID
              );
            },
          ),
          GoRoute(
            path: invoices,
            builder: (context, state) => const InvoicesScreen(),
          ),
          GoRoute(
            path: '/invoices/form',
            builder: (context, state) {
              final type = state.extra as InvoiceType? ?? InvoiceType.invoice;
              return InvoiceFormScreen(type: type);
            },
          ),
          GoRoute(
            path: '/invoices/details/:id',
            builder: (context, state) {
              final invoiceId = int.parse(state.pathParameters['id']!);
              return InvoiceDetailsScreen(invoiceId: invoiceId);
            },
          ),
          GoRoute(
            path: settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}