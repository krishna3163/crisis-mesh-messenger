# Implementation Tasks: Phase 2 & 3 - Resilience Modules

- `[x]` **Phase 1: Dependencies & Models**
    - `[x]` Update `pubspec.yaml` with `flutter_map` and `latlong2`
    - `[x]` Create `MapMarker` model (Using existing models)
- `[x]` **Phase 2: Mapping Module**
    - `[x]` Create `MapService` in `lib/core/services/maps/`
    - `[x]` Create `MapScreen` in `lib/features/maps/ui/screens/`
    - `[x]` Register `MapService` in `service_locator.dart`
- `[x]` **Phase 3: AI Assistant (First Aid Tree)**
    - `[x]` Implement `FirstAidKnowledgeBase` in `AIService`
    - `[x]` Update `AIScreen` to handle structured list-based steps
- `[x]` **Phase 4: Integration**
    - `[x]` Add "Maps" Tab to `HomeScreen`
    - `[x]` Link `EmergencyService` signals to `MapService` markers
- `[/]` **Phase 5: Verification**
    - `[ ]` Verify map rendering
    - `[ ]` Verify offline AI keyword matching
