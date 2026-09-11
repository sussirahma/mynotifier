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
        '${notification.title} ${notification.text}'.trim();

    if (originalText.isEmpty) {
      return null;
    }

    final text = originalText.toLowerCase();

    // =========================================================
    // 1. DETEKSI SUMBER
    // =========================================================

    final source = _detectSource(notification);

    // =========================================================
    // 2. DETEKSI NOMINAL
    // =========================================================

    final amount = _extractAmount(text);

    if (amount == null || amount <= 0) {
      return null;
    }

    // =========================================================
    // 3. DETEKSI TIPE TRANSAKSI
    // =========================================================

    final type = _detectTransactionType(
      text,
      source,
    );

    if (type == null) {
      return null;
    }

    // =========================================================
    // 4. DETEKSI PENGIRIM
    // =========================================================

    final sender = _extractSender(
      originalText,
      source,
      type,
    );

    // =========================================================
    // 5. BUAT TRANSACTION MODEL
    // =========================================================

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
  // DETEKSI NOMINAL
  // =========================================================

  static int? _extractAmount(
    String text,
  ) {
    /*
      Contoh yang didukung:

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

    // Ambil bagian sebelum koma.
    final integerPart = amountText.split(',').first;

    // Hilangkan titik sebagai separator ribuan.
    final cleanAmount = integerPart.replaceAll(
      '.',
      '',
    );

    return int.tryParse(cleanAmount);
  }

  // =========================================================
  // DETEKSI TIPE TRANSAKSI
  // =========================================================

  static String? _detectTransactionType(
    String text,
    String source,
  ) {
    // =======================================================
    // KHUSUS BRI
    // =======================================================

    if (source == 'BRI') {
      // -------------------------------------------------------
      // BRI - UANG KELUAR
      // -------------------------------------------------------
      //
      // Contoh notif:
      //
      // Transfer dari XXXXX0508 dengan nomor rekening tujuan
      // XXXXX3507 sebesar Rp10.000,00 BERHASIL.
      //
      // Artinya rekening kita:
      //
      // XXXXX0508
      //      ↓
      // XXXXX3507
      //
      // Jadi transaksi adalah UANG KELUAR.
      //

      if (text.contains('transfer dari') &&
          text.contains('nomor rekening tujuan')) {
        return 'expense';
      }

      if (text.contains('transfer ke') ||
          text.contains('transfer keluar') ||
          text.contains('dana keluar') ||
          text.contains('uang keluar') ||
          text.contains('berhasil transfer') ||
          text.contains('penarikan') ||
          text.contains('tarik tunai')) {
        return 'expense';
      }

      // -------------------------------------------------------
      // BRI - UANG MASUK
      // -------------------------------------------------------

      if (text.contains('transfer masuk') ||
          text.contains('dana masuk') ||
          text.contains('uang masuk') ||
          text.contains('transfer diterima') ||
          text.contains('menerima transfer') ||
          text.contains('menerima uang') ||
          text.contains('menerima dana') ||
          text.contains('dana diterima') ||
          text.contains('saldo bertambah')) {
        return 'income';
      }
    }

    // =======================================================
    // KHUSUS DANA
    // =======================================================

    if (source == 'DANA') {
      // -------------------------------------------------------
      // DANA - UANG MASUK
      // -------------------------------------------------------

      if (text.contains('diterima dari') ||
          text.contains('telah diterima') ||
          text.contains('dana diterima') ||
          text.contains('transfer diterima') ||
          text.contains('menerima transfer') ||
          text.contains('menerima uang') ||
          text.contains('menerima dana') ||
          text.contains('saldo bertambah')) {
        return 'income';
      }

      // -------------------------------------------------------
      // DANA - UANG KELUAR
      // -------------------------------------------------------

      if (text.contains('transfer ke') ||
          text.contains('transfer keluar') ||
          text.contains('pembayaran') ||
          text.contains('pembelian') ||
          text.contains('saldo berkurang') ||
          text.contains('berhasil membayar') ||
          text.contains('bayar')) {
        return 'expense';
      }
    }

    // =======================================================
    // KHUSUS SHOPEEPAY
    // =======================================================

    if (source == 'ShopeePay') {
      // -------------------------------------------------------
      // ShopeePay - UANG MASUK
      // -------------------------------------------------------

      if (text.contains('diterima dari') ||
          text.contains('has transferred') ||
          text.contains('has sent') ||
          text.contains('received') ||
          text.contains('sent you')) {
        return 'income';
      }

      // -------------------------------------------------------
      // ShopeePay - UANG KELUAR
      // -------------------------------------------------------

      if (text.contains('you transferred') ||
          text.contains('you have transferred') ||
          text.contains('sent to') ||
          text.contains('payment') ||
          text.contains('pembayaran') ||
          text.contains('pembelian') ||
          text.contains('you paid') ||
          text.contains('paid to')) {
        return 'expense';
      }
    }

    // =======================================================
    // KEYWORD UMUM - UANG MASUK
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
      'isi saldo',
      'pengisian saldo',
      'top up',
      'topup',
      'berhasil top up',
      'transfer diterima',
      'masuk ke rekening',
      'saldo diterima',
      'dana diterima',
      'berhasil menerima',

      // English
      'has transferred',
      'have transferred',
      'transferred to your',
      'transfer received',
      'money received',
      'received transfer',
      'received rp',
      'has sent',
      'sent you',
    ];

    for (final keyword in incomeKeywords) {
      if (text.contains(keyword)) {
        return 'income';
      }
    }

    // =======================================================
    // KEYWORD UMUM - UANG KELUAR
    // =======================================================

    final expenseKeywords = [
      'transfer ke',
      'transfer keluar',
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

      // English
      'you transferred',
      'you have transferred',
      'transfer sent',
      'sent to',
      'payment sent',
      'payment successful',
      'purchase successful',
      'withdrawal',
      'you paid',
      'paid to',
      'has been paid',
    ];

    for (final keyword in expenseKeywords) {
      if (text.contains(keyword)) {
        return 'expense';
      }
    }

    // Tidak dapat menentukan tipe transaksi.
    return null;
  }

  // =========================================================
  // DETEKSI SUMBER APLIKASI
  // =========================================================

  static String _detectSource(
    NotificationModel notification,
  ) {
    final package = notification.packageName.toLowerCase();

    final title = notification.title.toLowerCase();

    final notificationText =
        notification.text.toLowerCase();

    final combined =
        '$package $title $notificationText';

    // =======================================================
    // DANA
    // =======================================================

    if (package.contains('dana') ||
        title.contains('dana') ||
        notificationText.contains('dana')) {
      return 'DANA';
    }

    // =======================================================
    // SHOPEEPAY
    // =======================================================

    if (package.contains('shopeepay') ||
        title.contains('shopeepay') ||
        notificationText.contains('shopeepay')) {
      return 'ShopeePay';
    }

    if (combined.contains('shopee') &&
        (combined.contains('saldo') ||
            combined.contains('top up') ||
            combined.contains('topup') ||
            combined.contains('diterima') ||
            combined.contains('pembayaran') ||
            combined.contains('transferred') ||
            combined.contains('transfer'))) {
      return 'ShopeePay';
    }

    // =======================================================
    // BRIMO / BRI
    // =======================================================

    if (package.contains('brimo') ||
        package.contains('bri') ||
        title.contains('brimo') ||
        title.contains('bri') ||
        notificationText.contains('brimo') ||
        notificationText.contains('bank bri')) {
      return 'BRI';
    }

    // =======================================================
    // BCA
    // =======================================================

    if (package.contains('bca') ||
        title.contains('bca') ||
        notificationText.contains('bca')) {
      return 'BCA';
    }

    // =======================================================
    // MANDIRI
    // =======================================================

    if (package.contains('mandiri') ||
        title.contains('mandiri') ||
        notificationText.contains('mandiri')) {
      return 'Mandiri';
    }

    // =======================================================
    // GOPAY
    // =======================================================

    if (package.contains('gopay') ||
        title.contains('gopay') ||
        notificationText.contains('gopay') ||
        combined.contains('go-pay') ||
        combined.contains('go pay')) {
      return 'GoPay';
    }

    // =======================================================
    // OVO
    // =======================================================

    if (package.contains('ovo') ||
        title.contains('ovo') ||
        notificationText.contains('ovo')) {
      return 'OVO';
    }

    // =======================================================
    // LINKAJA
    // =======================================================

    if (package.contains('linkaja') ||
        title.contains('linkaja') ||
        notificationText.contains('linkaja') ||
        combined.contains('link aja')) {
      return 'LinkAja';
    }

    // =======================================================
    // LAZADA
    // =======================================================

    if (package.contains('lazada') ||
        title.contains('lazada') ||
        notificationText.contains('lazada')) {
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

    if (notification.packageName.isNotEmpty) {
      return notification.packageName;
    }

    return 'Unknown';
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
    // DANA - INCOMING
    // =======================================================

    if (source == 'DANA' &&
        type == 'income') {
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
    // SHOPEEPAY - INCOMING
    // =======================================================

    if (source == 'ShopeePay' &&
        type == 'income') {
      // -------------------------------------------------------
      // English:
      //
      // NABILA AGWITANTY has transferred
      // Rp1 to your ShopeePay.
      // -------------------------------------------------------

      final englishRegex = RegExp(
        r'^(.+?)\s+has\s+transferred\s+rp',
        caseSensitive: false,
      );

      final englishMatch =
          englishRegex.firstMatch(text);

      if (englishMatch != null) {
        return _cleanSender(
          englishMatch.group(1) ?? '',
        );
      }

      // -------------------------------------------------------
      // English:
      //
      // NABILA has sent Rp1 to your ShopeePay.
      // -------------------------------------------------------

      final englishRegex2 = RegExp(
        r'^(.+?)\s+has\s+sent\s+rp',
        caseSensitive: false,
      );

      final englishMatch2 =
          englishRegex2.firstMatch(text);

      if (englishMatch2 != null) {
        return _cleanSender(
          englishMatch2.group(1) ?? '',
        );
      }

      // -------------------------------------------------------
      // Indonesia:
      //
      // Diterima dari Septiyan Adam Maulana.
      // -------------------------------------------------------

      final indonesianRegex = RegExp(
        r'dari\s+(.+?)(?:\.|$)',
        caseSensitive: false,
      );

      final indonesianMatch =
          indonesianRegex.firstMatch(text);

      if (indonesianMatch != null) {
        return _cleanSender(
          indonesianMatch.group(1) ?? '',
        );
      }
    }

    // =======================================================
    // BRI - TRANSFER DARI
    // =======================================================

    if (source == 'BRI') {
      /*
        Contoh:

        Transfer dari XXXXXXXXXXXX0508
        dengan nomor rekening tujuan
        XXXXXXXXXXXX3507
        sebesar Rp10.000,00 BERHASIL.

        Bagian setelah "transfer dari"
        adalah rekening sumber.

        Kita simpan sebagai sender untuk saat ini
        karena TransactionModel menggunakan field sender.
      */

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
    // BRI - FORMAT ALTERNATIF INCOMING
    // =======================================================

    if (source == 'BRI' &&
        type == 'income') {
      final regex = RegExp(
        r'dari\s+(.+?)(?:\s+sebesar|\s+rp|$)',
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
    // BCA - FORMAT UMUM INCOMING
    // =======================================================

    if (source == 'BCA' &&
        type == 'income') {
      final regex = RegExp(
        r'dari\s+(.+?)(?:\s+sebesar|\s+rp|$)',
        caseSensitive: false,
      );

      final match = regex.firstMatch(text);

      if (match != null) {
        return _cleanSender(
          match.group(1) ?? '',
        );
      }
    }

    // Tidak ditemukan pengirim.
    return '';
  }

  // =========================================================
  // MEMBERSIHKAN NAMA PENGIRIM
  // =========================================================

  static String _cleanSender(
    String sender,
  ) {
    var result = sender.trim();

    // Hapus emoji uang
    result = result.replaceAll(
      '💰',
      '',
    );

    result = result.replaceAll(
      '💸',
      '',
    );

    result = result.replaceAll(
      '🤑',
      '',
    );

    // Hapus titik di akhir
    result = result.replaceFirst(
      RegExp(r'\.$'),
      '',
    );

    // Hapus spasi berlebihan
    result = result.replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    return result.trim();
  }
}