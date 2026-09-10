import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/transaction_model.dart';

class WebhookService {
  static const String webhookUrl =
      'https://webhook-server-sand.vercel.app/webhook';

  // =========================================================
  // KIRIM TRANSAKSI KE BACKEND
  // FORMAT MENGIKUTI BACKEND TEMAN
  // =========================================================

  static Future<bool> sendTransaction(
    TransactionModel transaction,
    String rawMessage,
  ) async {
    try {
      // -------------------------------------------------------
      // TYPE
      // income  -> incoming
      // expense -> outgoing
      // -------------------------------------------------------

      String backendType;

      if (transaction.type == 'income') {
        backendType = 'incoming';
      } else if (transaction.type == 'expense') {
        backendType = 'outgoing';
      } else {
        backendType = transaction.type;
      }

      // -------------------------------------------------------
      // DATETIME
      // Ubah timestamp menjadi ISO 8601 UTC
      // Contoh:
      // 2026-09-10T06:39:51.583Z
      // -------------------------------------------------------

      String dateTime;

      final milliseconds =
          int.tryParse(transaction.timestamp);

      if (milliseconds != null) {
        dateTime = DateTime
            .fromMillisecondsSinceEpoch(milliseconds)
            .toUtc()
            .toIso8601String();
      } else {
        dateTime = DateTime.now()
            .toUtc()
            .toIso8601String();
      }

      // -------------------------------------------------------
      // EVENT ID
      // -------------------------------------------------------

      final eventId =
          '${DateTime.now().microsecondsSinceEpoch}';

      // -------------------------------------------------------
      // PAYLOAD
      // -------------------------------------------------------

      final data = {
        'eventId': eventId,

        'appSource': transaction.source,

        'amount': transaction.amount,

        'payerName': transaction.sender.isNotEmpty
            ? transaction.sender
            : transaction.description,

        'type': backendType,

        'dateTime': dateTime,

        'rawMessage': rawMessage,
      };

      // -------------------------------------------------------
      // DEBUG
      // -------------------------------------------------------

      print('========================================');
      print('MENGIRIM TRANSAKSI KE BACKEND');
      print('Payload:');
      print(jsonEncode(data));
      print('========================================');

      // -------------------------------------------------------
      // POST
      // -------------------------------------------------------

      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      print('Webhook status   : ${response.statusCode}');
      print('Webhook response : ${response.body}');

      return response.statusCode >= 200 &&
          response.statusCode < 300;
    } catch (e) {
      print('Webhook error: $e');
      return false;
    }
  }
}