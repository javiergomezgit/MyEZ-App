//
//  InStockViewController.swift
//  MyEZ
//
//  Created by Javier Gomez on 7/19/19.
//  Copyright © 2019 JDev. All rights reserved.
//

import UIKit
import WebKit

class InStockViewController: UIViewController {

    @IBOutlet weak var webNewsletter: UIView!
    
    var refreshControl: UIRefreshControl!
    var webView: WKWebView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView = WKWebView(frame: webNewsletter.bounds)
       
        if let webView = webView {
            webView.translatesAutoresizingMaskIntoConstraints = false
            webNewsletter.addSubview(webView)
            let bindings: [String: AnyObject] = ["webView": webView]
            webNewsletter.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[webView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: bindings))
            webNewsletter.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[webView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: bindings))
            
            let url = URL(string:"https://www.ezinflatables.com/collections/offerapp")
            let request = URLRequest(url:url!)
            webView.load(request)
        }
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshWebView(_:)), for: UIControl.Event.valueChanged)
        webView!.scrollView.addSubview(refreshControl)
        webView!.scrollView.bounces = true
    }
    
    
    @objc func refreshWebView(_ sender: UIRefreshControl) {
        webView?.reload()
        sender.endRefreshing()
    }
    
}
