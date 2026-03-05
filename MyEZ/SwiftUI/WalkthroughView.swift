import SwiftUI

struct WalkthroughView: View {
    private let pages = ["walk1", "walk2", "walk3", "walk4", "walk5"]
    @State private var index = 0

    let onFinish: () -> Void

    var body: some View {
        ZStack {
            AppColors.dark.ignoresSafeArea()

            ZStack {
                Image(pages[index])
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()

                VStack(spacing: 18) {
                    Spacer()

                    HStack(spacing: 16) {
                    Button {
                        if index > 0 { index -= 1 }
                    } label: {
                        Image("arrowBack")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                    }
                    .buttonStyle(.plain)
                    .opacity(index == 0 ? 0.4 : 1)
                    .disabled(index == 0)

                    Spacer()

                    Button {
                        if index < pages.count - 1 {
                            index += 1
                        } else {
                            onFinish()
                        }
                    } label: {
                        Image("arrowButton")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 58, height: 58)
                    }
                    .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 28)

                    Button {
                        onFinish()
                    } label: {
                        Image("skipWalk")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 110, height: 36)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}
