# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is "당근 술래잡기" (Carrot Hide & Seek) - a location-based multiplayer game app where police catch thieves in a geofenced area. The project uses Flutter for the mobile client and Node.js with Socket.io for the backend.

## Build and Run Commands

### Flutter Client (front-end/)
```bash
cd front-end

# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Run with specific device
flutter run -d <device_id>

# Build for release
flutter build apk --release   # Android
flutter build ios --release   # iOS

# Analyze code
flutter analyze

# Run tests
flutter test
flutter test test/widget_test.dart  # Single test
```

### Backend Server (front-end/server/)
```bash
cd front-end/server

# Install dependencies
npm install

# Run in development (with hot reload)
npm run dev

# Run in production
npm start
```

### Environment Setup
- Create `.env` file in `front-end/` with `NAVER_MAP_CLIENT_ID`
- Server runs on port 3000 by default
- Android emulator uses `10.0.2.2:3000` to connect to host machine

## Architecture

### Flutter Client - MVVM with GetX

```
front-end/lib/
├── app/           # App configuration (routes, bindings, theme, constants)
├── models/        # Data models (PlayerModel, RoomModel, GameStateModel, etc.)
├── services/      # External communication (API, Socket, Location, Storage)
├── view_models/   # GetX Controllers (state management and business logic)
└── views/         # UI screens and widgets
```

**State Management**: GetX with reactive variables (`.obs`) and `Obx()` widgets

**Key Dependencies**:
- `get` - State management and navigation
- `flutter_naver_map` - Naver Maps integration
- `socket_io_client` - Real-time communication
- `location` - GPS tracking

### Backend Server - Express + Socket.io

```
front-end/server/
├── server.js           # Entry point, socket event routing
├── controllers/        # Room and game logic handlers
└── utils/store.js      # In-memory data storage
```

**Current Implementation**: Uses in-memory storage (not Redis yet)

## Key Data Flow

1. **Session**: User sets nickname → API creates session → stored in SharedPreferences
2. **Room Creation**: Host draws polygon area on map → creates room with OTP code
3. **Room Join**: Player enters OTP → joins via Socket.io
4. **Role Assignment**: Host assigns police/thief roles via Socket
5. **Game Events**: All game actions (arrest, jailbreak, boundary exit) are socket events

## Socket Events

**Client → Server**: `room:join`, `role:assign`, `game:start`, `arrest:request`, `arrest:respond`, `jailbreak:trigger`, `location:update`

**Server → Client**: `players:updated`, `role:assigned`, `game:started`, `game:tick`, `player:arrested`, `jailbreak:success`, `game:ended`

## Game Mechanics

- **Teams**: Police (catch thieves) vs Thieves (survive)
- **Win Conditions**: Police win if all thieves caught; Thieves win if any survive until time runs out
- **Geofencing**: Play area boundary - exit triggers 60-second countdown to auto-arrest
- **Jailbreak**: Living thief within 15m of jail can free all captured teammates

## Important Files

- [front-end/claude.md](front-end/claude.md) - Detailed project specification
- [front-end/3DAY_PLAN.md](front-end/3DAY_PLAN.md) - Development roadmap
- [front-end/lib/app/constants.dart](front-end/lib/app/constants.dart) - Game constants and enums
- [front-end/lib/app/bindings.dart](front-end/lib/app/bindings.dart) - GetX dependency injection
