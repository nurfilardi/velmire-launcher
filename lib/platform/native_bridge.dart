import 'package:flutter/services.dart';

class NativeBridge {
  static const channelName = 'id.samp.launcher/native';
  final MethodChannel _channel;

  NativeBridge({MethodChannel? channel}) : _channel = channel ?? const MethodChannel(channelName);

  Future<bool> hasStorageAccess() async =>
      await _channel.invokeMethod<bool>('hasStorageAccess') ?? false;

  Future<bool> requestStorageAccess() async =>
      await _channel.invokeMethod<bool>('requestStorageAccess') ?? false;

  Future<bool> isInstalled(String package) async =>
      await _channel.invokeMethod<bool>('isInstalled', {'package': package}) ?? false;

  Future<bool> launchGame({required String package, required String activity}) async =>
      await _channel.invokeMethod<bool>('launchGame', {
        'package': package,
        'activity': activity,
      }) ??
      false;

  Future<bool> installApk(String path) async =>
      await _channel.invokeMethod<bool>('installApk', {'path': path}) ?? false;
}
