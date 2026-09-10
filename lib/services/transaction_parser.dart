import '../models/notification_model.dart';
import '../models/transaction_model.dart';

class TransactionParser {
  // =========================================================
  // PARSE NOTIFIKASI
  // =========================================================

  static TransactionModel? parse(
    NotificationModel notification,
  ) {
    // Gabungkan title + text
    final originalText =
        '${notification.title} ${notification.text}';

    // Versi lowercase untuk pencarian keyword
    final text = originalText.toLowerCase();

    // =======================================================
    // 1. DETEKSI NOMINAL
    // =======================================================

    final amount = _extractAmount(text);

    // Kalau tidak ada nominal, bukan transaksi
    if (amount == null) {
      return null;
    }

    // =======================================================
    // 2. DETEKSI TIPE
    // =======================================================

    final type = _detectTransactionType(text);

    // Kalau tidak diketahui income / expense,
    // jangan dianggap transaksi
    if (type == null) {
      return null;
    }

    // =======================================================
    // 3. DETEKSI SUMBER
    // =======================================================

    final source = _detectSource(notification);

    // =======================================================
    // 4. DETEKSI PENGIRIM
    // =======================================================

    final sender = _extractSender(
      originalText,
      source,
      type,
    );

    // =======================================================
    // 5. BUAT MODEL TRANSAKSI
    // =======================================================

    return TransactionModel(
      source: source,
      type: type,
      amount: amount,
      description: notification.text,
      timestamp: notification.timestamp,
      sender: sender,
    );
  }

  // =========================================================
  // DETEKSI JUMLAH UANG
  // =========================================================

  static int? _extractAmount(String text) {
    /*
      Contoh yang bisa dibaca:

      Rp1
      Rp 1
      Rp10.000
      Rp10.000,00
      Rp 10.000,00
      Rp1.500.000
    */

    final regex = RegExp(
      r'rp\s*([0-9][0-9.]*(?:,[0-9]+)?)',
      caseSensitive: false,
    );

    final match = regex.firstMatch(text);

    if (match == null) {
      return null;
    }

    final amountText = match.group(1);

    if (amountText == null || amountText.isEmpty) {
      return null;
    }

    // =======================================================
    // Ambil bagian sebelum koma
    //
    // 10.000,00
    //      ↓
    // 10.000
    // =======================================================

    final integerPart = amountText.split(',').first;

    // =======================================================
    // Hilangkan titik
    //
    // 10.000
    //      ↓
    // 10000
    // =======================================================

    final cleanAmount = integerPart.replaceAll('.', '');

    return int.tryParse(cleanAmount);
  }

  // =========================================================
  // DETEKSI TIPE TRANSAKSI
  // =========================================================

  static String? _detectTransactionType(String text) {
    // =======================================================
    // UANG MASUK
    // =======================================================

    final incomeKeywords = [
      'transfer masuk',
      'uang masuk',
      'dana masuk',
      'menerima transfer',
      'menerima uang',
      'menerima dana',
      'diterima',
      'telah diterima',
      'saldo bertambah',
      'saldo masuk',
      'top up',
      'topup',
      'isi saldo',
      'pengisian saldo',
      'berhasil top up',
      'transfer diterima',
      'masuk ke rekening',
      'saldo diterima',
      'dana diterima',
      'berhasil menerima',
    ];

    for (final keyword in incomeKeywords) {
      if (text.contains(keyword)) {
        return 'income';
      }
    }

    // =======================================================
    // UANG KELUAR
    // =======================================================

    final expenseKeywords = [
      'transfer ke',
      'dana keluar',
      'uang keluar',
      'saldo berkurang',
      'tarik tunai',
      'withdraw',
      'berhasil membayar',
      'berhasil melakukan pembayaran',
      'pembayaran berhasil',
      'pembayaran',
      'bayar',
      'pembelian',
      'membeli',
      'payment',
      'telah dibayar',
      'berhasil transfer',
      'dikenakan biaya',
      'biaya admin',
      'biaya administrasi',
      'penarikan',
      'transaksi keluar',
    ];

    for (final keyword in expenseKeywords) {
      if (text.contains(keyword)) {
        return 'expense';
      }
    }

    return null;
  }

  // =========================================================
  // DETEKSI SUMBER
  // =========================================================

  static String _detectSource(
    NotificationModel notification,
  ) {
    final package =
        notification.packageName.toLowerCase();

    final title =
        notification.title.toLowerCase();

    final notificationText =
        notification.text.toLowerCase();

    // Gabungkan semuanya
    final combined =
        '$package $title $notificationText';

    // =======================================================
    // DANA
    // =======================================================

    if (combined.contains('dana')) {
      return 'DANA';
    }

    // =======================================================
    // SHOPEEPAY
    // =======================================================

    if (combined.contains('shopeepay')) {
      return 'ShopeePay';
    }

    // Beberapa notifikasi ShopeePay mungkin hanya
    // menggunakan kata Shopee.
    if (combined.contains('shopee') &&
        (
          combined.contains('saldo') ||
          combined.contains('top up') ||
          combined.contains('topup') ||
          combined.contains('diterima') ||
          combined.contains('pembayaran')
        )) {
      return 'ShopeePay';
    }

    // =======================================================
    // BRIMO / BRI
    // =======================================================

    if (combined.contains('brimo') ||
        combined.contains('bank bri') ||
        combined.contains('bri')) {
      return 'BRI';
    }

    // =======================================================
    // BCA
    // =======================================================

    if (combined.contains('bca')) {
      return 'BCA';
    }

    // =======================================================
    // MANDIRI
    // =======================================================

    if (combined.contains('mandiri')) {
      return 'Mandiri';
    }

    // =======================================================
    // GOPAY
    // =======================================================

    if (combined.contains('gopay') ||
        combined.contains('go-pay') ||
        combined.contains('go pay')) {
      return 'GoPay';
    }

    // =======================================================
    // OVO
    // =======================================================

    if (combined.contains('ovo')) {
      return 'OVO';
    }

    // =======================================================
    // LINKAJA
    // =======================================================

    if (combined.contains('linkaja') ||
        combined.contains('link aja')) {
      return 'LinkAja';
    }

    // =======================================================
    // LAZADA
    // =======================================================

    if (combined.contains('lazada')) {
      return 'Lazada';
    }

    // =======================================================
    // WHATSAPP
    // =======================================================

    if (package.contains('whatsapp') ||
        combined.contains('whatsapp')) {
      return 'WhatsApp';
    }

    // =======================================================
    // FALLBACK
    // =======================================================

    if (notification.title.isNotEmpty) {
      return notification.title;
    }

    return notification.packageName;
  }

  // =========================================================
  // DETEKSI PENGIRIM
  // =========================================================

  static String _extractSender(
    String text,
    String source,
    String type,
  ) {
    // =======================================================
    // DANA - UANG MASUK
    //
    // Contoh:
    //
    // DANA Rp1 telah diterima dari
    // ADINDA AULIA SABRINA ARUMSARI 💰
    //
    // Hasil:
    //
    // ADINDA AULIA SABRINA ARUMSARI
    // =======================================================

    if (source == 'DANA' && type == 'income') {
      final regex = RegExp(
        r'diterima\s+dari\s+(.+?)(?:\s*💰|$)',
        caseSensitive: false,
      );

      final match = regex.firstMatch(text);

      if (match != null) {
        return _cleanSender(
          match.group(1) ?? '',
        );
      }
    }

    // =======================================================
    // SHOPEEPAY - UANG MASUK
    //
    // Contoh:
    //
    // Saldo ShopeePay Diterima Rp1 telah diterima
    // dari Septiyan Adam Maulana.
    //
    // Hasil:
    //
    // Septiyan Adam Maulana
    // =======================================================

    if (source == 'ShopeePay' && type == 'income') {
      final regex = RegExp(
        r'dari\s+(.+?)(?:\.|$)',
        caseSensitive: false,
      );

      final match = regex.firstMatch(text);

      if (match != null) {
        return _cleanSender(
          match.group(1) ?? '',
        );
      }
    }

    // =======================================================
    // BRI - TRANSFER
    //
    // Contoh:
    //
    // Transfer dari XXXXXXXXXX0508 dengan nomor
    // rekening tujuan XXXXXXXXXX3507 sebesar
    // Rp10.000,00 BERHASIL.
    //
    // Hasil:
    //
    // XXXXXXXXXX0508
    // =======================================================

    if (source == 'BRI') {
      final regex = RegExp(
        r'transfer\s+dari\s+(.+?)\s+dengan',
        caseSensitive: false,
      );

      final match = regex.firstMatch(text);

      if (match != null) {
        return _cleanSender(
          match.group(1) ?? '',
        );
      }
    }

    // =======================================================
    // FALLBACK
    // =======================================================

    return '';
  }

  // =========================================================
  // MEMBERSIHKAN NAMA PENGIRIM
  // =========================================================

  static String _cleanSender(String sender) {
    var result = sender.trim();

    // Hapus emoji uang
    result = result.replaceAll('💰', '');

    // Hapus beberapa emoji umum
    result = result.replaceAll('💸', '');
    result = result.replaceAll('🤑', '');

    // Hapus titik di akhir
    result = result.replaceFirst(
      RegExp(r'\.$'),
      '',
    );

    // Hapus spasi berlebih
    result = result.replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    return result.trim();
  }
}