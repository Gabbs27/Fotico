# Fotico v2: Tezza-Inspired Redesign

## Overview

Transform Fotico from a simple photo editor into a Tezza-style aesthetic photo editing app with accounts, subscriptions, premium LUT presets, batch editing, and texture overlays. All data stored locally in Documents & Data.

## 1. Architecture Changes

### Navigation: Tab-Based Home
```
App Launch → OnboardingView (first launch only)
           → HomeTabView
               ├── Tab 1: Editor (MainEditorView — existing)
               ├── Tab 2: Cámara (CameraView — existing)
               ├── Tab 3: Proyectos (saved edits gallery)
               └── Tab 4: Perfil (account, subscription, settings)
```

### New Dependencies
- `StoreKit 2` — subscriptions (already in SDK)
- `AuthenticationServices` — Sign in with Apple (already in SDK)
- `SwiftData` — local persistence for projects, saved edits, user profile
- No external packages required

## 2. Account System

### Auth Flow
- Sign in with Apple via `AuthenticationServices`
- Optional — user can skip and use app without account
- Account needed for: subscription purchase, saved presets sync (future)
- Credentials stored in Keychain, profile in SwiftData

### Models
```swift
@Model class UserProfile {
    var appleUserID: String?
    var displayName: String
    var email: String?
    var avatarData: Data?
    var createdAt: Date
    var subscriptionTier: SubscriptionTier  // .free, .pro
}

enum SubscriptionTier: String, Codable {
    case free
    case pro
}
```

### Profile View
- Avatar, name, email
- Subscription status + manage button
- Saved presets count
- Settings (haptics toggle, export quality, about)

## 3. Subscription (StoreKit 2)

### Plans
| Plan | Price | Product ID |
|------|-------|------------|
| Fotico Pro Monthly | $4.99/mo | `com.fotico.pro.monthly` |
| Fotico Pro Annual | $29.99/yr | `com.fotico.pro.annual` |

### Implementation
- `SubscriptionService` using StoreKit 2 `Product`, `Transaction`
- Auto-renewal handling via `Transaction.updates` listener
- Paywall view with feature comparison (free vs pro)
- Premium content shows 🔒 badge → tap → paywall

### What Pro Unlocks
- 30+ premium LUT presets
- Premium overlays/textures
- Batch editing (copy/paste edits)
- Save unlimited custom presets

## 4. Preset System (LUT + CIFilter)

### Tiers
| Tier | Count | Tech | Access |
|------|-------|------|--------|
| Free | ~10 | CIFilter chains | Everyone |
| Pro | ~30+ | LUT .cube files | Subscribers |

### Categories
| Category | Icon | Mood |
|----------|------|------|
| Película | 🎞️ | Film emulation (Kodak, Fuji, Polaroid) |
| Cálidos | 🌅 | Warm, golden hour (Dorado, Miel, Canela) |
| Fríos | 🌊 | Cool, moody (Océano, Niebla, Invierno) |
| B&W | 🖤 | Monochrome (Noir, Plata, Carbón) |
| Cine | 🎬 | Cinematic grading (Teal&Orange, Noche) |
| Suaves | 🌸 | Soft, pastel (Pétalo, Nube, Algodón) |
| Editorial | 📰 | Magazine look (Revista, Portada, Glam) |
| Vintage | 🕰️ | Retro, nostalgic (Nostalgia, Sepia, VHS) |

### LUT Pipeline
```
.cube file → Data → parse to [Float] → CIColorCubeWithColorSpace → CIImage
```
- LUT files bundled in `Resources/LUTs/free/` and `Resources/LUTs/pro/`
- Each .cube file ~1-2MB (64x64x64 3D LUT)
- `LUTService` caches parsed LUT data in memory
- Applied via `CIFilter(name: "CIColorCubeWithColorSpace")`

### Preset Model (expanded)
```swift
struct FilterPreset: Identifiable, Codable, Sendable {
    let id: String
    let name: String
    let displayName: String
    let category: PresetCategory
    let tier: PresetTier
    let lutFileName: String?       // "kodak_gold.cube"
    let ciFilterName: String?      // fallback CIFilter
    let parameters: [FilterParameter]
    let defaultIntensity: Double
    let sortOrder: Int
}
```

### Preset Strip UI
- Horizontal scroll grouped by category tabs
- Each preset: thumbnail + name + 🔒 if pro
- Intensity slider below
- Category filter chips at top

## 5. Batch Editing (Copy/Paste)

### Flow
```
Edit photo → "Copiar Edición" button → EditState saved to clipboard
→ Open new photo → "Pegar Edición" → applies saved EditState
```

### Implementation
- `EditClipboard` singleton holds the copied `EditState`
- Button in top toolbar: copy icon (appears after any edit)
- Paste button appears in toolbar when clipboard has content
- Can also save edits permanently as "Mis Presets" (SwiftData)

### Saved Edits Model
```swift
@Model class SavedEdit {
    var name: String
    var editStateData: Data    // Codable EditState
    var thumbnailData: Data?
    var createdAt: Date
}
```

## 6. Overlays & Textures

### Categories
| Category | Examples |
|----------|---------|
| Dust | Particle overlays, film scratches |
| Light | Light leaks, lens flares, bokeh |
| Frames | Super8, Polaroid, 35mm borders |
| Paper | Paper texture, wrinkled, newsprint |
| Grain | Film grain at various intensities |

### Implementation
- PNG files in `Resources/Overlays/{category}/`
- Applied via `CISourceOverCompositing` (GPU-composited)
- Intensity slider controls overlay opacity
- New `OverlayPanelView` as 5th tool tab
- Pro overlays show 🔒 → paywall

### Pipeline
```
overlay PNG → CIImage → scale to match photo → adjust opacity → composite over edited image
```

## 7. Projects (Local Storage)

### Concept
Save edited photos as "projects" that can be re-opened and re-edited.

### Model
```swift
@Model class PhotoProject {
    var name: String
    var originalImagePath: String
    var editStateData: Data
    var thumbnailData: Data?
    var createdAt: Date
    var modifiedAt: Date
}
```

### Storage
- Original images saved to `Documents/projects/{id}/original.jpg`
- Edit state serialized as JSON
- Thumbnails generated on save (200x200)
- Projects tab shows grid of saved projects

## 8. New File Structure

```
Fotico/
  App/
    FoticoApp.swift          (updated: SwiftData + tab nav)
  Models/
    UserProfile.swift        (NEW: SwiftData model)
    PhotoProject.swift       (NEW: SwiftData model)
    SavedEdit.swift          (NEW: SwiftData model)
    EditState.swift          (updated: Codable)
    FilterPreset.swift       (updated: tier, LUT, sortOrder)
    OverlayAsset.swift       (NEW: overlay model)
    EffectType.swift
  Services/
    AuthService.swift        (NEW: Sign in with Apple)
    SubscriptionService.swift (NEW: StoreKit 2)
    LUTService.swift         (NEW: .cube parser + cache)
    ProjectStorageService.swift (NEW: save/load projects)
    EditClipboard.swift      (NEW: copy/paste edits)
    ImageFilterService.swift (updated: LUT support)
    CameraService.swift
    MetalKernelService.swift
    PhotoLibraryService.swift
    RenderEngine.swift
  ViewModels/
    AuthViewModel.swift      (NEW)
    SubscriptionViewModel.swift (NEW)
    ProjectsViewModel.swift  (NEW)
    PhotoEditorViewModel.swift (updated: clipboard, overlays)
    CameraViewModel.swift
  Views/
    HomeTabView.swift        (NEW: tab container)
    Onboarding/
      OnboardingView.swift   (NEW)
    Auth/
      LoginView.swift        (NEW: Sign in with Apple)
      PaywallView.swift      (NEW: subscription paywall)
    Profile/
      ProfileView.swift      (NEW)
      SettingsView.swift     (NEW)
    Projects/
      ProjectsGridView.swift (NEW)
      ProjectDetailView.swift (NEW)
    Editor/
      OverlayPanelView.swift (NEW: texture overlays)
      ... (existing editor views)
    Camera/
      ... (existing camera views)
    Components/
      PremiumBadge.swift     (NEW: 🔒 lock overlay)
      ... (existing components)
  Resources/
    LUTs/
      free/                  (bundled .cube files)
      pro/                   (bundled .cube files)
    Overlays/
      dust/                  (PNG files)
      light/                 (PNG files)
      frames/                (PNG files)
      paper/                 (PNG files)
      grain/                 (PNG files)
```

## 9. Bottom Toolbar Update

Current: `Presets | Ajustes | Efectos | Rotar`

New: `Presets | Ajustes | Efectos | Overlays | Rotar`

## 10. Implementation Priority

1. **Phase 1: Foundation** — SwiftData, tab nav, HomeTabView, updated models
2. **Phase 2: Presets** — LUT parser, 40+ presets, new preset UI with categories
3. **Phase 3: Overlays** — PNG overlays, OverlayPanelView, compositor
4. **Phase 4: Projects** — Save/load, ProjectsGridView
5. **Phase 5: Accounts** — AuthService, ProfileView, Sign in with Apple
6. **Phase 6: Subscription** — StoreKit 2, PaywallView, premium gating
7. **Phase 7: Batch Edit** — EditClipboard, copy/paste UI
8. **Phase 8: Polish** — Onboarding, animations, final testing
