import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/main.dart';

void main() {
  testWidgets('TCCNeuralApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TCCNeuralApp());
    expect(find.textContaining('Leitor EPUB'), findsOneWidget);
  });
}
