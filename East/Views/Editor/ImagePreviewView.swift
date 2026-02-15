import SwiftUI

struct ImagePreviewView: View {
    let image: UIImage?
    let isProcessing: Bool

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.eastDark

                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnifyGesture()
                                .onChanged { value in
                                    let newScale = lastScale * value.magnification
                                    scale = min(max(newScale, 1.0), 5.0)
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    if scale <= 1.0 {
                                        withAnimation(.spring(response: 0.3)) {
                                            scale = 1.0
                                            offset = .zero
                                            lastOffset = .zero
                                        }
                                    }
                                }
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    if scale > 1.0 {
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring(response: 0.3)) {
                                if scale > 1.0 {
                                    scale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                    lastScale = 1.0
                                } else {
                                    scale = 2.5
                                    lastScale = 2.5
                                }
                            }
                        }
                }

                if isProcessing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color.eastPrimary)
                        .scaleEffect(0.8)
                        .padding(8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                }
            }
        }
        .clipped()
    }
}
