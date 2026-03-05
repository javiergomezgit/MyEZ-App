//
//  AuthenticatedBrowserViewController.swift
//  MyEZ
//
//  Created by Javier Gomez on 3/4/26.
//

import UIKit
import WebKit

final class AuthenticatedBrowserViewController: UIViewController, WKUIDelegate {

    private(set) var webView: WKWebView!

    private let progressView = UIProgressView(progressViewStyle: .default)
    private var estimatedProgressObserver: NSKeyValueObservation?

    private var startURL: URL?
    private var pageTitleText: String?
    private var injectShopCSS: Bool = true
    private var showNavButtons: Bool = true

    private static let defaultShopURL = URL(string: "https://ezinflatables.odoo.com/shop")!

    private static let shopCSS = """
        .header_logo_wrapper {
          display: none !important;
        }
        #accessibility_settings_toggle{
          display: none !important;
        }
        #bottom {
          display: none !important;
        }
        .o_livechat_button {
          display: none !important;
        }
        #o_livechat_container {
          display: none !important;
        }

        /* Hide the navigation bar container */
        #o_main_nav_mobile {
          background: transparent !important;
          border: none !important;
          box-shadow: none !important;
          position: static !important;
        }

        /* Hide first 3 li elements */
        #o_main_nav_mobile ul li:nth-child(-n+3) {
          display: none !important;
        }

        /* Hide the ul styling */
        #o_main_nav_mobile ul {
          background: transparent !important;
          border: none !important;
          padding: 0 !important;
          margin: 0 !important;
        }

        /* Show only the 4th li with red circle in bottom-right */
        #o_main_nav_mobile ul li:nth-child(4) {
          display: block !important;
          position: fixed;
          bottom: 20px;
          right: 20px;
          z-index: 9999;
        }

        #o_main_nav_mobile ul li:nth-child(4) a {
          display: flex;
          align-items: center;
          justify-content: center;
          width: 50px;
          height: 50px;
          background-color: #dc3545;
          border-radius: 50%;
          color: white !important;
          text-decoration: none;
        }

        /* Hide the text, keep only the icon */
        #o_main_nav_mobile ul li:nth-child(4) a span {
          display: none !important;
        }

        body {
          padding-top: 0px !important;
        }
        .o_content {
          margin-top: 0px !important;
        }
    """

    // This MUST match the string in loginAndSaveCookie EXACTLY.
    private let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"

    var currentSessionID: String? {
        if let memorySessionID = SessionManager.shared.currentSessionID {
            return memorySessionID
        }
        return UserSession.shared.getSessionID()
    }

    func configure(url: URL, title: String? = nil, injectShopCSS: Bool = true, showNavButtons: Bool = true) {
        startURL = url
        pageTitleText = title
        self.injectShopCSS = injectShopCSS
        self.showNavButtons = showNavButtons
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.tintColor = .black

        if let pageTitleText {
            title = pageTitleText
        }

        if showNavButtons {
            loadCustomBars()
        }

        loadWeb()
    }

    deinit {
        estimatedProgressObserver?.invalidate()
    }

    // MARK: - Web setup
    private func loadWeb() {
        let webConfiguration = WKWebViewConfiguration()

        if injectShopCSS {
            let cleanCSS = Self.shopCSS.replacingOccurrences(of: "\n", with: " ")
            let jsString = "var style = document.createElement('style'); style.innerHTML = '\(cleanCSS)'; document.head.appendChild(style);"
            let userScript = WKUserScript(source: jsString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            webConfiguration.userContentController.addUserScript(userScript)
        }

        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self

        view = webView

        setupProgressView()
        setupEstimatedProgressObserver()

        let urlToLoad = startURL ?? Self.defaultShopURL
        setupWebview(url: urlToLoad)
    }

    private func setupWebview(url: URL) {
        webView.customUserAgent = userAgent
        webView.navigationDelegate = self

        guard let sessionID = currentSessionID else {
            let request = URLRequest(url: url)
            webView.load(request)
            return
        }

        let cookieDomain = url.host ?? "ezinflatables.odoo.com"
        let domains = [cookieDomain, ".\(cookieDomain)"]
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore

        let group = DispatchGroup()
        var didSetAnyCookie = false

        for domain in domains {
            let cookieProps: [HTTPCookiePropertyKey: Any] = [
                .name: "session_id",
                .value: sessionID,
                .domain: domain,
                .path: "/",
                .secure: true,
                .sameSitePolicy: "Lax",
                .expires: Date().addingTimeInterval(60 * 60 * 24 * 7)
            ]

            guard let cookie = HTTPCookie(properties: cookieProps) else { continue }

            didSetAnyCookie = true
            HTTPCookieStorage.shared.setCookie(cookie)

            group.enter()
            cookieStore.setCookie(cookie) {
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            if didSetAnyCookie {
                print("Cookie injected: \(sessionID)")
            }
            let request = URLRequest(url: url)
            self?.webView.load(request)
        }
    }

    private func clearWebViewCache(completion: @escaping () -> Void) {
        let dataStore = WKWebsiteDataStore.default()
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        let dateFrom = Date(timeIntervalSince1970: 0)

        print("🧹 Nuking WebView Cache...")

        dataStore.removeData(ofTypes: dataTypes, modifiedSince: dateFrom) {
            print("✨ WebView Cache Cleared.")
            completion()
        }
    }

    private func loadCustomBars() {
        let config = UIImage.SymbolConfiguration(scale: .large)

        let backImage = UIImage(systemName: "arrowshape.left.circle", withConfiguration: config)?.withRenderingMode(.alwaysOriginal)
        let refreshImage = UIImage(systemName: "arrow.clockwise.circle", withConfiguration: config)?.withRenderingMode(.alwaysOriginal)

        let leftButton = UIBarButtonItem(
            image: backImage,
            style: .plain,
            target: self,
            action: #selector(self.goBackward)
        )

        let rightButton = UIBarButtonItem(
            image: refreshImage,
            style: .plain,
            target: self,
            action: #selector(self.refreshBrowser)
        )

        navigationItem.leftBarButtonItem = leftButton
        navigationItem.rightBarButtonItem = rightButton
    }

    @objc private func goBackward() {
        if webView.canGoBack {
            webView.goBack()
        }
    }

    @objc private func refreshBrowser() {
        webView.reload()
    }

    func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }

    func refresh() {
        webView.reload()
    }

    private func setupProgressView() {
        guard let navigationBar = navigationController?.navigationBar else { return }

        progressView.transform = progressView.transform.scaledBy(x: 1, y: 5)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.addSubview(progressView)

        progressView.isHidden = true

        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2.0)
        ])
    }

    private func setupEstimatedProgressObserver() {
        estimatedProgressObserver = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            self?.progressView.progress = Float(webView.estimatedProgress)
        }
    }
}

// MARK: - WKNavigationDelegate
extension AuthenticatedBrowserViewController: WKNavigationDelegate {

    func webView(_: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
        UIView.transition(with: progressView, duration: 0.33, options: [.transitionCrossDissolve], animations: {
            self.progressView.isHidden = false
        }, completion: nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        UIView.transition(with: progressView, duration: 0.33, options: [.transitionCrossDissolve], animations: {
            self.progressView.isHidden = true
        }, completion: nil)

        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            print("🔎 WEBVIEW COOKIES FOUND: \(cookies.count)")
            for cookie in cookies {
                print("🍪 Name: \(cookie.name) | Value: \(cookie.value) | Domain: \(cookie.domain)")
            }

            if !cookies.contains(where: { $0.name == "session_id" }) {
                print("\u{274C} CRITICAL: session_id is MISSING from the WebView!")
            }
        }
    }
}
