import SwiftUI

struct RootView: View {
    @ObservedObject var appState: AppState
    @AppStorage("didCompleteWalkthrough") private var didCompleteWalkthrough = false
    
    var body: some View {
        Group {
            if appState.isAuthenticated {
                RootTabView(appState: appState)
            } else if !didCompleteWalkthrough {
                WalkthroughView {
                    didCompleteWalkthrough = true
                }
            } else {
                AuthFlowView(appState: appState)
            }
        }
        .preferredColorScheme(.dark)
    }
}
