//
//  ChatOnlineViewController.swift
//  MyEZ
//
//  Created by Javier Gomez on 11/20/18.
//  Copyright © 2018 JDev. All rights reserved.
//

import UIKit
import WebKit

class ChatOnlineViewController: UIViewController, WKUIDelegate {
    
    @IBOutlet weak var web: UIView!
    
    var webView: WKWebView!
    
    // MARK: - Private properties
    /// Progress view reflecting the current loading progress of the web view.
    let progressView = UIProgressView(progressViewStyle: .default)
    
    /// The observation object for the progress of the web view (we only receive notifications until it is deallocated).
    private var estimatedProgressObserver: NSKeyValueObservation?
    
    // MARK: - Public methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.backItem?.title = "Back"

        loadWeb()
    }
    
    //Load web embed on the view
    func loadWeb() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
        
        setupProgressView()
        setupEstimatedProgressObserver()
        
        if let initialUrl = URL(string: "https://tawk.to/chat/5e0120b527773e0d832a7141/default") {
            setupWebview(url: initialUrl)
        }
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
    
    private func setupWebview(url: URL) {
        let request = URLRequest(url: url)
        
        webView.load(request)
    }
}
