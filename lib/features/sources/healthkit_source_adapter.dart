import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../today/models/day_models.dart';
import 'source_adapter.dart';

class HealthKitSourceAdapter implements SourceAdapter, AuthorizationSourceAdapter {
  HealthKitSourceAdapter({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('perfect_day/healthkit');

  final MethodChannel _channel;

  @override
  SourceType get source => SourceType.health;

  bool get _isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<SourceConnectionState> connectionState() async {
    if (!_isSupportedPlatform) {
      return SourceConnectionState(
        type: source,
        connected: false,
        lastSyncAt: null,
      );
    }

    try {
      final Map<Object?, Object?>? raw =
          await _channel.invokeMapMethod<Object?, Object?>('connectionStatus');
      final bool connected = raw?['connected'] as bool? ?? false;
      final int? lastSyncMs = raw?['lastSyncAtMs'] as int?;
      return SourceConnectionState(
        type: source,
        connected: connected,
        lastSyncAt: lastSyncMs == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(lastSyncMs),
      );
    } catch (_) {
      return SourceConnectionState(
        type: source,
        connected: false,
        lastSyncAt: null,
      );
    }
  }

  @override
  Future<bool> requestAuthorization() async {
    if (!_isSupportedPlatform) {
      return false;
    }

    try {
      final bool? granted =
          await _channel.invokeMethod<bool>('requestAuthorization');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<SourceImportResult> importRange({
    required DateTime from,
    required DateTime to,
  }) async {
    if (!_isSupportedPlatform) {
      return const SourceImportResult(source: SourceType.health, events: <DayEvent>[]);
    }

    try {
      final List<dynamic>? rawEvents = await _channel.invokeMethod<List<dynamic>>(
        'importRange',
        <String, dynamic>{
          'fromMs': from.millisecondsSinceEpoch,
          'toMs': to.millisecondsSinceEpoch,
        },
      );

      final List<DayEvent> events = (rawEvents ?? <dynamic>[])
          .whereType<Map<dynamic, dynamic>>()
          .map((raw) => _mapRawEvent(raw))
          .whereType<DayEvent>()
          .toList();

      return SourceImportResult(source: SourceType.health, events: events);
    } catch (_) {
      return const SourceImportResult(source: SourceType.health, events: <DayEvent>[]);
    }
  }

  DayEvent? _mapRawEvent(Map<dynamic, dynamic> raw) {
    final String? id = raw['id'] as String?;
    final String? domainName = raw['domain'] as String?;
    final int? startMs = raw['startAtMs'] as int?;
    final int? endMs = raw['endAtMs'] as int?;
    if (id == null || domainName == null || startMs == null || endMs == null) {
      return null;
    }

    final DayDomain? domain = _domainFromName(domainName);
    if (domain == null) {
      return null;
    }

    return DayEvent(
      id: id,
      domain: domain,
      startAt: DateTime.fromMillisecondsSinceEpoch(startMs),
      endAt: DateTime.fromMillisecondsSinceEpoch(endMs),
      source: raw['source'] as String? ?? 'healthkit',
      note: raw['note'] as String?,
    );
  }

  DayDomain? _domainFromName(String name) {
    for (final DayDomain value in DayDomain.values) {
      if (value.name == name) {
        return value;
      }
    }
    return null;
  }
}
