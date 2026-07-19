import 'package:get_it/get_it.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_network_service.dart';
import 'package:crisis_mesh/core/services/messaging/message_storage_service.dart';
import 'package:crisis_mesh/core/services/rescue/emergency_service.dart';
import 'package:crisis_mesh/core/services/mesh/encryption_service.dart';
import 'package:crisis_mesh/core/services/ai/ai_service.dart';
import 'package:crisis_mesh/core/services/messaging/feed_service.dart';
import 'package:crisis_mesh/core/services/messaging/channel_service.dart';
import 'package:crisis_mesh/core/services/maps/map_service.dart';
import 'package:crisis_mesh/core/services/messaging/group_service.dart';
import 'package:crisis_mesh/core/services/rescue/rescue_medical_service.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_routing_service.dart';
import 'package:crisis_mesh/core/services/hardware/hardware_sensor_service.dart';
import 'package:crisis_mesh/core/services/community/community_service.dart';
import 'package:crisis_mesh/core/services/maps/ar_evacuation_service.dart';
import 'package:crisis_mesh/core/services/mesh/gateway_service.dart';

/// Global service locator instance
final getIt = GetIt.instance;

/// Initialize all services and register with GetIt
Future<void> setupServiceLocator() async {
  // Storage service (singleton)
  getIt.registerLazySingleton<MessageStorageService>(
    () => MessageStorageService(),
  );

  // Initialize storage
  await getIt<MessageStorageService>().initialize();

  // Encryption service (singleton)
  getIt.registerLazySingleton<EncryptionService>(
    () => EncryptionService(),
  );

  // Initialize encryption
  await getIt<EncryptionService>().initialize();

  // Mesh network service (singleton)
  getIt.registerLazySingleton<MeshNetworkService>(
    () => MeshNetworkService(),
  );

  // Feed service (singleton)
  getIt.registerLazySingleton<FeedService>(
    () => FeedService(getIt<MeshNetworkService>()),
  );

  // Initialize feed
  await getIt<FeedService>().initialize();

  // Channel service (singleton)
  getIt.registerLazySingleton<ChannelService>(
    () => ChannelService(getIt<MeshNetworkService>()),
  );

  // Initialize channel service
  await getIt<ChannelService>().initialize();

  // Group service (singleton)
  getIt.registerLazySingleton<GroupService>(
    () => GroupService(getIt<MeshNetworkService>()),
  );

  // Initialize group service
  await getIt<GroupService>().initialize();

  // Emergency service (singleton)
  getIt.registerLazySingleton<EmergencyService>(
    () => EmergencyService(),
  );

  // Rescue & Medical service (singleton)
  getIt.registerLazySingleton<RescueMedicalService>(
    () => RescueMedicalService(getIt<MeshNetworkService>()),
  );

  // Initialize rescue & medical service
  await getIt<RescueMedicalService>().initialize();

  // Mesh Routing service (singleton)
  getIt.registerLazySingleton<MeshRoutingService>(
    () => MeshRoutingService(getIt<MeshNetworkService>()),
  );

  // Initialize mesh routing service
  await getIt<MeshRoutingService>().initialize();

  // Hardware & Sensor service (singleton)
  getIt.registerLazySingleton<HardwareSensorService>(
    () => HardwareSensorService(getIt<MeshNetworkService>()),
  );

  // Initialize hardware sensor service
  getIt<HardwareSensorService>().initialize();

  // Community service (singleton)
  getIt.registerLazySingleton<CommunityService>(
    () => CommunityService(getIt<MeshNetworkService>()),
  );

  // Initialize community service
  await getIt<CommunityService>().initialize();

  // AR Evacuation service (singleton)
  getIt.registerLazySingleton<ArEvacuationService>(
    () => ArEvacuationService(),
  );

  // Initialize AR service
  getIt<ArEvacuationService>().initialize();

  // Gateway Relay service (singleton)
  getIt.registerLazySingleton<GatewayService>(
    () => GatewayService(),
  );

  // Initialize Gateway service
  getIt<GatewayService>().initialize();

  // AI service (singleton)
  getIt.registerLazySingleton<AIService>(
    () => AIService(),
  );

  // Initialize AI service
  await getIt<AIService>().initialize();

  // Map service (singleton)
  getIt.registerLazySingleton<MapService>(
    () => MapService(),
  );

  // Initialize Map service
  await getIt<MapService>().initialize();
}

/// Clean up and dispose all services
Future<void> disposeServices() async {
  await getIt<MessageStorageService>().close();
  getIt<MeshNetworkService>().dispose();
  await getIt.reset();
}
