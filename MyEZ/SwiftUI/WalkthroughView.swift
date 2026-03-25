import SwiftUI

struct WalkthroughView: View {
    private let pages = ["walk1", "walk2", "walk3", "walk4"]
    @State private var index = 0

    let onFinish: () -> Void

    private var topActionTitle: String {
        index == pages.count - 1 ? "Done" : "Skip"
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AppColors.dark.ignoresSafeArea()

            TabView(selection: $index) {
                ForEach(Array(pages.enumerated()), id: \.offset) { offset, page in
                    Image(page)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .ignoresSafeArea()
                        .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .interactive))
            .animation(.easeInOut(duration: 0.25), value: index)

            Button(action: onFinish) {
                Text(topActionTitle)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.34))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    )
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 18)
            .padding(.trailing, 20)
        }
    }
}
