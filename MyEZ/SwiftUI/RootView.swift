import SwiftUI

struct RootView: View {
    @ObservedObject var appState: AppState
    @AppStorage("didCompleteWalkthrough") private var didCompleteWalkthrough = false
    
    var body: some View {
        Group {
            // TEST: always show walkthrough — remove before release
            let showWalkthrough = false
            if !showWalkthrough && appState.isAuthenticated {
                RootTabView(appState: appState)
            } else if showWalkthrough || !didCompleteWalkthrough {
                WalkthroughView {
                    didCompleteWalkthrough = true
                }
            } else {
                AuthFlowView(appState: appState)
            }
        }
    }
}
