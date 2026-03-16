# GalaxyMinded - Design Document

**Date:** 2026-02-19
**Platform:** iOS 17+ (Swift / SwiftUI)
**Repo:** East (same repo as Lume, separate folder)
**Model:** 100% free, passion/portfolio project

---

## Overview

GalaxyMinded is a gamified space exploration app that combines NASA APIs, AR sky viewing, and an engagement system (XP, levels, badges, missions, quizzes) to make discovering the universe addictive and fun.

The user opens the app daily to see stunning space photos, track asteroids, follow the ISS in real time, explore Mars rover imagery, point their phone at the sky to discover planets in AR, and complete missions/quizzes to level up.

---

## Architecture: Modular by Feature

Each feature is an independent module with its own Views/ViewModels/Services. Shared infrastructure lives in `Shared/`.

```
East/
├── Fotico/                          (Lume - existing)
├── Fotico.xcodeproj/               (Lume project - existing)
├── GalaxyMinded/                    (NEW)
│   ├── App/
│   │   ├── GalaxyMindedApp.swift
│   │   ├── AppState.swift
│   │   └── TabRouter.swift
│   │
│   ├── Core/                        GAMIFICATION ENGINE
│   │   ├── Models/
│   │   │   ├── UserProfile.swift
│   │   │   ├── Badge.swift
│   │   │   ├── Mission.swift
│   │   │   └── QuizQuestion.swift
│   │   ├── Services/
│   │   │   ├── GamificationService.swift
│   │   │   ├── MissionEngine.swift
│   │   │   └── PersistenceService.swift
│   │   └── ViewModels/
│   │       └── ProfileViewModel.swift
│   │
│   ├── SpaceFeed/                   DAILY SPACE FEED
│   │   ├── Models/
│   │   │   ├── APOD.swift
│   │   │   └── SpaceNews.swift
│   │   ├── Services/
│   │   │   └── APODService.swift
│   │   ├── ViewModels/
│   │   │   └── SpaceFeedViewModel.swift
│   │   └── Views/
│   │       ├── SpaceFeedView.swift
│   │       ├── APODCardView.swift
│   │       └── FactOfDayView.swift
│   │
│   ├── Asteroids/                   ASTEROID TRACKER
│   │   ├── Models/
│   │   │   └── NearEarthObject.swift
│   │   ├── Services/
│   │   │   └── NeoWsService.swift
│   │   ├── ViewModels/
│   │   │   └── AsteroidsViewModel.swift
│   │   └── Views/
│   │       ├── AsteroidListView.swift
│   │       ├── AsteroidDetailView.swift
│   │       └── AsteroidSizeCompareView.swift
│   │
│   ├── ISSTracker/                  ISS LIVE TRACKER
│   │   ├── Models/
│   │   │   ├── ISSPosition.swift
│   │   │   └── Astronaut.swift
│   │   ├── Services/
│   │   │   ├── ISSLocationService.swift
│   │   │   └── AstronautService.swift
│   │   ├── ViewModels/
│   │   │   └── ISSTrackerViewModel.swift
│   │   └── Views/
│   │       ├── ISSMapView.swift
│   │       ├── ISSInfoOverlay.swift
│   │       └── CrewListView.swift
│   │
│   ├── MarsExplorer/                MARS ROVER GALLERY
│   │   ├── Models/
│   │   │   └── MarsPhoto.swift
│   │   ├── Services/
│   │   │   └── MarsRoverService.swift
│   │   ├── ViewModels/
│   │   │   └── MarsExplorerViewModel.swift
│   │   └── Views/
│   │       ├── MarsGalleryView.swift
│   │       ├── MarsPhotoDetailView.swift
│   │       └── RoverPickerView.swift
│   │
│   ├── SkyAR/                       AUGMENTED REALITY SKY
│   │   ├── Models/
│   │   │   ├── CelestialBody.swift
│   │   │   └── Constellation.swift
│   │   ├── Services/
│   │   │   └── AstronomyAPIService.swift
│   │   ├── ViewModels/
│   │   │   └── SkyARViewModel.swift
│   │   └── Views/
│   │       ├── SkyARView.swift
│   │       ├── PlanetAnnotation.swift
│   │       └── ConstellationOverlay.swift
│   │
│   ├── Quiz/                        DAILY QUIZ
│   │   ├── Services/
│   │   │   └── QuizService.swift
│   │   ├── ViewModels/
│   │   │   └── QuizViewModel.swift
│   │   └── Views/
│   │       ├── QuizView.swift
│   │       ├── QuizResultView.swift
│   │       └── LeaderboardView.swift
│   │
│   ├── Missions/                    MISSION SYSTEM
│   │   ├── ViewModels/
│   │   │   └── MissionsViewModel.swift
│   │   └── Views/
│   │       ├── MissionBoardView.swift
│   │       ├── MissionDetailView.swift
│   │       └── MissionCompleteView.swift
│   │
│   └── Shared/                      SHARED INFRASTRUCTURE
│       ├── Networking/
│       │   ├── NetworkManager.swift
│       │   ├── NASAEndpoint.swift
│       │   ├── ISSEndpoint.swift
│       │   ├── AstronomyEndpoint.swift
│       │   └── APIError.swift
│       ├── UI/
│       │   ├── GalaxyTheme.swift
│       │   ├── StarfieldBackground.swift
│       │   ├── XPProgressBar.swift
│       │   ├── BadgeView.swift
│       │   └── LoadingSpaceView.swift
│       ├── Extensions/
│       │   ├── Color+Galaxy.swift
│       │   ├── Date+Space.swift
│       │   └── View+Animations.swift
│       └── Persistence/
│           └── GalaxyMindedContainer.swift
│
├── GalaxyMinded.xcodeproj/         (NEW)
└── docs/
```

---

## APIs

| API | Endpoint | Auth | Rate Limit | Data |
|-----|----------|------|------------|------|
| NASA APOD | `api.nasa.gov/planetary/apod` | API Key (free) | 1,000 req/hr shared | Photo of the day, explanation, date |
| NASA NeoWs | `api.nasa.gov/neo/rest/v1/feed` | API Key (free) | 1,000 req/hr shared | Near-earth asteroids, hazard status, size, velocity |
| NASA Mars Rover | `api.nasa.gov/mars-photos/api/v1/rovers` | API Key (free) | 1,000 req/hr shared | Curiosity/Opportunity/Spirit photos by sol/camera |
| NASA EPIC | `api.nasa.gov/EPIC/api/natural` | API Key (free) | 1,000 req/hr shared | Earth photos from space |
| Where the ISS At | `api.wheretheiss.at/v1/satellites/25544` | None | ~1 req/sec | Lat, lon, altitude, velocity, visibility |
| Open Notify | `api.open-notify.org/astros.json` | None | ~1 req/5sec | People in space right now |
| Astronomy API | `astronomyapi.com` | API Key (free tier) | Free tier | Planet/star positions, moon phases |

---

## Gamification System

### XP Actions

| Action | XP |
|--------|-----|
| Open app (1x/day) | +10 |
| View daily APOD | +15 |
| Read full APOD explanation | +10 |
| Collect an asteroid | +20 |
| View ISS on map | +10 |
| Explore a Mars photo | +10 |
| Discover a planet in AR | +25 |
| Answer quiz correctly | +30 |
| Complete a mission | +50-200 |
| 7-day streak | +100 bonus |
| 30-day streak | +500 bonus |

### Levels

| Level | Name | XP Required | Unlocks |
|-------|------|-------------|---------|
| 1 | Terrestrial | 0 | Basic access |
| 2 | Lunar | 100 | Daily quiz |
| 3 | Martian | 300 | Full Mars Explorer |
| 4 | Asteroid Hunter | 600 | Asteroid collection |
| 5 | Orbital | 1,000 | Advanced ISS tracker |
| 6 | System Explorer | 1,800 | AR mode |
| 7 | Stellar | 3,000 | Advanced missions |
| 8 | Galactic | 5,000 | Special badge + full unlock |
| 9 | Astronomer | 8,000 | Legendary title |
| 10 | Galaxy Minded | 15,000 | Max title, golden badge |

### Badges

| Icon | Name | Condition |
|------|------|-----------|
| Fire | Streak Starter | 3 consecutive days |
| Fire x2 | On Fire | 7 consecutive days |
| Fire x3 | Unstoppable | 30 consecutive days |
| Camera | First Light | View first APOD |
| Red Circle | Martian Eye | Explore 50 Mars photos |
| Comet | Asteroid Hunter | Collect 10 asteroids |
| Satellite | ISS Spotter | Track ISS 10 times |
| Brain | Quiz Master | 50 correct answers |
| Target | Mission Complete | Complete 5 missions |
| Galaxy | Galaxy Minded | Reach level 10 |
| Telescope | Stargazer | Discover 20 objects in AR |
| 100 | Perfect Score | Perfect quiz (10/10) |

### Missions

**Daily** (refresh every 24h):
- "Daily Observer" -> View APOD + read explanation (+50 XP)
- "Quick Quiz" -> Answer 3 quiz questions (+40 XP)
- "ISS Check" -> Open ISS tracker (+30 XP)

**Weekly:**
- "Mars Explorer" -> View 20 Mars Rover photos (+150 XP)
- "Rock Hunter" -> Collect 5 new asteroids (+120 XP)
- "Perfect Streak" -> Don't break streak for 7 days (+200 XP)

**Discovery** (one-time):
- "First Contact" -> Use every feature at least once (+100 XP)
- "Amateur Astronomer" -> Discover all planets in AR (+250 XP)
- "Space Historian" -> View APODs from 30 different days (+200 XP)

---

## Navigation

5 tabs:

1. **Space Feed (Home)** - Hero APOD card, fun fact, asteroid preview, ISS mini-map, active missions
2. **Explore** - Sub-nav: Asteroids, Mars, Earth (EPIC), ISS Tracker fullscreen
3. **Sky AR** - Fullscreen AR camera with planet/star/constellation overlays
4. **Quiz** - Daily quiz with timer, categories, results + XP
5. **Profile** - Avatar, XP bar, streak, badge collection, stats, mission board

---

## Visual Style: Dark Sci-Fi + Neon

- Background: Deep black (#0A0A1A) with gradient to deep purple (#1A0A2E)
- Primary accent: Neon cyan (#00E5FF)
- Secondary accent: Purple (#B388FF)
- XP/Level: Gold (#FFD740)
- Danger/Asteroids: Red (#FF5252)
- Cards: Dark glass effect with subtle cyan border
- Typography: SF Pro + monospace variants for scientific data
- Animations: Star particles in backgrounds, fluid transitions

---

## Tech Stack

| Layer | Technology | Reason |
|-------|-----------|--------|
| UI | SwiftUI | Declarative, modern |
| State | @Observable (Observation framework) | iOS 17+, cleaner than ObservableObject |
| Networking | URLSession + async/await | Native, zero dependencies |
| Persistence | SwiftData | Modern, SwiftUI integrated |
| Maps | MapKit | ISS real-time tracker |
| AR | ARKit + RealityKit | Sky view, 3D planets |
| 3D | SceneKit/RealityKit | Celestial objects |
| Images | AsyncImage + custom cache | NASA photos are heavy |
| Animations | SwiftUI Animations + Canvas | Stars, particles |
| Target | iOS 17.0+ | SwiftData + Observation |

**Zero external dependencies.** Everything native.

---

## Data Flow

```
NASA APIs / ISS API / Astronomy API
        |
   NetworkManager (URLSession async/await)
        |
   Feature Services (APODService, NeoWsService, etc.)
        |
   Feature ViewModels (@Observable)
        |
   SwiftUI Views
        |
   User Actions -> GamificationService -> XP/Badges/Missions -> SwiftData
```

---

## Caching Strategy

| Data | Cache | Duration |
|------|-------|----------|
| Daily APOD | Disk | 24 hours |
| NeoWs asteroids | Disk | 12 hours |
| Mars Rover photos | Disk (images) | 7 days |
| EPIC photos | Disk | 24 hours |
| ISS position | Memory only | 5 seconds (real-time) |
| Astronomy positions | Disk | 1 hour |
| Quiz questions | Bundle + disk | Weekly refresh |

---

## Offline Behavior

- Feed: shows last cached APOD + saved data
- Asteroids: shows personal collection
- Mars: shows already downloaded photos
- ISS: requires connection (shows last known position)
- AR: requires connection for updated positions
- Quiz: works offline with pre-cached questions
- Missions & gamification: 100% offline
