# Implementation Plan: Phase 2 & 3 - Resilience Modules (Maps & AI)

This plan focuses on implementing the **Offline Mapping** pillar and enhancing the **AI Assistant** with a structured first-aid knowledge base.

## Goal Description
Evolve the super-app by providing users with geographic context (Maps) and reliable, offline emergency guidance (AI).

## User Review Required

> [!IMPORTANT]
> **Offline Maps**: I will integrate `flutter_map`. Initially, I will set up the infrastructure to support **pre-cached OSM tiles**. Users will eventually be able to load `.mbtiles` files for entire regions.

> [!NOTE]
> **AI Knowledge Base**: Instead of a cloud LLM, I will implement a **Structured Offline Knowledge Base** within the `AIService`. This ensures 100% reliability during a total internet blackout, following the "SelfAid" reference in our roadmap.

## Proposed Changes

### 1. Mapping Module (Phase 3)

#### [MODIFY] [pubspec.yaml](file:///C:/Users/krishna/StudioProjects/crisis-mesh-messenger/pubspec.yaml)
- Add `flutter_map: ^7.0.2` and `latlong2: ^0.9.1`.

#### [NEW] [map_service.dart](file:///C:/Users/krishna/StudioProjects/crisis-mesh-messenger/lib/core/services/maps/map_service.dart)
- Manages map center, zoom, and offline tile provider logic.
- Tracks "Safe Zones" and "Hazard Zones" received via mesh.

#### [NEW] [map_screen.dart](file:///C:/Users/krishna/StudioProjects/crisis-mesh-messenger/lib/features/maps/ui/screens/map_screen.dart)
- A full-screen interactive map.
- Overlays for Emergency Signals (SOS) and discovered Peers.

### 2. AI Assistant Enhancement (Phase 2)

#### [MODIFY] [ai_service.dart](file:///C:/Users/krishna/StudioProjects/crisis-mesh-messenger/lib/core/services/ai/ai_service.dart)
- Replace simple placeholder with a **First-Aid Decision Tree**.
- Implement keyword-based search for "CPR", "Bleeding", "Choking", etc.

### 3. UI/UX Expansion

#### [MODIFY] [home_screen.dart](file:///C:/Users/krishna/StudioProjects/crisis-mesh-messenger/lib/features/messaging/ui/screens/home_screen.dart)
- Add the **Maps** tab to the bottom navigation bar.
- Re-index tabs to: Chats, Channels, AI, Maps, Feed.

## Verification Plan

### Automated Tests
- **AI Test**: Verify that querying "CPR" returns structured steps from the knowledge base.
- **Service Test**: Verify `MapService` correctly stores/retrieves marker coordinates.

### Manual Verification
- Navigate to the **Maps** tab and verify the interactive map renders.
- Toggle "Hazard Zones" and verify placeholders appear.
- Check if SOS signals from the "Rescue" module automatically appear as markers on the Map.

---

**Does this plan for Offline Maps and Structured AI Guidance look good to you?**
