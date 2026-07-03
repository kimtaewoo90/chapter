import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/config/store_links.dart';
import '../core/constants/dev_flags.dart';
import '../core/utils/app_version_compare.dart';
import '../models/app_version_gate.dart';

/// Firebase Remote Config로 최소 지원 버전·점검 모드를 확인합니다.
class AppVersionService {
  AppVersionService({
    FirebaseRemoteConfig? remoteConfig,
    Future<PackageInfo> Function()? packageInfoLoader,
  })  : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance,
        _packageInfoLoader = packageInfoLoader ?? PackageInfo.fromPlatform;

  final FirebaseRemoteConfig _remoteConfig;
  final Future<PackageInfo> Function() _packageInfoLoader;

  static const minSupportedVersionKey = 'min_supported_version';
  static const maintenanceModeKey = 'maintenance_mode';
  static const forceUpdateTitleKey = 'force_update_title';
  static const forceUpdateMessageKey = 'force_update_message';
  static const maintenanceTitleKey = 'maintenance_title';
  static const maintenanceMessageKey = 'maintenance_message';
  static const iosStoreUrlKey = 'ios_store_url';
  static const androidStoreUrlKey = 'android_store_url';

  /// 앱 내장 기본값 — Remote Config 미연결 시에도 첫 출시 버전은 통과
  static const defaultMinSupportedVersion = '1.0.0';

  bool _configured = false;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
        ),
      );
      await _remoteConfig.setDefaults(const {
        minSupportedVersionKey: defaultMinSupportedVersion,
        maintenanceModeKey: false,
        forceUpdateTitleKey: '업데이트가 필요해요',
        forceUpdateMessageKey: '더 안정적인 챕터를 위해 최신 버전으로 업데이트해 주세요.',
        maintenanceTitleKey: '잠시 점검 중이에요',
        maintenanceMessageKey: '곧 다시 만나요. 잠시만 기다려 주세요.',
        iosStoreUrlKey: '',
        androidStoreUrlKey: '',
      });
      _configured = true;
    } catch (e, st) {
      debugPrint('Remote Config defaults skipped: $e\n$st');
    }
  }

  Future<String> currentVersionLabel() async {
    final info = await _packageInfoLoader();
    return info.version;
  }

  Future<String> currentBuildLabel() async {
    final info = await _packageInfoLoader();
    return '${info.version}+${info.buildNumber}';
  }

  Future<AppVersionGateResult> evaluate({bool forceFetch = false}) async {
    final current = await currentVersionLabel();

    if (kBypassVersionGate) {
      return AppVersionGateResult(
        currentVersion: current,
        minSupportedVersion: defaultMinSupportedVersion,
      );
    }

    await _ensureConfigured();

    if (forceFetch) {
      try {
        await _remoteConfig.fetchAndActivate();
      } catch (e, st) {
        debugPrint('Remote Config fetch skipped: $e\n$st');
      }
    } else {
      try {
        await _remoteConfig.fetchAndActivate();
      } catch (e, st) {
        debugPrint('Remote Config fetch skipped, using cache/defaults: $e\n$st');
      }
    }

    final minSupported = _remoteConfig.getString(minSupportedVersionKey).trim().isEmpty
        ? defaultMinSupportedVersion
        : _remoteConfig.getString(minSupportedVersionKey).trim();
    final maintenance = _remoteConfig.getBool(maintenanceModeKey);
    final storeUrl = _resolveStoreUrl();

    if (maintenance) {
      return AppVersionGateResult(
        currentVersion: current,
        minSupportedVersion: minSupported,
        blockReason: VersionBlockReason.maintenance,
        title: _remoteConfig.getString(maintenanceTitleKey).trim().isEmpty
            ? '잠시 점검 중이에요'
            : _remoteConfig.getString(maintenanceTitleKey).trim(),
        message: _remoteConfig.getString(maintenanceMessageKey).trim().isEmpty
            ? '곧 다시 만나요. 잠시만 기다려 주세요.'
            : _remoteConfig.getString(maintenanceMessageKey).trim(),
        storeUrl: storeUrl,
      );
    }

    if (isAppVersionOlderThan(current, minSupported)) {
      return AppVersionGateResult(
        currentVersion: current,
        minSupportedVersion: minSupported,
        blockReason: VersionBlockReason.forceUpdate,
        title: _remoteConfig.getString(forceUpdateTitleKey).trim().isEmpty
            ? '업데이트가 필요해요'
            : _remoteConfig.getString(forceUpdateTitleKey).trim(),
        message: _remoteConfig.getString(forceUpdateMessageKey).trim().isEmpty
            ? '더 안정적인 챕터를 위해 최신 버전으로 업데이트해 주세요.'
            : _remoteConfig.getString(forceUpdateMessageKey).trim(),
        storeUrl: storeUrl,
      );
    }

    return AppVersionGateResult(
      currentVersion: current,
      minSupportedVersion: minSupported,
    );
  }

  String _resolveStoreUrl() {
    final fromConfig = Platform.isIOS
        ? _remoteConfig.getString(iosStoreUrlKey).trim()
        : _remoteConfig.getString(androidStoreUrlKey).trim();
    if (fromConfig.isNotEmpty) return fromConfig;

    if (Platform.isIOS) {
      return StoreLinks.defaultIosStoreUrl;
    }
    return StoreLinks.androidStoreUrl;
  }
}
