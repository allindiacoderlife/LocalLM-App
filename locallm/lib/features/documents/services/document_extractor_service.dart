import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class DocumentExtractorService {
  DocumentExtractorService._();

  /// Extracts text content from a PDF or text file.
  static Future<String> extractText(File file) async {
    final path = file.path.toLowerCase();
    if (path.endsWith('.pdf')) {
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      try {
        final text = PdfTextExtractor(document).extractText();
        return text.trim();
      } finally {
        document.dispose();
      }
    } else {
      // Plain text, markdown, json, etc.
      return await file.readAsString();
    }
  }
}
