import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rap_trainer/lane/lane_plan.dart';
import 'package:rap_trainer/lane/lane_view.dart';

void main() {
  testWidgets('lane paints and the cue updates as the beat moves',
      (tester) async {
    final beat = ValueNotifier<double>(0.5);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 300,
          child: LaneView(beat: beat, planner: const LanePlanner(LaneConfig())),
        ),
      ),
    ));
    expect(find.text('Get ready…'), findsOneWidget);

    beat.value = 5.2;
    await tester.pump();
    expect(find.textContaining('Freestyle, then land on'), findsOneWidget);

    beat.value = 9.0;
    await tester.pump();
    expect(find.textContaining('End on a rhyme for'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
