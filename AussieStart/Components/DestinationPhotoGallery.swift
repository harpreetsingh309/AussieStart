import SwiftUI
import UIKit

struct DestinationPhotoGallery: View {
    let imageNames: [String]
    var title: String = "Photos"

    @State private var selection = 0
    @State private var fullscreenName: String?

    private var availableNames: [String] {
        imageNames.filter { UIImage(named: $0) != nil }
    }

    var body: some View {
        Group {
            if !availableNames.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(title)
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(AppTheme.title)
                        Spacer()
                        Text("\(selection + 1)/\(availableNames.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(AppTheme.mist, in: Capsule())
                    }

                    TabView(selection: $selection) {
                        ForEach(Array(availableNames.enumerated()), id: \.offset) { index, name in
                            Button {
                                fullscreenName = name
                            } label: {
                                Image(name)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 220)
                                    .clipped()
                                    .overlay(alignment: .bottomTrailing) {
                                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.white)
                                            .padding(8)
                                            .background(.black.opacity(0.35), in: Circle())
                                            .padding(12)
                                    }
                            }
                            .buttonStyle(.plain)
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(availableNames.enumerated()), id: \.offset) { index, name in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selection = index
                                    }
                                } label: {
                                    Image(name)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 64, height: 48)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .strokeBorder(
                                                    selection == index ? AppTheme.brandGreen : .clear,
                                                    lineWidth: 2
                                                )
                                        )
                                        .opacity(selection == index ? 1 : 0.7)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Photo \(index + 1)")
                            }
                        }
                    }
                }
                .fullScreenCover(item: Binding(
                    get: { fullscreenName.map(FullscreenPhoto.init(name:)) },
                    set: { fullscreenName = $0?.name }
                )) { photo in
                    FullscreenPhotoViewer(imageNames: availableNames, startName: photo.name)
                }
            }
        }
    }
}

private struct FullscreenPhoto: Identifiable {
    let name: String
    var id: String { name }
}

private struct FullscreenPhotoViewer: View {
    let imageNames: [String]
    let startName: String
    @Environment(\.dismiss) private var dismiss
    @State private var selection: Int = 0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            TabView(selection: $selection) {
                ForEach(Array(imageNames.enumerated()), id: \.offset) { index, name in
                    Image(name)
                        .resizable()
                        .scaledToFit()
                        .tag(index)
                        .padding()
                }
            }
            .tabViewStyle(.page)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
                    .padding()
            }
            .accessibilityLabel("Close")
        }
        .onAppear {
            selection = imageNames.firstIndex(of: startName) ?? 0
        }
    }
}
