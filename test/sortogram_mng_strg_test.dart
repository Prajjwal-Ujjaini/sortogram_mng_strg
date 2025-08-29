import 'package:flutter_test/flutter_test.dart';
import 'package:sortogram_mng_strg/sortogram_mng_strg.dart';
import 'package:sortogram_mng_strg/sortogram_mng_strg_platform_interface.dart';
import 'package:sortogram_mng_strg/sortogram_mng_strg_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSortogramMngStrgPlatform
    with MockPlatformInterfaceMixin
    implements SortogramMngStrgPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SortogramMngStrgPlatform initialPlatform = SortogramMngStrgPlatform.instance;

  test('$MethodChannelSortogramMngStrg is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSortogramMngStrg>());
  });

  test('getPlatformVersion', () async {
    SortogramMngStrg sortogramMngStrgPlugin = SortogramMngStrg();
    MockSortogramMngStrgPlatform fakePlatform = MockSortogramMngStrgPlatform();
    SortogramMngStrgPlatform.instance = fakePlatform;

    expect(await sortogramMngStrgPlugin.getPlatformVersion(), '42');
  });
}
