import 'dart:io';

void main() {
  final f = File('lib/screens/group_screen.dart');
  var s = f.readAsStringSync();
  s = s.replaceAll(r'$title', r'${title(context)}');
  f.writeAsStringSync(s);
  print(s.contains(r'${title(context)}'));
}
