import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CertificateGenerator {
  static Future<void> generate(String courseName) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text("Certificate of Completion",
                  style: pw.TextStyle(fontSize: 30)),
              pw.SizedBox(height: 20),
              pw.Text("This certifies you completed"),
              pw.SizedBox(height: 10),
              pw.Text(courseName, style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 20),
              pw.Text("Congratulations 🎉"),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (pw.PdfPageFormat format) async => pdf.save(),
    );
  }
}
