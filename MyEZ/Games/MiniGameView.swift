import SwiftUI
import WebKit

// Full-screen host for the HTML game (minigame.html, bundled with the app).
// Opened from the floating game button on the Deals page; presented with
// .fullScreenCover so it covers the custom tab bar.
struct MiniGameView: View {
    @StateObject private var viewModel = MiniGameViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GameWebView { message in
            if message["type"] as? String == "close" {
                dismiss()
            } else {
                viewModel.handle(message: message)
            }
        }
        .ignoresSafeArea()
        .statusBarHidden()
    }
}

// MARK: - Web view

private struct GameWebView: UIViewRepresentable {
    static let handlerName = "myezGame"

    let onMessage: ([String: Any]) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onMessage: onMessage)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        // The handler is held weakly via the proxy so the web view doesn't retain the coordinator
        config.userContentController.add(WeakMessageHandler(context.coordinator), name: Self.handlerName)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        if let url = Bundle.main.url(forResource: "minigame", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            print("❌ minigame.html missing from the app bundle")
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: handlerName)
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        let onMessage: ([String: Any]) -> Void

        init(onMessage: @escaping ([String: Any]) -> Void) {
            self.onMessage = onMessage
        }

        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any] else { return }
            onMessage(body)
        }
    }
}

private final class WeakMessageHandler: NSObject, WKScriptMessageHandler {
    weak var target: WKScriptMessageHandler?

    init(_ target: WKScriptMessageHandler) {
        self.target = target
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        target?.userContentController(userContentController, didReceive: message)
    }
}

#Preview {
    MiniGameView()
}
