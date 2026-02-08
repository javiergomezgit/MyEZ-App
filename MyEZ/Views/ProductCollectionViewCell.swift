//
//  ProductCollectionViewCell.swift
//  MyEZ
//
//  Created by Javier Gomez on 8/29/19.
//  Copyright © 2019 JDev. All rights reserved.
//

import UIKit

class ProductCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var productImageView: UIImageView!
    @IBOutlet weak var inStockImageView: UIImageView!
    @IBOutlet weak var favoriteImageView: UIImageView!
    @IBOutlet weak var salePriceLabel: UILabel!
    @IBOutlet weak var reguarPriceLabel: UILabel!
    @IBOutlet weak var nameProductLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
