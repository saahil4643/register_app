class NumberToWords {
  static const List<String> _units = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen'
  ];

  static const List<String> _tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety'
  ];

  /// Converts a numeric amount to Indian currency words format.
  /// E.g., 105.50 => "One Hundred Five Rupees and Fifty Paise Only"
  static String convert(double amount) {
    if (amount <= 0) {
      return 'Zero Rupees Only';
    }

    final int rupees = amount.floor();
    final int paise = ((amount - rupees) * 100).round();

    final String rupeesStr = _convertInteger(rupees);
    final String rupeeUnit = rupees == 1 ? 'Rupee' : 'Rupees';

    if (paise > 0) {
      final String paiseStr = _convertInteger(paise);
      return '$rupeesStr $rupeeUnit and $paiseStr Paise Only';
    } else {
      return '$rupeesStr $rupeeUnit Only';
    }
  }

  static String _convertInteger(int n) {
    if (n == 0) return '';
    if (n < 20) return _units[n];
    if (n < 100) {
      final String unitStr = n % 10 != 0 ? ' ${_units[n % 10]}' : '';
      return '${_tens[n ~/ 10]}$unitStr';
    }
    if (n < 1000) {
      final String rem = n % 100 != 0 ? ' ${_convertInteger(n % 100)}' : '';
      return '${_units[n ~/ 100]} Hundred$rem';
    }
    if (n < 100000) {
      final String rem = n % 1000 != 0 ? ' ${_convertInteger(n % 1000)}' : '';
      return '${_convertInteger(n ~/ 1000)} Thousand$rem';
    }
    if (n < 10000000) {
      final String rem = n % 100000 != 0 ? ' ${_convertInteger(n % 100000)}' : '';
      return '${_convertInteger(n ~/ 100000)} Lakh$rem';
    }
    final String rem = n % 10000000 != 0 ? ' ${_convertInteger(n % 10000000)}' : '';
    return '${_convertInteger(n ~/ 10000000)} Crore$rem';
  }
}
