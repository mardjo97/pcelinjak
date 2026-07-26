import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Minimalni DOCX (OOXML) generator — tekst, naslovi i tabele.
class DocxBuilder {
  final _body = StringBuffer();

  void heading(String text, {int level = 1}) {
    final size = level == 1 ? 32 : 24; // half-points
    _body.writeln(
      '<w:p><w:pPr><w:jc w:val="center"/>'
      '<w:rPr><w:b/><w:sz w:val="$size"/><w:szCs w:val="$size"/></w:rPr></w:pPr>'
      '<w:r><w:rPr><w:b/><w:sz w:val="$size"/><w:szCs w:val="$size"/></w:rPr>'
      '<w:t>${_esc(text)}</w:t></w:r></w:p>',
    );
  }

  void paragraph(String text, {bool bold = false, bool justify = false}) {
    final jc = justify ? '<w:jc w:val="both"/>' : '';
    final b = bold ? '<w:b/>' : '';
    _body.writeln(
      '<w:p><w:pPr>$jc</w:pPr>'
      '<w:r><w:rPr>$b</w:rPr><w:t xml:space="preserve">${_esc(text)}</w:t></w:r></w:p>',
    );
  }

  void emptyLine() => _body.writeln('<w:p/>');

  void table(List<String> headers, List<List<String>> rows) {
    _body.writeln('<w:tbl>');
    _body.writeln(
      '<w:tblPr><w:tblW w:w="5000" w:type="pct"/>'
      '<w:tblBorders>'
      '<w:top w:val="single" w:sz="4" w:space="0" w:color="666666"/>'
      '<w:left w:val="single" w:sz="4" w:space="0" w:color="666666"/>'
      '<w:bottom w:val="single" w:sz="4" w:space="0" w:color="666666"/>'
      '<w:right w:val="single" w:sz="4" w:space="0" w:color="666666"/>'
      '<w:insideH w:val="single" w:sz="4" w:space="0" w:color="666666"/>'
      '<w:insideV w:val="single" w:sz="4" w:space="0" w:color="666666"/>'
      '</w:tblBorders></w:tblPr>',
    );
    _row(headers, header: true);
    for (final r in rows) {
      _row(r, header: false);
    }
    _body.writeln('</w:tbl>');
    emptyLine();
  }

  void pageBreak() {
    _body.writeln('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
  }

  void _row(List<String> cells, {required bool header}) {
    _body.writeln('<w:tr>');
    for (final c in cells) {
      final b = header ? '<w:b/>' : '';
      final shade = header
          ? '<w:tcPr><w:shd w:val="clear" w:color="auto" w:fill="D9D9D9"/></w:tcPr>'
          : '<w:tcPr/>';
      _body.writeln(
        '<w:tc>$shade<w:p><w:r><w:rPr>$b</w:rPr>'
        '<w:t xml:space="preserve">${_esc(c)}</w:t></w:r></w:p></w:tc>',
      );
    }
    _body.writeln('</w:tr>');
  }

  Uint8List build() {
    final documentXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    $_body
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134"/>
    </w:sectPr>
  </w:body>
</w:document>''';

    const contentTypes = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';

    const rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

    const docRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
</Relationships>''';

    final archive = Archive();
    void add(String name, String content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    add('[Content_Types].xml', contentTypes);
    add('_rels/.rels', rels);
    add('word/document.xml', documentXml);
    add('word/_rels/document.xml.rels', docRels);

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
