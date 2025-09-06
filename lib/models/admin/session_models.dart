enum DevicePlatform { android, ios, web, desktop }

class DeviceSnapshot {
  final String deviceId;
  final DevicePlatform platform;
  final String osVersion;
  final String appVersion;
  final String buildNumber;
  final String model;
  final DateTime lastSeen;
  
  const DeviceSnapshot({
    required this.deviceId,
    required this.platform,
    required this.osVersion,
    required this.appVersion,
    required this.buildNumber,
    required this.model,
    required this.lastSeen,
  });
}

class UserRuntimeFlags {
  final bool verboseLogging;
  final bool betaNutrition;
  final bool betaMusic;
  final bool forceLiteAnimations;
  
  const UserRuntimeFlags({
    this.verboseLogging = false,
    this.betaNutrition = false,
    this.betaMusic = false,
    this.forceLiteAnimations = false,
  });
  
  UserRuntimeFlags copyWith({
    bool? verboseLogging,
    bool? betaNutrition,
    bool? betaMusic,
    bool? forceLiteAnimations,
  }) =>
      UserRuntimeFlags(
        verboseLogging: verboseLogging ?? this.verboseLogging,
        betaNutrition: betaNutrition ?? this.betaNutrition,
        betaMusic: betaMusic ?? this.betaMusic,
        forceLiteAnimations: forceLiteAnimations ?? this.forceLiteAnimations,
      );
}

class UserDiagnostics {
  final String userId;
  final String email;
  final String role; // client/coach/admin
  final String plan; // free/pro
  final String timezone;
  final String locale;
  final List<DeviceSnapshot> devices;
  final UserRuntimeFlags flags;
  
  const UserDiagnostics({
    required this.userId,
    required this.email,
    required this.role,
    required this.plan,
    required this.timezone,
    required this.locale,
    this.devices = const [],
    this.flags = const UserRuntimeFlags(),
  });
}
