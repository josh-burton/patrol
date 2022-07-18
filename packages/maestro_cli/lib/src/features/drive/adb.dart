import 'dart:async';

import 'package:adb/adb.dart';
import 'package:maestro_cli/src/common/common.dart';
import 'package:maestro_cli/src/features/drive/constants.dart';
import 'package:path/path.dart' as path;

class MaestroAdb {
  MaestroAdb() : _adb = Adb();

  final Adb _adb;

  Future<void> init() => _adb.init();

  Future<List<String>> devices() => _adb.devices();

  Future<void> installApps({String? device, bool debug = false}) async {
    final serverInstallProgress = log.progress('Installing server');
    try {
      final p = path.join(
        artifactPath,
        debug ? debugServerArtifactFile : serverArtifactFile,
      );
      await _adb.forceInstallApk(p, device: device);
    } catch (err) {
      serverInstallProgress.fail('Failed to install server');
      rethrow;
    }
    serverInstallProgress.complete('Installed server');

    final instrumentInstallProgress =
        log.progress('Installing instrumentation');
    try {
      final p = path.join(
        artifactPath,
        debug ? debugInstrumentationArtifactFile : instrumentationArtifactFile,
      );
      await _adb.forceInstallApk(p, device: device);
    } catch (err) {
      instrumentInstallProgress.fail('Failed to install instrumentation');
      rethrow;
    }

    instrumentInstallProgress.complete('Installed instrumentation');
  }

  Future<void> forwardPorts(int port, {String? device}) async {
    final progress = log.progress('Forwarding ports');

    try {
      await _adb.forwardPorts(
        fromHost: port,
        toDevice: port,
        device: device,
      );
    } catch (err) {
      progress.fail('Failed to forward ports');
      rethrow;
    }

    progress.complete('Forwarded ports');
  }

  void runServer({
    required String? device,
    required int port,
  }) {
    _adb.instrument(
      packageName: 'pl.leancode.automatorserver.test',
      intentClass: 'androidx.test.runner.AndroidJUnitRunner',
      device: device,
      onStdout: log.info,
      onStderr: log.severe,
      arguments: {envPortKey: port.toString()},
    );
  }
}