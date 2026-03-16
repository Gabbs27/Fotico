# GalaxyMinded Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a gamified space exploration iOS app combining NASA APIs, AR sky viewing, and XP/missions/quiz system.

**Architecture:** Modular by Feature with MVVM. Each feature (SpaceFeed, Asteroids, ISS, Mars, AR, Quiz, Missions) is an independent module. Shared networking and UI components in Shared/. Gamification engine in Core/.

**Tech Stack:** Swift, SwiftUI, SwiftData, ARKit, RealityKit, MapKit, URLSession async/await. iOS 17+. Zero external dependencies.

**Design Doc:** `docs/plans/2026-02-19-galaxyminded-design.md`

---

## Task 1: Xcode Project Setup

**Files:**
- Create: `GalaxyMinded/` folder structure
- Create: Xcode project via CLI

**Step 1: Create folder structure**

```bash
cd /Users/gabriel/East
mkdir -p GalaxyMinded/{App,Core/{Models,Services,ViewModels},SpaceFeed/{Models,Services,ViewModels,Views},Asteroids/{Models,Services,ViewModels,Views},ISSTracker/{Models,Services,ViewModels,Views},MarsExplorer/{Models,Services,ViewModels,Views},SkyAR/{Models,Services,ViewModels,Views},Quiz/{Services,ViewModels,Views},Missions/{ViewModels,Views},Shared/{Networking,UI,Extensions,Persistence}}
```

**Step 2: Create GalaxyMindedApp.swift entry point**

```swift
// GalaxyMinded/App/GalaxyMindedApp.swift
import SwiftUI
import SwiftData

@main
struct GalaxyMindedApp: App {
    var body: some Scene {
        WindowGroup {
            TabRouter()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [UserProfile.self])
    }
}
```

**Step 3: Create TabRouter placeholder**

```swift
// GalaxyMinded/App/TabRouter.swift
import SwiftUI

struct TabRouter: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Text("Space Feed")
                .tabItem { Label("Feed", systemImage: "sparkles") }
                .tag(0)
            Text("Explore")
                .tabItem { Label("Explore", systemImage: "globe.americas") }
                .tag(1)
            Text("Sky AR")
                .tabItem { Label("AR", systemImage: "camera.viewfinder") }
                .tag(2)
            Text("Quiz")
                .tabItem { Label("Quiz", systemImage: "brain.head.profile") }
                .tag(3)
            Text("Profile")
                .tabItem { Label("Profile", systemImage: "person.circle") }
                .tag(4)
        }
        .tint(.cyan)
    }
}
```

**Step 4: Create Xcode project, build and run to verify**

**Step 5: Commit** — `feat: initial GalaxyMinded project setup with tab navigation`

---

## Task 2: Shared Infrastructure — Theme & Networking

**Files:**
- Create: `GalaxyMinded/Shared/UI/GalaxyTheme.swift`
- Create: `GalaxyMinded/Shared/Extensions/Color+Galaxy.swift`
- Create: `GalaxyMinded/Shared/Networking/APIError.swift`
- Create: `GalaxyMinded/Shared/Networking/NetworkManager.swift`
- Create: `GalaxyMinded/Shared/Networking/NASAEndpoint.swift`
- Create: `GalaxyMinded/Shared/Networking/ISSEndpoint.swift`

**Step 1: Color+Galaxy.swift**

```swift
import SwiftUI

extension Color {
    static let galaxyBackground = Color(red: 0.04, green: 0.04, blue: 0.10)
    static let galaxyDeepPurple = Color(red: 0.10, green: 0.04, blue: 0.18)
    static let galaxyCyan = Color(red: 0, green: 0.90, blue: 1.0)
    static let galaxyPurple = Color(red: 0.70, green: 0.53, blue: 1.0)
    static let galaxyGold = Color(red: 1.0, green: 0.84, blue: 0.25)
    static let galaxyRed = Color(red: 1.0, green: 0.32, blue: 0.32)
    static let galaxyCard = Color.white.opacity(0.08)
    static let galaxyCardBorder = Color.galaxyCyan.opacity(0.3)
}
```

**Step 2: GalaxyTheme.swift**

```swift
import SwiftUI

enum GalaxyTheme {
    static let backgroundGradient = LinearGradient(
        colors: [.galaxyBackground, .galaxyDeepPurple],
        startPoint: .top, endPoint: .bottom
    )

    static let cardStyle = RoundedRectangle(cornerRadius: 16)

    enum Font {
        static let heroTitle = SwiftUI.Font.system(size: 28, weight: .bold)
        static let sectionTitle = SwiftUI.Font.system(size: 20, weight: .semibold)
        static let body = SwiftUI.Font.system(size: 16)
        static let caption = SwiftUI.Font.system(size: 12)
        static let data = SwiftUI.Font.system(size: 14, design: .monospaced)
    }
}
```

**Step 3: APIError.swift**

```swift
import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case networkError(Error)
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .httpError(let code): return "HTTP error: \(code)"
        case .decodingError(let error): return "Decoding error: \(error.localizedDescription)"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .rateLimited: return "Rate limited. Try again later."
        }
    }
}
```

**Step 4: NASAEndpoint.swift**

```swift
import Foundation

enum NASAEndpoint {
    static let baseURL = "https://api.nasa.gov"
    static let apiKey = "DEMO_KEY" // Replace with real key

    case apod(date: String? = nil)
    case neoFeed(startDate: String, endDate: String)
    case marsPhotos(rover: String, sol: Int, camera: String? = nil)
    case epic(date: String? = nil)

    var url: URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.nasa.gov"

        var queryItems = [URLQueryItem(name: "api_key", value: Self.apiKey)]

        switch self {
        case .apod(let date):
            components.path = "/planetary/apod"
            if let date { queryItems.append(URLQueryItem(name: "date", value: date)) }
        case .neoFeed(let start, let end):
            components.path = "/neo/rest/v1/feed"
            queryItems.append(URLQueryItem(name: "start_date", value: start))
            queryItems.append(URLQueryItem(name: "end_date", value: end))
        case .marsPhotos(let rover, let sol, let camera):
            components.path = "/mars-photos/api/v1/rovers/\(rover)/photos"
            queryItems.append(URLQueryItem(name: "sol", value: "\(sol)"))
            if let camera { queryItems.append(URLQueryItem(name: "camera", value: camera)) }
        case .epic(let date):
            components.path = date != nil ? "/EPIC/api/natural/date/\(date!)" : "/EPIC/api/natural"
        }

        components.queryItems = queryItems
        return components.url
    }
}
```

**Step 5: ISSEndpoint.swift**

```swift
import Foundation

enum ISSEndpoint {
    case position
    case astronauts

    var url: URL? {
        switch self {
        case .position:
            return URL(string: "https://api.wheretheiss.at/v1/satellites/25544")
        case .astronauts:
            return URL(string: "http://api.open-notify.org/astros.json")
        }
    }
}
```

**Step 6: NetworkManager.swift**

```swift
import Foundation

actor NetworkManager {
    static let shared = NetworkManager()
    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 50_000_000, diskCapacity: 100_000_000)
        session = URLSession(configuration: config)
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func request<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        if httpResponse.statusCode == 429 { throw APIError.rateLimited }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}
```

**Step 7: Build and verify**

**Step 8: Commit** — `feat: add shared theme, colors, and networking layer`

---

## Task 3: Core — SwiftData Models & Gamification Engine

**Files:**
- Create: `GalaxyMinded/Core/Models/UserProfile.swift`
- Create: `GalaxyMinded/Core/Models/Badge.swift`
- Create: `GalaxyMinded/Core/Models/Mission.swift`
- Create: `GalaxyMinded/Core/Services/GamificationService.swift`
- Create: `GalaxyMinded/Core/Services/MissionEngine.swift`
- Create: `GalaxyMinded/Shared/Persistence/GalaxyMindedContainer.swift`

**Step 1: Badge.swift**

```swift
import Foundation

enum BadgeType: String, Codable, CaseIterable {
    case streakStarter, onFire, unstoppable
    case firstLight, martianEye, asteroidHunter
    case issSpotter, quizMaster, missionComplete
    case galaxyMinded, stargazer, perfectScore

    var name: String {
        switch self {
        case .streakStarter: return "Streak Starter"
        case .onFire: return "On Fire"
        case .unstoppable: return "Unstoppable"
        case .firstLight: return "First Light"
        case .martianEye: return "Martian Eye"
        case .asteroidHunter: return "Asteroid Hunter"
        case .issSpotter: return "ISS Spotter"
        case .quizMaster: return "Quiz Master"
        case .missionComplete: return "Mission Complete"
        case .galaxyMinded: return "Galaxy Minded"
        case .stargazer: return "Stargazer"
        case .perfectScore: return "Perfect Score"
        }
    }

    var icon: String {
        switch self {
        case .streakStarter, .onFire, .unstoppable: return "flame.fill"
        case .firstLight: return "camera.fill"
        case .martianEye: return "circle.fill"
        case .asteroidHunter: return "sparkle"
        case .issSpotter: return "antenna.radiowaves.left.and.right"
        case .quizMaster: return "brain.head.profile"
        case .missionComplete: return "target"
        case .galaxyMinded: return "sparkles"
        case .stargazer: return "binoculars.fill"
        case .perfectScore: return "checkmark.seal.fill"
        }
    }

    var condition: String {
        switch self {
        case .streakStarter: return "3 consecutive days"
        case .onFire: return "7 consecutive days"
        case .unstoppable: return "30 consecutive days"
        case .firstLight: return "View first APOD"
        case .martianEye: return "Explore 50 Mars photos"
        case .asteroidHunter: return "Collect 10 asteroids"
        case .issSpotter: return "Track ISS 10 times"
        case .quizMaster: return "50 correct answers"
        case .missionComplete: return "Complete 5 missions"
        case .galaxyMinded: return "Reach level 10"
        case .stargazer: return "Discover 20 objects in AR"
        case .perfectScore: return "Perfect quiz (10/10)"
        }
    }
}
```

**Step 2: Mission.swift**

```swift
import Foundation
import SwiftData

enum MissionType: String, Codable {
    case daily, weekly, discovery
}

enum MissionID: String, Codable, CaseIterable {
    // Daily
    case dailyObserver, quickQuiz, issCheck
    // Weekly
    case marsExplorer, rockHunter, perfectStreak
    // Discovery
    case firstContact, amateurAstronomer, spaceHistorian

    var type: MissionType {
        switch self {
        case .dailyObserver, .quickQuiz, .issCheck: return .daily
        case .marsExplorer, .rockHunter, .perfectStreak: return .weekly
        case .firstContact, .amateurAstronomer, .spaceHistorian: return .discovery
        }
    }

    var name: String {
        switch self {
        case .dailyObserver: return "Daily Observer"
        case .quickQuiz: return "Quick Quiz"
        case .issCheck: return "ISS Check"
        case .marsExplorer: return "Mars Explorer"
        case .rockHunter: return "Rock Hunter"
        case .perfectStreak: return "Perfect Streak"
        case .firstContact: return "First Contact"
        case .amateurAstronomer: return "Amateur Astronomer"
        case .spaceHistorian: return "Space Historian"
        }
    }

    var target: Int {
        switch self {
        case .dailyObserver: return 1
        case .quickQuiz: return 3
        case .issCheck: return 1
        case .marsExplorer: return 20
        case .rockHunter: return 5
        case .perfectStreak: return 7
        case .firstContact: return 5
        case .amateurAstronomer: return 8
        case .spaceHistorian: return 30
        }
    }

    var xpReward: Int {
        switch self {
        case .dailyObserver: return 50
        case .quickQuiz: return 40
        case .issCheck: return 30
        case .marsExplorer: return 150
        case .rockHunter: return 120
        case .perfectStreak: return 200
        case .firstContact: return 100
        case .amateurAstronomer: return 250
        case .spaceHistorian: return 200
        }
    }
}

@Model
final class UserMission {
    var missionId: String
    var type: String
    var progress: Int
    var target: Int
    var xpReward: Int
    var isCompleted: Bool
    var startDate: Date
    var expirationDate: Date?

    init(missionId: MissionID) {
        self.missionId = missionId.rawValue
        self.type = missionId.type.rawValue
        self.progress = 0
        self.target = missionId.target
        self.xpReward = missionId.xpReward
        self.isCompleted = false
        self.startDate = Date()

        switch missionId.type {
        case .daily:
            self.expirationDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        case .weekly:
            self.expirationDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())
        case .discovery:
            self.expirationDate = nil
        }
    }
}
```

**Step 3: UserProfile.swift**

```swift
import Foundation
import SwiftData

@Model
final class UserProfile {
    var name: String
    var xp: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: Date?
    var unlockedBadges: [String]
    var collectedAsteroidIds: [String]
    var arDiscoveries: [String]
    var totalQuizCorrect: Int
    var totalQuizzesTaken: Int
    var missionsCompleted: Int
    var marsPhotosViewed: Int
    var issTracksCount: Int
    var apodsViewed: Int
    var createdAt: Date

    init(name: String = "Explorer") {
        self.name = name
        self.xp = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastActiveDate = nil
        self.unlockedBadges = []
        self.collectedAsteroidIds = []
        self.arDiscoveries = []
        self.totalQuizCorrect = 0
        self.totalQuizzesTaken = 0
        self.missionsCompleted = 0
        self.marsPhotosViewed = 0
        self.issTracksCount = 0
        self.apodsViewed = 0
        self.createdAt = Date()
    }

    var level: Int {
        switch xp {
        case 0..<100: return 1
        case 100..<300: return 2
        case 300..<600: return 3
        case 600..<1000: return 4
        case 1000..<1800: return 5
        case 1800..<3000: return 6
        case 3000..<5000: return 7
        case 5000..<8000: return 8
        case 8000..<15000: return 9
        default: return 10
        }
    }

    var levelName: String {
        switch level {
        case 1: return "Terrestrial"
        case 2: return "Lunar"
        case 3: return "Martian"
        case 4: return "Asteroid Hunter"
        case 5: return "Orbital"
        case 6: return "System Explorer"
        case 7: return "Stellar"
        case 8: return "Galactic"
        case 9: return "Astronomer"
        case 10: return "Galaxy Minded"
        default: return "Unknown"
        }
    }

    var xpForNextLevel: Int {
        switch level {
        case 1: return 100
        case 2: return 300
        case 3: return 600
        case 4: return 1000
        case 5: return 1800
        case 6: return 3000
        case 7: return 5000
        case 8: return 8000
        case 9: return 15000
        default: return 15000
        }
    }

    var xpProgress: Double {
        let thresholds = [0, 100, 300, 600, 1000, 1800, 3000, 5000, 8000, 15000]
        let currentThreshold = thresholds[min(level - 1, 9)]
        let nextThreshold = thresholds[min(level, 9)]
        let range = nextThreshold - currentThreshold
        guard range > 0 else { return 1.0 }
        return Double(xp - currentThreshold) / Double(range)
    }
}
```

**Step 4: GamificationService.swift**

```swift
import Foundation
import SwiftData

enum XPAction {
    case openApp, viewAPOD, readExplanation, collectAsteroid
    case viewISS, exploreMarsPhoto, discoverARObject
    case quizCorrect, completeMission(xp: Int)
    case streakBonus7, streakBonus30

    var xp: Int {
        switch self {
        case .openApp: return 10
        case .viewAPOD: return 15
        case .readExplanation: return 10
        case .collectAsteroid: return 20
        case .viewISS: return 10
        case .exploreMarsPhoto: return 10
        case .discoverARObject: return 25
        case .quizCorrect: return 30
        case .completeMission(let xp): return xp
        case .streakBonus7: return 100
        case .streakBonus30: return 500
        }
    }
}

@Observable
final class GamificationService {
    var profile: UserProfile

    init(profile: UserProfile) {
        self.profile = profile
    }

    func awardXP(_ action: XPAction) {
        let previousLevel = profile.level
        profile.xp += action.xp
        if profile.level > previousLevel {
            // Level up detected — can trigger UI notification
        }
    }

    func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastActive = profile.lastActiveDate {
            let lastDay = calendar.startOfDay(for: lastActive)
            let diff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if diff == 1 {
                profile.currentStreak += 1
                if profile.currentStreak > profile.longestStreak {
                    profile.longestStreak = profile.currentStreak
                }
                if profile.currentStreak == 7 { awardXP(.streakBonus7) }
                if profile.currentStreak == 30 { awardXP(.streakBonus30) }
            } else if diff > 1 {
                profile.currentStreak = 1
            }
        } else {
            profile.currentStreak = 1
        }

        profile.lastActiveDate = today
    }

    func checkBadges() {
        let earned = profile.unlockedBadges
        if profile.currentStreak >= 3 && !earned.contains(BadgeType.streakStarter.rawValue) {
            profile.unlockedBadges.append(BadgeType.streakStarter.rawValue)
        }
        if profile.currentStreak >= 7 && !earned.contains(BadgeType.onFire.rawValue) {
            profile.unlockedBadges.append(BadgeType.onFire.rawValue)
        }
        if profile.currentStreak >= 30 && !earned.contains(BadgeType.unstoppable.rawValue) {
            profile.unlockedBadges.append(BadgeType.unstoppable.rawValue)
        }
        if profile.apodsViewed >= 1 && !earned.contains(BadgeType.firstLight.rawValue) {
            profile.unlockedBadges.append(BadgeType.firstLight.rawValue)
        }
        if profile.marsPhotosViewed >= 50 && !earned.contains(BadgeType.martianEye.rawValue) {
            profile.unlockedBadges.append(BadgeType.martianEye.rawValue)
        }
        if profile.collectedAsteroidIds.count >= 10 && !earned.contains(BadgeType.asteroidHunter.rawValue) {
            profile.unlockedBadges.append(BadgeType.asteroidHunter.rawValue)
        }
        if profile.issTracksCount >= 10 && !earned.contains(BadgeType.issSpotter.rawValue) {
            profile.unlockedBadges.append(BadgeType.issSpotter.rawValue)
        }
        if profile.totalQuizCorrect >= 50 && !earned.contains(BadgeType.quizMaster.rawValue) {
            profile.unlockedBadges.append(BadgeType.quizMaster.rawValue)
        }
        if profile.missionsCompleted >= 5 && !earned.contains(BadgeType.missionComplete.rawValue) {
            profile.unlockedBadges.append(BadgeType.missionComplete.rawValue)
        }
        if profile.level >= 10 && !earned.contains(BadgeType.galaxyMinded.rawValue) {
            profile.unlockedBadges.append(BadgeType.galaxyMinded.rawValue)
        }
        if profile.arDiscoveries.count >= 20 && !earned.contains(BadgeType.stargazer.rawValue) {
            profile.unlockedBadges.append(BadgeType.stargazer.rawValue)
        }
    }
}
```

**Step 5: Build and verify**

**Step 6: Commit** — `feat: add core models, gamification engine, and badge system`

---

## Task 4: Shared UI Components

**Files:**
- Create: `GalaxyMinded/Shared/UI/StarfieldBackground.swift`
- Create: `GalaxyMinded/Shared/UI/XPProgressBar.swift`
- Create: `GalaxyMinded/Shared/UI/BadgeView.swift`
- Create: `GalaxyMinded/Shared/UI/LoadingSpaceView.swift`
- Create: `GalaxyMinded/Shared/Extensions/View+Animations.swift`

**Step 1: StarfieldBackground.swift** — Canvas-based animated star particle background

**Step 2: XPProgressBar.swift** — Animated progress bar showing XP toward next level, gold accent

**Step 3: BadgeView.swift** — Badge display component (locked=gray, unlocked=glowing)

**Step 4: LoadingSpaceView.swift** — Custom loading animation with orbiting dots

**Step 5: View+Animations.swift** — Shared animation modifiers (glow, pulse, fadeSlide)

**Step 6: Build and verify**

**Step 7: Commit** — `feat: add shared UI components - starfield, XP bar, badges, loading`

---

## Task 5: SpaceFeed Module — APOD + Daily Feed

**Files:**
- Create: `GalaxyMinded/SpaceFeed/Models/APOD.swift`
- Create: `GalaxyMinded/SpaceFeed/Services/APODService.swift`
- Create: `GalaxyMinded/SpaceFeed/ViewModels/SpaceFeedViewModel.swift`
- Create: `GalaxyMinded/SpaceFeed/Views/SpaceFeedView.swift`
- Create: `GalaxyMinded/SpaceFeed/Views/APODCardView.swift`
- Create: `GalaxyMinded/SpaceFeed/Views/FactOfDayView.swift`

**Step 1: APOD.swift**

```swift
import Foundation

struct APOD: Codable, Identifiable {
    var id: String { date }
    let copyright: String?
    let date: String
    let explanation: String
    let hdurl: String?
    let mediaType: String
    let title: String
    let url: String
}
```

**Step 2: APODService.swift** — Fetches APOD from NASA API using NetworkManager

**Step 3: SpaceFeedViewModel.swift** — Loads APOD, manages state (loading/loaded/error)

**Step 4: APODCardView.swift** — Hero card with AsyncImage, title, "Read More" expanding explanation

**Step 5: FactOfDayView.swift** — "Did you know..." card with random space facts

**Step 6: SpaceFeedView.swift** — ScrollView composing: APODCard + FactOfDay + asteroid preview + ISS mini + missions

**Step 7: Wire SpaceFeedView into TabRouter tab 0**

**Step 8: Build, run, verify APOD loads**

**Step 9: Commit** — `feat: add space feed with NASA APOD integration`

---

## Task 6: Asteroids Module — NeoWs Tracker + Collection

**Files:**
- Create: `GalaxyMinded/Asteroids/Models/NearEarthObject.swift`
- Create: `GalaxyMinded/Asteroids/Services/NeoWsService.swift`
- Create: `GalaxyMinded/Asteroids/ViewModels/AsteroidsViewModel.swift`
- Create: `GalaxyMinded/Asteroids/Views/AsteroidListView.swift`
- Create: `GalaxyMinded/Asteroids/Views/AsteroidDetailView.swift`
- Create: `GalaxyMinded/Asteroids/Views/AsteroidSizeCompareView.swift`

**Step 1: NearEarthObject.swift**

```swift
import Foundation

struct NeoFeedResponse: Codable {
    let elementCount: Int
    let nearEarthObjects: [String: [NearEarthObject]]
}

struct NearEarthObject: Codable, Identifiable {
    let id: String
    let name: String
    let nasaJplUrl: String
    let absoluteMagnitudeH: Double
    let estimatedDiameter: EstimatedDiameter
    let isPotentiallyHazardousAsteroid: Bool
    let closeApproachData: [CloseApproach]
    let isSentryObject: Bool
}

struct EstimatedDiameter: Codable {
    let meters: DiameterRange
}

struct DiameterRange: Codable {
    let estimatedDiameterMin: Double
    let estimatedDiameterMax: Double
}

struct CloseApproach: Codable {
    let closeApproachDate: String
    let relativeVelocity: Velocity
    let missDistance: MissDistance
}

struct Velocity: Codable {
    let kilometersPerSecond: String
}

struct MissDistance: Codable {
    let kilometers: String
    let lunar: String
}
```

**Step 2: NeoWsService.swift** — Fetches today's asteroids from NeoWs feed

**Step 3: AsteroidsViewModel.swift** — Loads NEOs, manages collection (add to profile.collectedAsteroidIds)

**Step 4: AsteroidListView.swift** — List of asteroids with hazard indicator, size, distance

**Step 5: AsteroidDetailView.swift** — Detail view with all data + "Collect" button that awards XP

**Step 6: AsteroidSizeCompareView.swift** — Visual comparison of asteroid size vs known objects

**Step 7: Wire into Explore tab**

**Step 8: Build, run, verify asteroids load**

**Step 9: Commit** — `feat: add asteroid tracker with NeoWs API and collection system`

---

## Task 7: ISS Tracker Module — Live Map

**Files:**
- Create: `GalaxyMinded/ISSTracker/Models/ISSPosition.swift`
- Create: `GalaxyMinded/ISSTracker/Models/Astronaut.swift`
- Create: `GalaxyMinded/ISSTracker/Services/ISSLocationService.swift`
- Create: `GalaxyMinded/ISSTracker/Services/AstronautService.swift`
- Create: `GalaxyMinded/ISSTracker/ViewModels/ISSTrackerViewModel.swift`
- Create: `GalaxyMinded/ISSTracker/Views/ISSMapView.swift`
- Create: `GalaxyMinded/ISSTracker/Views/ISSInfoOverlay.swift`
- Create: `GalaxyMinded/ISSTracker/Views/CrewListView.swift`

**Step 1: ISSPosition.swift**

```swift
import Foundation

struct ISSPosition: Codable {
    let name: String
    let id: Int
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let velocity: Double
    let visibility: String
    let footprint: Double
    let timestamp: Int
}
```

**Step 2: Astronaut.swift**

```swift
import Foundation

struct AstronautResponse: Codable {
    let number: Int
    let people: [Astronaut]
}

struct Astronaut: Codable, Identifiable {
    var id: String { name }
    let name: String
    let craft: String
}
```

**Step 3: ISSLocationService.swift** — Polls ISS position every 5 seconds using Timer + async

**Step 4: AstronautService.swift** — Fetches people in space

**Step 5: ISSTrackerViewModel.swift** — Manages live position updates, crew list

**Step 6: ISSMapView.swift** — MapKit Map with ISS annotation that moves in real time

**Step 7: ISSInfoOverlay.swift** — Overlay showing altitude, velocity, visibility

**Step 8: CrewListView.swift** — List of astronauts currently in space

**Step 9: Wire into Explore tab**

**Step 10: Build, run, verify ISS tracks on map**

**Step 11: Commit** — `feat: add ISS live tracker with MapKit and crew list`

---

## Task 8: Mars Explorer Module — Rover Gallery

**Files:**
- Create: `GalaxyMinded/MarsExplorer/Models/MarsPhoto.swift`
- Create: `GalaxyMinded/MarsExplorer/Services/MarsRoverService.swift`
- Create: `GalaxyMinded/MarsExplorer/ViewModels/MarsExplorerViewModel.swift`
- Create: `GalaxyMinded/MarsExplorer/Views/MarsGalleryView.swift`
- Create: `GalaxyMinded/MarsExplorer/Views/MarsPhotoDetailView.swift`
- Create: `GalaxyMinded/MarsExplorer/Views/RoverPickerView.swift`

**Step 1: MarsPhoto.swift**

```swift
import Foundation

struct MarsPhotoResponse: Codable {
    let photos: [MarsPhoto]
}

struct MarsPhoto: Codable, Identifiable {
    let id: Int
    let sol: Int
    let camera: MarsCamera
    let imgSrc: String
    let earthDate: String
    let rover: MarsRover
}

struct MarsCamera: Codable {
    let name: String
    let fullName: String
}

struct MarsRover: Codable {
    let name: String
    let status: String
}
```

**Step 2: MarsRoverService.swift** — Fetches photos by rover/sol/camera

**Step 3: MarsExplorerViewModel.swift** — Manages photo loading, rover/sol selection, pagination

**Step 4: MarsGalleryView.swift** — Grid layout of Mars photos with lazy loading

**Step 5: MarsPhotoDetailView.swift** — Fullscreen photo with camera/rover/date info

**Step 6: RoverPickerView.swift** — Picker for Curiosity/Opportunity/Spirit + sol slider

**Step 7: Wire into Explore tab**

**Step 8: Build, run, verify Mars photos load**

**Step 9: Commit** — `feat: add Mars rover photo gallery with filtering`

---

## Task 9: Sky AR Module — Augmented Reality

**Files:**
- Create: `GalaxyMinded/SkyAR/Models/CelestialBody.swift`
- Create: `GalaxyMinded/SkyAR/Services/AstronomyAPIService.swift`
- Create: `GalaxyMinded/SkyAR/ViewModels/SkyARViewModel.swift`
- Create: `GalaxyMinded/SkyAR/Views/SkyARView.swift`
- Create: `GalaxyMinded/SkyAR/Views/PlanetAnnotation.swift`

**Step 1: CelestialBody.swift** — Model for planets/stars with name, position, type, size

**Step 2: AstronomyAPIService.swift** — Fetches planet/star positions from Astronomy API (or fallback to calculated positions using CoreLocation + date)

**Step 3: SkyARViewModel.swift** — Manages AR session, converts celestial coordinates to AR world positions

**Step 4: SkyARView.swift** — UIViewRepresentable wrapping ARKit session with camera passthrough

**Step 5: PlanetAnnotation.swift** — AR overlay showing planet name, icon, distance when tapped

**Step 6: Wire into Tab 2 (AR)**

**Step 7: Add Info.plist camera usage description**

**Step 8: Build on device, verify AR works**

**Step 9: Commit** — `feat: add AR sky view with planet discovery`

---

## Task 10: Quiz Module

**Files:**
- Create: `GalaxyMinded/Core/Models/QuizQuestion.swift`
- Create: `GalaxyMinded/Quiz/Services/QuizService.swift`
- Create: `GalaxyMinded/Quiz/ViewModels/QuizViewModel.swift`
- Create: `GalaxyMinded/Quiz/Views/QuizView.swift`
- Create: `GalaxyMinded/Quiz/Views/QuizResultView.swift`

**Step 1: QuizQuestion.swift**

```swift
import Foundation

enum QuizCategory: String, Codable, CaseIterable {
    case planets, history, astronauts, phenomena, missions

    var name: String {
        switch self {
        case .planets: return "Planets"
        case .history: return "Space History"
        case .astronauts: return "Astronauts"
        case .phenomena: return "Phenomena"
        case .missions: return "Missions"
        }
    }
}

struct QuizQuestion: Codable, Identifiable {
    let id: UUID
    let question: String
    let options: [String]
    let correctIndex: Int
    let category: QuizCategory
    let explanation: String
}
```

**Step 2: QuizService.swift** — Bundled JSON of 200+ questions, random daily selection of 10

**Step 3: QuizViewModel.swift** — Manages quiz flow: current question, timer, score, XP calculation

**Step 4: QuizView.swift** — Question display with tappable options, timer bar, progress indicator

**Step 5: QuizResultView.swift** — Score summary, XP earned, badge check for perfectScore

**Step 6: Wire into Tab 3 (Quiz)**

**Step 7: Build, run, verify quiz flow**

**Step 8: Commit** — `feat: add daily quiz with categories and XP rewards`

---

## Task 11: Missions Module

**Files:**
- Create: `GalaxyMinded/Core/Services/MissionEngine.swift`
- Create: `GalaxyMinded/Missions/ViewModels/MissionsViewModel.swift`
- Create: `GalaxyMinded/Missions/Views/MissionBoardView.swift`
- Create: `GalaxyMinded/Missions/Views/MissionDetailView.swift`
- Create: `GalaxyMinded/Missions/Views/MissionCompleteView.swift`

**Step 1: MissionEngine.swift** — Generates daily/weekly missions, tracks progress, checks expiration, awards XP on completion

**Step 2: MissionsViewModel.swift** — Loads active missions from SwiftData, refreshes expired ones

**Step 3: MissionBoardView.swift** — Segmented by Daily/Weekly/Discovery with progress bars

**Step 4: MissionDetailView.swift** — Detail with progress, description, reward preview

**Step 5: MissionCompleteView.swift** — Celebration animation + XP awarded

**Step 6: Build, verify mission creation and tracking**

**Step 7: Commit** — `feat: add mission system with daily, weekly, and discovery missions`

---

## Task 12: Profile Module

**Files:**
- Create: `GalaxyMinded/Core/ViewModels/ProfileViewModel.swift`
- Create: `GalaxyMinded/Missions/Views/ProfileView.swift` (actually in a Profile folder)

**Step 1: ProfileViewModel.swift** — Exposes profile data, stats, badges for display

**Step 2: ProfileView.swift** — Avatar + level + XP bar + streak + badge grid + stats + mission board link

**Step 3: Wire into Tab 4 (Profile)**

**Step 4: Build, verify profile displays correctly**

**Step 5: Commit** — `feat: add profile view with XP, badges, and stats`

---

## Task 13: Explore Tab Composition + Final Wiring

**Files:**
- Create: `GalaxyMinded/App/ExploreView.swift`
- Modify: `GalaxyMinded/App/TabRouter.swift`
- Modify: `GalaxyMinded/App/GalaxyMindedApp.swift`

**Step 1: ExploreView.swift** — Segmented nav with Asteroids / Mars / Earth / ISS sections

**Step 2: Update TabRouter** — Wire all 5 tabs to real views

**Step 3: Update GalaxyMindedApp** — Add all SwiftData models to container

**Step 4: Add AppState.swift** — Global state managing GamificationService initialization on launch, streak update

**Step 5: Full build and test all tabs**

**Step 6: Commit** — `feat: wire all modules into tab navigation and app state`

---

## Task 14: Polish — Animations, Starfield, Transitions

**Step 1: Apply StarfieldBackground to all main views

**Step 2: Add glass card styling to all cards

**Step 3: Add transition animations between tabs

**Step 4: Add haptic feedback on XP gain, badge unlock, mission complete

**Step 5: Add level-up celebration overlay

**Step 6: Full visual review and cleanup

**Step 7: Commit** — `feat: add visual polish - starfield, glass cards, animations, haptics`

---

## Dependency Order

```
Task 1  (Project setup)
  └→ Task 2  (Shared infra)
       └→ Task 3  (Core models + gamification)
            └→ Task 4  (Shared UI components)
                 ├→ Task 5  (SpaceFeed)
                 ├→ Task 6  (Asteroids)
                 ├→ Task 7  (ISS Tracker)
                 ├→ Task 8  (Mars Explorer)
                 ├→ Task 9  (Sky AR)
                 ├→ Task 10 (Quiz)
                 └→ Task 11 (Missions)
                      ├→ Task 12 (Profile)
                      └→ Task 13 (Final wiring)
                           └→ Task 14 (Polish)
```

Tasks 5-11 can be built in parallel after Task 4 is done.
