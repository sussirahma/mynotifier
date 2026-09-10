import 'dart:async';

import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/transaction_parser.dart';
import '../services/webhook_service.dart';
import '../models/notification_model.dart';
import '../models/transaction_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // =========================================================
  // VARIABLE
  // =========================================================

  bool isEnabled = false;

  // Menyimpan SEMUA notifikasi yang diterima
  final List<NotificationModel> notifications = [];

  // Menyimpan HANYA notifikasi yang terdeteksi sebagai transaksi
  final List<TransactionModel> transactions = [];

  // Stream subscription
  StreamSubscription<Map<dynamic, dynamic>>? notificationSubscription;

  // =========================================================
  // INIT STATE
  // =========================================================

  @override
  void initState() {
    super.initState();

    checkPermission();
    listenToNotifications();
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    notificationSubscription?.cancel();

    super.dispose();
  }

  // =========================================================
  // CEK NOTIFICATION ACCESS
  // =========================================================

  Future<void> checkPermission() async {
    try {
      final enabled = await NotificationService.isNotificationListenerEnabled();

      if (!mounted) return;

      setState(() {
        isEnabled = enabled;
      });
    } catch (e) {
      debugPrint('Error cek notification access: $e');
    }
  }

  // =========================================================
  // BUKA SETTINGS
  // =========================================================

  Future<void> openSettings() async {
    try {
      await NotificationService.openNotificationSettings();

      await Future.delayed(const Duration(seconds: 1));

      await checkPermission();
    } catch (e) {
      debugPrint('Error membuka notification settings: $e');
    }
  }

  // =========================================================
  // MENDENGARKAN NOTIFIKASI
  // =========================================================

  void listenToNotifications() {
    notificationSubscription = NotificationService.notificationStream.listen(
      (data) async {
        try {
          // -----------------------------------------------
          // 1. Ubah data Android menjadi NotificationModel
          // -----------------------------------------------

          final notification = NotificationModel.fromMap(data);

          // -----------------------------------------------
          // 2. Simpan SEMUA notifikasi
          // -----------------------------------------------

          notifications.insert(0, notification);

          // -----------------------------------------------
          // 3. Jalankan parser transaksi
          // -----------------------------------------------

          final transaction = TransactionParser.parse(notification);

          // -----------------------------------------------
          // 4. CEK APAKAH TRANSAKSI
          // -----------------------------------------------

          if (transaction != null) {
            // ---------------------------------------------
            // Simpan ke daftar transaksi
            // ---------------------------------------------

            transactions.insert(0, transaction);

            // ---------------------------------------------
            // LOG TRANSAKSI
            // ---------------------------------------------

            debugPrint('================================');

            debugPrint('TRANSAKSI TERDETEKSI');

            debugPrint('Source: ${transaction.source}');

            debugPrint('Type: ${transaction.type}');

            debugPrint('Amount: ${transaction.amount}');

            debugPrint('Description: ${transaction.description}');

            debugPrint('Mengirim transaksi ke backend...');

            // ---------------------------------------------
            // KIRIM HANYA TRANSAKSI KE BACKEND
            // ---------------------------------------------

            final success = await WebhookService.sendTransaction(
              transaction,
              notification.text,
            );

            if (success) {
              debugPrint('TRANSAKSI BERHASIL DIKIRIM KE BACKEND');
            } else {
              debugPrint('GAGAL MENGIRIM TRANSAKSI KE BACKEND');
            }

            debugPrint('================================');
          } else {
            // ---------------------------------------------
            // BUKAN TRANSAKSI
            // ---------------------------------------------

            debugPrint('Notifikasi biasa diabaikan:');

            debugPrint('Package: ${notification.packageName}');

            debugPrint('Title: ${notification.title}');

            debugPrint('Text: ${notification.text}');

            debugPrint('Tidak dikirim ke backend.');
          }

          // -----------------------------------------------
          // 5. UPDATE UI
          // -----------------------------------------------

          if (!mounted) return;

          setState(() {});
        } catch (e) {
          debugPrint('Error membaca data notifikasi: $e');
        }
      },
      onError: (error) {
        debugPrint('Notification stream error: $error');
      },
    );
  }

  // =========================================================
  // TOTAL UANG MASUK
  // =========================================================

  int get totalIncome {
    return transactions
        .where((transaction) => transaction.isIncome)
        .fold(0, (total, transaction) => total + transaction.amount);
  }

  // =========================================================
  // TOTAL UANG KELUAR
  // =========================================================

  int get totalExpense {
    return transactions
        .where((transaction) => transaction.isExpense)
        .fold(0, (total, transaction) => total + transaction.amount);
  }

  // =========================================================
  // FORMAT RUPIAH
  // =========================================================

  String formatRupiah(int amount) {
    return 'Rp${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      // =====================================================
      // APP BAR
      // =====================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,

        title: const Row(
          children: [
            Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFF2563EB),
              size: 28,
            ),

            SizedBox(width: 10),

            Text(
              'MyNotifier',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),

      // =====================================================
      // BODY
      // =====================================================
      body: RefreshIndicator(
        onRefresh: checkPermission,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // =================================================
              // JUDUL
              // =================================================

              const Text(
                'Monitoring Transaksi',

                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Pantau transaksi dari notifikasi perangkat Anda.',

                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),

              const SizedBox(height: 24),

              // =================================================
              // STATUS CARD
              // =================================================
              _buildStatusCard(),

              const SizedBox(height: 28),

              // =================================================
              // RINGKASAN
              // =================================================
              const Text(
                'Ringkasan',

                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 14),

              // =================================================
              // UANG MASUK & KELUAR
              // =================================================
              Row(
                children: [
                  Expanded(
                    child: _buildMoneyCard(
                      icon: Icons.arrow_downward_rounded,
                      title: 'Uang Masuk',
                      value: formatRupiah(totalIncome),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: _buildMoneyCard(
                      icon: Icons.arrow_upward_rounded,
                      title: 'Uang Keluar',
                      value: formatRupiah(totalExpense),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // =================================================
              // JUMLAH TRANSAKSI & NOTIFIKASI
              // =================================================
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.receipt_long_rounded,

                      title: 'Transaksi',

                      value: transactions.length.toString(),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.notifications_none_rounded,

                      title: 'Notifikasi',

                      value: notifications.length.toString(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // =================================================
              // TRANSAKSI TERBARU
              // =================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  const Text(
                    'Transaksi Terbaru',

                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),

                  // TextButton(
                  //   onPressed: () {},

                  //   child: const Text(
                  //     'Lihat Semua',

                  //     style: TextStyle(
                  //       color:
                  //           Color(0xFF2563EB),
                  //       fontWeight:
                  //           FontWeight.w600,
                  //     ),
                  //   ),
                  // ),
                ],
              ),

              const SizedBox(height: 8),

              // =================================================
              // LIST TRANSAKSI
              // =================================================
              if (transactions.isEmpty)
                _buildEmptyState()
              else
                Column(
                  children: transactions.map((transaction) {
                    return _buildTransactionCard(transaction);
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================
  // STATUS CARD
  // ===========================================================

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],

          begin: Alignment.topLeft,

          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.20),

            blurRadius: 20,

            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,

                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),

                  borderRadius: BorderRadius.circular(14),
                ),

                child: const Icon(
                  Icons.notifications_active_rounded,

                  color: Colors.white,

                  size: 25,
                ),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),

                  borderRadius: BorderRadius.circular(20),
                ),

                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,

                      decoration: BoxDecoration(
                        color: isEnabled
                            ? Colors.greenAccent
                            : Colors.orangeAccent,

                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 7),

                    Text(
                      isEnabled ? 'Aktif' : 'Tidak Aktif',

                      style: const TextStyle(
                        color: Colors.white,

                        fontSize: 12,

                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          const Text(
            'Status Notification Listener',

            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),

          const SizedBox(height: 5),

          Text(
            isEnabled
                ? 'Listener sedang aktif'
                : 'Akses notifikasi belum aktif',

            style: const TextStyle(
              color: Colors.white,

              fontSize: 20,

              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            isEnabled
                ? 'MyNotifier siap membaca notifikasi yang masuk.'
                : 'Aktifkan akses agar MyNotifier dapat membaca notifikasi.',

            style: const TextStyle(
              color: Colors.white70,

              fontSize: 13,

              height: 1.4,
            ),
          ),

          if (!isEnabled) ...[
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 48,

              child: ElevatedButton(
                onPressed: openSettings,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,

                  foregroundColor: const Color(0xFF2563EB),

                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),

                child: const Text(
                  'Aktifkan Akses Notifikasi',

                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================
  // MONEY CARD
  // ===========================================================

  Widget _buildMoneyCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 40,
            height: 40,

            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),

              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(icon, color: const Color(0xFF2563EB), size: 21),
          ),

          const SizedBox(height: 15),

          Text(
            value,

            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,

            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // STAT CARD
  // ===========================================================

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 40,
            height: 40,

            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),

              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(icon, color: const Color(0xFF2563EB), size: 21),
          ),

          const SizedBox(height: 15),

          Text(
            value,

            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,

            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // EMPTY STATE
  // ===========================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),

      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,

            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),

              borderRadius: BorderRadius.circular(20),
            ),

            child: const Icon(
              Icons.receipt_long_outlined,

              color: Color(0xFF2563EB),

              size: 32,
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            'Belum Ada Transaksi',

            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Notifikasi transaksi yang berhasil\n'
            'ditangkap akan muncul di sini.',

            textAlign: TextAlign.center,

            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // TRANSACTION CARD
  // ===========================================================

  Widget _buildTransactionCard(TransactionModel transaction) {
    final bool isIncome = transaction.isIncome;

    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: const Color(0xFFE5E7EB)),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),

            blurRadius: 8,

            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ===================================================
          // ICON
          // ===================================================

          Container(
            width: 45,
            height: 45,

            decoration: BoxDecoration(
              color: isIncome
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFFEF2F2),

              borderRadius: BorderRadius.circular(14),
            ),

            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,

              color: isIncome ? Colors.green : Colors.red,

              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          // ===================================================
          // DATA
          // ===================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Expanded(
                      child: Text(
                        transaction.source,

                        style: const TextStyle(
                          fontSize: 15,

                          fontWeight: FontWeight.w700,

                          color: Color(0xFF111827),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Text(
                      '${isIncome ? '+' : '-'}${transaction.formattedAmount}',

                      style: TextStyle(
                        fontSize: 14,

                        fontWeight: FontWeight.w800,

                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  transaction.description,

                  maxLines: 3,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 12,

                    color: Color(0xFF6B7280),

                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),

                      decoration: BoxDecoration(
                        color: isIncome
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFEF2F2),

                        borderRadius: BorderRadius.circular(8),
                      ),

                      child: Text(
                        isIncome ? 'Uang Masuk' : 'Uang Keluar',

                        style: TextStyle(
                          fontSize: 10,

                          fontWeight: FontWeight.w600,

                          color: isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Text(
                      _formatTimestamp(transaction.timestamp),

                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // FORMAT TIMESTAMP
  // ===========================================================

  String _formatTimestamp(String timestamp) {
    if (timestamp.isEmpty) {
      return '';
    }

    try {
      final milliseconds = int.tryParse(timestamp);

      if (milliseconds == null) {
        return '';
      }

      final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);

      final hour = date.hour.toString().padLeft(2, '0');

      final minute = date.minute.toString().padLeft(2, '0');

      return '$hour:$minute';
    } catch (e) {
      return '';
    }
  }
}
