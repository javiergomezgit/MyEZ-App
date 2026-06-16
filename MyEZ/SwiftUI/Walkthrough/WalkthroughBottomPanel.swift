import SwiftUI

/// Shared floating bottom panel used by every walkthrough page.
struct WalkthroughBottomPanel: View {
    @Binding var index: Int
    let totalPages: Int
    let title: String
    let subtitle: String
    var onDone: (() -> Void)? = nil

    private var isLast: Bool { index == totalPages - 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Text(subtitle)
                .font(.system(size: 15))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if isLast {
                // Last page: dots centered + full-width Get Started button
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        ForEach(0..<totalPages, id: \.self) { i in
                            Circle()
                                .fill(i == index ? AppColors.accentRed : AppColors.borderStrong)
                                .frame(width: i == index ? 8 : 7, height: i == index ? 8 : 7)
                        }
                    }
                    Spacer()
                }
                .padding(.top, 2)

                Button(action: { onDone?() }) {
                    Text("Get Started")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .fill(AppColors.accentRed)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)

            } else {
                // Other pages: back arrow + dots + forward arrow
                HStack {
                    Button(action: { if index > 0 { index -= 1 } }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(index == 0 ? AppColors.textMuted : AppColors.textPrimary)
                    }
                    .disabled(index == 0)

                    Spacer()

                    HStack(spacing: 6) {
                        ForEach(0..<totalPages, id: \.self) { i in
                            Circle()
                                .fill(i == index ? AppColors.accentRed : AppColors.borderStrong)
                                .frame(width: i == index ? 8 : 7, height: i == index ? 8 : 7)
                        }
                    }

                    Spacer()

                    Button(action: { index += 1 }) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.accentRed)
                    }
                }
                .padding(.top, 6)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 32)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColors.surfacePrimary)
                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: -4)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 16)
    }
}
