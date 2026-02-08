//
//  ShopViewController.swift
//  MyEZ
//
//  Created by Javier Gomez on 8/27/19.
//  Copyright © 2019 JDev. All rights reserved.
//

import UIKit


class ShopViewController: UIViewController {
    
    @IBOutlet weak var chooserProductsStock: UISegmentedControl!
    @IBOutlet weak var productsContainer: UIView!
    @IBOutlet weak var stockContainer: UIView!
    
    let buttonBar = UIView()


    override func viewDidLoad() {
        
        chooserProductsStock.addTarget(self, action: #selector(segmentedControlValueChanged(_:)), for: .valueChanged)

        chooserProductsStock.backgroundColor = .clear
        chooserProductsStock.tintColor = .clear
        
        chooserProductsStock.setTitleTextAttributes([
            NSAttributedString.Key.font : UIFont(name: "DINCondensed-Bold", size: 18),
            NSAttributedString.Key.foregroundColor: UIColor.lightGray
            ], for: .normal)
        
        chooserProductsStock.setTitleTextAttributes([
            NSAttributedString.Key.font : UIFont(name: "DINCondensed-Bold", size: 18),
            NSAttributedString.Key.foregroundColor: UIColor.orange
            ], for: .selected)
        

        // This needs to be false since we are using auto layout constraints
        buttonBar.translatesAutoresizingMaskIntoConstraints = false
        buttonBar.backgroundColor = UIColor.orange
      
        view.addSubview(buttonBar)
        
        // Constrain the top of the button bar to the bottom of the segmented control
        buttonBar.topAnchor.constraint(equalTo: chooserProductsStock.bottomAnchor).isActive = true
        buttonBar.heightAnchor.constraint(equalToConstant: 5).isActive = true
        // Constrain the button bar to the left side of the segmented control
        buttonBar.leftAnchor.constraint(equalTo: chooserProductsStock.leftAnchor).isActive = true
        // Constrain the button bar to the width of the segmented control divided by the number of segments
        buttonBar.widthAnchor.constraint(equalTo: chooserProductsStock.widthAnchor, multiplier: 1 / CGFloat(chooserProductsStock.numberOfSegments)).isActive = true
    }
    
    
    
    @objc func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        UIView.animate(withDuration: 0.3) {
            self.buttonBar.frame.origin.x = (self.chooserProductsStock.frame.width / CGFloat(self.chooserProductsStock.numberOfSegments)) * CGFloat(self.chooserProductsStock.selectedSegmentIndex)
        }
        
        if chooserProductsStock.selectedSegmentIndex == 0 {
            //prodcuts on
            productsContainer.alpha = 1.0
            stockContainer.alpha = 0.0
        } else {
            //stock on
            productsContainer.alpha = 0.0
            stockContainer.alpha = 1.0
        }
    }


}
