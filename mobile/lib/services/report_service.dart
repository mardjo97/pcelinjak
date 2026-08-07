import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../database/app_database.dart';
import '../models/hive_status_rules.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';
import 'beekeeper_prefs.dart';
import 'docx_builder.dart';

enum ReportType {
  harvestByPasture,
  prijavaStanja,
  queensOverview,
  movedHistory,
}

enum ReportFormat { pdf, docx, csv }

extension ReportTypeX on ReportType {
  String title(AppLocalizations l10n) {
    switch (this) {
      case ReportType.harvestByPasture:
        return l10n.reportHarvestTitle;
      case ReportType.prijavaStanja:
        return l10n.reportPrijavaTitle;
      case ReportType.queensOverview:
        return l10n.reportQueensTitle;
      case ReportType.movedHistory:
        return 'Istorija selidbi';
    }
  }

  String subtitle(AppLocalizations l10n) {
    switch (this) {
      case ReportType.harvestByPasture:
        return l10n.reportHarvestSubtitle;
      case ReportType.prijavaStanja:
        return l10n.reportPrijavaSubtitle;
      case ReportType.queensOverview:
        return l10n.reportQueensSubtitle;
      case ReportType.movedHistory:
        return 'Sve selidbe košnica po lokaciji, paši i periodu';
    }
  }

  /// Naslov u izvoznom fajlu — uvek srpski (zvanični obrasci / konzistentnost).
  String get documentTitle {
    switch (this) {
      case ReportType.harvestByPasture:
        return 'Prinos po paši i pčelinjaku';
      case ReportType.prijavaStanja:
        return 'Prijava stanja (Prilog 4)';
      case ReportType.queensOverview:
        return 'Pregled matica';
      case ReportType.movedHistory:
        return 'Istorija selidbi';
    }
  }

  String get documentSubtitle {
    switch (this) {
      case ReportType.harvestByPasture:
        return 'Sume kg za tekuću godinu, po paši i pčelinjaku';
      case ReportType.prijavaStanja:
        return 'Obrazac sa barkodovima aktivnih košnica — po pčelinjaku';
      case ReportType.queensOverview:
        return 'Godina, markiranje i poreklo aktivnih matica';
      case ReportType.movedHistory:
        return 'Pregled svih selidbi po košnici, lokaciji i periodu';
    }
  }
}

extension ReportFormatX on ReportFormat {
  String get label {
    switch (this) {
      case ReportFormat.pdf:
        return 'PDF';
      case ReportFormat.docx:
        return 'Word (DOCX)';
      case ReportFormat.csv:
        return 'CSV';
    }
  }

  String get extension {
    switch (this) {
      case ReportFormat.pdf:
        return 'pdf';
      case ReportFormat.docx:
        return 'docx';
      case ReportFormat.csv:
        return 'csv';
    }
  }

  String get mime {
    switch (this) {
      case ReportFormat.pdf:
        return 'application/pdf';
      case ReportFormat.docx:
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case ReportFormat.csv:
        return 'text/csv';
    }
  }
}

class PrijavaStanjaOptions {
  PrijavaStanjaOptions({
    required this.beekeeperName,
    required this.hid,
    required this.asOf,
    required this.apiaryUuids,
  });

  final String beekeeperName;
  final String hid;
  final DateTime asOf;
  final List<String> apiaryUuids;
}

class ReportService {
  ReportService(this.db);

  final AppDatabase db;
  final _dateFmt = DateFormat('dd.MM.yyyy. HH:mm');
  final _dayFmt = DateFormat('dd');
  final _monthFmt = DateFormat('MM');
  final _yearFmt = DateFormat('yyyy');

  Future<void> generateAndShare(
    ReportType type, {
    required ReportFormat format,
    PrijavaStanjaOptions? prijava,
  }) async {
    final year = DateTime.now().year;
    final name = _baseName(type, year);
    final bytes = switch (format) {
      ReportFormat.pdf => await _buildPdf(type, prijava: prijava),
      ReportFormat.docx => await _buildDocx(type, prijava: prijava),
      ReportFormat.csv => Uint8List.fromList([
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode(await _buildCsv(type, prijava: prijava)),
      ]),
    };
    await _shareBytes(bytes, '$name.${format.extension}', format.mime);
  }

  Future<void> _shareBytes(
    Uint8List bytes,
    String filename,
    String mime,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, filename));
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mime, name: filename)],
        subject: filename,
      ),
    );
  }

  String _baseName(ReportType type, int year) {
    final slug = switch (type) {
      ReportType.harvestByPasture => 'prinos_$year',
      ReportType.prijavaStanja => 'prijava_stanja',
      ReportType.queensOverview => 'matice',
      ReportType.movedHistory => 'istorija_selidbi',
    };
    return 'pcelinjak_$slug';
  }

  Future<PrijavaStanjaOptions> _prijavaFromConfig() async {
    final name = await BeekeeperPrefs.reportName();
    final hid = await BeekeeperPrefs.hid();
    final apiaries = await db.listApiaries();
    return PrijavaStanjaOptions(
      beekeeperName: name,
      hid: hid,
      asOf: DateTime.now(),
      apiaryUuids: apiaries.map((a) => a.uuid).toList(),
    );
  }

  // ─── PDF ─────────────────────────────────────────────────────────────

  Future<Uint8List> _buildPdf(
    ReportType type, {
    PrijavaStanjaOptions? prijava,
  }) async {
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();
    final theme = pw.ThemeData.withFont(base: font, bold: fontBold);
    final doc = pw.Document(theme: theme);
    final year = DateTime.now().year;
    final generatedAt = _dateFmt.format(DateTime.now());

    if (type == ReportType.prijavaStanja) {
      final opts = prijava ?? await _prijavaFromConfig();
      await _addPrijavaPdfPages(doc, opts);
    } else {
      final body = switch (type) {
        ReportType.harvestByPasture => await _harvestPdf(year),
        ReportType.queensOverview => await _queensPdf(),
        ReportType.movedHistory => await _movedHistoryPdf(),
        ReportType.prijavaStanja => <pw.Widget>[],
      };
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (ctx) => [
            pw.Text(
              'Pčelinjak — ${type.documentTitle}',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              type.documentSubtitle,
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Generisano: $generatedAt',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 16),
            ...body,
          ],
        ),
      );
    }
    return Uint8List.fromList(await doc.save());
  }

  Future<void> _addPrijavaPdfPages(
    pw.Document doc,
    PrijavaStanjaOptions opts,
  ) async {
    final pages = await _prijavaPages(opts);
    if (pages.isEmpty) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (_) => pw.Center(child: pw.Text('Nema izabranih pčelinjaka.')),
        ),
      );
      return;
    }
    for (final page in pages) {
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 28),
          build: (ctx) => _prijavaFormPdf(page),
        ),
      );
    }
  }

  // ─── DOCX ────────────────────────────────────────────────────────────

  Future<Uint8List> _buildDocx(
    ReportType type, {
    PrijavaStanjaOptions? prijava,
  }) async {
    final doc = DocxBuilder();
    final year = DateTime.now().year;
    final generatedAt = _dateFmt.format(DateTime.now());

    if (type == ReportType.prijavaStanja) {
      final opts = prijava ?? await _prijavaFromConfig();
      final pages = await _prijavaPages(opts);
      if (pages.isEmpty) {
        doc.paragraph('Nema izabranih pčelinjaka.');
      } else {
        for (var i = 0; i < pages.length; i++) {
          if (i > 0) doc.pageBreak();
          _prijavaFormDocx(doc, pages[i]);
        }
      }
    } else {
      doc.heading('Pčelinjak — ${type.documentTitle}');
      doc.paragraph(type.documentSubtitle);
      doc.paragraph('Generisano: $generatedAt');
      doc.emptyLine();
      if (type == ReportType.harvestByPasture) {
        await _harvestDocx(doc, year);
      } else if (type == ReportType.movedHistory) {
        await _movedHistoryDocx(doc);
      } else {
        await _queensDocx(doc);
      }
    }
    return doc.build();
  }

  // ─── CSV ─────────────────────────────────────────────────────────────

  Future<String> _buildCsv(
    ReportType type, {
    PrijavaStanjaOptions? prijava,
  }) async {
    final year = DateTime.now().year;
    return switch (type) {
      ReportType.harvestByPasture => await _harvestCsv(year),
      ReportType.queensOverview => await _queensCsv(),
      ReportType.prijavaStanja => await _prijavaCsv(
        prijava ?? await _prijavaFromConfig(),
      ),
      ReportType.movedHistory => await _movedHistoryCsv(),
    };
  }

  // ─── shared data ─────────────────────────────────────────────────────

  Future<List<_PrijavaPage>> _prijavaPages(PrijavaStanjaOptions opts) async {
    final all = await db.listApiaries();
    final selected =
        all.where((a) => opts.apiaryUuids.contains(a.uuid)).toList()
          ..sort((a, b) => a.workNumber.compareTo(b.workNumber));
    final out = <_PrijavaPage>[];
    for (final a in selected) {
      final hives = await db.listHives(a.uuid, activeOnly: true);
      out.add(
        _PrijavaPage(
          apiary: a,
          barcodes: hives
              .map((h) => h.barcode)
              .where((b) => b.trim().isNotEmpty)
              .toList(),
          beekeeperName: opts.beekeeperName,
          hid: opts.hid,
          asOf: opts.asOf,
        ),
      );
    }
    return out;
  }

  Future<_HarvestData> _harvestData(int year) async {
    final apiaries = await db.listApiaries();
    final apiaryById = {for (final a in apiaries) a.uuid: a};
    final hives = await db.listAllHives();
    final rows = <_HarvestAgg>[];
    for (final h in hives) {
      final harvests = await db.harvestsForHive(h.uuid, year: year);
      for (final hv in harvests) {
        rows.add(
          _HarvestAgg(
            apiary: apiaryById[h.apiaryUuid]?.name ?? '—',
            workNumber: apiaryById[h.apiaryUuid]?.workNumber ?? 0,
            pasture: hv.pastureType,
            kg: hv.amountKg,
          ),
        );
      }
    }
    final map = <String, double>{};
    for (final r in rows) {
      final key = '${r.workNumber}|${r.apiary}|${r.pasture}';
      map[key] = (map[key] ?? 0) + r.kg;
    }
    final sorted = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final pastureTotals = <String, double>{};
    for (final r in rows) {
      pastureTotals[r.pasture] = (pastureTotals[r.pasture] ?? 0) + r.kg;
    }
    final total = rows.fold<double>(0, (s, r) => s + r.kg);
    return _HarvestData(
      year: year,
      total: total,
      pastureTotals: pastureTotals,
      byApiary: sorted,
    );
  }

  Future<_QueensData> _queensData() async {
    final apiaries = {for (final a in await db.listApiaries()) a.uuid: a};
    final hives = await db.listAllHives()
      ..sort((a, b) {
        final aw = apiaries[a.apiaryUuid]?.workNumber ?? 9999;
        final bw = apiaries[b.apiaryUuid]?.workNumber ?? 9999;
        if (aw != bw) return aw.compareTo(bw);
        return a.orderNumber.compareTo(b.orderNumber);
      });

    final data = <List<String>>[];
    var marked = 0;
    var withQueen = 0;
    for (final h in hives) {
      if (HiveStatusRules.normalize(h.status) != 'ACTIVE') continue;
      final q = await db.activeQueen(h.uuid);
      final a = apiaries[h.apiaryUuid];
      if (q == null) {
        data.add([
          '${a?.workNumber ?? '?'}',
          '${h.orderNumber}',
          h.barcode,
          '—',
          'ne',
          'bez matice',
        ]);
        continue;
      }
      withQueen++;
      if (q.marked) marked++;
      data.add([
        '${a?.workNumber ?? '?'}',
        '${h.orderNumber}',
        h.barcode,
        '${q.queenYear ?? '—'}',
        q.marked ? 'da' : 'ne',
        q.origin?.isNotEmpty == true ? q.origin! : '—',
      ]);
    }
    return _QueensData(rows: data, withQueen: withQueen, marked: marked);
  }

  Future<List<_MovedHistoryRow>> _movedHistoryData() async {
    final apiaries = {for (final a in await db.listApiaries()) a.uuid: a};
    final hives = {for (final h in await db.listAllHives()) h.uuid: h};
    final movedGroups = (await db.listWorkGroups())
        .where((g) => g.groupType == 'MOVED')
        .toList();

    final rows = <_MovedHistoryRow>[];
    for (final group in movedGroups) {
      final memberships = await db.groupHives(group.uuid, filter: 'ALL');
      for (final item in memberships) {
        final hive = hives[item.hiveUuid];
        if (hive == null) continue;
        final apiary = apiaries[hive.apiaryUuid];
        rows.add(
          _MovedHistoryRow(
            workNumber: apiary?.workNumber ?? 0,
            apiaryName: apiary?.name ?? '—',
            orderNumber: hive.orderNumber,
            barcode: hive.barcode,
            pasture: item.pastureType ?? group.pastureType ?? '—',
            locationName: item.locationName ?? group.locationName ?? '—',
            activeFrom: item.activeFrom ?? item.dateCreated,
            activeTo: item.activeTo,
            status: item.membershipStatus,
          ),
        );
      }
    }

    rows.sort((a, b) {
      if (a.workNumber != b.workNumber) {
        return a.workNumber.compareTo(b.workNumber);
      }
      final byOrder = a.orderNumber.compareTo(b.orderNumber);
      if (byOrder != 0) return byOrder;
      return b.activeFrom.compareTo(a.activeFrom);
    });
    return rows;
  }

  // ─── PDF parts ───────────────────────────────────────────────────────

  List<pw.Widget> _prijavaFormPdf(_PrijavaPage page) {
    final day = _dayFmt.format(page.asOf);
    final month = _monthFmt.format(page.asOf);
    final year = _yearFmt.format(page.asOf);
    return [
      pw.Center(
        child: pw.Text(
          'PRIJAVA STANJA NA PČELINJAKU',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
      ),
      pw.SizedBox(height: 6),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.RichText(
              text: pw.TextSpan(
                style: const pw.TextStyle(fontSize: 11),
                children: [
                  const pw.TextSpan(text: 'na dan  '),
                  pw.TextSpan(
                    text: day,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  const pw.TextSpan(text: '.  '),
                  pw.TextSpan(
                    text: month,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  const pw.TextSpan(text: '.  '),
                  pw.TextSpan(
                    text: year,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  const pw.TextSpan(text: '. godine'),
                ],
              ),
            ),
          ),
          pw.Text(
            'PRILOG 4',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
      pw.SizedBox(height: 14),
      _sectionHeader('Podaci o pčelaru'),
      pw.SizedBox(height: 8),
      pw.Row(
        children: [
          pw.SizedBox(
            width: 210,
            child: pw.Text(
              'HID (veterinarski broj gazdinstva):',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
          pw.Expanded(child: _digitBoxes(page.hid, boxes: 12)),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Row(
        children: [
          pw.SizedBox(
            width: 210,
            child: pw.Text(
              'Ime i prezime pčelara:',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 0.7)),
              ),
              child: pw.Text(
                page.beekeeperName.isEmpty ? ' ' : page.beekeeperName,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 14),
      _sectionHeader('Podaci o pčelinjaku'),
      pw.SizedBox(height: 6),
      pw.Text(
        'Pčelinjak ${page.apiary.workNumber} · ${page.apiary.name}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 6),
      pw.Row(
        children: [
          pw.SizedBox(
            width: 210,
            child: pw.Text(
              'ID broj pčelinjaka:',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
          pw.Expanded(
            child: _digitBoxes(page.apiary.officialId ?? '', boxes: 12),
          ),
        ],
      ),
      pw.SizedBox(height: 14),
      _sectionHeader('Identifikacioni brojevi pčelinjih društava'),
      pw.SizedBox(height: 8),
      if (page.barcodes.isEmpty)
        pw.Text(
          'Nema aktivnih košnica na ovom pčelinjaku.',
          style: const pw.TextStyle(fontSize: 10),
        )
      else
        _barcodeGrid(page.barcodes),
      pw.SizedBox(height: 8),
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Ukupno društava: ${page.barcodes.length}',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ),
      pw.SizedBox(height: 18),
      pw.Text(
        'Izjavljujem pod punom materijalnom i krivičnom odgovornošću da su podaci o '
        'brojnom stanju pčelinjih društava na pčelinjaku tačni.',
        style: const pw.TextStyle(fontSize: 10),
        textAlign: pw.TextAlign.justify,
      ),
      pw.SizedBox(height: 28),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Column(
            children: [
              pw.Container(
                width: 180,
                height: 24,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 0.7)),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Svojeručni potpis pčelara',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    ];
  }

  void _prijavaFormDocx(DocxBuilder doc, _PrijavaPage page) {
    final day = _dayFmt.format(page.asOf);
    final month = _monthFmt.format(page.asOf);
    final year = _yearFmt.format(page.asOf);
    doc.heading('PRIJAVA STANJA NA PČELINJAKU');
    doc.paragraph(
      'na dan $day. $month. $year. godine                    PRILOG 4',
    );
    doc.emptyLine();
    doc.paragraph('Podaci o pčelaru', bold: true);
    doc.paragraph('HID (veterinarski broj gazdinstva): ${page.hid}');
    doc.paragraph('Ime i prezime pčelara: ${page.beekeeperName}');
    doc.emptyLine();
    doc.paragraph('Podaci o pčelinjaku', bold: true);
    doc.paragraph('Pčelinjak ${page.apiary.workNumber} · ${page.apiary.name}');
    doc.paragraph('ID broj pčelinjaka: ${page.apiary.officialId ?? ''}');
    doc.emptyLine();
    doc.paragraph('Identifikacioni brojevi pčelinjih društava', bold: true);
    if (page.barcodes.isEmpty) {
      doc.paragraph('Nema aktivnih košnica na ovom pčelinjaku.');
    } else {
      const cols = 4;
      final rows = <List<String>>[];
      for (var i = 0; i < page.barcodes.length; i += cols) {
        final end = (i + cols < page.barcodes.length)
            ? i + cols
            : page.barcodes.length;
        final row = page.barcodes.sublist(i, end);
        while (row.length < cols) {
          row.add('');
        }
        rows.add(row);
      }
      doc.table(List.filled(cols, ''), rows);
    }
    doc.paragraph('Ukupno društava: ${page.barcodes.length}', bold: true);
    doc.emptyLine();
    doc.paragraph(
      'Izjavljujem pod punom materijalnom i krivičnom odgovornošću da su podaci o '
      'brojnom stanju pčelinjih društava na pčelinjaku tačni.',
      justify: true,
    );
    doc.emptyLine();
    doc.paragraph('Svojeručni potpis pčelara: ________________________');
  }

  Future<List<pw.Widget>> _harvestPdf(int year) async {
    final d = await _harvestData(year);
    if (d.byApiary.isEmpty) {
      return [
        pw.Text(
          'Nema prinosa za $year.',
          style: const pw.TextStyle(fontSize: 12),
        ),
      ];
    }
    return [
      pw.Text(
        'Godina $year — ukupno ${d.total.toStringAsFixed(1)} kg',
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 12),
      pw.Text(
        'Po paši',
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 6),
      _pdfTable(
        headers: const ['Paša', 'kg'],
        data:
            d.pastureTotals.entries
                .map((e) => [e.key, e.value.toStringAsFixed(1)])
                .toList()
              ..sort((a, b) => a[0].compareTo(b[0])),
      ),
      pw.SizedBox(height: 16),
      pw.Text(
        'Po pčelinjaku i paši',
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 6),
      _pdfTable(
        headers: const ['Pčelinjak', 'Paša', 'kg'],
        data: d.byApiary.map((e) {
          final parts = e.key.split('|');
          return [
            '${parts[0]} · ${parts[1]}',
            parts[2],
            e.value.toStringAsFixed(1),
          ];
        }).toList(),
      ),
    ];
  }

  Future<void> _harvestDocx(DocxBuilder doc, int year) async {
    final d = await _harvestData(year);
    if (d.byApiary.isEmpty) {
      doc.paragraph('Nema prinosa za $year.');
      return;
    }
    doc.paragraph(
      'Godina $year — ukupno ${d.total.toStringAsFixed(1)} kg',
      bold: true,
    );
    doc.paragraph('Po paši', bold: true);
    doc.table(
      const ['Paša', 'kg'],
      d.pastureTotals.entries
          .map((e) => [e.key, e.value.toStringAsFixed(1)])
          .toList()
        ..sort((a, b) => a[0].compareTo(b[0])),
    );
    doc.paragraph('Po pčelinjaku i paši', bold: true);
    doc.table(
      const ['Pčelinjak', 'Paša', 'kg'],
      d.byApiary.map((e) {
        final parts = e.key.split('|');
        return [
          '${parts[0]} · ${parts[1]}',
          parts[2],
          e.value.toStringAsFixed(1),
        ];
      }).toList(),
    );
  }

  Future<String> _harvestCsv(int year) async {
    final d = await _harvestData(year);
    final buf = StringBuffer();
    buf.writeln('sekcija;pasa;pcelinjak;kg');
    for (final e
        in d.pastureTotals.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key))) {
      buf.writeln('po_pasi;${_csv(e.key)};;${e.value.toStringAsFixed(1)}');
    }
    for (final e in d.byApiary) {
      final parts = e.key.split('|');
      buf.writeln(
        'po_pcelinjaku;${_csv(parts[2])};${_csv('${parts[0]} · ${parts[1]}')};${e.value.toStringAsFixed(1)}',
      );
    }
    buf.writeln('ukupno;;;${d.total.toStringAsFixed(1)}');
    return buf.toString();
  }

  Future<List<pw.Widget>> _queensPdf() async {
    final d = await _queensData();
    if (d.rows.isEmpty) {
      return [
        pw.Text(
          'Nema aktivnih košnica.',
          style: const pw.TextStyle(fontSize: 12),
        ),
      ];
    }
    return [
      pw.Text(
        'Aktivne košnice: ${d.rows.length} · sa maticom: ${d.withQueen} · markirane: ${d.marked}',
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 12),
      _pdfTable(
        headers: const ['Pč.', 'RB', 'Barkod', 'God.', 'Mark.', 'Poreklo'],
        data: d.rows,
      ),
    ];
  }

  Future<void> _queensDocx(DocxBuilder doc) async {
    final d = await _queensData();
    if (d.rows.isEmpty) {
      doc.paragraph('Nema aktivnih košnica.');
      return;
    }
    doc.paragraph(
      'Aktivne košnice: ${d.rows.length} · sa maticom: ${d.withQueen} · markirane: ${d.marked}',
      bold: true,
    );
    doc.table(const [
      'Pč.',
      'RB',
      'Barkod',
      'God.',
      'Mark.',
      'Poreklo',
    ], d.rows);
  }

  Future<String> _queensCsv() async {
    final d = await _queensData();
    final buf = StringBuffer();
    buf.writeln('pcelinjak;rb;barkod;godina;markirana;poreklo');
    for (final r in d.rows) {
      buf.writeln(r.map(_csv).join(';'));
    }
    return buf.toString();
  }

  Future<List<pw.Widget>> _movedHistoryPdf() async {
    final rows = await _movedHistoryData();
    if (rows.isEmpty) {
      return [pw.Text('Nema evidentiranih selidbi.')];
    }
    return [
      _pdfTable(
        headers: const [
          'Pčelinjak',
          'RB',
          'Barkod',
          'Paša',
          'Lokacija',
          'Od',
          'Do',
          'Status',
        ],
        data: rows
            .map(
              (r) => [
                '${r.workNumber} · ${r.apiaryName}',
                '${r.orderNumber}',
                r.barcode,
                r.pasture,
                r.locationName,
                DateFormat('dd.MM.yyyy.').format(r.activeFrom),
                r.activeTo == null
                    ? '—'
                    : DateFormat('dd.MM.yyyy.').format(r.activeTo!),
                r.statusLabel,
              ],
            )
            .toList(),
      ),
    ];
  }

  Future<void> _movedHistoryDocx(DocxBuilder doc) async {
    final rows = await _movedHistoryData();
    if (rows.isEmpty) {
      doc.paragraph('Nema evidentiranih selidbi.');
      return;
    }
    doc.table(
      const [
        'Pčelinjak',
        'RB',
        'Barkod',
        'Paša',
        'Lokacija',
        'Od',
        'Do',
        'Status',
      ],
      rows
          .map(
            (r) => [
              '${r.workNumber} · ${r.apiaryName}',
              '${r.orderNumber}',
              r.barcode,
              r.pasture,
              r.locationName,
              DateFormat('dd.MM.yyyy.').format(r.activeFrom),
              r.activeTo == null
                  ? '—'
                  : DateFormat('dd.MM.yyyy.').format(r.activeTo!),
              r.statusLabel,
            ],
          )
          .toList(),
    );
  }

  Future<String> _movedHistoryCsv() async {
    final rows = await _movedHistoryData();
    final buf = StringBuffer();
    buf.writeln(
      'pcelinjak_rb;pcelinjak;rb_kosnice;barkod;pasa;lokacija;activeFrom;activeTo;status',
    );
    for (final r in rows) {
      buf.writeln(
        '${r.workNumber};${_csv(r.apiaryName)};${r.orderNumber};${_csv(r.barcode)};${_csv(r.pasture)};${_csv(r.locationName)};${DateFormat('dd.MM.yyyy.').format(r.activeFrom)};${r.activeTo == null ? '' : DateFormat('dd.MM.yyyy.').format(r.activeTo!)};${_csv(r.statusLabel)}',
      );
    }
    return buf.toString();
  }

  Future<String> _prijavaCsv(PrijavaStanjaOptions opts) async {
    final pages = await _prijavaPages(opts);
    final buf = StringBuffer();
    buf.writeln(
      'hid;ime;datum;pcelinjak_rb;pcelinjak_naziv;id_pcelinjaka;barkod',
    );
    final date = DateFormat('dd.MM.yyyy.').format(opts.asOf);
    for (final page in pages) {
      if (page.barcodes.isEmpty) {
        buf.writeln(
          '${_csv(page.hid)};${_csv(page.beekeeperName)};$date;'
          '${page.apiary.workNumber};${_csv(page.apiary.name)};${_csv(page.apiary.officialId ?? '')};',
        );
        continue;
      }
      for (final code in page.barcodes) {
        buf.writeln(
          '${_csv(page.hid)};${_csv(page.beekeeperName)};$date;'
          '${page.apiary.workNumber};${_csv(page.apiary.name)};${_csv(page.apiary.officialId ?? '')};${_csv(code)}',
        );
      }
    }
    return buf.toString();
  }

  String _csv(String v) {
    if (v.contains(';') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  pw.Widget _sectionHeader(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey300,
        border: pw.Border.all(color: PdfColors.grey600, width: 0.6),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _digitBoxes(String value, {required int boxes}) {
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    final digits = List.generate(
      boxes,
      (i) => i < cleaned.length ? cleaned[i] : '',
    );
    return pw.Row(
      children: [
        for (final d in digits)
          pw.Expanded(
            child: pw.Container(
              margin: const pw.EdgeInsets.only(right: 2),
              height: 20,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey700, width: 0.6),
              ),
              child: pw.Text(
                d,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  pw.Widget _barcodeGrid(List<String> barcodes) {
    const cols = 4;
    final rows = <List<String>>[];
    for (var i = 0; i < barcodes.length; i += cols) {
      final end = (i + cols < barcodes.length) ? i + cols : barcodes.length;
      final row = barcodes.sublist(i, end);
      while (row.length < cols) {
        row.add('');
      }
      rows.add(row);
    }
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.5),
      children: [
        for (final row in rows)
          pw.TableRow(
            children: [
              for (final cell in row)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 5,
                  ),
                  child: pw.Text(cell, style: const pw.TextStyle(fontSize: 10)),
                ),
            ],
          ),
      ],
    );
  }

  pw.Widget _pdfTable({
    required List<String> headers,
    required List<List<String>> data,
  }) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.centerLeft,
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
    );
  }
}

class _PrijavaPage {
  _PrijavaPage({
    required this.apiary,
    required this.barcodes,
    required this.beekeeperName,
    required this.hid,
    required this.asOf,
  });

  final Apiary apiary;
  final List<String> barcodes;
  final String beekeeperName;
  final String hid;
  final DateTime asOf;
}

class _HarvestData {
  _HarvestData({
    required this.year,
    required this.total,
    required this.pastureTotals,
    required this.byApiary,
  });

  final int year;
  final double total;
  final Map<String, double> pastureTotals;
  final List<MapEntry<String, double>> byApiary;
}

class _QueensData {
  _QueensData({
    required this.rows,
    required this.withQueen,
    required this.marked,
  });

  final List<List<String>> rows;
  final int withQueen;
  final int marked;
}

class _MovedHistoryRow {
  _MovedHistoryRow({
    required this.workNumber,
    required this.apiaryName,
    required this.orderNumber,
    required this.barcode,
    required this.pasture,
    required this.locationName,
    required this.activeFrom,
    required this.activeTo,
    required this.status,
  });

  final int workNumber;
  final String apiaryName;
  final int orderNumber;
  final String barcode;
  final String pasture;
  final String locationName;
  final DateTime activeFrom;
  final DateTime? activeTo;
  final String status;

  String get statusLabel => switch (status) {
    'ACTIVE' => 'Aktivna',
    'FINISHED' => 'Završena',
    'REMOVED' => 'Uklonjena',
    _ => status,
  };
}

class _HarvestAgg {
  _HarvestAgg({
    required this.apiary,
    required this.workNumber,
    required this.pasture,
    required this.kg,
  });

  final String apiary;
  final int workNumber;
  final String pasture;
  final double kg;
}
