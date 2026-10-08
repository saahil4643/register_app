import 'package:flutter/foundation.dart';
import 'api_service.dart';

class GstTaxpayerInfo {
  final String gstin;
  final String stateCode;
  final String pan;
  final String legalName;
  final String tradeName;
  final String status;
  final String taxpayerType;
  final String constitutionOfBusiness;
  final String registrationDate;
  final String address;
  final String fetchedAt;
  final String source;

  GstTaxpayerInfo({
    required this.gstin,
    this.stateCode = '',
    this.pan = '',
    this.legalName = '',
    this.tradeName = '',
    this.status = '',
    this.taxpayerType = '',
    this.constitutionOfBusiness = '',
    this.registrationDate = '',
    this.address = '',
    this.fetchedAt = '',
    this.source = '',
  });

  factory GstTaxpayerInfo.fromJson(Map<String, dynamic> json) {
    return GstTaxpayerInfo(
      gstin: json['gstin']?.toString() ?? '',
      stateCode: json['stateCode']?.toString() ?? json['state_code']?.toString() ?? '',
      pan: json['pan']?.toString() ?? '',
      legalName: json['legalName']?.toString() ?? json['legal_name']?.toString() ?? '',
      tradeName: json['tradeName']?.toString() ?? json['trade_name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      taxpayerType: json['taxpayerType']?.toString() ?? json['taxpayer_type']?.toString() ?? '',
      constitutionOfBusiness: json['constitutionOfBusiness']?.toString() ?? json['constitution_of_business']?.toString() ?? '',
      registrationDate: json['registrationDate']?.toString() ?? json['registration_date']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      fetchedAt: json['fetchedAt']?.toString() ?? json['fetched_at']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
    );
  }
}

class GstService {
  static final GstService _instance = GstService._internal();
  factory GstService() => _instance;
  GstService._internal();

  static const Map<String, String> stateCodes = {
    '01': 'Jammu & Kashmir',
    '02': 'Himachal Pradesh',
    '03': 'Punjab',
    '04': 'Chandigarh',
    '05': 'Uttarakhand',
    '06': 'Haryana',
    '07': 'Delhi',
    '08': 'Rajasthan',
    '09': 'Uttar Pradesh',
    '10': 'Bihar',
    '11': 'Sikkim',
    '12': 'Arunachal Pradesh',
    '13': 'Nagaland',
    '14': 'Manipur',
    '15': 'Mizoram',
    '16': 'Tripura',
    '17': 'Meghalaya',
    '18': 'Assam',
    '19': 'West Bengal',
    '20': 'Jharkhand',
    '21': 'Odisha',
    '22': 'Chhattisgarh',
    '23': 'Madhya Pradesh',
    '24': 'Gujarat',
    '26': 'Dadra & Nagar Haveli and Daman & Diu',
    '27': 'Maharashtra',
    '29': 'Karnataka',
    '30': 'Goa',
    '31': 'Lakshadweep',
    '32': 'Kerala',
    '33': 'Tamil Nadu',
    '34': 'Puducherry',
    '35': 'Andaman & Nicobar Islands',
    '36': 'Telangana',
    '37': 'Andhra Pradesh',
    '38': 'Ladakh',
  };

  /// Fetches taxpayer details from GET /api/v1/gst/{gstin}
  Future<GstTaxpayerInfo?> fetchTaxpayer(String gstin, {bool refresh = false}) async {
    final clean = gstin.trim().toUpperCase();
    if (clean.isEmpty) return null;

    try {
      final query = refresh ? '?refresh=true' : '';
      final response = await ApiService().get('/api/v1/gst/$clean$query');

      Map<String, dynamic> data = response;
      if (response['data'] is Map<String, dynamic>) {
        data = response['data'] as Map<String, dynamic>;
      }

      if (data.containsKey('legalName') || data.containsKey('tradeName') || data.containsKey('gstin')) {
        return GstTaxpayerInfo.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching GST taxpayer: $e');
      return null;
    }
  }

  /// Validates GSTIN checksum and format from GET /api/v1/gst/{gstin}/validate
  Future<Map<String, dynamic>?> validateGstin(String gstin) async {
    final clean = gstin.trim().toUpperCase();
    if (clean.isEmpty) return null;

    try {
      final response = await ApiService().get('/api/v1/gst/$clean/validate');
      if (response['data'] is Map<String, dynamic>) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    } catch (e) {
      debugPrint('Error validating GSTIN: $e');
      return null;
    }
  }

  static String getStateFromCode(String code) {
    return stateCodes[code] ?? '';
  }
}
