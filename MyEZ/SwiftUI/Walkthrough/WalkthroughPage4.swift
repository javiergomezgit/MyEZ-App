import SwiftUI

// MARK: - Individual Cards

private struct BackDealCard: View {
    var body: some View {
        HStack {
            Text("☀️").font(.system(size: 20))
            Spacer()
            Text("Expires in 2dh 24h")
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(Color(hex: "CDCDD8"))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct MiddleDealCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text("👀").font(.system(size: 20))
                Spacer()
                Text("BOGO")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().stroke(AppColors.borderStrong, lineWidth: 1))
            }
            Text("Weekend Warrior Deal")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .background(Color(hex: "E2E2EA"))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct FrontDealCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text("💧").font(.system(size: 22))
                Spacer()
                Text("Expires in 2d 14h")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)

            Text("Summer Blowout Sale")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 18)
                .padding(.top, 8)

            Text("Save up to 40% on water slides")
                .font(.system(size: 13))
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 18)
                .padding(.top, 3)

            Spacer()

            HStack {
                Text("40% OFF")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(AppColors.accentRed))

                Spacer()

                Text("View Deal")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(AppColors.accentRed))
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(AppColors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppColors.borderSubtle, lineWidth: 0.7)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)
    }
}

// MARK: - Stacked Deck

private struct StackedDealsView: View {
    var body: some View {
        // Cards peek from behind — back on top, front at bottom (later = higher z-order)
        ZStack(alignment: .top) {
            BackDealCard()
                .rotationEffect(.degrees(-4), anchor: .bottom)
                .padding(.horizontal, 14)

            MiddleDealCard()
                .rotationEffect(.degrees(2), anchor: .bottom)
                .padding(.horizontal, 6)
                .offset(y: 44)

            FrontDealCard()
                .offset(y: 88)
        }
        .frame(height: 270)
        .padding(.horizontal, 20)
    }
}

// MARK: - Page View

struct WalkthroughPage4: View {
    @Binding var index: Int
    let totalPages: Int
    let onFinish: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear

            VStack {
                Spacer()
                StackedDealsView()
                Spacer()
            }
            .padding(.bottom, 240)

            WalkthroughBottomPanel(
                index: $index,
                totalPages: totalPages,
                title: "Deals Built for You",
                subtitle: "Exclusive time-limited offers pushed directly to your phone. They expire automatically, so you never miss a window.",
                onDone: onFinish
            )
        }
    }
}
