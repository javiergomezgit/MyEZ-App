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
    /// Progress view reflecting the current loading progress of the web view.
    let progressView = UIProgressView(progressViewStyle: .default)
    
    /// The observation object for the progress of the web view (we only receive notifications until it is deallocated).
    private var estimatedProgressObserver: NSKeyValueObservation?
    
    // MARK: - Public methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadCustomBars(updateBar: true)
      
        loadWeb()
        
        testingfromShopify()
      
    }
    
    func testingfromShopify() {
        
//        let client = Graph.Client(
//            shopDomain: "ez-inflatables-inc.myshopify.com",
//            apiKey:     "e78a3a7c6015dbc918bf038db8596328"
//        )
        
        
//        let query = Storefront.buildQuery { $0
//            
//            .shop { $0
//                .name()
//                .description()
//                .moneyFormat()
//                .paymentSettings() { $0
//                    .shopifyPaymentsAccountId()
//                }
//            }
//            .products(first:5) { $0
//                .edges { $0
//                    .node() { $0
//                        .id()
//                        .description()
//                        .title()
//                        .handle()
//                        .images(first:1) { $0
//                            .edges { $0
//                                .node { $0
//                                    .id()
//                                    .originalSrc()
//                                }
//                            }
//                        }
//                    }
//                }
//                .hashValue
//            }
//            .customer(customerAccessToken: "2147803791402") { $0
//                .firstName()
//                .email()
//                .displayName()
//                .addresses() { $0
//                    .edges() { $0
//                        .node() { $0
//                            .id()
//                        }
//                    }
//                }
//            }
//            .collections(first:1) { $0
//                .edges() { $0
//                    .node() { $0
//                        .title()
//                    }
//                }
//            }
//        }
//    
//        
//        
//        
//        let task = client.queryGraphWith(query) { response, error in
//          
//            if let response = response {
//                let name = response.shop.name
//                print (name)
//                print (response.shop)
//                print (response.shop.description)
//                print (response.shop.moneyFormat)
//                print (response.shop.paymentSettings)
//                print (response.products)
//                print (response.products.edges)
//                print (response.products.fields)
//                
//                print (response.collections)
//                
//                print (response.customer)
//                print (response.customer?.addresses)
//                print (response.customer?.email)
//                print (response.customer?.firstName)
//            } else {
//                print("Query failed: \(error)")
//            }
//        }
//        task.resume()
        
        
        //CREate USER SUCCESSFULlY
//        let input = Storefront.CustomerCreateInput.create(email: "john.smith@gmail.com", password: "123456")
//
//        let mutation = Storefront.buildMutation { $0
//            .customerCreate(input: input) { $0
//                .customer { $0
//                    .id()
//                    .email()
//                    .firstName()
//                    .lastName()
//                }
//                .userErrors { $0
//                    .field()
//                    .message()
//                }
//            }
//        }
//
//        let task = client.mutateGraphWith(mutation, completionHandler: { (response, error) in
//            if let response = response {
//
//                print (response)
//                print (response.fields)
//            } else {
//                print (error)
//            }
//        })
//        task.resume()
    
        
        
//  SIGNIN USER
//        let input = Storefront.CustomerAccessTokenCreateInput.create(
//            email:    "john.smith@gmail.com",
//            password: "123456"
//        )
//
//        let mutation = Storefront.buildMutation { $0
//            .customerAccessTokenCreate(input: input) { $0
//                .customerAccessToken { $0
//                    .accessToken()
//                    .expiresAt()
//                }
//                .userErrors { $0
//                    .field()
//                    .message()
//                }
//            }
//        }
//        let task = client.mutateGraphWith(mutation, completionHandler: { (response, error) in
//            if let response = response {
//
//                print (response)
//                print (response.fields)
//            } else {
//                print (error)
//            }
//        })
//        task.resume()
        
        
        //reset a customer's password using a recovery token:
//        let customerID = GraphQL.ID(rawValue: "Z2lkOi8vc2hvcGlmeS9DdXN0b21lci8yMTU3NTA3ODM3OTk0")
//        let input      = Storefront.CustomerResetInput.create(resetToken: "9a3364188282d0cb0090c22a101ca0b4", password: "abc123") //need token that user received in email
//        let mutation   = Storefront.buildMutation { $0
//            .customerReset(id: customerID, input: input) { $0
//                .customer { $0
//                    .id()
//                    .firstName()
//                    .lastName()
//                }
//                .userErrors { $0
//                    .field()
//                    .message()
//                }
//            }
//        }
//
//        let task = client.mutateGraphWith(mutation) { response, error in
//            if let mutation = response?.customerReset {
//
//                if let customer = mutation.customer, !mutation.userErrors.isEmpty {
//                    let firstName = customer.firstName
//                    let lastName = customer.lastName
//
//                    print (firstName)
//                } else {
//
//                    print("Failed to reset password. Encountered invalid fields:")
//                    mutation.userErrors.forEach {
//                        let fieldPath = $0.field?.joined() ?? ""
//                        print("  \(fieldPath): \($0.message)")
//                    }
//                }
//
//            } else {
//                print("Failed to reset password: \(error)")
//            }
//        }
//        task.resume()
        
        //SENDING EMAL TO RESET PASSWORD
//        let mutation = Storefront.buildMutation { $0
//            .customerRecover(email: "javier.go.go@hotmail.com") { $0
//                .userErrors { $0
//                    .field()
//                    .message()
//                }
//            }
//        }
//
//        let task = client.mutateGraphWith(mutation, completionHandler: { (response, error) in
//            if let response = response {
//
//                print (response)
//                print (response.fields)
//            } else {
//                print (error)
//            }
//        })
//
        
        
        //READING TOKEN AND LOGIN AFTER THAT
//        let input = Storefront.CustomerAccessTokenCreateInput.create(
//            email:    "javier.go.go@hotmail.com",
//            password: "javier"
//        )
//
//        let mutation = Storefront.buildMutation { $0
//            .customerAccessTokenCreate(input: input) { $0
//                .customerAccessToken { $0
//                    .accessToken()
//                    .expiresAt()
//                }
//                .userErrors { $0
//                    .field()
//                    .message()
//                }
//            }
//        }
//
//        var token = "8d654f070f11e2196eca519e3f3b3b4a"
//        let task = client.mutateGraphWith(mutation, completionHandler: { (response, error) in
//            if let response = response {
//
//                let values = response.fields.values
//                print (values)
//                print (values.count)
//                print (type(of: values))
//
//                let val = values.first as? [String: Any]
//                print (val)
//
//                print (val?.first)
//                print (val?.values)
//                print (val?.keys)
//
//                print (val!["customerAccessToken"])
//
//                let va = val!["customerAccessToken"] as? [String: Any]
//
//                print (va?.values)
//                print (va?.keys)
//                print (val?.count)
//
//                print (va!["accessToken"])
//
//
//                let tokens = va!["accessToken"]
//                token = tokens as! String
//
//            } else {
//                print (error)
//            }
//        })
//        task.resume()
//
//
//        let query = Storefront.buildQuery { $0
//            .customer(customerAccessToken: token) { $0
//                .id()
//                .firstName()
//                .lastName()
//                .email()
//            }
//        }
//
//        let task1 = client.queryGraphWith(query) { (response, error) in
//            if let response = response {
//                print (response)
//                print (response.fields)
//
//            } else {
//                print (error)
//            }
//        }
//        task1.resume()
    

    }
        

   
    
    //Load web embed on the view
    func loadWeb() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
        
        setupProgressView()
        setupEstimatedProgressObserver()
        
        if let initialUrl = URL(string: "https://www.ezinflatables.com/collections/testing") {
            setupWebview(url: initialUrl)
        }
    }
    
    //Load custom navigation bar with 2 different buttons
    func loadCustomBars(updateBar: Bool){
        let backBrowserImage = UIImage(named: "backwardBrowser")
        let leftButton = UIBarButtonItem(image: backBrowserImage, style: .plain, target: self, action: #selector(self.goBackward))
        
        let refreshBrowserImage  = UIImage(named: "refreshBrowser")
        let rightButton = UIBarButtonItem(image: refreshBrowserImage, style: .plain, target: self, action: #selector(self.refreshBrowser))
        
        navigationItem.setLeftBarButton(leftButton, animated: true)
        navigationItem.setRightBarButton(rightButton, animated: true)
    }
    
    //Functions for browser buttons
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
    
    private func setupWebview(url: URL) {
        let request = URLRequest(url: url)
        
        webView.navigationDelegate = self
        webView.load(request)
    }
}

// MARK: - WKNavigationDelegate
extension BrowseViewController: WKNavigationDelegate {
    
    func webView(_: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        UIView.transition(with: progressView,
                          duration: 0.33,
                          options: [.transitionCrossDissolve],
                          animations: {
                            self.progressView.isHidden = false
        },
                          completion: nil)
    }
    
    func webView(_: WKWebView, didFinish _: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        UIView.transition(with: progressView,
                          duration: 0.33,
                          options: [.transitionCrossDissolve],
                          animations: {
                            self.progressView.isHidden = true
        },
                          completion: nil)
    }
}
