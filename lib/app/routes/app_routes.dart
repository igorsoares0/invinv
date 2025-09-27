import 'package:go_router/go_router.dart';
import '../../features/clients/screens/clients_screen.dart';
import '../../features/clients/screens/client_form_screen.dart';
import '../../features/products/screens/products_screen.dart';
import '../../features/products/screens/product_form_screen.dart';
import '../../features/invoices/screens/invoices_screen.dart';
import '../../features/invoices/screens/invoice_form_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../shared/models/models.dart';
import '../app.dart';

class AppRoutes {
  static const String home = '/';
  static const String clients = '/clients';
  static const String clientForm = '/clients/form';
  static const String products = '/products';
  static const String productForm = '/products/form';
  static const String invoices = '/invoices';
  static const String settings = '/settings';

  static final GoRouter router = GoRouter(
    initialLocation: invoices,
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: home,
            builder: (context, state) => const InvoicesScreen(),
          ),
          GoRoute(
            path: clients,
            builder: (context, state) => const ClientsScreen(),
          ),
          GoRoute(
            path: clientForm,
            builder: (context, state) {
              return ClientFormScreen(
                client: null,
              );
            },
          ),
          GoRoute(
            path: products,
            builder: (context, state) => const ProductsScreen(),
          ),
          GoRoute(
            path: productForm,
            builder: (context, state) {
              return ProductFormScreen(
                product: null,
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
            path: settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}