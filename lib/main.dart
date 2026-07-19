import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/di/service_locator.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_network_service.dart';
import 'package:crisis_mesh/core/services/ai/ai_service.dart';
import 'package:crisis_mesh/core/services/maps/map_service.dart';
import 'package:crisis_mesh/core/services/rescue/emergency_service.dart';
import 'package:crisis_mesh/core/services/messaging/feed_service.dart';
import 'package:crisis_mesh/core/services/messaging/channel_service.dart';
import 'package:crisis_mesh/core/services/messaging/group_service.dart';
import 'package:crisis_mesh/core/services/rescue/rescue_medical_service.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_routing_service.dart';
import 'package:crisis_mesh/core/services/hardware/hardware_sensor_service.dart';
import 'package:crisis_mesh/core/services/community/community_service.dart';
import 'package:crisis_mesh/core/services/maps/ar_evacuation_service.dart';
import 'package:crisis_mesh/core/services/mesh/gateway_service.dart';
import 'package:crisis_mesh/features/messaging/ui/screens/home_screen.dart';
import 'ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await setupServiceLocator();
  
  runApp(const CrisisMeshApp());
}

class CrisisMeshApp extends StatelessWidget {
  const CrisisMeshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => getIt<MeshNetworkService>(),
        ),
        ChangeNotifierProvider(
          create: (_) => getIt<AIService>(),
        ),
        ChangeNotifierProvider(
          create: (_) => getIt<MapService>(),
        ),
        ChangeNotifierProvider(
          create: (_) => getIt<EmergencyService>(),
        ),
        ChangeNotifierProvider(
          create: (_) => getIt<FeedService>(),
        ),
        ChangeNotifierProvider(
          create: (_) => getIt<ChannelService>(),
        ),
        ChangeNotifierProvider(
          create: (_) => getIt<GroupService>(),
        ),
        ChangeNotifierProvider(
          create: (_) => getIt<RescueMedicalService>(),
        ),
        ChangeNotifierProvider(
          create: (_) => getIt<MeshRoutingService>(),
        ),
        ChangeNotifierProvider(
          create: (_) => getIt<HardwareSensorService>(),
        ),
        ChangeNotifierProvider(
          create: (_) => getIt<CommunityService>(),
        ),
        ChangeNotifierProvider(
          create: (_) => getIt<ArEvacuationService>(),
        ),
        ChangeNotifierProvider(
          create: (_) => getIt<GatewayService>(),
        ),
      ],
      child: MaterialApp(
        title: 'Crisis Mesh',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
