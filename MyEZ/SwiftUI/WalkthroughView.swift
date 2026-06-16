import SwiftUI

struct WalkthroughView: View {
    @State private var index = 0
    private let totalPages = 4

    let onFinish: () -> Void

    private var showSkip: Bool { index < totalPages - 1 }

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

            if showSkip {
                Button(action: onFinish) {
                    Text("Skip")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(index == 0 ? AppColors.textSecondary : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(index == 0 ? Color.clear : Color.black.opacity(0.34))
                        .overlay(
                            Capsule()
                                .stroke(index == 0 ? Color.clear : Color.white.opacity(0.16), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 18)
                .padding(.trailing, 20)
            }
        }
    }
}
