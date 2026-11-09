import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fitness_app/services/connectivity_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression tests for the "Please check your internet connection" toast that
/// used to appear on every cold start, because a single early (and often
/// transiently wrong) connectivity reading was trusted.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('PonnamKarthik/fluttertoast');
  late int toastCount;
  late StreamController<List<ConnectivityResult>> stream;

  setUp(() {
    toastCount = 0;
    stream = StreamController<List<ConnectivityResult>>.broadcast();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'showToast') toastCount++;
      return true;
    });
    NetworkService.connectivityStreamForTesting = stream.stream;
    NetworkService.offlineConfirmDelay = const Duration(seconds: 3);
  });

  tearDown(() async {
    await NetworkService.disposeForTesting();
    NetworkService.resetTestingOverrides();
    await stream.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('transient "none" at launch does NOT toast when the uplink works',
      (tester) async {
    NetworkService.connectivityCheckerForTesting =
        () async => [ConnectivityResult.none];
    NetworkService.internetAccessCheckerForTesting = () async => true;

    unawaited(NetworkService.initialize());
    await tester.pump(const Duration(seconds: 10));

    expect(toastCount, 0);
  });

  testWidgets('really being offline still shows the toast once', (tester) async {
    NetworkService.connectivityCheckerForTesting =
        () async => [ConnectivityResult.none];
    NetworkService.internetAccessCheckerForTesting = () async => false;

    unawaited(NetworkService.initialize());
    await tester.pump(const Duration(seconds: 1));
    expect(toastCount, 0, reason: 'must wait before warning');

    await tester.pump(const Duration(seconds: 5));
    expect(toastCount, 1);
  });

  testWidgets('a quick drop and reconnect does not toast', (tester) async {
    NetworkService.connectivityCheckerForTesting =
        () async => [ConnectivityResult.wifi];
    NetworkService.internetAccessCheckerForTesting = () async => false;

    unawaited(NetworkService.initialize());
    await tester.pump();

    stream.add([ConnectivityResult.none]);
    await tester.pump(const Duration(seconds: 1));
    stream.add([ConnectivityResult.wifi]);
    await tester.pump(const Duration(seconds: 10));

    expect(toastCount, 0);
  });

  testWidgets('VPN-only connection is not treated as offline', (tester) async {
    NetworkService.connectivityCheckerForTesting =
        () async => [ConnectivityResult.vpn];
    NetworkService.internetAccessCheckerForTesting = () async => false;

    unawaited(NetworkService.initialize());
    await tester.pump(const Duration(seconds: 10));

    expect(toastCount, 0);
  });

  testWidgets('calling initialize twice does not stack listeners',
      (tester) async {
    NetworkService.connectivityCheckerForTesting =
        () async => [ConnectivityResult.wifi];
    NetworkService.internetAccessCheckerForTesting = () async => false;

    unawaited(NetworkService.initialize());
    await tester.pump();
    unawaited(NetworkService.initialize());
    await tester.pump();

    expect(stream.hasListener, isTrue);
    stream.add([ConnectivityResult.none]);
    await tester.pump(const Duration(seconds: 10));

    expect(toastCount, 1);
  });
}
