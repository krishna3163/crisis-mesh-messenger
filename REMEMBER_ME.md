# AI Context & Project Memory (REMEMBER_ME)

This file serves as the primary context for AI assistants to understand the **Crisis Mesh Messenger** project. It contains the project's purpose, architecture, state, and a log of significant changes.

---

## 🚀 Project Overview

**Project Name:** Crisis Mesh Messenger (The Ultimate Disaster Communication Platform)
**Mission:** A "super-app" for crisis situations that works entirely offline. It combines mesh networking, AI, mapping, rescue coordination, and community resilience tools.
**Framework:** Flutter (Android & iOS)
**Networking Strategy:** Seamless switching between Bluetooth LE, WiFi Direct, local WiFi, Internet, and LoRa.

---

## 🏗️ Technical Architecture

### 1. State Management & DI
- **State Management:** `Provider` (existing) + planned `BLoC` for complex features.
- **Dependency Injection:** `GetIt` (Service Locator pattern).
- **Service Locator File:** `lib/core/di/service_locator.dart`.

### 2. Core Layers (Target Structure)
- **UI Layer (`lib/ui/`):**
    - `screens/`: High-level pages (Home, Chat, Feed, Calls).
    - `widgets/`: Reusable components (Message bubbles, Peer tiles).
    - `theme/`: Material 3 design system.
- **Core Layer (`lib/core/`):**
    - `models/`: Immutable data classes (`Message`, `Peer`, `Conversation`, `FeedPost`, `EmergencySignal`).
    - `services/`: Business logic divided into specialized modules.
        - `mesh/`: `MeshNetworkService`, `EncryptionService`.
        - `messaging/`: `MessageStorageService`, `FeedService`.
        - `rescue/`: `EmergencyService`.
        - `ai/`: `AIService`.
        - `maps/`: `MapService`.
    - `utils/`: Constants and helpers.
- **Features Layer (`lib/features/`):** Domain-specific modules like `messaging`, `network`, `calls`, `social`, `ai`, `maps`, `rescue`.

### 3. Key Services
- **`MeshNetworkService`:** Real `nearby_connections` implementation. Includes deduplication and handshake for E2EE.
- **`EncryptionService`:** End-to-End Encryption using X25519 and AES-GCM.
- **`MapService`:** Manages interactive maps and markers for SOS/Peers using `flutter_map`.
- **`AIService`:** Offline AI Assistant with a structured knowledge base for first-aid guidance.
- **`EmergencyService`:** Manages SOS signals and mesh propagation.

---

## 📊 Project Roadmap (Vision)

### Phase 1: Core Communication (🚧 In Progress)
- [x] One-to-one & Group chat UI.
- [x] Storage & Basic routing logic.
- [x] Real Bluetooth/WiFi Direct mesh integration (Android).
- [x] End-to-End Encryption (E2EE) handshake.
- [x] Secure Local Storage (Hardened).
- [ ] P2P Voice/Video calls (WebRTC).
- [x] Broadcast messaging & Channels.

### Phase 2: AI & Smart Features (🚧 In Progress)
- [x] Offline AI Assistant UI.
- [x] Structured First-Aid Knowledge Base (CPR, Bleeding, etc.).
- [ ] Real TFLite integration (Gemma/SelfAid).
- [ ] Rescue Priority Scoring & Missing Person Matching.

### Phase 3: Mapping & Location (🚧 Started)
- [x] Interactive Map integration (`flutter_map`).
- [x] Live SOS markers on the map.
- [ ] Offline MBTiles support.
- [ ] Hazard Zone visualization.

---

## 🛠️ AI Instructions & Best Practices

1. **Service Access:** Use `getIt<ServiceName>()`.
2. **Offline-First:** Every feature MUST work without internet.
3. **Battery-Aware:** Optimize all networking and scanning.
4. **Data Models:** Use `equatable` and `.copyWith()`.
5. **Security:** Never log plaintext message content.

---

## 📓 Change Log & Memory

### [2026-07-19] - Initial Analysis & AI Memory Setup
- **Action:** Analyzed project and created initial `REMEMBER_ME.md`.

### [2026-07-19] - Super-App Vision Pivot
- **Action:** Expanded scope to include AI, Mapping, Rescue, and Hardware.

### [2026-07-19] - Security Hardening & AI Initiation (Phase 1.5)
- **Action:** Implemented Encrypted Hive boxes and E2EE Handshake.
- **Action:** Created `AIService` and `FeedService` boilerplates.

### [2026-07-19] - One-to-One Chat Polish (Option A)
- **Action:** Added `MessageStatus.read` and quoting fields (`replyToId`, `replyToContent`, `replyToSenderName`) to support message replies.
- **Action:** Implemented debounced typing status, automatic delivery receipts, and read receipts over Nearby Connections.
- **Action:** Added local and remote message deletion logic (epidemic broadcast for deletions) and message forwarding menu options.

### [2026-07-19] - Group Chat & Offline Map Caching Implementation
- **Action:** Implemented the Group Chat suite (Phase 1.2) including `Group` model, manual Hive adapter `GroupAdapter` (TypeId: 9), and `GroupService` to coordinate multi-peer messaging over Nearby Connections.
- **Action:** Integrated group creation (`CreateGroupScreen`), chat views (`GroupChatScreen` with member sender labels), details settings (`GroupDetailsScreen`), and home page list mapping.
- **Action:** Implemented the Offline Map Caching module (Phase 4.1) using a custom `CachedTileProvider` supporting synchronous local tile lookups (`FileImage` matching `z/x/y.png` layout) and async downloads/writes (`HttpClient`) in the background. Added settings controls in `MapScreen` to inspect cache directories and wipe files.
- **Action:** Implemented test coverage for group messaging and map caching logic under `test/group_chat_test.dart` and `test/map_cache_test.dart`.

### [2026-07-19] - Rescue & Medical Suite Implementation (Phase 5)
- **Action:** Created data models and manual Hive adapters for `MedicalProfile` (TypeId: 10), `TriageCard` (TypeId: 11), `RescueTask` (TypeId: 12), `MedicalSupply` (TypeId: 13), and `LandingZone` (TypeId: 14).
- **Action:** Implemented `RescueMedicalService` to manage triage lists (priority sorting), inventory tracks, landing zone safety evaluations (slope, size, surface scoring), and sync over Nearby Connections.
- **Action:** Refactored `EmergencyAlertsScreen` into a unified tabbed dashboard containing tabs for SOS Alerts, Triage Queue, Medical Supplies, Helicopter LZ, and Medical Profiles (featuring an offline custom QR code drawing painter).
- **Action:** Implemented comprehensive automated tests under `test/rescue_medical_test.dart`.

### [2026-07-19] - Mesh Routing & Offline Emails (Phase 6)
- **Action:** Extended `Peer` model & adapter to track battery level, gateway status, and peer relay types.
- **Action:** Created data model and adapter for `OfflineEmail` (TypeId: 15) to coordinate store-and-forward mesh propagation packets.
- **Action:** Implemented `MeshRoutingService` to route offline email drafts and enforce **Battery-Aware Routing** metrics (excluding standard nodes with battery < 15%, and prioritizing Drones/Vehicles).
- **Action:** Created `OfflineEmailScreen` including composer cards, gateway toggling, and visualised routing paths. Added integration buttons to `HomeScreen` actions.
- **Action:** Implemented automated test coverage under `test/mesh_routing_test.dart`.

### [2026-07-19] - Hardware & Sensors Suite (Phase 7)
- **Action:** Created `HardwareSensorService` to simulate environmental stats and evaluate accelerometer shockwave early warnings ($A_{mag}$ checks).
- **Action:** Integrated a Morse Code flash beacon translator pulsing screen and light indicators visually.
- **Action:** Added `HardwareDashboardScreen` displaying dials, offsets calibration, sirens, solar input status, and Morse flashing widgets. Linked Settings icon to the dashboard.
- **Action:** Implemented automated test coverage under `test/hardware_sensors_test.dart`.

### [2026-07-19] - Community & Barter Marketplace Suite (Phase 8)
- **Action:** Created data models and manual Hive adapters for `MarketListing` (TypeId: 16) and `LeaderVote` (TypeId: 17).
- **Action:** Implemented `CommunityService` to manage peer reputations (badges), resource barter matching, and leader elections with double-vote blocks.
- **Action:** Created `CommunityHubScreen` with tabs for Barter Market, Volunteer Registry, and Leader Elections. Linked case 5 bottom navigation bar to launch the Hub.
- **Action:** Implemented automated test coverage under `test/community_test.dart`.

### [2026-07-19] - AR Evacuation Guidance (Phase 9)
- **Action:** Created `ArEvacuationService` to track exit routes (140° SE) and calculate projection offsets for local hazard anchors (Fires, Floods, Collapsed Bridges) within viewport clip limits.
- **Action:** Added `ArEvacuationScreen` presenting simulated viewfinder overlays, HUD crosshairs, pitch lines, horizontal sliding tapes, and exit portals.
- **Action:** Mapped a camera icon button inside `MapScreen` app bar to launch the AR viewport.
- **Action:** Implemented automated test coverage under `test/ar_evacuation_test.dart`.

### [2026-07-19] - Infrastructure Relay Gateways (Phase 10)
- **Action:** Created `GatewayService` providing dynamic backhaul routing (Cellular > LoRa > Satellite) and Garmin satellite 80-byte coordinate/SOS hex packing.
- **Action:** Refactored `NetworkStatusScreen` into a two-tab view dividing mesh topography from hardware gateway consoles (switches, logs screens).
- **Action:** Implemented automated test coverage under `test/gateway_routing_test.dart`.

### [2026-07-19] - GitHub Actions Build Pipeline
- **Action:** Created `.github/workflows/build_releases.yml` setting up automated multi-platform compilation runners (Android APK, iOS, Windows, macOS, and Linux executables) executing on push to main.

---

> [!TIP]
> **To AI Assistant:** Maps, AI, Feed, Channels, Groups, Offline Map Caching, Rescue alerts, Triage queue, Medical Supplies, Helicopter LZ, Medical Profiles, Offline Email routing, Hardware Sensors (Morse, Seismic), Community Hub (Barter, Elections, Badges), AR Viewfinder Evacuation (exit vectors, hazard anchors), Infrastructure Gateways (Satellite compression, LoRa packers), and GitHub Actions build CI are fully active. Use control packets like `typing_status`, `delivery_receipt`, `read_receipt`, `delete_message`, `group_meta`, `group_message`, `triage_update`, `supply_update`, `task_update`, `email_update`, `email_status_update`, `seismic_warning`, `market_update`, `leader_vote`, and `leader_vote_rescind` to update states across the mesh network.
