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
    private var earlyJS: String?
    private var customCSS: String?
    private var customJS: String?
    private var showNavButtons: Bool = true
    var blockCheckoutNavigation: Bool = false

    func configure(
        url: URL,
        title: String? = nil,
        earlyJS: String? = nil,
        customCSS: String? = nil,
        customJS: String? = nil,
        showNavButtons: Bool = true,
        blockCheckoutNavigation: Bool = false
    ) {
        startURL = url
        pageTitleText = title
        self.earlyJS = earlyJS
        self.customCSS = customCSS
        self.customJS = customJS
        self.showNavButtons = showNavButtons
        self.blockCheckoutNavigation = blockCheckoutNavigation
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

        // Runs before any page scripts — used to intercept/block widget injection
        if let earlyJS {
            let userScript = WKUserScript(source: earlyJS, injectionTime: .atDocumentStart, forMainFrameOnly: false)
            webConfiguration.userContentController.addUserScript(userScript)
        }

        if let customCSS {
            let cleanCSS = customCSS.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "'", with: "\\'")
            let jsString = "var style = document.createElement('style'); style.innerHTML = '\(cleanCSS)'; document.head.appendChild(style);"
            let userScript = WKUserScript(source: jsString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            webConfiguration.userContentController.addUserScript(userScript)
        }

        if let customJS {
            let userScript = WKUserScript(source: customJS, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            webConfiguration.userContentController.addUserScript(userScript)
        }

        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        webView.navigationDelegate = self

        view = webView

        setupProgressView()
        setupEstimatedProgressObserver()

        if let url = startURL {
            webView.load(URLRequest(url: url))
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
        if webView.canGoBack { webView.goBack() }
    }

    @objc private func refreshBrowser() {
        webView.reload()
    }

    func goBack() {
        if webView.canGoBack { webView.goBack() }
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

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if blockCheckoutNavigation,
           let url = action.request.url,
           url.absoluteString.contains("/checkout") {
            decisionHandler(.cancel)
            webView.evaluateJavaScript("window.myezShowModal && window.myezShowModal();", completionHandler: nil)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
        UIView.transition(with: progressView, duration: 0.33, options: [.transitionCrossDissolve], animations: {
            self.progressView.isHidden = false
        }, completion: nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        UIView.transition(with: progressView, duration: 0.33, options: [.transitionCrossDissolve], animations: {
            self.progressView.isHidden = true
        }, completion: nil)
    }
}
