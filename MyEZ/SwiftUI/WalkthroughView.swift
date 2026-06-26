import SwiftUI

struct WalkthroughView: View {
    @State private var index = 0
    private let totalPages = 4

    let onFinish: () -> Void

    private var topButtonLabel: String {
        index == totalPages - 1 ? "Done" : "Skip"
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            SceneBackgroundView()

            TabView(selection: $index) {
                WalkthroughPage1(index: $index, totalPages: totalPages)
                    .tag(0)
                WalkthroughPage2(index: $index, totalPages: totalPages)
                    .tag(1)
                WalkthroughPage3(index: $index, totalPages: totalPages)
                    .tag(2)
                WalkthroughPage4(index: $index, totalPages: totalPages, onFinish: onFinish)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.25), value: index)

            Button(action: onFinish) {
                Text(topButtonLabel)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 11)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.30))
                    )
            }
            .buttonStyle(.plain)
            .padding(.top, 18)
            .padding(.trailing, 20)
        }
    }
}
