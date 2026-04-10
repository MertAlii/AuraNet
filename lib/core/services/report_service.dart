import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../features/scan/models/device_model.dart';

class ReportService {
  /// Tarama sonuçlarını PDF olarak üretir ve dosya yolunu döner.
  static Future<File> generateScanReport(List<DeviceModel> devices, String networkName, int score, {String? aiRecommendation}) async {
    final pdf = pw.Document();
    
    // Skor rengini belirle
    PdfColor scoreColor = PdfColors.green;
    String scoreLabel = 'GÜVENLİ';
    if (score < 40) {
      scoreColor = PdfColors.red;
      scoreLabel = 'YÜKSEK RİSK';
    } else if (score < 75) {
      scoreColor = PdfColors.orange;
      scoreLabel = 'ORTA RİSK';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header Bölümü
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('AuraNet', style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  pw.Text('Profesyonel Ağ Analiz Raporu', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Tarih: ${DateTime.now().toString().substring(0, 16)}', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('ID: #${DateTime.now().millisecondsSinceEpoch.toString().split('').reversed.join('').substring(0, 8)}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 2, color: PdfColors.blue900),
          pw.SizedBox(height: 20),

          // Özet Bilgi Kartı
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Ağ Bilgileri', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                      pw.SizedBox(height: 8),
                      pw.Text('Ağ Adı: $networkName'),
                      pw.Text('Tespit Edilen Cihaz: ${devices.length}'),
                      pw.Text('Analiz Türü: Derin Tarama (Premium)'),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                      color: scoreColor,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(50)),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text('$score', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                        pw.Text(scoreLabel, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 30),

          if (aiRecommendation != null) ...[
            pw.Text('Aura AI Güvenlik Analizi', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(aiRecommendation, style: const pw.TextStyle(fontSize: 11)),
            ),
            pw.SizedBox(height: 30),
          ],

          pw.Text('Cihaz Listesi ve Zafiyet Analizi', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ['IP Adresi', 'Cihaz İsmi', 'Donanım Üreticisi', 'Açık Portlar'],
            data: devices.map((d) => [
              d.ipAddress,
              d.deviceName,
              d.vendorName,
              d.openPorts.isEmpty ? 'Güvenli (Açık port yok)' : d.openPorts.join(', '),
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
            cellHeight: 30,
            cellStyle: const pw.TextStyle(fontSize: 10),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
          ),
          
          pw.SizedBox(height: 40),
          pw.Divider(),
          pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Text('Bu rapor AuraNet AI tarafından otomatik olarak oluşturulmuştur. © 2024 AuraNet Team.', 
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
          ),
        ],
      ),
    );

    final output = await getExternalStorageDirectory() ?? await getTemporaryDirectory();
    final file = File('${output.path}/AuraNet_Rapor_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
