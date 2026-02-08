//
//  ProductViewController.swift
//  MyEZ
//
//  Created by Javier Gomez on 8/29/19.
//  Copyright © 2019 JDev. All rights reserved.
//

import UIKit

class ProductViewController: UIViewController {

    @IBOutlet weak var imagen1: UIImageView!
    @IBOutlet weak var stockImageView: UIImageView!
    @IBOutlet weak var favoriteImageView: UIImageView!
    @IBOutlet weak var unitPhotoImageView: UIImageView!
    
    
    var imageName: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupImageView()
    }
    
    private func setupImageView() {
        guard let name = imageName else { return }
        
        if let image = UIImage(named: name) {
            imagen1.image = image
        }
    }
    

    
}
