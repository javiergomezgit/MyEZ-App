//
//  BrowseViewController.swift
//  MyEZ
//
//  Created by Javier Gomez on 11/8/17.
//  Copyright © 2017 JDev. All rights reserved.
//

import UIKit
import WebKit
import NVActivityIndicatorView


class BrowseViewController: UIViewController, WKUIDelegate {
    
    @IBOutlet weak var web: UIView!
    
    var webView: WKWebView!
    
    // MARK: - Private properties
    let progressView = UIProgressView(progressViewStyle: .default)
    private var estimatedProgressObserver: NSKeyValueObservation?
    
    var currentSessionID: String? {
        
        //Try getting session from memory
        if let memorySessionID = SessionManager.shared.currentSessionID {
            return memorySessionID
        }
        
        //Fallback to device memory
        return UserSession.shared.getSessionID()
    }
    
    // MARK: - Public methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = .black
        loadCustomBars(updateBar: true)
        loadWeb()
    }
    
    // Load web embed with CSS Injection
    func loadWeb() {
        let webConfiguration = WKWebViewConfiguration()
        let cssString = """
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
       
        let cleanCSS = cssString.replacingOccurrences(of: "\n", with: " ")
        
        let jsString = "var style = document.createElement('style'); style.innerHTML = '\(cleanCSS)'; document.head.appendChild(style);"
        
        let userScript = WKUserScript(source: jsString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        
        webConfiguration.userContentController.addUserScript(userScript)
        
        // 2. Initialize WebView with this configuration
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        
        // Set the main view to be the webView
        view = webView
        
        setupProgressView()
        setupEstimatedProgressObserver()
        
        if let initialUrl = URL(string: "https://ezinflatables.odoo.com/shop") {
            setupWebview(url: initialUrl)
        }
    }
    
    // Load custom navigation bar
    func loadCustomBars(updateBar: Bool) {
        // 1. Configuration for Nav Bar Icons (Scale: Large makes them easier to tap/see)
        let config = UIImage.SymbolConfiguration(scale: .large) // or .medium for standard size
        
        // 2. Load System Symbols directly (No Assets needed!)
        // "chevron.backward" is the standard back arrow
        // "arrow.clockwise" is the standard refresh icon
        let backImage = UIImage(systemName: "arrowshape.left.circle", withConfiguration: config)?
            .withRenderingMode(.alwaysOriginal) // Keeps them Black/Dark
        
        let refreshImage = UIImage(systemName: "arrow.clockwise.circle", withConfiguration: config)?
            .withRenderingMode(.alwaysOriginal)
        
        // 3. Create Buttons
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
        
        // 4. Assign to Left and Right
        navigationItem.leftBarButtonItem = leftButton
        navigationItem.rightBarButtonItem = rightButton
    }
    
    // Functions for browser buttons
    @objc func goBackward() {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    @objc func refreshBrowser(){
        webView.reload()
    }
    
    
    // MARK: - Private methods
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
    
    // 3. COOKIE INJECTION: Inject Session before loading
    private func setupWebview(url: URL) {
        
        // This MUST match the string in loginAndSaveCookie EXACTLY.
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"
        
        webView.navigationDelegate = self
        
        guard let sessionID = currentSessionID else {
            // If no session exists, just load normally (user might need to login manually)
            let request = URLRequest(url: url)
            webView.load(request)
            return
        }
        
        clearWebViewCache { [weak self] in
            guard let self = self else { return }
            
            let cookieDomain = url.host ?? "ezinflatables.odoo.com"
            
            // Define the cookie
            let cookieProps: [HTTPCookiePropertyKey: Any] = [
                .name: "session_id",
                .value: sessionID,
                .domain: cookieDomain,
                .path: "/",
                .secure: "TRUE",
                .expires: Date().addingTimeInterval(60 * 60 * 24 * 7) // 1 week
            ]
            
            if let cookie = HTTPCookie(properties: cookieProps) {
                // Set cookie asynchronously, then load page
                webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie) { [weak self] in
                    print("Cookie injected: \(sessionID)")
                    let request = URLRequest(url: url)
                    self?.webView.load(request)
                }
            } else {
                // Fallback if cookie creation fails
                let request = URLRequest(url: url)
                webView.load(request)
            }
        }
    }
    
    func clearWebViewCache(completion: @escaping () -> Void) {
        let dataStore = WKWebsiteDataStore.default()
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        let dateFrom = Date(timeIntervalSince1970: 0)
        
        print("🧹 Nuking WebView Cache...")
        
        dataStore.removeData(ofTypes: dataTypes, modifiedSince: dateFrom) {
            print("✨ WebView Cache Cleared.")
            completion()
        }
    }
}

// MARK: - WKNavigationDelegate
extension BrowseViewController: WKNavigationDelegate {
    
    func webView(_: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
        UIView.transition(with: progressView, duration: 0.33, options: [.transitionCrossDissolve], animations: {
            self.progressView.isHidden = false
        }, completion: nil)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // 1. Hide Progress Bar (Your existing code)
        UIView.transition(with: progressView, duration: 0.33, options: [.transitionCrossDissolve], animations: {
            self.progressView.isHidden = true
        }, completion: nil)
        
        // 2. DEBUG: Print visible cookies
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            print("🔎 WEBVIEW COOKIES FOUND: \(cookies.count)")
            for cookie in cookies {
                print("🍪 Name: \(cookie.name) | Value: \(cookie.value) | Domain: \(cookie.domain)")
            }
            
            // CHECK: Do you see 'session_id' here?
            if !cookies.contains(where: { $0.name == "session_id" }) {
                print("❌ CRITICAL: session_id is MISSING from the WebView!")
            }
        }
    }
}
