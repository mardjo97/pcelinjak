import 'dart:io';

void main() {
  final base = Directory('lib/l10n');
  final sr = File('${base.path}/app_sr.arb').readAsStringSync();

  var bs = sr.replaceFirst('"@@locale": "sr"', '"@@locale": "bs"');
  bs = bs.replaceAll('Nesinhronizovani', 'Nesinhronizirani');
  bs = bs.replaceAll('Izmena pčelinjaka', 'Izmjena pčelinjaka');
  bs = bs.replaceAll('"edit": "Izmeni"', '"edit": "Izmijeni"');
  bs = bs.replaceAll('Izmeni u grupi', 'Izmijeni u grupi');
  File('${base.path}/app_bs.arb').writeAsStringSync(bs);

  final cnr = sr.replaceFirst('"@@locale": "sr"', '"@@locale": "cnr"');
  File('${base.path}/app_cnr.arb').writeAsStringSync(cnr);

  stdout.writeln(File('${base.path}/app_bs.arb').readAsStringSync().substring(0, 80));
  stdout.writeln('ok');
}
