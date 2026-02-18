import Foundation

struct CameraType: Identifiable, Sendable {
    let id: String
    let name: String
    let icon: String
    let lutFileName: String?
    let grainIntensity: Double
    let vignetteIntensity: Double
    let bloomIntensity: Double
    let lightLeakEnabled: Bool

    static let allTypes: [CameraType] = [
        CameraType(id: "normal", name: "Normal", icon: "camera",
                   lutFileName: nil,
                   grainIntensity: 0, vignetteIntensity: 0, bloomIntensity: 0, lightLeakEnabled: false),
        CameraType(id: "disposable", name: "Disposable", icon: "camera.compact",
                   lutFileName: "disposable.cube",
                   grainIntensity: 0.3, vignetteIntensity: 1.5, bloomIntensity: 0, lightLeakEnabled: true),
        CameraType(id: "polaroid", name: "Polaroid", icon: "camera.viewfinder",
                   lutFileName: "polaroid.cube",
                   grainIntensity: 0.05, vignetteIntensity: 0.8, bloomIntensity: 0, lightLeakEnabled: false),
        CameraType(id: "film35mm", name: "35mm", icon: "camera.aperture",
                   lutFileName: "portra.cube",
                   grainIntensity: 0.15, vignetteIntensity: 0.3, bloomIntensity: 0, lightLeakEnabled: false),
        CameraType(id: "fuji400", name: "Fuji 400", icon: "camera.circle",
                   lutFileName: "fuji_400h.cube",
                   grainIntensity: 0.1, vignetteIntensity: 0.2, bloomIntensity: 0, lightLeakEnabled: false),
        CameraType(id: "super8", name: "Super8", icon: "film",
                   lutFileName: "super8.cube",
                   grainIntensity: 0.4, vignetteIntensity: 1.2, bloomIntensity: 0, lightLeakEnabled: false),
        CameraType(id: "glow", name: "Glow", icon: "sparkle",
                   lutFileName: "honey.cube",
                   grainIntensity: 0, vignetteIntensity: 0, bloomIntensity: 0.3, lightLeakEnabled: false),
        CameraType(id: "nocturna", name: "Nocturna", icon: "moon.fill",
                   lutFileName: "carbon.cube",
                   grainIntensity: 0.15, vignetteIntensity: 0.6, bloomIntensity: 0, lightLeakEnabled: false),
    ]
}
