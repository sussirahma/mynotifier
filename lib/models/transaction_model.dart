class TransactionModel {
  final String source;
  final String type;
  final int amount;
  final String description;
  final String timestamp;
  final String sender;

  TransactionModel({
    required this.source,
    required this.type,
    required this.amount,
    required this.description,
    required this.timestamp,
    this.sender = '',
  });

  // =========================================================
  // CEK TIPE TRANSAKSI
  // =========================================================

  bool get isIncome => type == 'income';

  bool get isExpense => type == 'expense';

  // =========================================================
  // FORMAT NOMINAL
  // =========================================================

  String get formattedAmount {
    return 'Rp${amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}';
  }
}