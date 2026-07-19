# Crisis Mesh Messenger 🛰️👥🗺️

A decentralized, infrastructure-free messaging and disaster response "super-app" for crisis situations, running completely offline on mobile and desktop platforms.

## Overview

Crisis Mesh Messenger enables people to communicate and organize relief when traditional infrastructure (internet, cell towers, power grids) fails due to natural disasters, war, or grid collapse. 

Messages hop from device to device using Bluetooth, Wi-Fi Direct, and sub-GHz LoRa modules, creating a resilient mesh network that requires no central servers.

---

## ⚡ Key Features

### 1. Peer-to-Peer Mesh Communication
- **One-to-One & Closed Groups**: Secure group chat rooms with member administration roles and metadata broadcasts.
- **Message Reply & Quote**: Interactive reply banners in threads to follow discussions.
- **Debounced Status Receipts**: Peer typing states, delivery confirmations, and read receipts updated instantly over Nearby Connections.
- **Epidemic Deletions**: Clear messages locally or propagate deletion packets network-wide.

### 2. Digital Triage & Rescue Center (Phase 5)
- **Digital Triage Queue**: Color-coded patient cards sorted dynamically by urgency level (RED priority sorted first). Supports vital logs updates and resolves tracking.
- **Supplies Inventory**: Log medication, fuel, water, and tools stock counts. Automatically alerts in RED when stock falls below safety thresholds.
- **Landing Zone Selector**: Helicopter landing suitability scoring evaluating slope, dimensions, obstacles, and surface types.
- **Offline QR Profiles**: Painter compiles emergency contact details into scan-ready QR grids without external visual engines.

### 3. Battery-Aware Mesh Routing (Phase 6)
- **Prioritized Relay Paths**: Network routes prioritize high-energy nodes (drone and vehicle relays) while excluding handheld devices under 15% battery to preserve survival resources.
- **Store-and-Forward Email**: Draft, queue, and propagate emails node-to-node. Gateways automatically upload packets to public SMTP servers once they encounter internet backhaul.

### 4. Earthquake Early Warnings & Morse Beacons (Phase 7)
- **Seismic Shock Alerts**: Accelerometer monitoring checks 3D gravity vectors ($A_{mag} = \sqrt{x^2+y^2+z^2}$). Shocks exceeding 3.5 m/s² trigger siren flashes and auto-broadcast warning packets to nearby nodes.
- **Visual Morse Signaler**: Translates text messages (like "SOS") into timed visual pulses on a screen-based flashing beacon.

### 5. Community Barter Boards & Elections (Phase 8)
- **Barter Market**: Decentralized offers/requests board for trading food, water, fuel, and medications.
- **Neighborhood Elections**: Cast coordinator votes securely, avoiding double-votes.
- **Volunteer Registry**: Lists relief members, tracking resolved cases and assigning responder levels (Bronze/Silver/Gold) dynamically.

### 6. AR Evacuation viewfinders (Phase 9)
- **Visual Compass Overlay**: Overlay path directions and hazard zones (fires, floods, collapsed structures) dynamically on a viewfinder custom canvas based on device compass headings.

### 7. Garmin Satellite & LoRa Relays (Phase 10)
- **80-Byte Satellite Compressor**: Packs coordinates, sender IDs, and SOS text into a compact binary package for upload to expensive Garmin InReach networks.
- **LoRa Packeter**: Splits payloads exceeding 256 bytes into radio-chunk frames for sub-GHz transceiver modules.

---

## 🏗️ Technical Architecture

- **Framework:** Flutter 3.24+ (Support for iOS, Android, Windows, macOS, and Linux)
- **State Management:** Provider + GetIt (Dependency Injection container)
- **Local Storage:** Encrypted Hive NoSQL database
- **P2P Transport:** Nearby Connections API, Multipeer Connectivity, sub-GHz serial radio transceivers
- **Encryption:** End-to-End Encryption (E2EE) handshake using X25519 and AES-GCM

---

## 🚀 Quick Start & Development

### Local Setup
```bash
# Fetch package dependencies
flutter pub get

# Run automated tests
flutter test

# Start the application on connected device
flutter run
```

### GitHub CI Build Action
We configure a GitHub Actions workflow in `.github/workflows/build_releases.yml` which automatically compiles production binaries on push to `main`:
- **Android**: Release APK (`app-release.apk`)
- **iOS**: Unsigned Runner App bundle (`Runner.app`)
- **Windows**: Desktop executable package
- **macOS**: Application bundle
- **Linux**: Build binaries

---

## 🧪 Automated Testing
All services and logic flows are backed by unit tests under the `/test` directory:
- `test/group_chat_test.dart` (Group messaging mechanics)
- `test/map_cache_test.dart` (Sync tile serving)
- `test/rescue_medical_test.dart` (LZ score formulas, triage priorities, supplies)
- `test/mesh_routing_test.dart` (Battery limits, store-and-forward email routing)
- `test/hardware_sensors_test.dart` (Earthquake vector gravity and Morse light maps)
- `test/community_test.dart` (Election votes, peer registry badges)
- `test/ar_evacuation_test.dart` (AR viewport coordinate calculations)
- `test/gateway_routing_test.dart` (80-byte Garmin packing bytes, LoRa chunk limits)

---

## 📄 License
MIT License - Free for humanitarian and emergency relief coordination.
