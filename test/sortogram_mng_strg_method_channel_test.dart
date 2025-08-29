import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortogram_mng_strg/sortogram_mng_strg_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelSortogramMngStrg platform = MethodChannelSortogramMngStrg();
  const MethodChannel channel = MethodChannel('sortogram_mng_strg');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
