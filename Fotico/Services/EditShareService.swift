import Foundation
import UIKit

struct EditShareService {
    static func shareURL(from editState: EditState) -> URL? {
        guard let data = try? JSONEncoder().encode(editState) else { return nil }
        let base64 = data.base64EncodedString()
        guard let encoded = base64.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return URL(string: "lume://edit?data=\(encoded)")
    }

    static func editState(from url: URL) -> EditState? {
        guard url.scheme == "lume",
              url.host == "edit",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let dataParam = components.queryItems?.first(where: { $0.name == "data" })?.value,
              let data = Data(base64Encoded: dataParam) else { return nil }
        return try? JSONDecoder().decode(EditState.self, from: data)
    }

    @MainActor
    static func presentShareSheet(editState: EditState) {
        guard let url = shareURL(from: editState) else { return }
        let text = "¡Mira mi edición en Lumé! \(url.absoluteString)"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        rootVC.present(activityVC, animated: true)
    }
}
