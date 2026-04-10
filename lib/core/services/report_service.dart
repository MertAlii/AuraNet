import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../features/scan/models/device_model.dart';

class ReportService {
  /// Tarama sonuçlarını PDF olarak üretir ve dosya yolunu döner.
  static Future<File> generateScanReport(List<DeviceModel> devices, String networkName, int score) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('AuraNet Ağ Analiz Raporu', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text(DateTime.now().toString().substring(0, 16)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Ağ Adı: $networkName'),
                  pw.Text('Cihaz Sayısı: ${devices.length}'),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue, width: 2),
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Text('Skor: $score', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
              ),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Text('Tespit Edilen Cihazlar', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Divider(),
          pw.TableHelper.fromTextArray(
            headers: ['IP Adresi', 'MAC Adresi', 'Üretici', 'Açık Portlar'],
            data: devices.map((d) => [
              d.ipAddress,
              d.macAddress,
              d.vendorName,
              d.openPorts.join(', '),
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
            },
          ),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/AuraNet_Rapor_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
