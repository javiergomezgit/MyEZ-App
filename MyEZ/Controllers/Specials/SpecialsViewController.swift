//
//  SpecialsViewController.swift
//  MyEZ
//
//  Created by Javier Gomez on 10/20/17.
//  Copyright © 2017 JDev. All rights reserved.
//

import UIKit
import NVActivityIndicatorView


class SpecialsViewController: UIViewController {

    @IBOutlet weak var selectSpecialsInStock: UISegmentedControl!
    
    @IBOutlet weak var reloadIndicator: NVActivityIndicatorView!
    
    @IBOutlet weak var inStockContainer: UIView!
    @IBOutlet weak var dealsContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reloadIndicator.type = .orbit
    }
    
    @IBAction func specialsInStockChanged(_ sender: UISegmentedControl) {
         if selectSpecialsInStock.selectedSegmentIndex == 0 {
            inStockContainer.alpha = 0.0
            dealsContainer.alpha = 1.0
         } else {
            inStockContainer.alpha = 1.0
            dealsContainer.alpha = 0.0
        }
    }
}



