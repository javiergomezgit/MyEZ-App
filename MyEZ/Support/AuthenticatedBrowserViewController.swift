//
//  AuthenticatedBrowserViewController.swift
//  MyEZ
//
//  Created by Javier Gomez on 3/4/26.
//

import UIKit
import WebKit

struct AccountProfileInfo {
    let name: String
    let email: String
    let phone: String
    let companyName: String
    let zipCode: String
}

final class AuthenticatedBrowserViewController: UIViewController, WKUIDelegate {

    private(set) var webView: WKWebView!

    private let progressView = UIProgressView(progressViewStyle: .default)
    private var estimatedProgressObserver: NSKeyValueObservation?

    private var startURL: URL?
    private var pageTitleText: String?
    private var injectShopCSS: Bool = true
    private var showNavButtons: Bool = true
    private var onAccountProfileSaved: ((AccountProfileInfo) -> Void)?
    private var portalSavePathPrefix: String?
    private var onPortalSave: (() -> Void)?
    private var lastSyncedAccountSignature: String?
    private var didTriggerAccountReadback = false
    private var didHandlePortalSave = false

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

    private static let portalSaveObserverScript = """
        (function() {
          if (window.__myezPortalSaveInstalled) { return; }
          window.__myezPortalSaveInstalled = true;

          function markSavePending(form) {
            if (!form || !(form instanceof HTMLFormElement)) { return; }
            var action = form.getAttribute('action') || window.location.pathname || '';
            try {
              sessionStorage.setItem('myezPortalSavePending', action || '1');
              console.log('[MyEZ][PortalSave] marked pending for action=' + action);
            } catch (error) {}
          }

          document.addEventListener('submit', function(event) {
            markSavePending(event.target);
          }, true);

          document.addEventListener('click', function(event) {
            var button = event.target && event.target.closest ? event.target.closest("button[type='submit'], input[type='submit'], .btn[type='submit']") : null;
            if (!button) { return; }
            var form = button.form || (button.closest ? button.closest('form') : null);
            markSavePending(form);
          }, true);
        })();
    """

    // This MUST match the string in loginAndSaveCookie EXACTLY.
    private let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"

    var currentSessionID: String? {
        if let memorySessionID = SessionManager.shared.currentSessionID {
            return memorySessionID
        }
        return UserSession.shared.getSessionID()
    }

    func configure(
        url: URL,
        title: String? = nil,
        injectShopCSS: Bool = true,
        showNavButtons: Bool = true,
        onAccountProfileSaved: ((AccountProfileInfo) -> Void)? = nil,
        portalSavePathPrefix: String? = nil,
        onPortalSave: (() -> Void)? = nil
    ) {
        startURL = url
        pageTitleText = title
        self.injectShopCSS = injectShopCSS
        self.showNavButtons = showNavButtons
        self.onAccountProfileSaved = onAccountProfileSaved
        self.portalSavePathPrefix = portalSavePathPrefix
        self.onPortalSave = onPortalSave
        didTriggerAccountReadback = false
        didHandlePortalSave = false
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

        if onPortalSave != nil {
            let portalSaveScript = WKUserScript(
                source: Self.portalSaveObserverScript,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            )
            webConfiguration.userContentController.addUserScript(portalSaveScript)
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

    private func handlePortalSaveIfNeeded(from webView: WKWebView) {
        guard let onPortalSave = onPortalSave, let portalSavePathPrefix = portalSavePathPrefix else { return }
        guard !didHandlePortalSave else { return }

        let currentPath = webView.url?.path ?? ""
        guard currentPath.hasPrefix(portalSavePathPrefix) else { return }

        let script = """
            (function() {
              var pending = '';
              try {
                pending = sessionStorage.getItem('myezPortalSavePending') || '';
              } catch (error) {}

              var hasSuccessBanner = !!document.querySelector('.alert-success, .alert.alert-success, .o_portal_details.alert-success');
              return {
                pending: pending,
                path: window.location.pathname,
                hasSuccessBanner: hasSuccessBanner
              };
            })();
        """

        webView.evaluateJavaScript(script) { [weak self] result, error in
            if let error {
                print("[MyEZ][PortalSave] evaluateJavaScript failed: \(error.localizedDescription)")
                return
            }

            guard
                let self = self,
                let payload = result as? [String: Any]
            else {
                print("[MyEZ][PortalSave] no payload returned from portal save JS")
                return
            }

            let pending = payload["pending"] as? String ?? ""
            let path = payload["path"] as? String ?? currentPath
            let hasSuccessBanner = payload["hasSuccessBanner"] as? Bool ?? false

            print("[MyEZ][PortalSave] path=\(path) pending=\(!pending.isEmpty) hasSuccessBanner=\(hasSuccessBanner)")

            guard !pending.isEmpty else { return }

            self.didHandlePortalSave = true
            self.webView.evaluateJavaScript("try { sessionStorage.removeItem('myezPortalSavePending'); } catch (error) {}") { _, _ in }
            print("[MyEZ][PortalSave] save detected for \(portalSavePathPrefix), dismissing browser")
            onPortalSave()
        }
    }

    private func extractAccountProfileIfNeeded(from webView: WKWebView) {
        guard onAccountProfileSaved != nil else { return }

        let currentPath = webView.url?.path ?? ""
        guard currentPath.hasPrefix("/my") else {
            print("[MyEZ][AccountSync] skipping extraction because current path is not in /my: \(currentPath)")
            return
        }

        print("[MyEZ][AccountSync] didFinish on \(currentPath), checking for account form and completed save")

        let script = """
            (function() {
              function readValue(selectors) {
                for (var i = 0; i < selectors.length; i++) {
                  var element = document.querySelector(selectors[i]);
                  if (element && typeof element.value === 'string') {
                    return element.value.trim();
                  }
                }
                return '';
              }

              var accountForm = document.querySelector("form[action*='/my/account'], form.o_portal_my_details");
              var successBanner = document.querySelector('.alert-success, .alert.alert-success, .o_portal_details.alert-success');
              var successText = successBanner ? (successBanner.textContent || '').trim() : '';
              var hasNameField = !!document.querySelector("input[name='name']");
              var hasEmailField = !!document.querySelector("input[name='email'], input[name='login']");
              var hasCompanyField = !!document.querySelector("input[name='company_name'], input[name='companyName']");
              var hasZipField = !!document.querySelector("input[name='zip'], input[name='zipcode'], input[name='zipCode']");
              var hasAccountFields = hasNameField || hasEmailField || hasCompanyField || hasZipField;
              var hasAccountForm = !!accountForm || hasAccountFields;
              console.log('[MyEZ][AccountSync] path=' + window.location.pathname + ' successBanner=' + !!successBanner + ' hasAccountForm=' + hasAccountForm + ' successText=' + successText);
              if (!hasAccountForm) {
                return {
                  shouldSync: false,
                  successBannerFound: !!successBanner,
                  hasAccountForm: hasAccountForm,
                  hasAccountFields: hasAccountFields,
                  successText: successText,
                  path: window.location.pathname
                };
              }

              return {
                shouldSync: true,
                successBannerFound: !!successBanner,
                hasAccountForm: hasAccountForm,
                hasAccountFields: hasAccountFields,
                successText: successText,
                path: window.location.pathname,
                name: readValue(["input[name='name']"]),
                email: readValue(["input[name='email']", "input[name='login']"]),
                phone: readValue(["input[name='phone']", "input[name='mobile']"]),
                companyName: readValue(["input[name='company_name']", "input[name='companyName']"]),
                zipCode: readValue(["input[name='zip']", "input[name='zipcode']", "input[name='zipCode']"])
              };
            })();
        """

        webView.evaluateJavaScript(script) { [weak self] result, error in
            if let error {
                print("[MyEZ][AccountSync] evaluateJavaScript failed: \(error.localizedDescription)")
                return
            }
            guard
                let payload = result as? [String: Any],
                let self = self
            else {
                print("[MyEZ][AccountSync] no payload returned from account sync JS")
                return
            }

            let shouldSync = payload["shouldSync"] as? Bool ?? false
            let successBannerFound = payload["successBannerFound"] as? Bool ?? false
            let hasAccountForm = payload["hasAccountForm"] as? Bool ?? false
            let hasAccountFields = payload["hasAccountFields"] as? Bool ?? false
            let successText = payload["successText"] as? String ?? ""
            let path = payload["path"] as? String ?? webView.url?.path ?? "unknown"

            print("[MyEZ][AccountSync] JS payload path=\(path) shouldSync=\(shouldSync) successBannerFound=\(successBannerFound) hasAccountForm=\(hasAccountForm) hasAccountFields=\(hasAccountFields) successText=\(successText)")

            guard shouldSync else {
                print("[MyEZ][AccountSync] skipping Firebase sync because no account form was found")
                return
            }

            guard hasAccountFields else {
                if path == "/my", !self.didTriggerAccountReadback, let accountURL = URL(string: "https://ezinflatables.odoo.com/my/account") {
                    self.didTriggerAccountReadback = true
                    print("[MyEZ][AccountSync] /my page has no account fields, loading /my/account to read back saved values")
                    webView.load(URLRequest(url: accountURL))
                } else {
                    print("[MyEZ][AccountSync] account form detected but no editable account fields were found")
                }
                return
            }

            let accountInfo = AccountProfileInfo(
                name: (payload["name"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
                email: (payload["email"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
                phone: (payload["phone"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
                companyName: (payload["companyName"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
                zipCode: (payload["zipCode"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            )

            print("[MyEZ][AccountSync] extracted values name='\(accountInfo.name)' email='\(accountInfo.email)' phone='\(accountInfo.phone)' company='\(accountInfo.companyName)' zip='\(accountInfo.zipCode)'")

            let extractedAllEmpty = accountInfo.name.isEmpty
                && accountInfo.email.isEmpty
                && accountInfo.phone.isEmpty
                && accountInfo.companyName.isEmpty
                && accountInfo.zipCode.isEmpty

            if extractedAllEmpty, path == "/my", !self.didTriggerAccountReadback,
               let accountURL = URL(string: "https://ezinflatables.odoo.com/my/account") {
                self.didTriggerAccountReadback = true
                print("[MyEZ][AccountSync] /my returned empty account values, loading /my/account to read back saved values")
                webView.load(URLRequest(url: accountURL))
                return
            }

            guard !accountInfo.name.isEmpty || !accountInfo.email.isEmpty else {
                print("[MyEZ][AccountSync] extracted values were empty, aborting sync")
                return
            }

            let cachedUser = UserSession.shared.load()
            let normalizedPhone = accountInfo.phone.unicodeScalars
                .filter { CharacterSet.decimalDigits.contains($0) }
                .map(String.init)
                .joined()
            let didChange = cachedUser?.name != accountInfo.name
                || cachedUser?.email != accountInfo.email
                || userInformation.phone != normalizedPhone
                || userInformation.companyName != accountInfo.companyName
                || userInformation.zipCode != accountInfo.zipCode

            print("[MyEZ][AccountSync] normalized phone='\(normalizedPhone)' compared against cached values didChange=\(didChange)")

            guard didChange else {
                print("[MyEZ][AccountSync] no account changes detected, skipping sync")
                return
            }

            let signature = [
                accountInfo.name,
                accountInfo.email,
                normalizedPhone,
                accountInfo.companyName,
                accountInfo.zipCode
            ].joined(separator: "|")

            if self.lastSyncedAccountSignature == signature {
                print("[MyEZ][AccountSync] identical account payload already synced, skipping duplicate write")
                return
            }

            self.lastSyncedAccountSignature = signature
            print("[MyEZ][AccountSync] invoking onAccountProfileSaved callback")
            self.onAccountProfileSaved?(accountInfo)
        }
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

    func webView(_ webView: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
        UIView.transition(with: progressView, duration: 0.33, options: [.transitionCrossDissolve], animations: {
            self.progressView.isHidden = false
        }, completion: nil)

        print("[MyEZ][AccountSync] webView didStart url=\(webView.url?.absoluteString ?? "nil")")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        UIView.transition(with: progressView, duration: 0.33, options: [.transitionCrossDissolve], animations: {
            self.progressView.isHidden = true
        }, completion: nil)

        print("[MyEZ][AccountSync] webView didFinish url=\(webView.url?.absoluteString ?? "nil")")

        handlePortalSaveIfNeeded(from: webView)
        extractAccountProfileIfNeeded(from: webView)

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
