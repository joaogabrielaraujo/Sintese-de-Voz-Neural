import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/main.dart';

void main() {
  testWidgets('TCCNeuralApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TCCNeuralApp());
    expect(find.text('VozLume'), findsWidgets);
    expect(find.text('OFFLINE'), findsOneWidget);
    expect(find.text('Importar EPUB'), findsOneWidget);
  });
}
