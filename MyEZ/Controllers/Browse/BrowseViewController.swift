/*
//
//  BrowseViewController.swift
//  MyEZ
//
//  Created by Javier Gomez on 11/8/17.
//  Copyright © 2017 JDev. All rights reserved.
//

import UIKit

final class BrowseViewController: UIViewController {
    
    private let embeddedBrowser = AuthenticatedBrowserViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Embed the authenticated browser as a child view controller
        addChild(embeddedBrowser)
        embeddedBrowser.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(embeddedBrowser.view)
        NSLayoutConstraint.activate([
            embeddedBrowser.view.topAnchor.constraint(equalTo: view.topAnchor),
            embeddedBrowser.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            embeddedBrowser.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            embeddedBrowser.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        embeddedBrowser.didMove(toParent: self)

        if let url = URL(string: "https://ezinflatables.odoo.com/shop") {
            embeddedBrowser.configure(url: url, title: "Browse", injectShopCSS: true, showNavButtons: true)
        }
    }
}

*/
