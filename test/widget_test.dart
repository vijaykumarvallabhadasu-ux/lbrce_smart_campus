import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lbrce_smart_campus_navigator/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Smart Campus app starts on WelcomeScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const LBRCEApp());
    await tester.pumpAndSettle();

    expect(find.text('LBRCE'), findsOneWidget);
    expect(find.text('Smart Campus'), findsOneWidget);
    expect(find.text('Navigator'), findsOneWidget);
    expect(find.text('Explore Campus'), findsOneWidget);
  });

  testWidgets('Explore Campus button navigates to MainScreen with Explore, Saved, My GPS tabs',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const LBRCEApp());
    await tester.pumpAndSettle();

    // Scroll to and tap Explore Campus button
    final exploreButton = find.text('Explore Campus');
    await tester.ensureVisible(exploreButton);
    await tester.pumpAndSettle();
    await tester.tap(exploreButton);
    await tester.pumpAndSettle();

    // Verify MainScreen elements
    expect(find.text('LBRCE'), findsWidgets);
    expect(find.text('SMART CAMPUS NAVIGATOR'), findsOneWidget);
    expect(find.text('Explore Places'), findsOneWidget);
    expect(find.text('Total Places'), findsOneWidget);

    // Verify bottom navigation items (3 destinations: Explore, Saved, My GPS)
    expect(find.byType(NavigationDestination), findsNWidgets(3));
  });

  testWidgets('Navigation bar switches to Saved and My GPS screens',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const LBRCEApp());
    await tester.pumpAndSettle();

    final exploreButton = find.text('Explore Campus');
    await tester.ensureVisible(exploreButton);
    await tester.pumpAndSettle();
    await tester.tap(exploreButton);
    await tester.pumpAndSettle();

    // Switch to Saved tab using bottom navigation bar destination
    await tester.tap(find.text('Saved').last);
    await tester.pumpAndSettle();
    expect(find.text('Your Saved Places'), findsOneWidget);
    expect(find.text('No saved places yet'), findsOneWidget);
    expect(find.text('Browse Campus Places'), findsOneWidget);

    // Switch to My GPS tab
    await tester.tap(find.text('My GPS').last);
    await tester.pumpAndSettle();
    expect(find.text('Current Location'), findsOneWidget);
    expect(find.text('Enable Location'), findsOneWidget);
    expect(find.text('Open Current Location in Google Maps'), findsOneWidget);
    expect(find.text('Official Campus Entrance Pin'), findsOneWidget);
  });

  testWidgets('Search filters places on ExploreScreen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const LBRCEApp());
    await tester.pumpAndSettle();

    final exploreButton = find.text('Explore Campus');
    await tester.ensureVisible(exploreButton);
    await tester.pumpAndSettle();
    await tester.tap(exploreButton);
    await tester.pumpAndSettle();

    // Enter search text in search TextField
    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'Central Library');
    await tester.pumpAndSettle();

    // Place card for Central Library should be visible, others filtered out
    expect(find.widgetWithText(PlaceCard, 'Central Library'), findsOneWidget);
    expect(find.widgetWithText(PlaceCard, 'ECE Block'), findsNothing);
  });
}
