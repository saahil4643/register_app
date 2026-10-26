import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/features/invoices/models/invoice_item.dart';
import 'package:app/features/products/models/product.dart';
import 'package:app/features/customers/models/customer.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Invoice Financial Calculations Tests', () {
    test('Calculates item subtotal, tax and total correctly', () {
      final product = Product(
        id: 'PROD-1',
        name: 'Item A',
        sku: 'SKU-001',
        barcode: '123456',
        category: 'General',
        brand: 'BrandX',
        purchasePrice: 50.0,
        sellingPrice: 100.0,
        stock: 20,
        minStock: 5,
        gst: 18.0,
        unitAbbreviation: 'Pcs',
        createdAt: DateTime.now(),
      );

      final item = InvoiceItem(
        id: 'item-1',
        product: product,
        quantity: 2,
        unitPrice: 100.0,
        taxPercentage: 18.0,
      );

      // 2 * 100 = 200 subtotal
      expect(item.subtotal, 200.0);
      // 18% of 200 = 36.0 tax
      expect(item.taxAmount, 36.0);
      // 200 + 36 = 236.0 total
      expect(item.total, 236.0);
    });

    test('Handles quantity updates via copyWith', () {
      final product = Product(
        id: 'PROD-2',
        name: 'Item B',
        sku: 'SKU-002',
        barcode: '',
        category: '',
        brand: '',
        purchasePrice: 10.0,
        sellingPrice: 50.0,
        stock: 10,
        minStock: 1,
        gst: 0.0,
        unitAbbreviation: 'Pcs',
        createdAt: DateTime.now(),
      );

      final item = InvoiceItem(
        id: 'item-2',
        product: product,
        quantity: 1,
        unitPrice: 50.0,
        taxPercentage: 0.0,
      );

      final updated = item.copyWith(quantity: 5);
      expect(updated.quantity, 5);
      expect(updated.total, 250.0);
    });

    test('Creates Service and Goods items properly', () {
      final serviceProduct = Product(
        id: 'SRV-1',
        name: 'Website Consulting',
        sku: 'SRV-001',
        productType: 'service',
        category: 'Services',
        sellingPrice: 2500.0,
        stock: 0,
        minStock: 0,
        trackInventory: false,
        gst: 18.0,
        createdAt: DateTime.now(),
      );

      expect(serviceProduct.productType, 'service');
      expect(serviceProduct.trackInventory, false);
      expect(serviceProduct.sellingPrice, 2500.0);
    });

    test('Customer model instantiates with business details', () {
      final customer = Customer(
        id: 'CUST-1',
        customerType: 'business',
        displayName: 'Acme Corp',
        companyName: 'Acme Corporation Pvt Ltd',
        primaryPhone: '+91 9876543210',
        email: 'billing@acme.com',
        gstNumber: '29ABCDE1234F1Z5',
        billingCity: 'Bengaluru',
        paymentTerms: 'Net 30',
        createdAt: DateTime.now(),
      );

      expect(customer.customerType, 'business');
      expect(customer.displayName, 'Acme Corp');
      expect(customer.gstNumber, '29ABCDE1234F1Z5');
      expect(customer.paymentTerms, 'Net 30');
    });
  });
}
